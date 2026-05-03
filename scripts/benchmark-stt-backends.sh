#!/usr/bin/env bash
set -euo pipefail

# Benchmarks local STT backends on synthetic utterances that mirror
# Prompt 037 operator scenarios. Uses whisper.cpp by default and can
# optionally benchmark an MLX command if VOICEBAR_MLX_STT_COMMAND is set.
#
# MLX command template requirements:
# - Must print transcript text to stdout.
# - Must exit non-zero on failure.
# - Must include the literal token {audio}, which this script replaces
#   with the generated wav path.
#
# Example:
# VOICEBAR_MLX_STT_COMMAND='swift run --package-path /path/to/mlx-bench STTBench --audio "{audio}"'

WHISPER_BINARY="${VOICEBAR_WHISPER_CPP_BINARY:-$HOME/Library/Application Support/VoiceBar/runtime/whisper.cpp/source/build/bin/whisper-cli}"
WHISPER_MODEL="${VOICEBAR_WHISPER_CPP_MODEL:-$HOME/Library/Application Support/VoiceBar/runtime/whisper.cpp/models/ggml-base.en.bin}"
WHISPER_THREADS="${VOICEBAR_WHISPER_CPP_THREADS:-8}"
VOICE_NAME="${VOICEBAR_STT_BENCH_VOICE:-Samantha}"
MLX_COMMAND_TEMPLATE="${VOICEBAR_MLX_STT_COMMAND:-}"

if ! command -v say >/dev/null 2>&1; then
  echo "Error: macOS 'say' command is required." >&2
  exit 1
fi

if ! command -v afconvert >/dev/null 2>&1; then
  echo "Error: macOS 'afconvert' command is required." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required." >&2
  exit 1
fi

if [[ ! -x "$WHISPER_BINARY" ]]; then
  echo "Error: whisper.cpp binary not found or not executable at: $WHISPER_BINARY" >&2
  exit 1
fi

if [[ ! -f "$WHISPER_MODEL" ]]; then
  echo "Error: whisper.cpp model file not found at: $WHISPER_MODEL" >&2
  exit 1
fi

if [[ -n "$MLX_COMMAND_TEMPLATE" ]] && [[ "$MLX_COMMAND_TEMPLATE" != *"{audio}"* ]]; then
  echo "Error: VOICEBAR_MLX_STT_COMMAND must include the '{audio}' placeholder." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d -t voicebar-stt-bench)"
trap 'rm -rf "$TMP_DIR"' EXIT

declare -a IDS=(
  "short_testing"
  "list_numbered"
  "prose_newline"
  "long_toggle"
  "long_hold"
)

declare -a TEXTS=(
  "testing one two three"
  "make this a numbered list one apples two oranges three pears"
  "this is a new line of products"
  "this is a long continuous toggle dictation sample where i keep speaking for around fifteen seconds without intentional silence so we can inspect end to end latency and confirm that speech is not cut off unexpectedly in the middle of an utterance"
  "this is a long hold to talk sample where i keep speaking while the key would normally be held down and then release at the end to trigger insertion with minimal delay for a productivity workflow"
)

declare -a RATES=(185 180 180 145 150)

