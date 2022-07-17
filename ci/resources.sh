#!/usr/bin/env bash

GIT_HASH="$(git rev-list -n 1 HEAD)"
PATTERN_MINOR_BRANCH='^\([0-9]\+\.[0-9]\+\)\(-dev\)\?$'
PATTERN_STABLE_VERSION='[0-9]\+\.[0-9]\+\.[0-9]\+'
PARENT_IMAGE="httpd:2.4"

function write_status() {
  echo "${1:-}" | awk -v "label=$2" '{ gsub(/^/, "-- ["label"] -- "); print $0 }'
}

function write_info() {
  write_status "$1" "info"
}

function reqVar() {
  : "${!1?\$${1} is not set}"
}

function reqVarNonEmpty() {
  : "${!1:?\$${1} is Empty}"
}

function toBool() {
  local BOOL
  BOOL=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case ${BOOL} in
  1 | yes | on | true) echo "true" ;;
  0 | no | off | false) echo "false" ;;
  *) echo "null" ;;
  esac
}

function isBranch() {
  reqVarNonEmpty CI_BRANCH
  [[ "$CI_BRANCH" == "$CI_TAG" ]] && echo 'false' || echo 'true'
}

function isTag() {
  [[ "$(isBranch)" == "false" ]] && echo 'true' || echo 'false'
}

function isMinorBranch() {
  reqVarNonEmpty CI_BRANCH

  local RESULT
  RESULT="$(echo "$CI_BRANCH" | sed 's/'"$PATTERN_MINOR_BRANCH"'//g')"
  [[ -z "$RESULT" ]] && echo 'true' || echo 'false'
}

function getVersions() {
  local BRANCH="${1:-}"
  if [[ -z "$BRANCH" ]]; then
    git tag --list 'v[0-9]*' --sort '-v:refname' | trimVersionFlag | grep -i '^'"$PATTERN_STABLE_VERSION"'\(-[^ ]\+\)\?$'
  else
    local BRANCH_PATTERN
    BRANCH_PATTERN=$(echo "$BRANCH" | sed 's/\./\\./g')
    git tag --list 'v[0-9]*' --sort '-v:refname' | trimVersionFlag | grep -i '^'"$PATTERN_STABLE_VERSION"'\(-[^ ]\+\)\?$' | grep '^'"$BRANCH_PATTERN"
  fi
}

function getStableVersions() {
  getVersions "${1:-}" | grep -i '^'"$PATTERN_STABLE_VERSION"'$'
}

function trimVersionFlag() {
  sed 's/^v\(.*\)/\1/g'
}

function getLatestVersion() {
  getVersions "$1" | head -n1
}

function getLatestStableVersion() {
  getStableVersions "${1:-}" | head -n 1
}

function getLatestStableOrPreVersion() {
  local BRANCH="$1"
  reqVarNonEmpty BRANCH
  LATEST_VERSION="$(getLatestStableVersion "$BRANCH")"
  if [[ -z "$LATEST_VERSION" ]]; then
    LATEST_VERSION="$(getLatestVersion "$BRANCH")"
  fi
  echo "$LATEST_VERSION"
}

function getStableMajorVersions() {
  getStableVersions | cut -d "." -f1 | trimVersionFlag | uniq
}

function getStableMinorVersionsOfMajor() {
  getStableVersions | grep '^'"$1"'.[0-9]\+\.[0-9]\+$' | cut -d "." -f1-2 | trimVersionFlag | uniq
}

function getStablePatchVersionsOfMinor() {
  getStableVersions | grep '^'"$1"'.[0-9]\+$' | trimVersionFlag | uniq
}

function getLatestStableVersionOfMajor() {
  getStableVersions | grep '^'"$1"'.[0-9]\+\.[0-9]\+$' | trimVersionFlag | uniq | head -n1
}

function getLatestStableVersionOfMinor() {
  getStableVersions | grep '^'"$1"'.[0-9]\+$' | trimVersionFlag | uniq | head -n1
}


function isValidSemanticVersion() {
  local VERSION="$1"
  local RESULT
  RESULT="$(python -c "import semantic_version; print(semantic_version.validate('$VERSION'))")"
  [[ "$RESULT" == "True" ]] && echo "true" || echo "false"
}

function isPreRelease() {
  local VERSION="$1"
  local RESULT
  RESULT="$(python -c "import semantic_version; print(len(semantic_version.Version('$VERSION').prerelease) > 0)")"
  [[ "$RESULT" == "True" ]] && echo "true" || echo "false"
}

function toMinorDevVersion() {
  local VERSION="$1"
  echo "$VERSION" | sed 's/'"$PATTERN_MINOR_BRANCH"'/\1-dev/g'
}

function getImageLayers() {
  local IMAGE="$1"
  docker image inspect -f '{{range $key, $value := .RootFS.Layers}}{{printf "%s\n" $value}}{{end}}' "$IMAGE" | head -n -1
}

function isParentImageUpgraded() {
  local IMAGE="$1"
  local PARENT_IMAGE="$2"

  reqVarNonEmpty IMAGE
  reqVarNonEmpty PARENT_IMAGE

  local LAYERS
  local PARENT_LAYERS

  LAYERS="$(getImageLayers "$IMAGE")"
  PARENT_LAYERS="$(getImageLayers "$PARENT_IMAGE")"

  local RESULT
  RESULT="$(echo "$LAYERS" | grep "$(echo "$PARENT_LAYERS" | tail -n 1)")"
  [[ -z "$RESULT" ]] && echo "true" || echo "false"
}

function isImageDownloaded() {
  local IMAGE="$1"
  docker image inspect "$IMAGE" &>/dev/null && echo 'true' || echo 'false'
}

