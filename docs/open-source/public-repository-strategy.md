# Public Repository Strategy

## Recommendation

Do not make the private working repository public directly.

Create a sanitized public-facing repository or clean public fork after the release candidate tree is proven clean. Keep the private internal repository as the working source until the public tree has passed sanitisation, dependency review, security review, and operator approval.

## Public Tree Shape

The first public-facing tree should include product source, build scripts, public-safe product documentation, governance files, and synthetic examples only.

Do not carry these internal surfaces into the first public tree unless they are individually reviewed and redacted:

- `memory_bank/`
- `planning/kanban/`
- `docs/orchestration/prompt-artifacts/`
- private model-switch handoff notes
- private prompt archives
- private reports, logs, screenshots, screen recordings, request dumps, transcripts, and snippet exports

## Public Repository Metadata Recommendations

Recommended description:

> Local-first Mac voice workflow tool for dictation, snippets, text-to-speech, and human-controlled Artificial Intelligence (AI) automation.

Recommended topics:

- `macos`
- `swift`
- `speech-to-text`
- `dictation`
- `local-first`
- `privacy`
- `whisper-cpp`
- `ollama`
- `productivity`
- `voice-workflows`

Recommended homepage:

- Leave homepage blank until the refreshed walkthrough video or a dedicated public project page is complete.

## Maintainer Model

- The operator is the maintainer and final approver.
- Public users may open issues and pull requests (PRs).
- Contributors should use a fork-and-pull-request workflow.
- No public contributor should have direct write access to `main`.
- `main` should be protected with required pull request review, status checks, resolved conversations, and security review.
- Automated hosted review is an additional review layer, not the only security gate.
- Local Codex deep review remains required for substantial or security-sensitive changes.

## Public Data Rules

- Public examples must be synthetic only.
- Private snippets and private reports stay outside Git.
- Command-text snippets are documented as text expansion only.
- Public docs must avoid operator-local paths, private repository links, private pull request links, cloud project identifiers, credentials, and raw personal data.
- Security reports should use the process in `SECURITY.md`.

## License Direction

Apache License 2.0 is the selected project license direction for VoiceBar.

Apache License 2.0 fits VoiceBar because it is permissive, commercially friendly, includes explicit patent language, and is widely understood for developer-facing local Artificial Intelligence (AI), automation, dictation, snippets, and desktop-integration tools.

The private working repository now includes `LICENSE`, `NOTICE`, and a preliminary `THIRD_PARTY_NOTICES.md` inventory. Public release remains blocked until third-party notices are completed against the exact sanitized public-facing tree.

## Public Install Strategy

The first normal-user install path should be native Mac packaging through GitHub Releases, not repository cloning.

Target install posture:

- signed and notarised Mac app artifact
- `VoiceBar-macos-arm64.dmg` when disk image packaging is implemented
- `VoiceBar-macos-arm64.zip` if zip remains the first release artifact
- checksum files when practical
- first-run guidance for Microphone and Accessibility permissions
- local runtime setup guidance for Kokoro, `whisper.cpp`, and Ollama unless those steps are bundled or automated

The current private working repository package output remains `build/export/VoiceBar.app` and `build/export/VoiceBar-macos-adhoc.zip`. That output is acceptable for local iteration and staging, but it is not the polished public distribution target.

The refreshed launch walkthrough video should not block the source-first repository opening. Public documentation should say: "Updated walkthrough video coming soon. VoiceBar is source-first today; the refreshed launch walkthrough will be added after it is complete."

Homebrew Cask is planned after the first stable signed and notarised release artifact exists. It requires a stable public release uniform resource locator (URL) and checksum. It is not required for the first public source release, but it is the preferred later one-command install path.

## Containerisation Position

VoiceBar is a native Mac application. Containerisation is not the primary distribution path and is not required for open source release.

Containers do not solve VoiceBar's desktop integration requirements:

- Microphone permission
- Accessibility permission
- global hotkeys
- Function key (Fn) behavior
- text insertion
- native app packaging

Containers may still be useful for developer tooling, documentation builds, or non-desktop tests.

## Product Limitations To Disclose

Public materials should disclose that noisy-background dictation is not fully hardened. VoiceBar currently relies on microphone capture plus local speech-to-text, and noisy environments can degrade transcription quality.

Recommended current guidance:

- Use a quieter environment.
- Use a headset microphone.
- Use system-level microphone noise isolation where available.

Do not claim Apple Voice Isolation is controlled programmatically by VoiceBar unless that is separately verified.
