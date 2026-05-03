#!/usr/bin/env bash
set -euo pipefail

runtime_root="${VOICEBAR_WHISPER_RUNTIME_ROOT:-$HOME/Library/Application Support/VoiceBar/runtime/whisper.cpp}"
source_root="${VOICEBAR_WHISPER_SOURCE_ROOT:-${runtime_root}/source}"
model_root="${VOICEBAR_WHISPER_MODEL_ROOT:-${runtime_root}/models}"
build_root="${VOICEBAR_WHISPER_BUILD_ROOT:-${source_root}/build}"
repo_url="${VOICEBAR_WHISPER_REPO_URL:-https://github.com/ggml-org/whisper.cpp.git}"
model_name="${VOICEBAR_WHISPER_MODEL_NAME:-base.en}"

safe_child_path() {
  local target="$1"
  local allowed_parent="$2"
  local label="$3"

  if [[ -z "${target}" || "${target}" == "/" || "${target}" == "." || "${target}" == ".." ]]; then
    echo "Refusing unsafe ${label}: ${target:-<empty>}" >&2
    return 1
  fi

  local target_parent
  target_parent="$(dirname "${target}")"
  local target_name
  target_name="$(basename "${target}")"
  if [[ "${target_name}" == "." || "${target_name}" == ".." ]]; then
    echo "Refusing unsafe ${label}: ${target}" >&2
    return 1
  fi

  local allowed_real
  allowed_real="$(cd "${allowed_parent}" && pwd -P)"
  local target_real

  if [[ -L "${target}" && ! -e "${target}" ]]; then
    echo "Refusing unsafe ${label}: ${target} is a dangling symlink" >&2
    return 1
  fi

  if [[ -e "${target}" && ! -d "${target}" ]]; then
    echo "Refusing unsafe ${label}: ${target} exists but is not a directory" >&2
    return 1
  fi

  if [[ -d "${target}" ]]; then
    target_real="$(cd "${target}" && pwd -P)"
  else
    local probe="${target_parent}"
    local missing_components=("${target_name}")
    while [[ ! -e "${probe}" ]]; do
      local component
      component="$(basename "${probe}")"
      if [[ "${component}" == "." || "${component}" == ".." ]]; then
        echo "Refusing unsafe ${label}: ${target}" >&2
        return 1
      fi

      missing_components=("${component}" "${missing_components[@]}")
      local next_probe
      next_probe="$(dirname "${probe}")"
      if [[ "${next_probe}" == "${probe}" ]]; then
        echo "Refusing unsafe ${label}: ${target_parent} has no existing parent" >&2
        return 1
      fi
      probe="${next_probe}"
    done

    if [[ ! -d "${probe}" ]]; then
      echo "Refusing unsafe ${label}: ${probe} is not a directory" >&2
      return 1
    fi

    target_real="$(cd "${probe}" && pwd -P)"
    for component in "${missing_components[@]}"; do
      target_real="${target_real}/${component}"
    done
  fi

  case "${target_real}" in
    "${allowed_real}"/*) ;;
    *)
      echo "Refusing unsafe ${label}: ${target_real} is outside ${allowed_real}" >&2
      return 1
      ;;
  esac

  if [[ "${target_real}" == "${allowed_real}" ]]; then
    echo "Refusing unsafe ${label}: ${target_real} matches allowed parent" >&2
    return 1
  fi

  printf '%s\n' "${target_real}"
}

remove_generated_tree() {
  local target="$1"
  local allowed_parent="$2"
  local label="$3"
  local safe_target
  safe_target="$(safe_child_path "${target}" "${allowed_parent}" "${label}")" || exit 1

  if [[ -e "${safe_target}" ]]; then
    rm -rf -- "${safe_target}"
  fi
}

if [[ -n "${VOICEBAR_WHISPER_CMAKE_ARCHITECTURES:-}" ]]; then
  cmake_architectures="${VOICEBAR_WHISPER_CMAKE_ARCHITECTURES}"
elif [[ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" == "1" ]]; then
  cmake_architectures="arm64"
else
  cmake_architectures="$(uname -m)"
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install whisper.cpp." >&2
  exit 1
fi

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake is required to build whisper.cpp." >&2
  exit 1
fi

mkdir -p "${runtime_root}"
runtime_root="$(cd "${runtime_root}" && pwd -P)"
source_root="$(safe_child_path "${source_root}" "${runtime_root}" "VOICEBAR_WHISPER_SOURCE_ROOT")" || exit 1
model_root="$(safe_child_path "${model_root}" "${runtime_root}" "VOICEBAR_WHISPER_MODEL_ROOT")" || exit 1
mkdir -p "$(dirname "${source_root}")" "${model_root}"

if [[ ! -d "${source_root}/.git" ]]; then
  remove_generated_tree "${source_root}" "${runtime_root}" "VOICEBAR_WHISPER_SOURCE_ROOT"
  git clone --depth 1 "${repo_url}" "${source_root}"
else
  git -C "${source_root}" fetch --depth 1 origin
  git -C "${source_root}" reset --hard origin/HEAD
fi

build_root="$(safe_child_path "${build_root}" "${source_root}" "VOICEBAR_WHISPER_BUILD_ROOT")" || exit 1

# AppleClang rejects GGML's `-mcpu=native` on some Apple Silicon setups; keep
# explicit architecture + Metal enabled so the runtime stays native and fast.
remove_generated_tree "${build_root}" "${source_root}" "VOICEBAR_WHISPER_BUILD_ROOT"
cmake -S "${source_root}" -B "${build_root}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES="${cmake_architectures}" \
  -DGGML_NATIVE=OFF \
  -DGGML_METAL=ON
cmake --build "${build_root}" -j --config Release

"${source_root}/models/download-ggml-model.sh" "${model_name}" "${model_root}"

echo "Configured whisper.cpp runtime:"
echo "  Source root: ${source_root}"
echo "  Build root: ${build_root}"
echo "  CLI binary: ${build_root}/bin/whisper-cli"
file "${build_root}/bin/whisper-cli" || true
echo "  Model root: ${model_root}"
echo "  Model file: ${model_root}/ggml-${model_name}.bin"
