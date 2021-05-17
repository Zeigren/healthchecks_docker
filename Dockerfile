ARG VERSION

FROM python:alpine AS build

ARG VERSION

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=true
ENV APP_ROOT="/usr/src/app"
ENV APP_HOME="/usr/src/app/hc"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV APP_REPO="https://github.com/healthchecks/healthchecks.git"

RUN apk add --no-cache \
    gcc git jpeg-dev libffi-dev musl-dev postgresql-dev zlib-dev

RUN git clone --branch ${VERSION} --depth 1 ${APP_REPO} ${APP_ROOT} \
    && python -m venv $VIRTUAL_ENV \
    && pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -U -r /usr/src/app/requirements.txt gunicorn

COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR ${APP_ROOT}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gunicorn", "-c", "gunicorn.conf.py", "hc.wsgi:application"]


FROM python:alpine AS production

ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$DATE \
    org.label-schema.vendor="Zeigren" \
    org.label-schema.name="zeigren/healthchecks" \
    org.label-schema.url="https://hub.docker.com/r/zeigren/healthchecks" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url=$URL \
    org.label-schema.vcs-branch=$BRANCH \
    org.label-schema.vcs-ref=$COMMIT

ENV PYTHONUNBUFFERED 1
ENV APP_ROOT="/usr/src/app"
ENV APP_HOME="/usr/src/app/hc"
ENV VIRTUAL_ENV="/opt/venv"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=build $VIRTUAL_ENV $VIRTUAL_ENV
COPY --from=build $APP_ROOT $APP_ROOT
COPY env_secrets_expand.sh docker-entrypoint.sh /

RUN chmod +x /env_secrets_expand.sh \
    && chmod +x /docker-entrypoint.sh

WORKDIR ${APP_ROOT}

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["gunicorn", "-c", "gunicorn.conf.py", "hc.wsgi:application"]
