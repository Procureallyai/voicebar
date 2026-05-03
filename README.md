# VoiceBar

VoiceBar is an open-source, Mac-first voice workflow tool for developers and privacy-conscious Artificial Intelligence (AI) practitioners. It brings private dictation, snippets, custom-vocabulary-style corrections, local speech-to-text, local text-to-speech direction, and human-controlled automation into a native macOS menu bar app that developers can inspect, run from source, and adapt to their own workflows.

Built by Live.

VoiceBar was built by Live as a local-first voice workflow tool for privacy-conscious Artificial Intelligence (AI) productivity and evidence-first governance.

## Why VoiceBar Exists

Voice workflows can be powerful, but many productivity tools trade speed for trust in opaque cloud systems. VoiceBar explores a different posture: local runtimes where practical, clear human control, synthetic public examples, and explicit safety boundaries.

VoiceBar sits in the voice-workflow category alongside dictation assistants, local automation launchers, and text-to-speech utilities, but its center of gravity is different: Mac-first, source-first today, local-first where practical, and built for developer workflows where the user stays in control of what runs.

VoiceBar is also a public proof-of-work. Live is an Artificial Intelligence (AI) engineer and machine learning engineer working across Artificial Intelligence (AI) governance, policy, guardrails, and practical automation. Digital Dance AI (DDAI) helps organisations deploy practical Artificial Intelligence (AI) workflows with governance built in. Evidary is the evidence and verification platform being built for Artificial Intelligence (AI) governance, policy, and audit-readiness.

VoiceBar reflects the same philosophy in a daily tool: automation should be useful, inspectable, and under the user's control. Snippets expand text; they do not silently execute commands.

## Public Links

