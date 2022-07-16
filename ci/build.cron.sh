
LATEST_VERSION="$(getLatestStableOrPreVersion "$CI_BRANCH")"
if [[ -z "$LATEST_VERSION" ]]; then
  echo "There is no stable version nor pre-release $CI_BRANCH"
  exit 0
fi

VERSION_CACHE="$LATEST_VERSION"
docker pull "$CI_IMAGE_NAME:$VERSION_CACHE" || true
BUILD_DIR="/tmp/.build"
if [[ -d "$BUILD_DIR" ]]; then
  rm -rf "$BUILD_DIR"
fi
if [[ "${CI_REPOSITORY_URL+x}" == "x" ]]; then
  CI_REPOSITORY_URL="$(git remote get-url "$CI_REPOSITORY_ALIAS")"
fi

git clone --branch "v$LATEST_VERSION" "$CI_REPOSITORY_URL" "$BUILD_DIR"
cd "$BUILD_DIR"
# update git commit hash
GIT_HASH="$(git rev-list -n 1 HEAD)"
docker pull httpd:2.4

image="$CI_IMAGE_NAME:$GIT_HASH"
if [[ "$(isImageDownloaded "$image")" != "true" ]]; then
  docker pull "$image"
fi
if [[ "$(isParentImageUpgraded "$image" "httpd:2.4")" == "true" ]]; then
  docker build . --pull \
    --cache-from "$CI_IMAGE_NAME:$VERSION_CACHE" \
    --tag "$CI_IMAGE_NAME:$GIT_HASH" \
    --tag "$CI_IMAGE_NAME:build-$CI_BUILD_NUMBER"

  if [[ "${CI_SKIP_TEST}" != "y" ]] && [[ -f "test/__init__.py" ]]; then
    export HTTPD_IMAGE_NAME="$CI_IMAGE_NAME"
    export HTTPD_IMAGE_TAG="$GIT_HASH"
    export HTTPD_WAIT_TIMEOUT="$CI_DOCKER_START_TIMEOUT"
    py.test
  fi
else
  echo "Parent image is not upgraded. New build is not necessary."
fi
