# VoiceBar Homebrew Cask Feasibility And Future Tap Plan

## Purpose

This document records the future Homebrew Cask path for VoiceBar without claiming that Homebrew works today.

## Current Status

Homebrew Cask is not available for VoiceBar today.

VoiceBar is currently source-first for developers and technical users. The current preview artifact path is:

- `build/export/VoiceBar.app`
- `build/export/VoiceBar-macos-adhoc.zip`

Those artifacts are ad-hoc signed technical-tester preview outputs. They are not Developer ID signed, not Apple notarized, and not frictionless public-user installers.

Ad-hoc signed technical-tester preview builds may still trigger macOS Gatekeeper warnings. Homebrew Cask does not solve Gatekeeper trust for unsigned, ad-hoc signed, or non-notarized Mac apps.

## Feasibility

Homebrew Cask is feasible later if VoiceBar has a stable public release artifact.

The future Homebrew Cask should wrap a release artifact that already exists elsewhere, usually from GitHub Releases. Homebrew should be the install convenience layer, not the first place where release trust is established.

Required future inputs:

- Public release uniform resource locator (URL): `PUBLIC_RELEASE_URL_PLACEHOLDER`
- Version tag: `VERSION_TAG_PLACEHOLDER`
- Secure Hash Algorithm 256-bit (SHA-256) checksum: `SHA256_CHECKSUM_PLACEHOLDER`
- App artifact name: `APP_ARTIFACT_NAME_PLACEHOLDER`
- Developer ID signed Mac app artifact
- Apple notarized Mac app artifact
- First-run Microphone and Accessibility permission guidance
- Local runtime setup guidance for Kokoro, `whisper.cpp`, and Ollama unless those steps are bundled or automated later

## Why Homebrew Is Not Primary Yet

GitHub Releases remains the planned primary public-user route before Homebrew Cask.

Homebrew is not primary yet because:

- there is no stable signed and notarized public VoiceBar artifact
- there is no public release uniform resource locator (URL)
- there is no release checksum workflow
- Developer ID signing is unavailable right now
- Apple notarization is unavailable right now
- Homebrew Cask does not remove first-launch trust checks for unsigned or non-notarized apps
- public repository publication still requires explicit operator approval

Current technical testers should use the source-first and ad-hoc preview artifact guides instead of Homebrew.

## Future Tap Shape

A future tap could live in a repository such as:

```text
homebrew-voicebar
```

Do not create or publish that repository in this lane.

The future cask file could be:

```text
Casks/voicebar.rb
```

Do not publish this cask until a stable signed and notarized artifact, public release uniform resource locator (URL), version tag, and Secure Hash Algorithm 256-bit (SHA-256) checksum exist.

## Blocked Preview Cask Template

The template below is intentionally blocked. It is included only to show the future shape of a Homebrew Cask after release gates are complete.

```ruby
cask "voicebar" do
  version "VERSION_TAG_PLACEHOLDER"
  sha256 "SHA256_CHECKSUM_PLACEHOLDER"

  url "PUBLIC_RELEASE_URL_PLACEHOLDER/APP_ARTIFACT_NAME_PLACEHOLDER"
  name "VoiceBar"
  desc "Local-first Mac voice workflow tool"
  homepage "PUBLIC_PROJECT_HOMEPAGE_PLACEHOLDER"

  app "VoiceBar.app"

  caveats <<~EOS
    VoiceBar requires Microphone and Accessibility permissions for dictation,
    text insertion, selected-text reading, and global hotkeys.

    Follow the VoiceBar first-run guide after installation.
  EOS
end
```

Do not replace the checksum with `sha256 :no_check` unless the operator explicitly approves that weaker release posture in a future lane.

## Future Publication Checklist

Before publishing a cask:

- verify the app artifact is Developer ID signed
- verify the app artifact is Apple notarized
- verify the artifact downloads from the public release uniform resource locator (URL)
- compute and record the Secure Hash Algorithm 256-bit (SHA-256) checksum
- test install and uninstall on a clean Mac
- test first launch from the installed app bundle
- verify Microphone and Accessibility permission prompts from the installed app bundle
- verify the Homebrew Cask caveats point to current first-run guidance
- run local continuous integration (CI)
- run hosted continuous integration (CI)
- complete local Codex review
- complete automated hosted review where available
- get explicit operator approval before publication

## Non-Goals For This Lane

This lane does not:

- publish a Homebrew tap
- publish a Homebrew Cask
- make any repository public
- update the public-staging repository
- require Apple credentials
- require Google credentials
- implement Developer ID signing
- implement Apple notarization
- claim that `brew install --cask voicebar` works today
