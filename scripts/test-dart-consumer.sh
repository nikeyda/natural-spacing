#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
consumer_path="$project_root/examples/consumers/dart"
dart_cli="${NATURAL_SPACING_DART:-dart}"
pub_cache="${NATURAL_SPACING_DART_CONSUMER_PUB_CACHE:-/tmp/natural-spacing-dart-consumer-pub-cache}"

mkdir -p "$pub_cache"

(
  cd "$consumer_path"
  PUB_CACHE="$pub_cache" "$dart_cli" pub get --offline
  PUB_CACHE="$pub_cache" "$dart_cli" run bin/main.dart
)

echo "Dart consumer smoke passed: an independent path dependency imported and exercised the core."
