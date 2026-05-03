#!/usr/bin/env bash
set -euo pipefail

bash scripts/verify-commit-prompt.sh || exit 1
bash scripts/build.sh
bash scripts/test.sh
