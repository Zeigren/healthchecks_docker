#!/bin/sh
source /env_secrets_expand.sh
set -e

if [ ! -f "$APP_ROOT/secret_key.txt" ]; then
  echo "Creating Secret Key"
  cat > "$APP_ROOT/password.awk" <<EOF
BEGIN {
    srand();
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    s = "";
    for(i=0;i<50;i++) {
        s = s "" substr(chars, int(rand()*62), 1);
    }
    print s
}

EOF
  awk -f password.awk > "$APP_ROOT/secret_key.txt"
  rm password.awk
fi

echo "Creating gunicorn.conf.py"
# https://docs.gunicorn.org/en/stable/configure.html
cat > "$APP_ROOT/gunicorn.conf.py" <<EOF
import multiprocessing

bind = "0.0.0.0:8000"

workers = ${GUNICORN_WORKERS:-multiprocessing.cpu_count() * 2}

max_requests = 1000
max_requests_jitter = 50

EOF

echo "Creating local_settings.py"
# https://docs.djangoproject.com/en/3.2/ref/settings/
cat > "$APP_HOME/local_settings.py" <<EOF
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if os.getenv("SECRET_KEY"):
    # Secret key from environment variable
    SECRET_KEY = os.getenv("SECRET_KEY").strip()
else:
    # Secret key from file
    SECRET_KEY = open("${APP_ROOT}/secret_key.txt", "r").read().strip()

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.getenv("DB_NAME", BASE_DIR + "/db/hc.sqlite"),
    }
}

DEBUG = ${DEBUG:-False}
STATIC_ROOT = "${APP_STATIC:-/usr/src/static}"

# SMTP credentials for sending email
EMAIL_HOST_PASSWORD = "${EMAIL_HOST_PASSWORD:-}"

# Discord integration
DISCORD_CLIENT_SECRET = "${DISCORD_CLIENT_SECRET:-}"

# LINE Notify
LINENOTIFY_CLIENT_SECRET = "${LINENOTIFY_CLIENT_SECRET:-}"

# Matrix
MATRIX_ACCESS_TOKEN = "${MATRIX_ACCESS_TOKEN:-}"

# PagerDuty
PD_VENDOR_KEY = "${PD_VENDOR_KEY:-}"

# Pushover integration
PUSHOVER_API_TOKEN = "${PUSHOVER_API_TOKEN:-}"

# Pushbullet integration
PUSHBULLET_CLIENT_SECRET = "${PUSHBULLET_CLIENT_SECRET:-}"

# Slack integration
SLACK_CLIENT_SECRET = "${SLACK_CLIENT_SECRET:-}"

# Telegram integration -- override in local_settings.py
TELEGRAM_TOKEN = "${TELEGRAM_TOKEN:-}"

# SMS and WhatsApp (Twilio) integration
TWILIO_AUTH = "${TWILIO_AUTH:-}"

# Trello
TRELLO_APP_KEY = "${TRELLO_APP_KEY:-}"

EOF

# https://docs.djangoproject.com/en/3.2/ref/django-admin/
echo "Running database migrations and collecting static files"
python manage.py makemigrations
python manage.py migrate --noinput
python manage.py collectstatic --noinput
python manage.py compress
python manage.py clearsessions
echo "Static files collected and database migrations completed!"

if [ "$PRUNE_PINGS" = "True" ]; then
  echo "Removing old records from the api_ping table, keeping 100 most recent pings"
  python manage.py prunepings
  echo "Pings pruned!"
fi

if [ "$PRUNE_NOTIFICATIONS" = "True" ]; then
  echo "Removing old notification records"
  python manage.py prunenotifications
  echo "Notification records pruned!"
fi

if [ "$PRUNE_USERS" = "True" ]; then
  echo "Pruning users who have not logged in within the past 6 months"
  python manage.py pruneusers
  echo "Pruned users!"
fi

if [ "$PRUNE_TOKEN_BUCKET" = "True" ]; then
  echo "Removing records older than one day from the api_tokenbucket table"
  python manage.py prunetokenbucket
  echo "api_tokenbucket pruned!"
fi

if [ "$PRUNE_FLIPS" = "True" ]; then
  echo "Pruning flip objects from more than 3 months ago"
  python manage.py pruneflips
  echo "Flip objects pruned!"
fi

# Currently Broken
# manage.py createsuperuser: error: unrecognized arguments: --noinput
if [ "$CREATE_SUPERUSER" = "True" ]; then
  echo "Creating superuser"
  python manage.py createsuperuser --noinput
fi

echo "Running sendalerts"
nohup python manage.py sendalerts >/dev/null 2>&1 &

exec "$@"
