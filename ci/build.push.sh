write_info "Set cache image tag"

VERSION_CACHE="$GIT_HASH"
if [ "$(isBranch)" == "true" ]; then
  VERSION_CACHE="$CI_BRANCH"
  if [ "${VERSION_CACHE:${#VERSION_CACHE}-4}" != "-dev" ]; then
    VERSION_CACHE="${VERSION_CACHE}-dev"
  fi
fi

write_info "Trying to pull cache image: $CI_IMAGE_NAME:$VERSION_CACHE"
docker pull "$CI_IMAGE_NAME:$VERSION_CACHE" || true

write_info "Check if the build was triggered by pushing to a branch"
if [ "$(isBranch)" == "true" ]; then
  write_info "Download python requirements: "
  write_info ""
  pip install -r "$PROJECT_ROOT/ci/requirements.txt"

  write_info "Building '--cache-from' argument for docker build"
  cache_from_args=()
  if docker image inspect "$CI_IMAGE_NAME:$VERSION_CACHE" 1>/dev/null; then
    cache_from_args=(--cache-from "$CI_IMAGE_NAME:$VERSION_CACHE")
  fi

  write_info "Building image with cache: ${cache_from_args[*]}"
  docker build . --pull "${cache_from_args[@]}" --tag "$CI_IMAGE_NAME:$GIT_HASH"

  write_info "Check if the test was not set to be skipped"
  if [ "$CI_SKIP_TEST" != "y" ]; then

    write_info "Start testing..."
    export HTTPD_IMAGE_NAME="$CI_IMAGE_NAME"
    export HTTPD_IMAGE_TAG="$GIT_HASH"
    export HTTPD_WAIT_TIMEOUT="$CI_DOCKER_START_TIMEOUT"
    py.test

    write_info "All tests are finished"
  else
    write_info "Skipping tests"
  fi
else
  write_info "The build was not triggered by pushing to a branch. Skipping build."
fi
