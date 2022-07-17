#!/usr/bin/env bash

set -eu -o pipefail

export PROJECT_ROOT="${0%/*}/.."
cd "$PROJECT_ROOT"

export GIT_HASH=""

source "$PROJECT_ROOT/ci/resources.sh"

export CI_DRY_RUN=""
export CI_BRANCH=""
export CI_TAG=""
export CI_IMAGE_NAME=""
export CI_SKIP_TEST=""
export CI_DOCKER_START_TIMEOUT="180"
export CI_EVENT_TYPE=""
export CI_REPOSITORY_ALIAS="origin"
export CI_REPOSITORY_URL=""
export CI_BUILD_NUMBER="$GIT_HASH"

while getopts ":t:b:i:T:e:r:R:B:dhs" opt; do
  case $opt in
  t) CI_TAG="$OPTARG" ;;
  T) CI_DOCKER_START_TIMEOUT="$OPTARG" ;;
  b) CI_BRANCH="$OPTARG" ;;
  i) CI_IMAGE_NAME="$OPTARG" ;;
  s) CI_SKIP_TEST="y" ;;
  r) CI_REPOSITORY_ALIAS="$OPTARG" ;;
  R) CI_REPOSITORY_URL="$OPTARG" ;;
  B) CI_BUILD_NUMBER="$OPTARG" ;;
  e)
    case "$OPTARG" in
    push | api | cron) CI_EVENT_TYPE="$OPTARG" ;;
    *)
      echo >&2 "Invalid event type: $OPTARG"
      exit 1
      ;;
    esac
    ;;
  h)
    echo "Usage: $0 [-t <string>] [-b <string>] [-i <string>] [-e <string>] [-r <string>] [-d] [-s] [-h]"
    echo "Options:"
    echo -e "\t-t <string>\tGit commit tag if the build was triggered by tag. Do not use it anyway!"
    echo -e "\t-b <string>\tGit branch if the build was triggered by branch. If \"-t\" was given too, \"-b\" will always be ignored!"
    echo -e "\t-i <string>\tDocker image name without version tag."
    echo -e "\t-s\t\tSkip running tests"
    echo -e "\t-e <string>\tEvent type. Valid types: "
    echo -e "\t-r <string>\tRemote repository alias. Default: origin"
    echo -e "\t-R <string>\tRemote repository URL. Default: the url of the repository alias"
    echo -e "\t-B <string>\tBuild number. git commit hash by default"
    echo -e "\t-h\t\tShows this help message"
    exit 0
    ;;
  *)
    echo >&2 "Invalid option: -$OPTARG. Use \"-h\" to get help."
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [[ -n "$CI_TAG" ]]; then
  CI_BRANCH="$CI_TAG" # for easier local test
fi

reqVarNonEmpty CI_IMAGE_NAME
reqVarNonEmpty CI_BRANCH
reqVarNonEmpty GIT_HASH
reqVarNonEmpty CI_EVENT_TYPE

write_info "Event type: $CI_EVENT_TYPE"

if [[ "$CI_EVENT_TYPE" == "cron" ]]; then
  write_info "Run cron job"
  write_time_info

  write_info "Check if the build was triggered by pushing to a branch."
  if [[ "$(isBranch)" == "true" ]]; then

    write_info "Check if the name of the branch is a minor version like 2.1 and not 2.1.0"
    if [[ "$(isMinorBranch)" == "true" ]]; then
      write_info "Start building..."
      source "$PROJECT_ROOT/ci/build.cron.sh"
      write_info "The build was finished successfully."
    else
      write_info "The name of the branch is not a minor version: $CI_BRANCH"
    fi
  else
    write_info "The build was not triggerd by pushing to a branch"
  fi
else
  write_info "Start building triggered by pushing to a branch: $CI_BRANCH"
  source "$PROJECT_ROOT/ci/build.push.sh"
  write_info "The build was finished successfully."
fi
