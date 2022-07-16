VERSION_CACHE="$GIT_HASH"
if [ "$(isBranch)" == "true" ]; then
  VERSION_CACHE="$CI_BRANCH"
  if [ "${VERSION_CACHE:${#VERSION_CACHE}-4}" != "-dev" ]; then
    VERSION_CACHE="${VERSION_CACHE}-dev"
  fi
fi

echo "Trying to pull cache image..."
docker pull "$CI_IMAGE_NAME:$VERSION_CACHE" || true

if [ "$(isBranch)" == "true" ]; then
  echo "Download python requirements: "
  echo
  pip install -r "$PROJECT_ROOT/ci/requirements.txt"

  echo "Setting cache image..."
  cache_from_args=()
  if docker image inspect "$CI_IMAGE_NAME:$VERSION_CACHE" 1>/dev/null; then
    cache_from_args=(--cache-from "$CI_IMAGE_NAME:$VERSION_CACHE")
  fi

  echo "Building image..."
  docker build . --pull "${cache_from_args[@]}" --tag "$CI_IMAGE_NAME:$GIT_HASH"

  if [ "$CI_SKIP_TEST" != "y" ]; then
    export HTTPD_IMAGE_NAME="$CI_IMAGE_NAME"
    export HTTPD_IMAGE_TAG="$GIT_HASH"
    export HTTPD_WAIT_TIMEOUT="$CI_DOCKER_START_TIMEOUT"
    py.test
  fi
fi
