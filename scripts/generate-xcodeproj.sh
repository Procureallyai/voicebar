#!/usr/bin/env bash
set -euo pipefail

required_version="$(tr -d '[:space:]' < .xcodegen-version)"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen ${required_version} is required to generate VoiceBar.xcodeproj." >&2
  exit 1
fi

installed_version="$(xcodegen --version | awk '{print $2}')"
if [[ "${installed_version}" != "${required_version}" ]]; then
  echo "Warning: expected xcodegen ${required_version} but found ${installed_version}; generated project output may drift from the checked-in VoiceBar.xcodeproj." >&2
fi

xcodegen generate
