#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

if [[ -z "$*" ]]; then
  ./run.sh pip
else
  ./run.sh pip "$@"
fi