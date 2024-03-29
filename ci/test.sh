#!/usr/bin/env bash

set -eu -o pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
source "$PROJECT_ROOT/ci/resources.sh"

export CI_SKIP_TEST=""
export CI_IMAGE_NAME=""
export CI_EVENT_TYPE="push"
export CI_DOCKER_START_TIMEOUT=180

while getopts ":i:e:T:hs" opt; do
  case $opt in
  s) CI_SKIP_TEST="y" ;;
  i) CI_IMAGE_NAME="$OPTARG" ;;
  T) CI_DOCKER_START_TIMEOUT="$OPTARG" ;;
  e)
    case "$OPTARG" in
    push | cron) CI_EVENT_TYPE="$OPTARG" ;;
    *)
      echo >&2 "Invalid event type: $OPTARG"
      exit 1
      ;;
    esac
    ;;
  h)
    echo "Usage: $0 [options]"
    echo "Options:"
    echo -e "\t-i <string>\tDocker image name without version tag."
    echo -e "\t-s         \tSkip running tests"
    echo -e "\t-T         \tStart timeout before considering the test failed."
    echo -e "\t-e <string>\tEvent type. Valid types: api, cron"
    echo -e "\t-h         \tShows this help message"
    exit 0
    ;;
  *)
    echo >&2 "Invalid option: -$OPTARG. Use \"-h\" to get help."
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [[ "$CI_EVENT_TYPE" == "cron" ]]; then
  BUILD_DIR="$PROJECT_ROOT/var/.build"
  write_info "Change directory to $BUILD_DIR"
  cd "$BUILD_DIR"
  GIT_HASH="$(git rev-list -n 1 HEAD)"
fi

# TODO: support multi-arch image test

write_info "Download python requirements: "
pip_install_ci_requirements

write_info "Check if the test was not set to be skipped and the python test exists."
if [[ "$CI_SKIP_TEST" != "y" ]] && [[ -f "test/__init__.py" ]]; then
  write_info "Start testing..."

  export HTTPD_IMAGE_NAME="$CI_IMAGE_NAME"
  export HTTPD_IMAGE_TAG="$GIT_HASH"
  export HTTPD_WAIT_TIMEOUT="$CI_DOCKER_START_TIMEOUT"
  py.test

  write_info "All tests are finished"
else
  write_info "Skipping tests"
fi