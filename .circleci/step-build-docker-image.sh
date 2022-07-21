#!/usr/bin/env bash

./ci/local-builder.sh ./ci/build.sh \
  -i "$HTTPD_IMAGE_NAME" \
  -t "$CIRCLE_TAG" \
  -b "$CIRCLE_BRANCH" \
  -e "$CI_EVENT_TYPE" \
  -B "circleci-$CIRCLE_BUILD_NUM" \
  -R "$CI_REPOSITORY_URL"
