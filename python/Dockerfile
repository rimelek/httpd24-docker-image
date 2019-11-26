FROM python:3.7-alpine

RUN apk add \
    docker-cli \
    git \
    openssh-client

ARG APP_USER="app"
ARG APP_USER_ID="1000"
ARG APP_USER_HOME="/home/app"

ARG APP_GROUP="${APP_USER}"
ARG APP_GROUP_ID="${APP_USER_ID}"
ARG APP_DOCKER_GROUP="docker"
ARG APP_DOCKER_GROUP_ID="131"

RUN addgroup -g "${APP_GROUP_ID}" "${APP_GROUP}" \
 && adduser -u "${APP_USER_ID}" -G "${APP_GROUP}" -h "${APP_USER_HOME}" -D "${APP_USER}" \
 && addgroup -g "${APP_DOCKER_GROUP_ID}" "${APP_DOCKER_GROUP}" \
 && addgroup "${APP_USER}" "${APP_DOCKER_GROUP}" \
 && pip install virtualenv \
 && virtualenv /venv \
 && chown -R ${APP_USER}:${APP_GROUP} /venv

ENV PATH="/venv/bin:$PATH"

USER ${APP_USER}