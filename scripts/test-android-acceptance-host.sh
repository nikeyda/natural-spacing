#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"

"$project_root/packages/kotlin/gradlew" \
  --no-daemon \
  --project-dir "$project_root/examples/acceptance/android" \
  :app:lintDebug \
  :app:assembleDebug

echo "Android acceptance host checks passed: lint clean and Debug APK assembled without install or launch."