function deployCommandGen() (
  local GIT_HASH
  GIT_HASH="$(git rev-list -n 1 HEAD)"
  local SEMANTIC_VERSION="false"
  local CURRENT_VERSION=""
  local LATEST_VERSION=""
  local LATEST_MINOR=""
  local LATEST_MAJOR=""
  local CUSTOM_TAGS=""
  local IMAGE_NAME=""
  local IMAGE_TAG="$GIT_HASH"
  local OPTIND
  local OPTARG

  while getopts ":v:l:m:M:i:t:T:s" opt; do
    case $opt in
    v) CURRENT_VERSION="$OPTARG" ;;
    l) LATEST_VERSION="$OPTARG" ;;
    m) LATEST_MINOR="$OPTARG" ;;
    M) LATEST_MAJOR="$OPTARG" ;;
    i) IMAGE_NAME="$OPTARG" ;;
    t) IMAGE_TAG="$OPTARG" ;;
    s) SEMANTIC_VERSION="true" ;;
    T) CUSTOM_TAGS="$CUSTOM_TAGS $OPTARG" ;;
    *)
      echo >&2 "Invalid flag: $opt"
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  function tag() { echo "docker tag \"$IMAGE_NAME:$IMAGE_TAG\" \"$IMAGE_NAME:$1\""; }
  function push() { echo "docker push \"$IMAGE_NAME:$1\""; }
  function pushAs() {
    if [[ "$IMAGE_TAG" != "$1" ]]; then
      tag "$1"
    fi
    push "$1"
  }

  local CURRENT_VALID
  local LATEST_VALID

  CURRENT_VALID="$(isValidSemanticVersion "$CURRENT_VERSION")"
  LATEST_VALID="$(isValidSemanticVersion "$LATEST_VERSION")"
  if [[ -z "$IMAGE_NAME" ]]; then
    echo >&2 "IMAGE_NAME is empty"
    exit 1
  fi
  if [[ -n "$CURRENT_VERSION" ]]; then
    if [[ "$CURRENT_VALID" != "true" ]] && [[ -n "$CURRENT_VERSION" ]]; then
      echo >&2 "Invalid CURRENT_VERSION: $CURRENT_VERSION"
      return 1
    fi
    if [[ "$LATEST_VALID" != "true" ]] && [[ -n "$LATEST_VERSION" ]]; then
      echo >&2 "Invalid LATEST_VERSION: $LATEST_VERSION"
      return 1
    fi

    pushAs "$CURRENT_VERSION"

    if [[ "$SEMANTIC_VERSION" == "true" ]]; then
      if [[ -z "$LATEST_MINOR" ]]; then
        # LATEST_MINOR="$(getLatestStableVersion "$(echo "$CURRENT_VERSION" | cut -d . -f1-2)")"
        LATEST_MINOR="$(getLatestStableVersionOfMinor "$(echo "$CURRENT_VERSION" | cut -d . -f1-2)")"
      fi

      if [[ -z "$LATEST_MAJOR" ]]; then
        # LATEST_MAJOR="$(git tag -l "v$(echo "$CURRENT_VERSION" | cut -d . -f1).*")"
        LATEST_MAJOR="$(getLatestStableVersionOfMajor "$(echo "$CURRENT_VERSION" | cut -d . -f1)")"
      fi

      if [[ -z "$LATEST_VERSION" ]]; then
        LATEST_VERSION="$(getLatestStableVersion)"
      fi

      # push commands

      if [[ "$LATEST_MINOR" == "$CURRENT_VERSION" ]]; then
        pushAs "$(echo "$CURRENT_VERSION" | cut -d . -f1-2)"
      fi

      if [[ "$LATEST_MAJOR" == "$CURRENT_VERSION" ]]; then
        pushAs "$(echo "$CURRENT_VERSION" | cut -d . -f1)"
      fi

      if [[ -n "$LATEST_VERSION" ]] && [[ "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
        pushAs latest
      fi
    fi
  fi

  pushAs "$GIT_HASH"

  for i in $CUSTOM_TAGS; do
    pushAs "$i"
  done
)

function dcdCommandGen() {
  reqVarNonEmpty VERSION
  reqVarNonEmpty CI_IMAGE_NAME
  reqVarNonEmpty CI_EVENT_TYPE
  reqVarNonEmpty PROJECT_ROOT

  if [[ "$CI_EVENT_TYPE" == "cron" ]]; then
    cd "$PROJECT_ROOT"
    if [[ "$(isBranch)" ]]; then
      reqVarNonEmpty CI_BRANCH
      if [[ "$(isMinorBranch)" == "true" ]]; then
        LATEST_VERSION="$(getLatestStableOrPreVersion "$CI_BRANCH")"
        if [[ -n "$LATEST_VERSION" ]]; then
          reqVarNonEmpty CI_BUILD_NUMBER
          if [[ "$(isImageDownloaded "$CI_IMAGE_NAME:build-$CI_BUILD_NUMBER")" == "true" ]]; then
            deployCommandGen -v "$LATEST_VERSION" -i "$CI_IMAGE_NAME" -t "build-$CI_BUILD_NUMBER" -s
          fi
        fi
      fi
    fi
  else
    if [ "$(isValidSemanticVersion "$VERSION")" == "true" ]; then
      deployCommandGen -v "$VERSION" -i "$CI_IMAGE_NAME" -s
    elif [ "$(isMinorBranch "$VERSION")" == "true" ]; then
      deployCommandGen -T "$(toMinorDevVersion "$VERSION")" -i "$CI_IMAGE_NAME"
    fi
  fi

}
