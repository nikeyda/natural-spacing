#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data_path="${NATURAL_SPACING_IOS_ACCEPTANCE_DERIVED_DATA:-/tmp/natural-spacing-ios-acceptance-derived}"

xcodebuild build -quiet \
  -project "$project_root/examples/acceptance/ios/NaturalSpacingIOSAcceptance.xcodeproj" \
  -scheme NaturalSpacingIOSAcceptance \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO

app_path="$derived_data_path/Build/Products/Debug-iphonesimulator/NaturalSpacingIOSAcceptance.app"
test -x "$app_path/NaturalSpacingIOSAcceptance"
test -f "$app_path/Info.plist"

echo "iOS acceptance host compiled: $app_path"
