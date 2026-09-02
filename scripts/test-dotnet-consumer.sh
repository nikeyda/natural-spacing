#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
dotnet_cli="${NATURAL_SPACING_DOTNET:-dotnet}"
dotnet_home="${NATURAL_SPACING_DOTNET_HOME:-/tmp/natural-spacing-dotnet-consumer-home}"

mkdir -p "$dotnet_home"

DOTNET_CLI_HOME="$dotnet_home" \
DOTNET_CLI_TELEMETRY_OPTOUT=1 \
DOTNET_NOLOGO=1 \
DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
"$dotnet_cli" run \
  --project "$project_root/examples/consumers/dotnet/NaturalSpacing.Consumer.csproj" \
  --configuration Release \
  --nologo

echo ".NET consumer smoke passed: an independent ProjectReference imported and exercised the core."
