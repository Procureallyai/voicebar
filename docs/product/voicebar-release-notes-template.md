# VoiceBar Release Notes Template

Use this template for future tester previews or public releases. Keep the install-status language honest for the artifact being shipped.

## Title

VoiceBar <version or preview label>

## Install Status

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

## Audience

- Developers and technical testers for ad-hoc preview builds.
- Normal Mac users only after a Developer ID signed and Apple notarized release artifact exists.

## Artifact

- Artifact name:
- Artifact type:
- Signing status:
- Notarization status:
- Checksum:

## What Changed

-

## Installation Notes

- Follow the Source-First Install Guide for source builds.
- Follow the First-Run Guide for Microphone and Accessibility permission.
- Ad-hoc preview artifacts may require manual approval in `System Settings > Privacy & Security`.

## Known Limitations

- Ad-hoc preview builds are not notarized.
- Function key (Fn) behavior depends on macOS, keyboard settings, firmware, and app conflicts.
- Dictation quality can degrade in noisy backgrounds.
- External local runtime and model setup may be required.

## Validation

- Build:
- Tests:
- Continuous integration:
- Packaging:
- Preview artifact check:

## Publication Gate

- Operator approval:
- Automated hosted review:
- Local Codex review:
- Public repository or staging repository visibility:
- External runtime and model redistribution review:
