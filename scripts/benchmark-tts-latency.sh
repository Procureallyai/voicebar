#!/usr/bin/env bash
set -euo pipefail

runtime_python="${VOICEBAR_KOKORO_PYTHON:-$HOME/Library/Application Support/VoiceBar/runtime/kokoro-venv/bin/python}"

if [[ ! -x "$runtime_python" ]]; then
  echo "VoiceBar text-to-speech latency benchmark failed: Kokoro python was not found at $runtime_python" >&2
  echo "Run bash scripts/setup-kokoro-runtime.sh, then retry." >&2
  exit 1
fi

"$runtime_python" - <<'PY'
from kokoro import KPipeline
import os
import sys
import time


def milliseconds_since(start):
    return int((time.perf_counter() - start) * 1000)


verbose_segments = os.environ.get("VOICEBAR_TTS_BENCHMARK_VERBOSE_SEGMENTS") == "1"


def synthesize(pipeline, label, text, emit=True):
    request_start = time.perf_counter()
    first_chunk_ms = None
    chunk_count = 0
    sample_count = 0

    for _, _, audio in pipeline(text, voice="af_heart"):
        if first_chunk_ms is None:
            first_chunk_ms = milliseconds_since(request_start)
        chunk_count += 1
        sample_count += len(audio)

    total_ms = milliseconds_since(request_start)
    if chunk_count == 0 or first_chunk_ms is None:
        print(f"{label}: failed because Kokoro produced no audio chunks", file=sys.stderr)
        raise SystemExit(1)

    audio_seconds = sample_count / 24000
    if emit:
        print(
            f"{label}: chars={len(text)} words={len(text.split())} "
            f"first_chunk_ms={first_chunk_ms} total_ms={total_ms} "
            f"chunks={chunk_count} audio_seconds={audio_seconds:.2f}"
        )
    return first_chunk_ms, total_ms


def chunks(words, size):
    return [" ".join(words[index:index + size]) for index in range(0, len(words), size)]


short_text = "VoiceBar quick latency test."
medium_text = (
    "VoiceBar reads a medium paragraph so the operator can compare request setup, "
    "first generated audio, and completion without exposing private text. The "
    "sentence mix is synthetic and intentionally plain."
)
long_text = " ".join(
    ["This synthetic long form latency passage keeps VoiceBar local and avoids private operator content."] * 40
)

print("VoiceBar text-to-speech Kokoro latency benchmark")
bootstrap_start = time.perf_counter()
repo_id = os.environ.get("VOICEBAR_KOKORO_REPO_ID") or None
pipeline = KPipeline(lang_code="a", repo_id=repo_id)
print(f"pipeline_load_ms={milliseconds_since(bootstrap_start)}")

for label, text in {
    "short": short_text,
    "medium": medium_text,
    "long_unsegmented": long_text,
}.items():
    synthesize(pipeline, label, text)

long_words = long_text.split()
for segment_size in (12, 24):
    first_segment_ms = None
    segmented_start = time.perf_counter()
    segment_count = 0
    for segment in chunks(long_words, segment_size):
        segment_first_ms, _ = synthesize(
            pipeline,
            f"long_segment_{segment_size}_words_{segment_count + 1}",
            segment,
            emit=verbose_segments or segment_count == 0,
        )
        if first_segment_ms is None:
            first_segment_ms = segment_first_ms
        segment_count += 1
    print(
        f"long_segmented_{segment_size}_words: segments={segment_count} "
        f"first_segment_ms={first_segment_ms} total_ms={milliseconds_since(segmented_start)}"
    )
PY
