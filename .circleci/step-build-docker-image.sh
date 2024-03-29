#!/usr/bin/env bash

command=(
  ./ci/local-builder.sh
  ./ci/build.sh
  -i "$HTTPD_IMAGE_NAME"
  -t "$CIRCLE_TAG"
  -b "$CIRCLE_BRANCH"
  -e "$CI_EVENT_TYPE"
  -B "circleci-$CIRCLE_BUILD_NUM"
  -R "$CI_REPOSITORY_URL"
)

if [[ "${CI_DEBUG+x}" == "x" ]] && [[ "$CI_DEBUG" != "" ]]; then
  command+=(-d)
fi

"${command[@]}"