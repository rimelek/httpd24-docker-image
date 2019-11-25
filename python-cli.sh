#!/usr/bin/env bash

set -eu

cd "$(dirname "$0")"

if [[ -z "$*" ]]; then
  ./python.sh
else
  ./python.sh python "$@"
fi