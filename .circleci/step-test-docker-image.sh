#!/usr/bin/env bash

./ci/local-builder.sh ./ci/test.sh \
  -i "$HTTPD_IMAGE_NAME" \
  -e "$CI_EVENT_TYPE" \
  -T "$HTTPD_WAIT_TIMEOUT"