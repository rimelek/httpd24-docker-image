#!/usr/bin/env bash

set -e

PROJECT_ROOT="${0%/*}/.."
cd "$PROJECT_ROOT"

source "$PROJECT_ROOT/ci/resources.sh"

CI_BRANCH=""
CI_TAG=""
CI_IMAGE_NAME=""
CI_EVENT_TYPE=""
CI_BUILD_NUMBER="${GIT_HASH}"

while getopts ":t:b:i:e:B:dh" opt; do
  case $opt in
  t) CI_TAG="$OPTARG" ;;
  b) CI_BRANCH="$OPTARG" ;;
  i) CI_IMAGE_NAME="$OPTARG" ;;
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
    echo "Usage: $0 [-t <string>] [-b <string>] [-i <string>] [-h]"
    echo "Options:"
    echo -e "\t-t <string>\tGit commit tag if the build was triggered by tag. Do not use it anyway!"
    echo -e "\t-b <string>\tGit branch if the build was triggered by branch. If \"-t\" was given too, \"-b\" will always be ignored!"
    echo -e "\t-i <string>\tDocker image name without version tag."
    echo -e "\t-e <string>\tEvent type. Valid types: "
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
reqVarNonEmpty CI_EVENT_TYPE

# remove first character if that is "v"
# remember CI_BRANCH is CI_TAG if tag was set
VERSION=$(echo "$CI_BRANCH" | trimVersionFlag)

DCD_COMMAND="$(dcdCommandGen)"

echo "DCD COMMAND:"
echo "$DCD_COMMAND"

if [[ -n "$DCD_COMMAND" ]]; then
  eval "$DCD_COMMAND"
fi
