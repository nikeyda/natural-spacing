#!/usr/bin/env bash
set -euo pipefail

flutter_version="3.47.2"
archive_name="flutter_linux_${flutter_version}-stable.tar.xz"
archive_sha256="447878859d01ca9bfdb99a85f245af07ed8a15fedcd9d189c4749e8e92d1f185"
archive_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$archive_name"
runner_temp="${RUNNER_TEMP:-/tmp}"
install_dir="${NATURAL_SPACING_FLUTTER_INSTALL_DIR:-$runner_temp/natural-spacing-flutter-$flutter_version}"
archive_path="$runner_temp/$archive_name"
flutter_bin="$install_dir/flutter/bin"

if [[ ! -x "$flutter_bin/flutter" ]]; then
  mkdir -p "$install_dir"
  curl -L --fail --silent --show-error --retry 5 \
    --output "$archive_path" \
    "$archive_url"
  printf '%s  %s\n' "$archive_sha256" "$archive_path" | sha256sum --check --strict
  tar -xJf "$archive_path" -C "$install_dir"
  rm -f "$archive_path"
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$flutter_bin" >> "$GITHUB_PATH"
else
  printf 'Add %s to PATH.\n' "$flutter_bin"
fi
