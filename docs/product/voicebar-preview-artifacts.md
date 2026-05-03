# VoiceBar Ad-Hoc Preview Artifact Guide

## Preview Status

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

Ad-hoc preview artifacts are for technical testers only. They are not polished public-user release artifacts.

## Current Preview Artifact

Build the current zip preview from the repository root:

```bash
bash scripts/package-app.sh
```

Current outputs:

- `build/export/VoiceBar.app`
- `build/export/VoiceBar-macos-adhoc.zip`

The archive name intentionally uses `adhoc` to avoid implying Developer ID signing, Apple notarization, or general public install readiness.

## Optional Future Disk Image

A future disk image (DMG) preview may be useful for tester handoff, but it must remain clearly labeled as an ad-hoc preview until Developer ID signing and Apple notarization exist.

Acceptable future preview names:

- `VoiceBar-macos-adhoc-preview.dmg`
- `VoiceBar-macos-adhoc-preview.zip`

Do not use final public release names such as `VoiceBar-macos-arm64.dmg` for ad-hoc tester previews. Reserve final release names for signed and notarized artifacts.

## Gatekeeper And First Launch

macOS may block first launch because current preview builds are not Developer ID notarized.

Tester guidance:

- Expect a first-launch warning on some Macs.
- Approve launch only if the tester intentionally trusts the preview source.
- Use `System Settings > Privacy & Security` to review and approve a blocked launch when needed.
- Follow the first-run guide for Microphone and Accessibility permission.
- Expect ad-hoc preview rebuilds to potentially require fresh Microphone and Accessibility permission grants because they do not provide stable macOS Transparency, Consent, and Control (TCC) identity.

Do not describe this path as frictionless, normal-user-ready, or equivalent to a notarized release.

## Sharing Rules

Before sharing any preview artifact:

- Confirm it was built from the intended branch.
- Confirm it contains no private snippets, private paths, private logs, screenshots, recordings, transcripts, credentials, tokens, or private repository links.
- Confirm third-party runtime and model artifacts are not bundled unless redistribution rights are verified.
- Confirm the recipient understands this is a technical tester preview.
- Do not publish a GitHub Release unless the operator explicitly approves it.

## Verification

Recommended local verification:

```bash
git diff --check
bash scripts/build.sh
bash scripts/test.sh
bash scripts/ci.sh
bash scripts/package-app.sh
```

Optional artifact checks:

```bash
codesign --verify --deep --strict build/export/VoiceBar.app
spctl -a -vv build/export/VoiceBar.app
```

For current ad-hoc preview artifacts, those trust-policy checks may fail or report no usable trusted signature. Treat that as preview-truth evidence, not as public release readiness.
