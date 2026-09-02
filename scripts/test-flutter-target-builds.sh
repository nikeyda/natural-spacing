#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_cli="${NATURAL_SPACING_FLUTTER:-flutter}"
target_list="${NATURAL_SPACING_FLUTTER_TARGETS:-web}"
pub_cache="${NATURAL_SPACING_FLUTTER_PUB_CACHE:-/tmp/natural-spacing-flutter-pub-cache}"
config_home="${NATURAL_SPACING_FLUTTER_CONFIG_HOME:-/tmp/natural-spacing-flutter-config}"
storage_base_url="${NATURAL_SPACING_FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}"
pub_hosted_url="${NATURAL_SPACING_FLUTTER_PUB_HOSTED_URL:-https://pub.dev}"
smoke_dir="$(mktemp -d "${TMPDIR:-/tmp}/natural-spacing-flutter-targets.XXXXXX")"

cleanup() {
  rm -rf "$smoke_dir"
}
trap cleanup EXIT

run_flutter() {
  CI=true FLUTTER_SKIP_UPDATE_CHECK=true FLUTTER_SUPPRESS_ANALYTICS=true \
    FLUTTER_STORAGE_BASE_URL="$storage_base_url" PUB_HOSTED_URL="$pub_hosted_url" \
    PUB_CACHE="$pub_cache" XDG_CONFIG_HOME="$config_home" \
    "$flutter_cli" "$@"
}

mkdir -p "$pub_cache" "$config_home"
run_flutter create \
  --empty \
  --platforms="$target_list" \
  --project-name natural_spacing_target_smoke \
  "$smoke_dir"

cp "$project_root/examples/acceptance/flutter/lib/main.dart" "$smoke_dir/lib/main.dart"
run_flutter pub add \
  --directory "$smoke_dir" \
  "natural_spacing@{path: $project_root/packages/dart}" \
  "natural_spacing_flutter@{path: $project_root/packages/flutter}"

(
  cd "$smoke_dir"
  run_flutter analyze

  case "$(uname -s)" in
    Darwin) bundle_target="darwin" ;;
    Linux) bundle_target="linux-x64" ;;
    MINGW*|MSYS*|CYGWIN*) bundle_target="windows-x64" ;;
    *) echo "Unsupported bundle host: $(uname -s)" >&2; exit 1 ;;
  esac
  run_flutter build bundle --debug --target-platform="$bundle_target"

  IFS=',' read -r -a targets <<< "$target_list"
  for target in "${targets[@]}"; do
    case "$target" in
      web) run_flutter build web --debug ;;
      macos) run_flutter build macos --debug ;;
      ios) run_flutter build ios --simulator --debug --no-codesign ;;
      android) run_flutter build apk --debug ;;
      windows) run_flutter build windows --debug ;;
      *) echo "Unsupported Flutter target: $target" >&2; exit 1 ;;
    esac
  done
)

echo "Flutter target smoke passed: bundle plus $target_list."