runtime_ms() {
  local cmd="$1"
  python3 - <<'PY' "$cmd"
import subprocess
import sys
import time

cmd = sys.argv[1]
started = time.time()
subprocess.run(["/bin/zsh", "-lc", cmd], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
ended = time.time()
print(f"{(ended - started) * 1000:.0f}")
PY
}

runtime_ms_with_output() {
  local cmd="$1"
  python3 - <<'PY' "$cmd"
import subprocess
import sys
import time

cmd = sys.argv[1]
started = time.time()
completed = subprocess.run(["/bin/zsh", "-lc", cmd], check=True, capture_output=True, text=True)
ended = time.time()
stdout = completed.stdout.strip().replace("\n", " ")
print(f"{(ended - started) * 1000:.0f}|{stdout}")
PY
}

audio_duration_seconds() {
  local wav_path="$1"
  afinfo "$wav_path" 2>/dev/null | awk -F': ' '/estimated duration/ {print $2}' | awk '{print $1}' | head -n1
}

echo "VoiceBar STT backend benchmark"
echo "Whisper binary: $WHISPER_BINARY"
echo "Whisper model:  $WHISPER_MODEL"
echo "Whisper threads: $WHISPER_THREADS"
if [[ -n "$MLX_COMMAND_TEMPLATE" ]]; then
  echo "MLX command: configured"
else
  echo "MLX command: not configured (set VOICEBAR_MLX_STT_COMMAND to enable)"
fi

echo
printf "%-16s %-11s %-11s %-11s %-11s %-11s\n" "utterance" "audio_s" "whisper_cold" "whisper_warm" "mlx_cold" "mlx_warm"
printf "%-16s %-11s %-11s %-11s %-11s %-11s\n" "--------" "-------" "------------" "------------" "--------" "--------"

whisper_cold_total=0
whisper_warm_total=0
mlx_cold_total=0
mlx_warm_total=0
mlx_count=0

for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"
  text="${TEXTS[$i]}"
  rate="${RATES[$i]}"

  aiff="$TMP_DIR/${id}.aiff"
  wav="$TMP_DIR/${id}.wav"

  /usr/bin/say -v "$VOICE_NAME" -r "$rate" -o "$aiff" "$text"
  /usr/bin/afconvert -f WAVE -d LEI16@16000 "$aiff" "$wav" >/dev/null 2>&1

  audio_s="$(audio_duration_seconds "$wav")"

  whisper_out1="$TMP_DIR/${id}-whisper-cold"
  whisper_out2="$TMP_DIR/${id}-whisper-warm"

  whisper_cmd1="\"$WHISPER_BINARY\" -m \"$WHISPER_MODEL\" -f \"$wav\" -l en -np -nt -otxt -of \"$whisper_out1\" -t \"$WHISPER_THREADS\""
  whisper_cmd2="\"$WHISPER_BINARY\" -m \"$WHISPER_MODEL\" -f \"$wav\" -l en -np -nt -otxt -of \"$whisper_out2\" -t \"$WHISPER_THREADS\""

  whisper_cold_ms="$(runtime_ms "$whisper_cmd1")"
  whisper_warm_ms="$(runtime_ms "$whisper_cmd2")"

  whisper_cold_total=$((whisper_cold_total + whisper_cold_ms))
  whisper_warm_total=$((whisper_warm_total + whisper_warm_ms))

  mlx_cold="n/a"
  mlx_warm="n/a"

  if [[ -n "$MLX_COMMAND_TEMPLATE" ]]; then
    mlx_cmd1="${MLX_COMMAND_TEMPLATE//\{audio\}/$wav}"
    mlx_cmd2="${MLX_COMMAND_TEMPLATE//\{audio\}/$wav}"

    mlx_cold_pair="$(runtime_ms_with_output "$mlx_cmd1")"
    mlx_warm_pair="$(runtime_ms_with_output "$mlx_cmd2")"

    mlx_cold="${mlx_cold_pair%%|*}"
    mlx_warm="${mlx_warm_pair%%|*}"

    mlx_cold_total=$((mlx_cold_total + mlx_cold))
    mlx_warm_total=$((mlx_warm_total + mlx_warm))
    mlx_count=$((mlx_count + 1))
  fi

  whisper_cold_label="${whisper_cold_ms}ms"
  whisper_warm_label="${whisper_warm_ms}ms"
  mlx_cold_label="$mlx_cold"
  mlx_warm_label="$mlx_warm"

  if [[ "$mlx_cold" != "n/a" ]]; then
    mlx_cold_label="${mlx_cold}ms"
  fi

  if [[ "$mlx_warm" != "n/a" ]]; then
    mlx_warm_label="${mlx_warm}ms"
  fi

  printf "%-16s %-11s %-11s %-11s %-11s %-11s\n" "$id" "$audio_s" "$whisper_cold_label" "$whisper_warm_label" "$mlx_cold_label" "$mlx_warm_label"
done

echo
python3 - <<'PY' "$whisper_cold_total" "$whisper_warm_total" "${#IDS[@]}" "$mlx_cold_total" "$mlx_warm_total" "$mlx_count"
import sys

whisper_cold_total = int(sys.argv[1])
whisper_warm_total = int(sys.argv[2])
count = int(sys.argv[3])
mlx_cold_total = int(sys.argv[4])
mlx_warm_total = int(sys.argv[5])
mlx_count = int(sys.argv[6])

print(f"Whisper average cold: {whisper_cold_total / count:.0f}ms")
print(f"Whisper average warm: {whisper_warm_total / count:.0f}ms")

if mlx_count > 0:
    print(f"MLX average cold:     {mlx_cold_total / mlx_count:.0f}ms")
    print(f"MLX average warm:     {mlx_warm_total / mlx_count:.0f}ms")
else:
    print("MLX averages:         unavailable (no VOICEBAR_MLX_STT_COMMAND configured)")
PY

echo
cat <<'EOT'
Notes:
- "cold" and "warm" here are first vs immediate second run for the same utterance in this script session.
- This benchmark measures STT backend latency only; it does not include live microphone capture, dictation stop heuristics, formatter, or insertion.
- For end-to-end runtime truth, pair this script with app diagnostics (`dictation.capture.completed` + `dictation.pipeline.latency`).
EOT
