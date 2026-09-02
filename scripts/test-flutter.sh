#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_cli="${NATURAL_SPACING_FLUTTER:-flutter}"
pub_cache="${NATURAL_SPACING_FLUTTER_PUB_CACHE:-/tmp/natural-spacing-flutter-pub-cache}"
config_home="${NATURAL_SPACING_FLUTTER_CONFIG_HOME:-/tmp/natural-spacing-flutter-config}"
storage_base_url="${NATURAL_SPACING_FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}"
pub_hosted_url="${NATURAL_SPACING_FLUTTER_PUB_HOSTED_URL:-https://pub.dev}"

mkdir -p "$pub_cache" "$config_home"

for package_path in \
  "$project_root/packages/flutter" \
  "$project_root/examples/consumers/flutter" \
  "$project_root/examples/acceptance/flutter"
do
  (
    cd "$package_path"
    CI=true FLUTTER_SKIP_UPDATE_CHECK=true FLUTTER_SUPPRESS_ANALYTICS=true \
      FLUTTER_STORAGE_BASE_URL="$storage_base_url" PUB_HOSTED_URL="$pub_hosted_url" \
      PUB_CACHE="$pub_cache" XDG_CONFIG_HOME="$config_home" "$flutter_cli" pub get
    CI=true FLUTTER_SKIP_UPDATE_CHECK=true FLUTTER_SUPPRESS_ANALYTICS=true \
      FLUTTER_STORAGE_BASE_URL="$storage_base_url" PUB_HOSTED_URL="$pub_hosted_url" \
      PUB_CACHE="$pub_cache" XDG_CONFIG_HOME="$config_home" "$flutter_cli" analyze
    CI=true FLUTTER_SKIP_UPDATE_CHECK=true FLUTTER_SUPPRESS_ANALYTICS=true \
      FLUTTER_STORAGE_BASE_URL="$storage_base_url" PUB_HOSTED_URL="$pub_hosted_url" \
      PUB_CACHE="$pub_cache" XDG_CONFIG_HOME="$config_home" "$flutter_cli" test
  )
done
