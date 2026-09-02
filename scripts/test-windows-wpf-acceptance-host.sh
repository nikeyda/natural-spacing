#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
dotnet_cli="${NATURAL_SPACING_DOTNET:-dotnet}"
dotnet_home="${NATURAL_SPACING_DOTNET_HOME:-/tmp/natural-spacing-dotnet-acceptance-home}"

mkdir -p "$dotnet_home"

DOTNET_CLI_HOME="$dotnet_home" \
DOTNET_CLI_TELEMETRY_OPTOUT=1 \
DOTNET_NOLOGO=1 \
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
"$dotnet_cli" build \
  "$project_root/examples/acceptance/windows-wpf/NaturalSpacing.Wpf.Acceptance.csproj" \
  --configuration Release \
  --nologo

echo "WPF acceptance host compile passed: Release Windows executable built without launch."
