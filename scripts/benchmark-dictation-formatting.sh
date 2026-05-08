#!/usr/bin/env bash
set -euo pipefail

mode="${1:-deterministic}"
quality="${2:-balanced}"
scratch_path="${VOICEBAR_SWIFT_SCRATCH_PATH:-/tmp/voicebar-dictation-formatting-benchmark}"

case "$mode" in
  deterministic)
    swift run --scratch-path "$scratch_path" VoiceBarDictationBenchmarks --quality "$quality"
    ;;
  live-ollama)
    swift run --scratch-path "$scratch_path" VoiceBarDictationBenchmarks --live-ollama --quality "$quality"
    ;;
  *)
    echo "Usage: bash scripts/benchmark-dictation-formatting.sh [deterministic|live-ollama] [fast|balanced|quality]" >&2
    exit 2
    ;;
esac
