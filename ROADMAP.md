# VoiceBar Roadmap

This roadmap is public-facing planning, not a promise that every item exists today. VoiceBar is source-first now, and normal-user binary distribution is future work.

## Source-First Launch

VoiceBar is launching from source first for developers, technical users, and contributors. The current path is local setup, local runtime installation, and source build validation.

Current source-first path:

```bash
bash scripts/setup-kokoro-runtime.sh
bash scripts/setup-whisper-runtime.sh
bash scripts/run.sh
bash scripts/package-app.sh
```

## Signed And Notarized Mac Builds

Signed and Apple-notarized Mac builds are future work. The current exported package is ad-hoc signed and may require manual approval in macOS security settings.

Planned work:

- Developer ID signing
- Apple notarization
- stable app identity for Mac permissions
- release artifact checksum generation
- release notes for public builds

## Disk Image Distribution

Disk Image (DMG) distribution is the preferred future normal-user Mac install path after signing and notarization are ready.

Planned work:

- `VoiceBar-macos-arm64.dmg`
- drag-to-Applications install flow
- checksum publication
- first-run Microphone and Accessibility guidance

## Homebrew Cask Future Path

Homebrew Cask is a later convenience layer, not the first trust surface.

It depends on:

- stable public release uniform resource locator (URL)
- stable version tag
- Secure Hash Algorithm 256-bit (SHA-256) checksum
- Developer ID signed and Apple-notarized release artifact
- operator approval before publication

The future target command is:

```bash
brew install --cask voicebar
```

That command is not claimed to work today.

## Noise-Isolation Improvements

Noisy-background dictation is not fully hardened today. Future work should improve capture quality without pretending noisy environments are solved.

Planned work:

- noisy-background benchmark samples
- private-text-free audio diagnostics
- configurable silence threshold
- noise gate
- high-pass filter
- stronger voice activity detection
- optional noise suppression after license and dependency review

## Microphone Selector And Input-Level Meter

VoiceBar should make microphone state easier to inspect and control.

Planned work:

- microphone selector
- input-level meter
- capture device status
- clearer permission and device failure states

## Stronger Local Speech-To-Text Backends

VoiceBar currently uses local `whisper.cpp` for speech-to-text. Future work can evaluate stronger local backends while preserving the local-first posture.

Potential directions:

- larger local speech-to-text models
- lower-latency local inference
- stronger punctuation and casing
- private-text-free benchmark fixtures
- backend abstraction that avoids locking VoiceBar to one vendor

## Local Text-To-Speech Improvements

VoiceBar currently supports local text-to-speech direction through Kokoro-backed Quick when configured, with advanced or fallback speech paths preserved.

Planned work:

- better local voice selection
- lower first-audio latency
- more reliable long-form playback
- clearer runtime setup guidance
- future bundled or automated local runtime setup after license review

## Snippets And Custom Vocabulary

VoiceBar snippets should support exact trigger phrases, explicit aliases, and custom-vocabulary-style product-name corrections.

Current posture:

- public examples use synthetic names such as `ExampleAudit`, `AcmeReview`, and `LocalReviewTool`
- real maintainer workflow terms belong in private local configuration
- aliases are explicit and deterministic
- broad fuzzy matching is not a release goal

## Privacy-Safe Command Execution

VoiceBar should keep command execution human-controlled and auditable.

Current posture:

- snippet expansion inserts text only
- deterministic formatter output can shape text but cannot authorize actions by itself
- language-model suggestions can inform text handling but cannot authorize actions by themselves
- executable actions require the raw spoken transcript to match a configured trigger

Planned work:

- clearer action configuration guidance
- safer action review surfaces
- private-text-free action diagnostics
- tighter command confirmation options

## Agent Completion Watcher

Agent Completion Watcher is roadmap-only. It does not exist in VoiceBar today.

The idea is a privacy-safe command-line helper or wrapper for Codex command-line interface (CLI), Claude Code, and other command-line interface (CLI) agent tools.

Potential behavior:

- optional Mac notification when a long-running agent task finishes
- optional VoiceBar overlay alert
- optional spoken completion alert
- no keylogging
- no terminal screen scraping by default
- no claim that it monitors unrelated terminal content

## Windows Companion

Windows support is future-only. It would require separate work for keyboard hooks, microphone capture, text insertion, permissions, packaging, and local runtime setup.

## iPhone Companion

An iPhone companion app is future-only. It is parked until the Mac source-first launch and Mac distribution path are stable.
