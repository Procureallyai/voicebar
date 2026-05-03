# VoiceBar Source-First Install Guide

## Install Status

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

This guide is for contributors and technical testers who are comfortable with source builds, local runtime setup, and macOS permission prompts.

## What This Path Is

- Current path: source-first local development and tester preview.
- Current artifacts: ad-hoc signed local app bundle and zip archive.
- Current repository status: private working repository until explicit operator approval.
- Current release status: no public release, no Developer ID signed public installer, and no Apple notarization.

## What This Path Is Not

- Not a frictionless normal-user installer.
- Not a notarized public-user release.
- Not a Homebrew Cask release.
- Not a release approval for the public-staging repository.
- Not a redistribution approval for external runtime or model artifacts.

## Requirements

- Apple silicon Mac recommended.
- macOS 15 or newer.
- Full Xcode 16 or newer for application packaging.
- Command line tools needed by the setup scripts.
- Local disk space for VoiceBar runtime files and downloaded models.
- Comfort granting Microphone and Accessibility permissions to a local app bundle.

## Source-First Setup

From the repository root:

```bash
bash scripts/setup-kokoro-runtime.sh
bash scripts/setup-whisper-runtime.sh
bash scripts/run.sh
```

What those commands do:

- `bash scripts/setup-kokoro-runtime.sh` configures the local Kokoro-backed text-to-speech runtime used by the current Quick path.
- `bash scripts/setup-whisper-runtime.sh` configures the local `whisper.cpp` speech-to-text runtime used by dictation.
- `bash scripts/run.sh` builds and launches the local development helper at `~/Applications/VoiceBar.app`.

Relaunch VoiceBar after setting up Kokoro if the app was already running, because the Quick text-to-speech engine is selected at app startup.

## Optional Local Package Export

Technical testers can build the current local preview archive:

```bash
bash scripts/package-app.sh
```

Current outputs:

- `build/export/VoiceBar.app`
- `build/export/VoiceBar-macos-adhoc.zip`

These outputs are ad-hoc signed and intended for local iteration or technical tester preview only. macOS may block first launch or require manual approval because the app is not Developer ID signed and Apple notarized.

Ad-hoc preview builds do not provide stable macOS Transparency, Consent, and Control (TCC) identity. After rebuilding or replacing the preview app bundle, testers may need to re-grant Microphone and Accessibility permissions in System Settings.

## Formatter Mode

VoiceBar can use Ollama for local formatter mode when enabled.

Minimum tester expectation:

- Install and run Ollama separately.
- Ensure the configured formatter model is available locally.
- Keep formatter fallback behavior enabled so dictation can still insert text if the model is unavailable or times out.

## Runtime And Model Licensing

External runtime and model files may carry separate license terms. Review the licenses for `whisper.cpp`, downloaded speech-to-text models, Ollama models, Kokoro-backed text-to-speech artifacts, and any future bundled models before redistribution.

## Validation

Recommended local validation before sharing a tester preview:

```bash
git diff --check
bash scripts/build.sh
bash scripts/test.sh
bash scripts/ci.sh
bash scripts/package-app.sh
```

Do not call a preview ready for normal public users unless a Developer ID signed and Apple notarized release artifact exists and has been verified.
