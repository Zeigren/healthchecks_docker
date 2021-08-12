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


FROM python:alpine AS production

ARG DATE
ARG VERSION

LABEL org.opencontainers.image.created=$DATE \
    org.opencontainers.image.authors="Zeigren" \
    org.opencontainers.image.url="https://github.com/Zeigren/healthchecks_docker" \
    org.opencontainers.image.source="https://github.com/Zeigren/healthchecks_docker" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.title="zeigren/healthchecks"

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
