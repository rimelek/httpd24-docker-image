#!/usr/bin/env bash

set -eu

export USER_ID="$(id -u)"
export GROUP=$(id -gn)
export GROUP_ID=$(id -g)
export PWD="$(pwd)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

python=(
  docker-compose
  --project-directory "$PROJECT_ROOT"
  --file "$SCRIPT_DIR/docker-compose.yml"
  run
  --rm
  python
)

if [[ -z "$*" ]]; then
  "${python[@]}"
else
  "${python[@]}" "$@"
fi
