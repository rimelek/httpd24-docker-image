#!/usr/bin/env bash

./ci/local-builder.sh ./ci/deploy.sh \
  -i "$HTTPD_IMAGE_NAME" \
  -I "$HTTPD_IMAGE_NAME_ALTERNATIVE" \
  -t "$CIRCLE_TAG" \
  -b "$CIRCLE_BRANCH" \
  -e "$CI_EVENT_TYPE" \
  -B "circleci-$CIRCLE_BUILD_NUM"