FROM cimg/python:3.7 as base

COPY --chown=circleci:circleci ci/requirements.txt /requirements.txt

RUN pip install -r /requirements.txt

ARG WORKDIR=/app
COPY --chown=circleci:circleci . "$WORKDIR"
WORKDIR "$WORKDIR"