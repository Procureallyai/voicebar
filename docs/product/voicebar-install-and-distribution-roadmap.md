# VoiceBar Install And Distribution Roadmap

## Purpose

This document records the truthful install and distribution path for VoiceBar public-release planning.

## Current Install Truth

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

VoiceBar currently supports a developer and operator install path:

```bash
bash scripts/setup-kokoro-runtime.sh
bash scripts/setup-whisper-runtime.sh
bash scripts/run.sh
bash scripts/package-app.sh
```

Current outputs:

- `bash scripts/run.sh` builds and launches the local development helper at `~/Applications/VoiceBar.app`.
- `bash scripts/package-app.sh` exports `build/export/VoiceBar.app`.
- `bash scripts/package-app.sh` also exports `build/export/VoiceBar-macos-adhoc.zip`.
- `bash scripts/setup-kokoro-runtime.sh` configures the local Kokoro runtime for the current Quick text-to-speech path.
- `bash scripts/setup-whisper-runtime.sh` configures the local `whisper.cpp` runtime for dictation.

Current limitations:

- The exported package is ad-hoc signed.
- The exported package is useful for local iteration and staging.
- The exported package is not the polished public distribution target.
- The exported package may trigger Mac trust warnings.
- The exported package is for technical testers only when shared as a preview artifact.
- Ad-hoc preview rebuilds do not provide stable macOS Transparency, Consent, and Control (TCC) identity, so testers may need to re-grant Microphone and Accessibility permissions after rebuilding or replacing the app bundle.
- Normal users should not need to understand Xcode.
- Normal users should not need to clone the repository unless they are contributors.

Current source-first and preview guides:

- [VoiceBar Source-First Install Guide](voicebar-source-first-install.md)
- [VoiceBar First-Run Guide](voicebar-first-run-guide.md)
- [VoiceBar Ad-Hoc Preview Artifact Guide](voicebar-preview-artifacts.md)
- [VoiceBar Homebrew Cask Feasibility And Future Tap Plan](voicebar-homebrew-cask-plan.md)
- [VoiceBar Release Notes Template](voicebar-release-notes-template.md)

## Public User Install Target

The preferred public install path is GitHub Releases.

Target release flow:

- Publish a Developer ID signed and Apple notarized Mac app artifact only after release verification is complete.
- Provide `VoiceBar-macos-arm64.dmg` when disk image packaging exists.
- Provide `VoiceBar-macos-arm64.zip` if zip remains the first release artifact.
- Include checksum files when practical.
- Guide users to drag `VoiceBar.app` into Applications or open the app from the archive.
- Provide first-run Microphone and Accessibility permission guidance.
- Provide local runtime setup guidance for Kokoro, `whisper.cpp`, and Ollama unless those steps are bundled or automated.

Developer ID signing and Apple notarization are not implemented in this lane.

## Local Runtime Setup

VoiceBar's current local dictation path depends on local runtime setup:

- `whisper.cpp` provides local speech-to-text transcription.
- Ollama provides local formatter models when formatter mode is enabled.
- Kokoro provides the local Quick text-to-speech runtime when configured.
- Users may need to install or configure those runtimes unless a later release bundles or automates them.
- External runtime and model redistribution rights must be reviewed before any artifact is bundled.

## Homebrew Cask Roadmap

Homebrew Cask is planned after the first stable Developer ID signed and Apple notarized release artifact exists.

Homebrew Cask should wrap a stable release artifact from GitHub Releases or another approved public release surface. Homebrew should be the install convenience layer, not the first place where release trust is established.

Homebrew Cask requires:

- a stable public release uniform resource locator (URL)
- a stable version tag
- a stable Secure Hash Algorithm 256-bit (SHA-256) checksum for the release artifact
- an app artifact name
- a repeatable Developer ID signed and Apple notarized Mac artifact

Homebrew Cask does not solve macOS Gatekeeper trust for unsigned, ad-hoc signed, or non-notarized apps. The current ad-hoc signed technical-tester preview archive may still require manual approval in macOS security settings.

Homebrew Cask is not required for the first public source release, but it is the preferred later one-command install path:

```bash
brew install --cask voicebar
```

That command is a future target and is not claimed to work today.

See [VoiceBar Homebrew Cask Feasibility And Future Tap Plan](voicebar-homebrew-cask-plan.md) for the blocked future cask template and publication checklist.

## Containerisation Position

VoiceBar does not need Docker or containerisation to be open source.

VoiceBar is a native Mac application. Containerisation is not the primary distribution path because it does not solve:

- Microphone permission
- Accessibility permission
- global hotkeys
- Function key (Fn) behavior
- text insertion
- native Mac app packaging
- first-run Gatekeeper and trust behavior

Recommended paths:

- Normal users should use native Mac packaging.
- Developers should use source builds plus setup scripts.
- Containers may be useful only for developer tooling, documentation builds, or non-desktop tests.

## Release Gates

Do not claim public distribution readiness until these gates are complete:

- signed app artifact
- Apple notarized app artifact
- disk image (DMG) or zip release artifact
- first-run permission guidance
- local runtime setup guidance
- checksum file when practical
- release notes
- clean hosted continuous integration (CI)
- clean local Codex review
- visible automated hosted review, or an explicit accepted alternative
- operator approval before publication
