#!/usr/bin/env bash
set -euo pipefail

configuration="${CONFIGURATION:-Release}"
derived_data_path="${DERIVED_DATA_PATH:-build/DerivedData}"
export_root="${EXPORT_ROOT:-build/export}"
project_path="${PROJECT_PATH:-VoiceBar.xcodeproj}"
scheme_name="${SCHEME_NAME:-VoiceBar}"
app_name="${APP_NAME:-VoiceBar}"
zip_name="${ZIP_NAME:-VoiceBar-macos-adhoc.zip}"
icon_source_path="${ICON_SOURCE_PATH:-Config/VoiceBar.icns}"
export_bundle_identifier="${EXPORT_BUNDLE_IDENTIFIER:-ai.procureally.voicebar}"
export_codesign_identity="${EXPORT_CODESIGN_IDENTITY:--}"
export_codesign_requirement="${EXPORT_CODESIGN_REQUIREMENT:-}"
minimum_xcode_major=16

show_usage() {
  cat <<'EOF'
Usage: bash scripts/package-app.sh

Build the ad-hoc signed VoiceBar.app bundle from the checked-in Xcode project and
copy it into a stable repo-local export directory for technical tester preview.

Outputs on a full-Xcode machine:
  build/export/VoiceBar.app
  build/export/VoiceBar-macos-adhoc.zip

Install status:
  This is an ad-hoc signed preview artifact path for developers and technical testers.
  It is not a Developer ID signed or Apple-notarized public-user release.

Environment overrides:
  CONFIGURATION
  DERIVED_DATA_PATH (repo-local path)
  EXPORT_ROOT (repo-local path)
  PROJECT_PATH
  SCHEME_NAME
  APP_NAME (simple leaf name)
  ZIP_NAME (simple leaf name)
  ICON_SOURCE_PATH (repo-local path, optional)
  EXPORT_BUNDLE_IDENTIFIER
  EXPORT_CODESIGN_IDENTITY
  EXPORT_CODESIGN_REQUIREMENT
EOF
}

require_repo_local_path() {
  local label="$1"
  local candidate="$2"
  local normalized_candidate
  local path_component
  local -a path_components

  if [[ -z "${candidate}" ]]; then
    echo "${label} must not be empty." >&2
    exit 1
  fi

  if [[ "${candidate}" = /* ]]; then
    echo "${label} must stay repo-local. Received absolute path: ${candidate}" >&2
    exit 1
  fi

  # Normalize away any leading ./ aliases plus trailing slashes so repo-root
  # aliases like "./", ".//", or "././." fail closed before cleanup.
  normalized_candidate="${candidate}"
  while [[ "${normalized_candidate}" == ./* ]]; do
    normalized_candidate="${normalized_candidate#./}"
  done
  while [[ "${normalized_candidate}" == */ ]]; do
    normalized_candidate="${normalized_candidate%/}"
  done

  if [[ -z "${normalized_candidate}" || "${normalized_candidate}" == "." ]]; then
    echo "${label} must not resolve to the repo root. Received: ${candidate}" >&2
    exit 1
  fi

  # Walk each component so empty segments, "." segments, and ".." traversal are
  # rejected before rm -rf touches any operator-provided path override.
  IFS='/' read -r -a path_components <<< "${normalized_candidate}"
  for path_component in "${path_components[@]}"; do
    if [[ -z "${path_component}" || "${path_component}" == "." ]]; then
      echo "${label} must use a normalized repo-local path without empty or '.' segments. Received: ${candidate}" >&2
      exit 1
    fi

    if [[ "${path_component}" == ".." ]]; then
      echo "${label} must not escape the repo root. Received: ${candidate}" >&2
      exit 1
    fi
  done
}

require_no_symlink_prefixes() {
  local label="$1"
  local candidate="$2"
  local normalized_candidate
  local current_path=""
  local path_component
  local -a path_components

  normalized_candidate="${candidate}"
  while [[ "${normalized_candidate}" == ./* ]]; do
    normalized_candidate="${normalized_candidate#./}"
  done
  while [[ "${normalized_candidate}" == */ ]]; do
    normalized_candidate="${normalized_candidate%/}"
  done

  IFS='/' read -r -a path_components <<< "${normalized_candidate}"
  for path_component in "${path_components[@]}"; do
    if [[ -z "${current_path}" ]]; then
      current_path="${path_component}"
    else
      current_path="${current_path}/${path_component}"
    fi

    # Refuse any existing symlinked prefix so rm -rf and mkdir -p stay inside
    # the real repo-local build roots instead of following redirected paths.
    if [[ -L "${current_path}" ]]; then
      echo "${label} must not traverse a symlinked path component. Received: ${candidate}" >&2
      exit 1
    fi
  done
}

