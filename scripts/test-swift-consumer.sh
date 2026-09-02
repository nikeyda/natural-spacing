#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
scratch_path="${NATURAL_SPACING_SWIFT_CONSUMER_BUILD:-/tmp/natural-spacing-swift-consumer-build}"

swift package \
  --package-path "$project_root/examples/consumers/swift" \
  --scratch-path "$scratch_path" \
  clean

swift run \
  --package-path "$project_root/examples/consumers/swift" \
  --scratch-path "$scratch_path" \
  NaturalSpacingConsumer
