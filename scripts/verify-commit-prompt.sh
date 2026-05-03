#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-origin/main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

if ! git rev-parse "$BASE_REF" >/dev/null 2>&1; then
  echo "Base ref '$BASE_REF' does not exist yet; skipping traceability check."
  exit 0
fi

BASE="$(git merge-base "$BASE_REF" HEAD)"

if [ -z "$BASE" ]; then
  echo "Could not compute merge base with $BASE_REF."
  exit 1
fi

FAIL=0

# GitHub pull_request workflows check out a synthetic merge commit at HEAD.
# VoiceBar lanes use linear topic-branch history, so enforce traceability on
# authored non-merge commits rather than the synthetic merge ref.
for sha in $(git rev-list --no-merges "$BASE"..HEAD); do
  msg="$(git show -s --format=%B "$sha")"
  if ! printf '%s' "$msg" | grep -q '^Prompt-Artifact:'; then
    echo "Missing Prompt-Artifact traceability in commit: $sha"
    FAIL=1
    continue
  fi

  while IFS= read -r artifact_line; do
    artifact_path="$(printf '%s' "${artifact_line#Prompt-Artifact:}" | sed 's/^[[:space:]]*//')"
    if [[ "$artifact_path" = /* ]]; then
      artifact_abs="$artifact_path"
    else
      artifact_abs="$REPO_ROOT/$artifact_path"
    fi

    if [ ! -f "$artifact_abs" ]; then
      echo "Prompt-Artifact path does not exist for commit $sha: $artifact_path"
      FAIL=1
    fi
  done < <(printf '%s\n' "$msg" | grep '^Prompt-Artifact:')
done

exit "$FAIL"
