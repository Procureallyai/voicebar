#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_CANDIDATE_DIR="$ROOT_DIR/build/public-release-candidate/voicebar"
SIBLING_CANDIDATE_DIR="$(cd "$ROOT_DIR/.." && pwd)/voicebar-public-release-candidate"
CANDIDATE_DIR="${1:-$DEFAULT_CANDIDATE_DIR}"
if [[ "$CANDIDATE_DIR" != /* ]]; then
    CANDIDATE_DIR="$PWD/$CANDIDATE_DIR"
fi

canonical_existing_path() {
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

canonical_target_path() {
    python3 -c 'import os, sys; parent=os.path.realpath(os.path.dirname(sys.argv[1])); print(os.path.join(parent, os.path.basename(sys.argv[1])))' "$1"
}

ROOT_DIR="$(canonical_existing_path "$ROOT_DIR")"
DEFAULT_CANDIDATE_DIR="$ROOT_DIR/build/public-release-candidate/voicebar"
SIBLING_CANDIDATE_DIR="$(canonical_target_path "$SIBLING_CANDIDATE_DIR")"
CANDIDATE_DIR="$(canonical_target_path "$CANDIDATE_DIR")"

case "$CANDIDATE_DIR" in
    "$ROOT_DIR"/build/public-release-candidate/voicebar|"$ROOT_DIR"/build/public-release-candidate/voicebar/*)
        ;;
    "$SIBLING_CANDIDATE_DIR")
        ;;
    *)
        echo "Refusing to export outside the known safe candidate path: $CANDIDATE_DIR" >&2
        echo "Expected path under: $ROOT_DIR/build/public-release-candidate/voicebar" >&2
        echo "Or exact sibling path: $SIBLING_CANDIDATE_DIR" >&2
        exit 1
        ;;
esac

ALLOWLIST_PATHS=(
    ".github/CODEOWNERS"
    ".github/ISSUE_TEMPLATE"
    ".github/pull_request_template.md"
    ".github/workflows/local-build-ci.yml"
    ".gitignore"
    ".xcodegen-version"
    "CODE_OF_CONDUCT.md"
    "CONTRIBUTING.md"
    "Config"
    "LICENSE"
    "NOTICE"
    "Package.resolved"
    "Package.swift"
    "README.md"
    "ROADMAP.md"
    "SECURITY.md"
    "Sources"
    "THIRD_PARTY_NOTICES.md"
    "docs/open-source"
    "docs/product"
    "docs/video"
    "project.yml"
    "scripts"
)

EXCLUDED_BASENAMES=(
    ".DS_Store"
)

EXCLUDED_RELATIVE_PATHS=(
    "docs/open-source/hosted-review-scan-triage.md"
    "docs/open-source/hosted-staging-validation-report.md"
    "docs/open-source/hosted-public-staging-report.md"
    "docs/open-source/public-release-checklist.md"
    "docs/open-source/public-release-candidate-report.md"
)

echo "Exporting sanitized public tree..."
echo "Source: $ROOT_DIR"
echo "Candidate: $CANDIDATE_DIR"

for path in "${ALLOWLIST_PATHS[@]}"; do
    if [ ! -e "$ROOT_DIR/$path" ]; then
        echo "Allowlisted path does not exist: $path" >&2
        exit 1
    fi
done

for path in "${ALLOWLIST_PATHS[@]}"; do
    if find "$ROOT_DIR/$path" -type l -print -quit | grep -q .; then
        echo "Refusing to copy allowlisted path with symlinks: $path" >&2
        find "$ROOT_DIR/$path" -type l -print >&2
        exit 1
    fi
done

rm -rf "$CANDIDATE_DIR"
mkdir -p "$CANDIDATE_DIR"

for path in "${ALLOWLIST_PATHS[@]}"; do
    mkdir -p "$CANDIDATE_DIR/$(dirname "$path")"
    cp -pR "$ROOT_DIR/$path" "$CANDIDATE_DIR/$path"
done

for basename in "${EXCLUDED_BASENAMES[@]}"; do
    find "$CANDIDATE_DIR" -name "$basename" -exec rm -f {} +
done

for path in "${EXCLUDED_RELATIVE_PATHS[@]}"; do
    rm -f "$CANDIDATE_DIR/$path"
done

echo "Candidate tree ready: $CANDIDATE_DIR"
