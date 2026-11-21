#!/usr/bin/env bash
set -euo pipefail

: "${RUST_SERVER:?Set RUST_SERVER before running this script}"

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

webdev serve --auto=refresh web:9321 -- \
  "--define=build_web_compilers:ddc=environment={\"RUST_SERVER\":\"${RUST_SERVER}\"}"
  