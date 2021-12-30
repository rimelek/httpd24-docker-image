#!/usr/bin/env bash

set -eu -o pipefail

(
  cd "$(dirname "$0")"

  workdir="$(cd .. && pwd)"

  docker-compose-v1 -f local-builder.yml build
  docker-compose-v1 -f local-builder.yml run --rm -v "$workdir:$workdir" --workdir "$workdir" ci bash
)