- LinkedIn: [Live Livingstone Rowe](https://www.linkedin.com/in/live-livingstone-rowe-776184256/)
- X: [@LiveMatrixCode](https://x.com/LiveMatrixCode)
- GitHub: [Procureallyai](https://github.com/Procureallyai)

## Walkthrough Video

Updated walkthrough video coming soon. VoiceBar is source-first today; the refreshed launch walkthrough will be added after it is complete.

## Who VoiceBar Is For

- Builders who want private dictation and text-to-speech on Mac.
- Developers who want snippet expansion without silent command execution.
- Artificial Intelligence (AI) practitioners who care about privacy, evidence, governance, and user agency.
- Contributors who want a practical open-source Mac automation project with maintainer-led review.

## Key Features

- Local-first Mac dictation through a local `whisper.cpp` speech-to-text runtime.
- Source-first setup for developers and technical users today.
- Function key (Fn) push-to-speak support where macOS and keyboard behavior expose reliable events.
- Fallback hold-to-talk shortcuts when Function key (Fn) behavior is unavailable or intercepted.
- Local formatter mode through Ollama when enabled.
- Operator-defined snippets with explicit trigger phrases, aliases, and custom-vocabulary-style product-name corrections.
- Command-text snippets that insert text only and never execute automatically.
- Local text-to-speech direction for selected text and clipboard text.
- Accessibility-based selected-text workflows and a macOS Service path.
- Privacy-conscious architecture that keeps snippets, transcripts, logs, screenshots, and recordings out of the public source tree.
- Human-controlled command execution: raw spoken transcript triggers can route allowlisted actions, while snippet text and formatter output do not silently run commands.
- Maintainer-led contribution and security review posture.

## Platform Support

VoiceBar is currently Mac-first.

Windows support is planned as a future roadmap item, but it is not part of the first public release. A Windows version would require a separate desktop integration layer for keyboard hooks, microphone capture, text insertion, installer packaging, and accessibility-equivalent permissions.

Backend feasibility exists because Ollama supports Windows and `whisper.cpp` can be built or used on Windows. The hard part is not only model inference; it is replicating the native desktop integration safely and reliably.

## Mac Requirements

Minimum guidance:

- Apple Silicon Mac recommended.
- macOS 15 or newer, matching the current package and Xcode project deployment target.
- 8 gigabytes random-access memory (RAM) minimum for light local dictation.
- Local disk space for speech-to-text models, formatter models, and application data.
- Microphone permission for dictation.
- Accessibility permission for text insertion and selected-text workflows.
- Local `whisper.cpp` runtime for transcription.
- Ollama for local formatter models when formatter mode is enabled.

Recommended guidance:

- Apple Silicon M-series Mac.
- 16 gigabytes random-access memory (RAM) or more.
- Enough storage for local speech-to-text and formatter models.
- Function key (Fn) support depends on macOS, keyboard firmware, and keyboard settings. Use fallback shortcuts such as Option+Period or a configured F13-F19 key if Function key (Fn) is unavailable.

## Provisional Windows Target

Windows support does not currently work in this repository.

Future Windows guidance is expected to start with:

- Windows 11 recommended.
- 16 gigabytes random-access memory (RAM) recommended.
- 8 gigabytes random-access memory (RAM) may work only for smaller models and lighter use.
- A modern central processing unit (CPU) can run smaller speech-to-text models, but latency may vary.
- A dedicated graphics processing unit (GPU), especially NVIDIA with Compute Unified Device Architecture (CUDA) support, is recommended for stronger local model performance.
- Separate Windows testing, packaging, permissions, and desktop-integration validation.

## Installation Overview

> **Install Status**
>
> VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.
>
> Current preview artifacts are for technical testers only. They are not frictionless public-user installers, not Apple-notarized releases, and not a signal that the private working repository or staging repository is approved for publication.

VoiceBar is not yet published as a polished public release package. The current repository supports local development, operator staging, and direct-distribution preparation.

Current developer and operator path:

```bash
bash scripts/setup-kokoro-runtime.sh
bash scripts/setup-whisper-runtime.sh
bash scripts/run.sh
bash scripts/package-app.sh
```

`bash scripts/run.sh` builds and launches the stable local development helper at `~/Applications/VoiceBar.app`. `bash scripts/package-app.sh` exports `build/export/VoiceBar.app` and `build/export/VoiceBar-macos-adhoc.zip`.

Important current truth:

- The current package output is ad-hoc signed.
- The current package output is acceptable for local iteration and staging.
- The current package output is not the polished public distribution target.
- The current package output may trigger Mac trust warnings.
- Ad-hoc preview rebuilds do not provide stable macOS Transparency, Consent, and Control (TCC) identity. Technical testers may need to re-grant Microphone and Accessibility permissions after rebuilding or replacing the app bundle.
- Technical testers may need to open the app through macOS security settings if Gatekeeper blocks first launch.
- Normal public users should wait for a signed and notarized release. They should not need to understand Xcode or clone this repository unless they are contributors.

Developer and tester guides:

- [Source-First Install Guide](docs/product/voicebar-source-first-install.md)
- [First-Run Guide](docs/product/voicebar-first-run-guide.md)
- [Ad-Hoc Preview Artifact Guide](docs/product/voicebar-preview-artifacts.md)
- [Public Roadmap](ROADMAP.md)
- [Homebrew Cask Feasibility And Future Tap Plan](docs/product/voicebar-homebrew-cask-plan.md)
- [Release Notes Template](docs/product/voicebar-release-notes-template.md)

Planned public user path:

- Download a Developer ID signed and Apple notarized Mac artifact from GitHub Releases.
- Use `VoiceBar-macos-arm64.dmg` when disk image packaging is implemented, or `VoiceBar-macos-arm64.zip` if zip remains the first release artifact.
- Drag `VoiceBar.app` into Applications or open the app from the archive.
- Follow first-run guidance for Microphone and Accessibility permissions.
- Follow local runtime setup guidance for Kokoro, `whisper.cpp`, and Ollama unless those steps are bundled or automated in a later release.
- Verify checksum files when they are provided.

The packaged normal-user release is planned after the source-first repository opening.

## Required macOS Permissions

VoiceBar needs macOS permissions for the workflows you enable:

- Microphone permission for dictation.
- Accessibility permission for text insertion, selected-text reading, and selected-text workflows.
- Login item approval only if launch-at-login is enabled.

Validate permissions from a real `.app` bundle rather than only from `swift run`, because macOS permission trust is tied to the app identity.

## Local Runtime Setup

VoiceBar's local-first posture depends on local runtimes:

- `whisper.cpp` powers local speech-to-text transcription for dictation.
- Ollama powers local formatter models when formatter mode is enabled.
- Kokoro-backed Quick is the current primary text-to-speech path when configured on the maintainer Mac.
- Premium text-to-speech remains an advanced or fallback path.
- `bash scripts/setup-kokoro-runtime.sh` configures the local Kokoro runtime used by the current Quick text-to-speech path.
- `bash scripts/setup-whisper-runtime.sh` configures the local `whisper.cpp` runtime used by dictation.

External runtime and model files may carry their own licenses. Review the license terms for `whisper.cpp`, Ollama, downloaded formatter models, and any future bundled speech-to-text or text-to-speech models before redistribution.

## Distribution Roadmap

GitHub Releases is the planned primary distribution surface for normal Mac users. The target artifact is a Developer ID signed and Apple notarized `VoiceBar-macos-arm64.dmg` or `VoiceBar-macos-arm64.zip`, with checksum files when practical.

Homebrew Cask is planned after the first stable Developer ID signed and Apple notarized release artifact exists. Homebrew Cask should wrap a stable release artifact from GitHub Releases or another approved public release surface; it should not be the first place where release trust is established.

Homebrew Cask requires a stable public release uniform resource locator (URL), version tag, Secure Hash Algorithm 256-bit (SHA-256) checksum, and app artifact name. It does not solve macOS Gatekeeper trust for unsigned, ad-hoc signed, or non-notarized apps.

The future one-command target is:

```bash
brew install --cask voicebar
```

That command is a future target and is not claimed to work today. See [Homebrew Cask Feasibility And Future Tap Plan](docs/product/voicebar-homebrew-cask-plan.md) for the blocked template and release gates.

VoiceBar does not need Docker or containerisation to be open source. VoiceBar is a native Mac application, and containers do not solve Microphone permission, Accessibility permission, global hotkeys, Function key (Fn) behavior, text insertion, or native app packaging. Containers may still be useful for developer tooling, documentation builds, or non-desktop tests.

## Usage Overview

Dictation:

- Choose a dictation mode in VoiceBar settings.
- Hold the configured push-to-speak shortcut, speak, and release to transcribe.
- Formatter mode can clean up text through a local Ollama model when enabled.
- Plain text mode keeps insertion simpler and lower-latency.

Function key (Fn) push-to-speak:

- Function key (Fn) support is experimental and depends on macOS and keyboard behavior.
- If another app intercepts Function key (Fn), use a fallback hold-to-talk shortcut.
- VoiceBar also supports safer fallback choices such as Option+Period or F13-F19 keys.

Snippets:

- Snippets use explicit trigger phrases and aliases.
- A snippet trigger inserts the configured text.
- Command-text snippets are text only. VoiceBar does not press Return, execute shell commands, or run arbitrary model output automatically.

Text-to-speech:

- Use Read Selection when Accessibility access is available.
- Use Read Clipboard for an explicit clipboard-driven path.
- Use the macOS Service path where enabled.

## Privacy And Security Posture

VoiceBar is designed as a local-first macOS utility. Core reading and dictation workflows should not require cloud text-to-speech or cloud speech-to-text services.

Privacy and security principles:

- Keep private snippets, reports, screenshots, transcripts, logs, and recordings out of Git.
- Use synthetic examples in public issues, pull requests (PRs), documentation, and demos.
- Do not include credentials, tokens, private repository links, or personal data in public artifacts.
- Treat command-text snippets as text expansion only.
- Route executable actions through explicit, deterministic, allowlisted controls.
- Review security-sensitive changes before merge.

## Open-Source Contribution Workflow

VoiceBar uses a maintainer-led contribution model:

- Use a fork-and-pull-request workflow.
- Do not push directly to `main`.
- Keep pull requests (PRs) focused and reviewable.
- Use synthetic examples only.
- Required checks should pass before merge.
- Review conversations should be resolved before merge.
- Security-sensitive changes need explicit security review.
- Automated hosted review may provide an additional pull request (PR) review layer.
- Local Codex deep review remains required for substantial or security-sensitive changes.

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License Status

VoiceBar is prepared for release under [Apache License 2.0](LICENSE). This is a permissive, commercially friendly license with explicit patent language, which fits a governance-aware developer tool better than a simpler permissive license for this project.

This is not legal advice. Public release still requires maintainer approval and final third-party notice review.

See [NOTICE](NOTICE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Third-Party Notices Status

The current dependency review found permissive dependency licenses only: Massachusetts Institute of Technology (MIT) License, Apache License 2.0, and Apache License 2.0 with Swift Runtime Library Exception.

`THIRD_PARTY_NOTICES.md` records the reviewed Swift Package Manager dependency set pinned in `Package.resolved`, including upstream notice-file status for each dependency.

Public release still requires operator approval, external runtime and model license review for any redistributed artifacts, and scans of the exact public-facing repository or clean public fork.

## Known Limitations

- VoiceBar is Mac-first; Windows and iPhone support are future work.
- There is no one-click normal-user installer today.
- Signed Disk Image (DMG), Developer ID signing, Apple notarization, and Homebrew Cask distribution are future work.
- Function key (Fn) behavior depends on macOS, keyboard firmware, settings, and conflicts with other apps.
- Noisy backgrounds can degrade dictation quality. Use a quieter environment, headset microphone, or system-level microphone noise isolation where available.
- Agent Completion Watcher is roadmap-only and does not exist in VoiceBar today.
- Local model performance depends on hardware, model size, warm-up state, and runtime configuration.
- Local builds are ad-hoc signed unless the maintainer configures a signing identity.
- Public release should use a sanitized public-facing repository or clean public fork, not the private working repository directly.

See [VoiceBar Roadmap](ROADMAP.md), [VoiceBar Install And Distribution Roadmap](docs/product/voicebar-install-and-distribution-roadmap.md), and [VoiceBar Noise-Isolation Roadmap](docs/product/voicebar-noise-isolation-roadmap.md).
