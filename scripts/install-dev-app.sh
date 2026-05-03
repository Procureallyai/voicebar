#!/usr/bin/env bash
set -euo pipefail

configuration="${SWIFT_BUILD_CONFIGURATION:-release}"
app_bundle_path="${APP_BUNDLE_PATH:-$HOME/Applications/VoiceBar.app}"
bundle_identifier="${BUNDLE_IDENTIFIER:-ai.procureally.voicebar}"
bundle_executable_name="${BUNDLE_EXECUTABLE_NAME:-VoiceBar}"
codesign_identity="${DEV_APP_CODESIGN_IDENTITY:--}"
skip_codesign="${DEV_APP_SKIP_CODESIGN:-0}"
codesign_requirement="${DEV_APP_CODESIGN_REQUIREMENT:-}"
launch_after_install=false
desktop_launcher_path="${DESKTOP_LAUNCHER_PATH:-$HOME/Desktop/VoiceBar.app}"

refresh_desktop_launcher() {
  if [[ -z "${desktop_launcher_path}" ]]; then
    return
  fi

  if [[ -e "${desktop_launcher_path}" && ! -L "${desktop_launcher_path}" ]]; then
    echo "Warning: skipped Desktop launcher refresh because ${desktop_launcher_path} already exists and is not a symlink." >&2
    return
  fi

  rm -f "${desktop_launcher_path}"
  ln -s "${app_bundle_path}" "${desktop_launcher_path}"
  echo "  Desktop launcher: ${desktop_launcher_path} -> ${app_bundle_path}"
}

launch_bundle_if_requested() {
  if [[ "${launch_after_install}" != true ]]; then
    return
  fi

  local launch_attempt
  for launch_attempt in 1 2 3; do
    if open "${app_bundle_path}"; then
      echo "Launched ${app_bundle_path}"
      return
    fi

    sleep 1
  done

  echo "Warning: VoiceBar.app installed successfully, but Launch Services did not reopen it automatically. Open ${app_bundle_path} from Finder or Spotlight." >&2
}

show_usage() {
  cat <<'EOF'
Usage: bash scripts/install-dev-app.sh [--launch]

Build the SwiftPM VoiceBarApp executable, wrap it in a stable local `.app`
bundle under `~/Applications`, and optionally launch that bundle.

This helper exists for local operator testing on Command Line Tools-only
machines. It does not replace `bash scripts/package-app.sh`, which remains the
truthful full-Xcode export path for `build/export/VoiceBar.app`.

Environment overrides:
  SWIFT_BUILD_CONFIGURATION   Swift build configuration (default: release)
  APP_BUNDLE_PATH             Target app bundle path (default: ~/Applications/VoiceBar.app)
  BUNDLE_IDENTIFIER           Bundle identifier for the dev app bundle
  BUNDLE_EXECUTABLE_NAME      Executable name inside the bundle (default: VoiceBar)
  DEV_APP_CODESIGN_IDENTITY   Signing identity for the local dev bundle.
                              Defaults to "-" for an ad-hoc local signature.
  DEV_APP_CODESIGN_REQUIREMENT
                              Optional designated requirement passed to
                              codesign. When omitted, ad-hoc signing uses the
                              default ad-hoc requirement and macOS may require
                              re-granting Microphone and Accessibility access
                              after rebuilds.
  DESKTOP_LAUNCHER_PATH       Desktop symlink target for the local helper app.
                              Defaults to ~/Desktop/VoiceBar.app. Set to an
                              empty string to skip Desktop launcher refresh.
  DEV_APP_SKIP_CODESIGN       Set to 1 to skip codesigning the local helper.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --launch)
      launch_after_install=true
      shift
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

if [[ "${app_bundle_path}" != *.app ]]; then
  echo "APP_BUNDLE_PATH must end with .app. Received: ${app_bundle_path}" >&2
  exit 1
fi

if ! command -v plutil >/dev/null 2>&1; then
  echo "plutil is required to assemble the local VoiceBar.app bundle." >&2
  exit 1
fi

