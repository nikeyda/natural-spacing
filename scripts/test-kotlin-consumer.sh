#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"

"$project_root/packages/kotlin/gradlew" \
  --no-daemon \
  --project-dir "$project_root/examples/consumers/kotlin" \
  run \
  :android-host:assembleDebug

echo "Kotlin consumer smoke passed: an independent composite build exercised the core and compiled Android Views/Compose source consumers."
