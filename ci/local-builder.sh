#!/usr/bin/env bash

set -eu -o pipefail

(
  cd "$(dirname "$0")"

  workdir="$(cd .. && pwd)"

  docker-compose -f local-builder.yml build
  docker-compose -f local-builder.yml run --rm -v "$workdir:$workdir" --workdir "$workdir" ci "$@"
)