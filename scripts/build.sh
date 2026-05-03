#!/usr/bin/env bash
set -euo pipefail

bash scripts/generate-xcodeproj.sh
swift build --product VoiceBarApp
