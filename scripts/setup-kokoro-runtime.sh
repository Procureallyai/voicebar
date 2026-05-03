#!/usr/bin/env bash
set -euo pipefail

runtime_root="${KOKORO_RUNTIME_ROOT:-$HOME/Library/Application Support/VoiceBar/runtime/kokoro-venv}"
python_bin="${PYTHON_BIN:-}"

if [[ -z "$python_bin" ]]; then
  for candidate in "$(command -v python3.12 || true)" /opt/homebrew/bin/python3.12 /usr/local/bin/python3.12; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      python_bin="$candidate"
      break
    fi
  done
fi

if [[ ! -x "$python_bin" ]]; then
  echo "Kokoro runtime setup failed: python executable not found at $python_bin" >&2
  echo "Set PYTHON_BIN to a Python 3.12 executable and retry." >&2
  exit 1
fi

if "$python_bin" - <<'PY' ; then
import sys
raise SystemExit(0 if sys.version_info[:2] == (3, 12) else 1)
PY
  true
else
  echo "Kokoro runtime setup failed: $python_bin is not Python 3.12." >&2
  echo "Set PYTHON_BIN to a Python 3.12 executable and retry." >&2
  exit 1
fi

mkdir -p "$(dirname "$runtime_root")"

"$python_bin" -m venv "$runtime_root"

source "$runtime_root/bin/activate"
python -m pip install --upgrade pip
python -m pip install "kokoro>=0.9.2" soundfile

python - <<'PY'
from kokoro import KPipeline

pipeline = KPipeline(lang_code='a')
print("Kokoro runtime warmup complete.")
print("Sample rate:", 24000)
print("Pipeline class:", type(pipeline).__name__)
PY

echo "Kokoro runtime ready at: $runtime_root"
