# VoiceBar Direct Distribution Checklist

Use this checklist when you need a truthful local `.app` bundle for VoiceBar without pretending signing or notarization are already complete.

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

## Scope

- direct-distribution iteration only
- no Mac App Store packaging
- no claim that the current artifact is Developer ID signed or Apple notarized
- no claim that the current operator Mac already has the required text-to-speech (TTS) model assets cached
- no claim that the current ad-hoc archive is the polished public-user install path
- no claim that ad-hoc preview artifacts are suitable for normal public users

## Prerequisites

- macOS 15+
- Apple silicon
- `xcodegen 2.45.4`
- Swift 6 toolchain
- a full `Xcode.app` available either through `xcode-select` or a command-scoped `DEVELOPER_DIR`

The current operator machine now satisfies the full-Xcode prerequisite globally:

- `xcode-select -p` returns `/Applications/Xcode.app/Contents/Developer`
- `xcodebuild -version` returns Xcode `26.4.1` (build `17E202`)
- a separate `~/Downloads/Xcode.app` copy still exists, but it is duplicate-app-path truth rather than the active packaging path

## Packaging Command

```bash
bash scripts/package-app.sh
```

What the script does on a full-Xcode machine:

1. Regenerates `VoiceBar.xcodeproj`.
2. Verifies that the active toolchain is a full Xcode 16+ install.
3. Builds the `VoiceBar` scheme in `Release` with signing disabled.
4. Stages the raw `.app` bundle under `build/DerivedData/Build/Products/Release/VoiceBar.app`.
5. Copies the staged bundle into `build/export/VoiceBar.app`.
6. Zips that bundle into `build/export/VoiceBar-macos-adhoc.zip`.

What the script does on this Mac today:

- succeeds directly because `xcode-select` now points at `/Applications/Xcode.app/Contents/Developer`
- also rejects repo-root aliases such as `./` or `././.` plus absolute cleanup overrides for `DERIVED_DATA_PATH` and `EXPORT_ROOT` so destructive cleanup stays repo-local
- also requires `APP_NAME` and `ZIP_NAME` overrides to stay simple leaf names so staged artifacts cannot escape `build/export/`
- leaves `bash scripts/build.sh`, `bash scripts/test.sh`, and `bash scripts/ci.sh` as the truthful local validation path when you are not running a full export

## Output Conventions

- SwiftPM debug binary: `.build/arm64-apple-macosx/debug/VoiceBarApp`
- DerivedData release bundle: `build/DerivedData/Build/Products/Release/VoiceBar.app`
- stable distribution bundle: `build/export/VoiceBar.app`
- stable ad-hoc signed technical tester preview archive: `build/export/VoiceBar-macos-adhoc.zip`

`build/export/` is the handoff folder for local operator install, later signing work, and future release automation.

Future public release artifact names should be:

- `VoiceBar-macos-arm64.dmg` when disk image (DMG) packaging exists
- `VoiceBar-macos-arm64.zip` if zip remains the first release artifact
- checksum files when practical

## Install And Run

Once `build/export/VoiceBar.app` exists:

1. Copy `VoiceBar.app` into `/Applications` or `~/Applications`.
2. Launch the app directly from Finder.
3. Grant Accessibility when prompted if you want `Read Selection`.
4. Enable the `Read with VoiceBar` Service under `System Settings > Keyboard > Keyboard Shortcuts > Services`.
5. Validate launch-at-login, hotkeys, floating-controller focus, and the Service path from the real bundle rather than from `swift run`.

The ad-hoc signed preview artifact is suitable for direct-distribution iteration and technical tester preview, but this lane does not claim frictionless internet-download installs yet. macOS may require manual approval because the artifact is not Developer ID signed and Apple notarized. Keep any first-launch Gatekeeper behavior `Unverified` until it is tested from the produced bundle on a target machine.

Normal public users should install from GitHub Releases after a Developer ID signed and Apple notarized artifact exists. They should not need Xcode or a repository clone unless they are contributors.

## Model Download And Cache Truth

- VoiceBar configures TTSKit for on-demand load.
- `Preload Premium Engine` defaults to on, so the app may attempt model preparation during bootstrap.
- If preload does not complete first, the first real Premium playback still becomes the truthful model-download and prepare moment.
- The most relevant local cache evidence is the app-owned Hugging Face model cache below the VoiceBar application-support directory.
- The older `~/Documents/huggingface/models/argmaxinc/ttskit-coreml` guidance is stale for the current branch truth because that location triggered an extra macOS Documents-folder prompt on the local helper app.
- The VoiceBar application-support directory contains both the model cache tree above and VoiceBar JavaScript Object Notation (JSON) overrides such as `pronunciation-dictionary.json` and `app-profiles.json`, so cite the product subpath rather than an operator-local absolute path when proving model readiness.
- Prompt 009 first proved the Premium `12hz-1.7b-customvoice` tree on this Mac, and Prompt 010 now routes both Premium and Quick cache preparation through the private Application Support tree.
- Prompt 011's fresh helper-bundle timings now keep the direct-distribution claim honest too: this Mac still is not playback-ready because Premium starts far too late and Quick / Auto still restart their first-output-buffer path during long-form playback.

## Signing And Notarization Prep

Prompt 008 intentionally stopped at a local preview bundle so local iteration was not blocked by Developer ID signing or Apple notarization.

Follow-on release work should add:

- a real Developer ID signing identity
- `codesign --verify --deep --strict` verification on the produced bundle
- Apple notarization submission and stapling
- a distribution test on a second machine for first-launch behavior
- first-run Microphone and Accessibility permission guidance
- release notes
- checksums for public artifacts
- Homebrew Cask only after a stable public release uniform resource locator (URL) and checksum exist

Until that follow-on lane lands, keep these claims out of release notes:

- "signed"
- "notarized"
- "safe to double-click on any Mac without prompts"
- "normal-user ready"

## Honest Release Gate

Do not call VoiceBar direct-distribution ready on the current operator Mac until all of these are true:

- `bash scripts/package-app.sh` succeeds on a full-Xcode machine
- `build/export/VoiceBar.app` is installed and launched from Finder
- the Service path, launch-at-login flow, hotkeys, and floating-controller focus are validated from the real bundle
- first real Premium model preparation succeeds and leaves local cache evidence
- real playback on the operator Mac succeeds instead of failing with `Failed to parse ML Program. It is likely an invalid or broken model.`
- any Developer ID signing or Apple notarization claims are backed by real release verification rather than intent
- noisy-background dictation limitations are documented, with future acceptance tests before claiming hardened noisy-background reliability
