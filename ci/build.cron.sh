write_info "Get the latest version"

LATEST_VERSION="$(getLatestStableOrPreVersion "$CI_BRANCH")"
if [[ -z "$LATEST_VERSION" ]]; then
  write_info "There is no stable version nor pre-release $CI_BRANCH"
  exit 0
fi
write_info "LATEST_VERSION=$LATEST_VERSION"

write_info "Set cache image tag to $LATEST_VERSION"
VERSION_CACHE="$LATEST_VERSION"

write_info "Try to pull image cache image: $CI_IMAGE_NAME:$VERSION_CACHE"
docker pull "$CI_IMAGE_NAME:$VERSION_CACHE" || true

write_info "Prepare build directory"
BUILD_DIR="$PROJECT_ROOT/var/.build"
if [[ -d "$BUILD_DIR" ]]; then
  rm -rf "$BUILD_DIR"
fi

write_info "Check if the the repository URL is not defined or empty"
if [[ "${CI_REPOSITORY_URL-x}" == "x" ]] || [[ -z "$CI_REPOSITORY_URL" ]]; then
  write_info "Repository URL is not defined."
  write_info "Get repository URL from the repository: $CI_REPOSITORY_ALIAS"
  CI_REPOSITORY_URL="$(git remote get-url "$CI_REPOSITORY_ALIAS")"
fi

write_info "Cloning from $CI_REPOSITORY_URL to $BUILD_DIR"
git clone --branch "v$LATEST_VERSION" "$CI_REPOSITORY_URL" "$BUILD_DIR"
cd "$BUILD_DIR"

write_info "Download python requirements: "
pip install -r requirements.txt

# update git commit hash
GIT_HASH="$(git rev-list -n 1 HEAD)"
write_info "Download $PARENT_IMAGE to see if it was upgraded since the last build"
docker pull "$PARENT_IMAGE"

image="$CI_IMAGE_NAME:$GIT_HASH"
write_info "Check if $image is available locally"
if [[ "$(isImageDownloaded "$image")" != "true" ]]; then
  write_info "Pull $image to compare with $PARENT_IMAGE"
  docker pull "$image"
fi

write_info "Check if $PARENT_IMAGE is the parent of $image, which means httpd:2.4 was upgraded since the last update."
if [[ "$(isParentImageUpgraded "$image" "$PARENT_IMAGE")" == "true" ]]; then

  write_info "Build the new docker image using $CI_IMAGE_NAME:$VERSION_CACHE as cache".
  write_info "Add the following tags to the image: "
  write_info "- $CI_IMAGE_NAME:$GIT_HASH"
  write_info "- $CI_IMAGE_NAME:build-$CI_BUILD_NUMBER"

  docker build . --pull \
    --cache-from "$CI_IMAGE_NAME:$VERSION_CACHE" \
    --tag "$CI_IMAGE_NAME:$GIT_HASH" \
    --tag "$CI_IMAGE_NAME:build-$CI_BUILD_NUMBER"

  write_info "Check if the test was not set to be skipped and the python test exists."

  if [[ "$CI_SKIP_TEST" != "y" ]] && [[ -f "test/__init__.py" ]]; then

    write_info "Start testing..."

    export HTTPD_IMAGE_NAME="$CI_IMAGE_NAME"
    export HTTPD_IMAGE_TAG="$GIT_HASH"
    export HTTPD_WAIT_TIMEOUT="$CI_DOCKER_START_TIMEOUT"
    py.test

    write_info "All tests are finished"
  fi
else
  write_info "Parent image is not upgraded. New build is not necessary."
fi