require_simple_name() {
  local label="$1"
  local candidate="$2"

  if [[ -z "${candidate}" ]]; then
    echo "${label} must not be empty." >&2
    exit 1
  fi

  if [[ "${candidate}" == */* || "${candidate}" == "." || "${candidate}" == ".." || "${candidate}" == *".."* ]]; then
    echo "${label} must be a simple leaf name. Received: ${candidate}" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "--help" ]]; then
  show_usage
  exit 0
fi

# Prefer an explicit per-command override so packaging can use a full Xcode
# bundle even when the machine-wide selection still points at CLT.
developer_directory="${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || true)}"
developer_directory_source="xcode-select"

if [[ -n "${DEVELOPER_DIR:-}" ]]; then
  developer_directory_source="DEVELOPER_DIR"
fi

if [[ -z "${developer_directory}" ]]; then
  echo "xcode-select did not report an active developer directory. Install and select a full Xcode.app before packaging VoiceBar." >&2
  exit 1
fi

if [[ "${developer_directory}" == *"CommandLineTools" ]]; then
  echo "VoiceBar packaging requires a full Xcode.app, but ${developer_directory_source} currently points at Command Line Tools: ${developer_directory}" >&2
  echo "Use bash scripts/build.sh, bash scripts/test.sh, and bash scripts/ci.sh on this machine until a full Xcode.app is installed and selected." >&2
  echo "Alternatively, set DEVELOPER_DIR to a full Xcode.app's Contents/Developer path before running this script." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is unavailable even though xcode-select points at ${developer_directory}. Repair the active Xcode.app before packaging VoiceBar." >&2
  exit 1
fi

# Parse the selected Xcode once so failures on an older toolchain explain the
# real mismatch instead of leaving xcodebuild to fail deeper in the build.
xcode_version="$(xcodebuild -version 2>/dev/null | awk 'NR==1 { print $2 }')"
xcode_major="${xcode_version%%.*}"

if [[ -z "${xcode_version}" || ! "${xcode_major}" =~ ^[0-9]+$ ]]; then
  echo "Unable to determine the active Xcode version from xcodebuild -version. Repair the active Xcode.app before packaging VoiceBar." >&2
  exit 1
fi

if (( xcode_major < minimum_xcode_major )); then
  echo "VoiceBar packaging requires Xcode ${minimum_xcode_major}+ for the current Swift 6 / macOS 15 toolchain, but xcode-select currently points at Xcode ${xcode_version}." >&2
  exit 1
fi

if ! command -v ditto >/dev/null 2>&1; then
  echo "ditto is required to stage and zip VoiceBar.app." >&2
  exit 1
fi

# Keep destructive cleanup scoped to repo-local build folders even when the
# operator overrides the output roots for a local iteration.
require_repo_local_path "DERIVED_DATA_PATH" "${derived_data_path}"
require_repo_local_path "EXPORT_ROOT" "${export_root}"
require_no_symlink_prefixes "DERIVED_DATA_PATH" "${derived_data_path}"
require_no_symlink_prefixes "EXPORT_ROOT" "${export_root}"
require_simple_name "APP_NAME" "${app_name}"
require_simple_name "ZIP_NAME" "${zip_name}"
if [[ -n "${icon_source_path}" ]]; then
  require_repo_local_path "ICON_SOURCE_PATH" "${icon_source_path}"
fi

bash scripts/generate-xcodeproj.sh

rm -rf "${derived_data_path}" "${export_root}"
mkdir -p "${export_root}"

# Use a deterministic DerivedData root so later docs, quality assurance, and release work can
# point at stable app-bundle and archive locations instead of Xcode temp paths.
xcodebuild \
  -project "${project_path}" \
  -scheme "${scheme_name}" \
  -configuration "${configuration}" \
  -derivedDataPath "${derived_data_path}" \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  DEVELOPMENT_TEAM="" \
  build

derived_app_path="${derived_data_path}/Build/Products/${configuration}/${app_name}.app"
export_app_path="${export_root}/${app_name}.app"
export_zip_path="${export_root}/${zip_name}"

if [[ ! -d "${derived_app_path}" ]]; then
  echo "Expected packaged app at ${derived_app_path}, but xcodebuild did not produce it." >&2
  exit 1
fi

if [[ -n "${icon_source_path}" && -f "${icon_source_path}" ]]; then
  mkdir -p "${derived_app_path}/Contents/Resources"
  ditto "${icon_source_path}" "${derived_app_path}/Contents/Resources/VoiceBar.icns"
  plutil -replace CFBundleIconFile -string "VoiceBar" "${derived_app_path}/Contents/Info.plist"
fi

ditto "${derived_app_path}" "${export_app_path}"

if command -v codesign >/dev/null 2>&1; then
  codesign_arguments=(
    --force
    --deep
    --sign "${export_codesign_identity}"
    --identifier "${export_bundle_identifier}"
  )

  if [[ -n "${export_codesign_requirement}" ]]; then
    codesign_arguments+=("-r=${export_codesign_requirement}")
  fi

  codesign "${codesign_arguments[@]}" "${export_app_path}" >/dev/null
fi

(
  cd "${export_root}"
  ditto -c -k --sequesterRsrc --keepParent "${app_name}.app" "${zip_name}"
)

echo "Packaged VoiceBar app:"
echo "  DerivedData bundle: ${derived_app_path}"
echo "  Export bundle: ${export_app_path}"
echo "  Ad-hoc signed technical tester preview archive: ${export_zip_path}"
echo
echo "Install by copying ${export_app_path} into /Applications or ~/Applications on a test machine."
echo "This script intentionally produces an ad-hoc signed preview bundle for source-first development and technical tester handoff."
echo "macOS may require manual approval because this artifact is not Developer ID signed or Apple-notarized."
echo "Ad-hoc preview rebuilds may also require re-granting Microphone and Accessibility permissions."
echo "Trusted signing and notarization remain later release work."
