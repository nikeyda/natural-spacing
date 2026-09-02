#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data_path="${NATURAL_SPACING_IOS_DERIVED_DATA:-/tmp/natural-spacing-ios-derived}"
device_udid="$({
  xcrun simctl list devices available --json
} | ruby -rjson -e '
  document = JSON.parse(STDIN.read)
  devices = document.fetch("devices").values.flatten
  device = devices.find do |candidate|
    candidate.fetch("name", "").start_with?("iPhone") &&
      candidate.fetch("isAvailable", true)
  end
  abort("No available iPhone Simulator was found.") if device.nil?
  puts device.fetch("udid")
')"

cd "$project_root"
xcodebuild test \
  -scheme NaturalSpacing-Package \
  -destination "platform=iOS Simulator,id=$device_udid" \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO
