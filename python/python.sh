#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

if [[ -z "$*" ]]; then
  ./run.sh
else
  ./run.sh python "$@"
fi