if ! command -v ditto >/dev/null 2>&1; then
  echo "ditto is required to copy the VoiceBar.app bundle and resource bundles." >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required to update the local VoiceBar.app bundle in place." >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
staging_root="${repo_root}/build/dev-app"
staging_bundle_path="${staging_root}/VoiceBar Dev.app"
contents_path="${staging_bundle_path}/Contents"
macos_path="${contents_path}/MacOS"
resources_path="${contents_path}/Resources"
plist_path="${contents_path}/Info.plist"
icon_source_path="${APP_ICON_PATH:-${repo_root}/Config/VoiceBar.icns}"

mkdir -p "$(dirname "${app_bundle_path}")"
rm -rf "${staging_root}"
mkdir -p "${macos_path}" "${resources_path}"

swift build -c "${configuration}" --product VoiceBarApp
binary_directory="$(swift build -c "${configuration}" --show-bin-path)"
binary_path="${binary_directory}/VoiceBarApp"

if [[ ! -x "${binary_path}" ]]; then
  echo "Expected SwiftPM executable at ${binary_path}, but it was not found." >&2
  exit 1
fi

ditto "${binary_path}" "${macos_path}/${bundle_executable_name}"

# SwiftPM resource bundles need to sit alongside the bundled app resources so
# Bundle.module lookups keep working when VoiceBar runs outside `.build/`.
while IFS= read -r resource_bundle_path; do
  ditto "${resource_bundle_path}" "${resources_path}/$(basename "${resource_bundle_path}")"
done < <(find "${binary_directory}" -maxdepth 1 -type d -name '*.bundle' | sort)

ditto "${repo_root}/Config/VoiceBar-Info.plist" "${plist_path}"
plutil -replace CFBundleExecutable -string "${bundle_executable_name}" "${plist_path}"
plutil -replace CFBundleIdentifier -string "${bundle_identifier}" "${plist_path}"
plutil -replace CFBundleName -string "VoiceBar" "${plist_path}"
plutil -replace CFBundleDisplayName -string "VoiceBar" "${plist_path}"

if [[ -f "${icon_source_path}" ]]; then
  ditto "${icon_source_path}" "${resources_path}/VoiceBar.icns"
  plutil -replace CFBundleIconFile -string "VoiceBar" "${plist_path}"
fi

if command -v codesign >/dev/null 2>&1 && [[ "${skip_codesign}" != "1" ]]; then
  codesign_arguments=(
    --force
    --deep
    --sign "${codesign_identity}"
    --identifier "${bundle_identifier}"
  )

  if [[ -n "${codesign_requirement}" ]]; then
    codesign_arguments+=("-r=${codesign_requirement}")
  fi

  codesign "${codesign_arguments[@]}" "${staging_bundle_path}" >/dev/null
fi

pkill -x VoiceBar >/dev/null 2>&1 || true
pkill -x VoiceBarApp >/dev/null 2>&1 || true
sleep 1
mkdir -p "${app_bundle_path}"
rsync -a --delete "${staging_bundle_path}/" "${app_bundle_path}/"

echo "Installed local VoiceBar.app bundle:"
echo "  Source executable: ${binary_path}"
echo "  Bundled executable: ${bundle_executable_name}"
echo "  Installed bundle: ${app_bundle_path}"
if [[ "${skip_codesign}" == "1" ]]; then
  echo "  Signing identity: skipped"
elif [[ -n "${codesign_identity}" ]]; then
  echo "  Signing identity: ${codesign_identity}"
else
  echo "  Signing identity: none (unsigned local dev bundle)"
fi
if [[ -n "${codesign_requirement}" ]]; then
  echo "  Designated requirement: ${codesign_requirement}"
fi
echo
echo "This helper is only the stable local dev-bundle path."
echo "Use bash scripts/package-app.sh on a full-Xcode machine for truthful build/export validation."
echo "Note: ad-hoc signed rebuilds may require re-granting Microphone and"
echo "Accessibility access because they do not provide stable macOS"
echo "Transparency, Consent, and Control (TCC) identity."

refresh_desktop_launcher

launch_bundle_if_requested
