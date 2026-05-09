# VoiceBar Manual Quality Assurance (QA) Checklist

Use this checklist for truthful operator validation on the current repo baseline.

## Preconditions

- Confirm whether the build under test is source-first, ad-hoc preview, or signed public release. Current repository builds are source-first or ad-hoc technical tester previews unless a later release lane proves Developer ID signing and Apple notarization.
- `bash scripts/build.sh`
- `bash scripts/test.sh`
- `bash scripts/ci.sh`
- `bash scripts/setup-kokoro-runtime.sh` when validating the merged Kokoro-backed Quick path
- `bash scripts/setup-whisper-runtime.sh` when validating the local v2 dictation path
- `bash scripts/package-app.sh` on this Mac now that a full Xcode bundle is already selected
- `bash scripts/run.sh` when you need the stable local `~/Applications/VoiceBar.app` helper bundle plus the Desktop launcher refresh
- a real `.app` bundle if you want truthful Services, launch-at-login, or end-to-end hotkey validation
- relaunch VoiceBar after `bash scripts/setup-kokoro-runtime.sh` if the app was already open, because Quick engine selection happens at app startup

## Machine Truth Before You Start

- `xcode-select -p` is now `/Applications/Xcode.app/Contents/Developer` on the current operator Mac.
- `xcodebuild -version` returns Xcode `26.4.1` (build `17E202`).
- `bash scripts/package-app.sh` now succeeds on this Mac and produces `build/export/VoiceBar.app` plus `build/export/VoiceBar-macos-adhoc.zip`.
- A separate `~/Downloads/Xcode.app` copy still exists, but it is duplicate-app-path truth rather than the active packaging path.
- `bash scripts/run.sh` now assembles and launches a stable local `~/Applications/VoiceBar.app` bundle for TCC and Finder relaunch testing on this machine.
- `bash scripts/run.sh` also refreshes the Desktop launcher symlink at `~/Desktop/VoiceBar.app`, which points to `~/Applications/VoiceBar.app`.
- The helper still relaunches into `AXIsProcessTrusted() == false` after local rebuilds on this Mac, and `security find-identity -v -p codesigning` currently returns `0 valid identities found`, so helper-path Accessibility stability remains `Unverified` until the operator re-grants the bundled `VoiceBar` row or a real local signing identity exists.
- Premium `12hz-1.7b-customvoice` assets are evidenced under the VoiceBar application-support Hugging Face model cache on this Mac.
- Quick `12hz-0.6b-customvoice` assets are evidenced under the VoiceBar application-support Hugging Face model cache on this Mac.
- The earlier `Failed to parse ML Program. It is likely an invalid or broken model.` state no longer reproduces after the Prompt 010 Hugging Face cache reinstall.
- Long-form playback continuity and startup smoothness remain operator-ear checks on the current merged runtime contract.
- Prompt 010 now also logs when the player schedules its first output buffer, because the older `playback.first-audio` timer only measured when the engine emitted audio, not when the speakers actually started.
- Prompt 011's newest helper-bundle benchmarks on a 214-character Terminal clipboard sample now show the current runtime blocker even more clearly on this Mac:
  - explicit `Premium` produced first audio after `12452ms`, did not schedule first speaker output until roughly `48.7s`, and completed generation in `56036ms`
  - explicit `Quick` produced first audio after `3113ms`, did not schedule first speaker output until roughly `13.3s`, and re-logged "Scheduled the first output buffer..." multiple times before completing generation in `30920ms`
  - `Auto` degraded to Quick because Premium was cold, produced first audio after `2724ms`, did not schedule first speaker output until roughly `7.3s`, and still re-logged that first-output-buffer event repeatedly before completing generation in `28495ms`
- Standalone upstream TTSKit benchmarking now proves the same machine-level problem outside the VoiceBar shell:
  - `0.6B CustomVoice` generated 25.1 seconds of audio in 97.2 seconds on this Mac
  - the default `1.7B CustomVoice` decoder path crashed in CoreML / ANE outside VoiceBar itself
  - forcing the `1.7B` decoder stack onto `cpuAndGPU` avoided that ANE crash, but 9.84 seconds of audio still took 47.86 seconds to generate
- Treat the current long-form defect as a real machine/runtime blocker, not as a closed app-layer bug, until a newer runtime path proves clean end-to-end on this hardware.
- Quick mode now uses a local Kokoro sidecar when the configured VoiceBar application-support Kokoro runtime exists and falls back to the existing TTSKit Quick path when it does not.
- Kokoro-backed Quick is now the truthful primary/default reading path on this M1 Max when that runtime is configured; Premium remains an explicit advanced path and should not be treated as the normal baseline during operator validation.
- Prompt 012 local Kokoro probes on this M1 Max were faster-than-real-time from the app-owned runtime path (`14.0s` audio in `3.2s`, `39.7s` audio in `7.9s`), but bundled first-speaker-output and final continuity judgment are still by-ear operator checks.
- The VoiceBar application-support directory includes both the VoiceBar JavaScript Object Notation (JSON) overrides and the app-owned Hugging Face cache tree, so use the product subpath when proving model readiness.

## Checklist

### Packaging And Install Path

- Run `bash scripts/package-app.sh` on a machine with a full `Xcode.app`.
- Confirm the script produces:
  - `build/export/VoiceBar.app`
  - `build/export/VoiceBar-macos-adhoc.zip`
- Copy `VoiceBar.app` into `/Applications` or `~/Applications`.
- Launch the copied app from Finder instead of relying on `swift run`.
- Keep this path labeled local iteration and staging only unless a Developer ID signed and Apple notarized public release artifact exists.
- For public release validation, confirm the intended artifact name is `VoiceBar-macos-arm64.dmg` or `VoiceBar-macos-arm64.zip`.
- Confirm checksum files and release notes exist before calling a public release artifact ready.

If you cannot run the exported bundle from Finder or validate the produced `build/export/VoiceBar.app`, mark this step `Unverified`.

### Public Install And First Run

- Confirm the Read Me (README) includes the Install Status box and source-first wording.
- Confirm normal-user instructions do not require Xcode once a signed public release exists.
- Confirm normal-user instructions do not require cloning the repository unless the user is contributing or following the current source-first developer path.
- Confirm ad-hoc preview artifact instructions say technical testers only.
- Confirm Gatekeeper instructions explain that macOS may require manual approval because current preview artifacts are not Developer ID notarized.
- Confirm first-run guidance explains Microphone permission.
- Confirm first-run guidance explains Accessibility permission for text insertion and selected-text workflows.
- Confirm first-run guidance explains Function key (Fn) behavior and fallback shortcuts.
- Confirm local `whisper.cpp` setup guidance is available.
- Confirm Ollama setup guidance is available when formatter mode is enabled.
- Confirm Kokoro or text-to-speech runtime setup guidance is available.
- Confirm the artifact is Developer ID signed and Apple notarized before claiming low-confusion public distribution readiness.
- Confirm Homebrew Cask language is future-facing until a stable public release uniform resource locator (URL) and checksum exist.

### Noisy-Background Dictation

- Run a quiet-room dictation sample with synthetic text.
- Run a steady background-noise dictation sample with synthetic text.
- Run an intermittent keyboard or room-noise dictation sample with synthetic text.
- Compare built-in microphone and headset microphone behavior when available.
- Confirm VoiceBar does not claim fully hardened noisy-background dictation.
- Confirm public guidance recommends a quieter environment, headset microphone, or system-level microphone noise isolation where available.
- Record stop reason, peak level, and transcription outcome where private-text-free telemetry is available.

If noisy-background reliability cannot be directly proven, mark it `Unverified` and keep it as a future improvement lane.

### Launch And Bootstrap

- Launch VoiceBar.
- Confirm the app starts without an immediate crash.
- Confirm the menu bar item appears.
- Confirm the default shell status still reports Accessibility, Services, or clipboard as the capture options.

### Accessibility Permission Flow

- Launch VoiceBar and confirm it does not immediately loop the Accessibility prompt on startup.
- Trigger `Read Selection` with Accessibility disabled.
- Confirm VoiceBar opens Accessibility settings guidance from that explicit action instead of re-triggering the system trust prompt every time.
- Confirm the app status explains that Services or clipboard are the fallback when Accessibility is off.
- Re-run `Read Selection` after granting access and confirm the prompt does not loop unnecessarily.
- Confirm the menu now exposes `Open Accessibility Settings`, `Reveal VoiceBar in Finder`, and `Relaunch VoiceBar` as operator recovery paths.
- If System Settings still shows VoiceBar enabled but the app behaves as though trust is missing, remove and re-add `~/Applications/VoiceBar.app` or `~/Desktop/VoiceBar.app`, then relaunch and retry.

If the helper row still looks enabled in System Settings but `Read Selection` behaves as though Accessibility is off after a local helper reinstall, keep this step `Blocked` on the current Mac and note that the bundled helper still needs a fresh `VoiceBar` row re-grant under the current ad-hoc signing setup.

### Selection Capture Across Surfaces

Run `Read Selection` against:

- Codex Mac app
- Safari or Chrome
- Slack
- TextEdit or Notes
- Gmail in the browser

Expected result:

- Apps that expose Accessibility selection should read directly.
- Apps that do not should fail honestly and point you to the Service path or clipboard path.

### Service Path

- Build and run a real `.app` bundle when available.
- Enable `Read with VoiceBar` under `System Settings > Keyboard > Keyboard Shortcuts > Services`.
- Invoke the Service from at least one app with selected text.
- Confirm the selected text is consumed immediately and routed into playback.

If you are only using the local dev helper from `bash scripts/run.sh`, keep this step `Unverified` until the full-Xcode `VoiceBar.app` export path is also proven.

### Clipboard Path

- Copy plain text.
- Trigger `Read Clipboard` from the menu bar.
- Confirm VoiceBar only reads clipboard text on explicit user action.
- Confirm there is no background clipboard polling.
- Confirm diagnostics show `kokoro-quick` when the local runtime is configured and the request is following the normal default path on this Mac.

### Long Prose And Markdown

- Feed a long prose selection.
- Feed markdown that includes headings, numbered lists, bullet lists, file paths, URLs, and fenced code blocks.
- Confirm prose stays readable, code fences are skipped in prose-first mode, and headings-only mode still omits body text.

### Voice, Style, And Playback Controls

- Switch between Premium, Quick, and Auto.
- Confirm Quick is using `kokoro-quick` in diagnostics when the runtime is configured.
- Confirm the default shell/app-profile routing now lands on Quick for the common operator surfaces unless you explicitly choose Premium.
- Change the default voice.
- Change the style preset and try Custom instruction.
- Confirm pause, resume, stop, and replay behave as expected.
- Confirm the floating controller tracks current state during playback.

### Per-App Profiles And Persistence

- Edit at least one per-app profile.
- Restart VoiceBar.
- Confirm the profile persists.
- Confirm pronunciation overrides and app profiles write to:
  - VoiceBar application-support `pronunciation-dictionary.json`
  - VoiceBar application-support `app-profiles.json`

### Hotkeys

- Verify the default shortcuts:
  - `Read Selection`: `Ctrl` + `Option` + `Command` + `R`
  - `Read Clipboard`: `Ctrl` + `Option` + `Command` + `C`
  - `Pause / Resume`: `Ctrl` + `Option` + `Command` + `P`
  - `Stop`: `Ctrl` + `Option` + `Command` + `S`
  - `Replay Last`: `Ctrl` + `Option` + `Command` + `L`
  - `Toggle Controller`: `Ctrl` + `Option` + `Command` + `V`
- Rebind one shortcut and confirm it persists.
- Confirm unregistered or conflicting shortcuts fail honestly.
- Confirm Hold-to-Talk mode persists after restart in both `Option Shortcut` and `Function key (Fn) experimental` modes.
- For `Option Shortcut`, confirm Option+Period still starts recording on press and stops on release.
- For `Function key (Fn) experimental`, first check `System Settings > Keyboard > Keyboard Shortcuts > Function Keys` and `System Settings > Keyboard > Press Function key (Fn) to` so Function key (Fn) / Globe key is not assigned to a conflicting system action such as emoji, input source switching, or system dictation.
- With `Function key (Fn) experimental` enabled, hold Function key (Fn), speak synthetic text only, and release.
- With `Function key (Fn) experimental` enabled, press Right Arrow in a text field and confirm VoiceBar does not start listening; unified logs should show the keyDown/keyUp path ignored rather than `holdToTalk.press`.
- Mark Function key (Fn) support as verified only if unified logs show `functionKey.press.detected`, `functionKey.release.detected`, `holdToTalk.press`, `holdToTalk.release`, and `dictation.pipeline.completed` from the installed app.
- Current operator Mac evidence from 2026-04-29 verifies Function key (Fn) support when Wispr Flow is quit: three installed-app runs logged press, release, capture, and pipeline completion. Retest after enabling any other app that may intercept Function key (Fn).
- If either Function key (Fn) press or release is missing, mark Function key (Fn) support blocked on this Mac and use Option+Period or an F13-F19 key.

If you are not validating through a real app bundle, keep end-to-end hotkey behavior marked `Unverified`.

### Launch At Login

- Validate only through a real `.app` bundle.
- Toggle launch-at-login on.
- If macOS requests approval, confirm the app surfaces that requirement honestly.
- Restart the machine or log out and back in if you need a full proof.

If you are not validating through the full-Xcode exported app bundle, mark this step `Unverified`.

### Diagnostics

- Open the Diagnostics tab.
- Confirm runtime status, engine status, and recent events refresh.
- Confirm diagnostics remain in-memory only and are not written to a disk log file.

### Desktop Launcher And Icon

- Run `bash scripts/run.sh`.
- Confirm `~/Desktop/VoiceBar.app` exists.
- Confirm it resolves to `~/Applications/VoiceBar.app`.
- Confirm the launcher opens VoiceBar.
- Confirm the launcher and helper both show the current VoiceBar icon.
- Confirm the operator-facing docs stay explicit that the Desktop launcher is convenience only, not Developer ID signing or Apple notarization proof.

### v2 Dictation And Actions

- Run `bash scripts/setup-whisper-runtime.sh` if the whisper.cpp runtime is not present yet.
- Confirm the Dictation settings tab reports the local speech-to-text (STT) and formatter runtime state honestly.
- Confirm the Formatter controls render as two non-overlapping rows: model field plus Apply, then mode picker.
- Start a dictation capture and confirm VoiceBar records, stops, and transcribes locally.
- If the Ollama formatter stalls, confirm VoiceBar falls back to snippet-expanded insertion instead of failing the whole dictation pass.
- Confirm insertion-at-cursor only happens when the operator keeps that setting enabled.
- Confirm Save Recent Dictations for Recovery is enabled by default and stores the formatted text plus raw transcript before insertion.
- Confirm Copy Last Dictation and Retry Insert Last Dictation recover the latest formatted text if the cursor was in the wrong place.
- Confirm Show Recent Dictations opens Settings > Dictation and shows only local history entries from VoiceBar Application Support.
- Confirm Clear History removes the local dictation history.
- Confirm dictation history diagnostics record character counts and redacted entry tokens only, not dictated text.
- Confirm snippets are read from the VoiceBar application-support snippets file.
- Confirm Local Snippets supports create, read, update, delete, enable, disable, multiline expansion editing, and explicit alias editing.
- Confirm the Label field is presented as display-only and is not described as a spoken trigger.
- Confirm Add Label as Trigger adds the current non-empty label to Trigger Phrases And Aliases only once after normalization.
- Confirm Add Speech Aliases adds conservative deterministic variants such as spacing camel-case labels, without broad fuzzy matching or model-generated phrases.
- Confirm snippet acceptance includes common speech-to-text recognition variants for operator-critical triggers only as explicit aliases; variants must not enable broad fuzzy matching.
- Confirm the synthetic command-text snippet expands from explicit aliases without executing anything.
- Confirm the synthetic command-text expansion has no newline, no carriage return, and no trailing newline.
- Confirm actions are read from the VoiceBar application-support actions file.
- Confirm model-detected action candidates do not execute arbitrary shell text.
- Confirm only allowlisted actions can run, with confirmation behavior matching the registry/settings truth.
- Confirm Audio Confirmation uses the current toggle, does not stack repeated stale confirmations, and records private-text-free `dictation.confirmation.*` diagnostics.
- Confirm these synthetic formatting acceptance utterances produce expected local output or documented formatter fallback: `make this a numbered list one apples two oranges three pears`, `this should be a sorted numbered list one bananas two apples three carrots`, `write this as a bullet list apples oranges pears`, `format this as an email to the team saying the report is ready`, and `this is a new line of products`.

If v2 latency, warm/cold behavior, or action/operator fit cannot be directly proven from the current run, keep those parts `Unverified`.

### Text-To-Speech (TTS) Model Readiness

- Trigger the first real Premium playback on the operator Mac.
- If preload is on, note whether the app appears to prepare the Premium engine during bootstrap before you manually start playback.
- Confirm whether model download or preparation occurs.
- Check for local cache evidence under the VoiceBar application-support Hugging Face model cache.
- Trigger an explicit Quick-path playback as well and confirm whether `12hz-0.6b-customvoice` is also created under that cache root.
- If playback or preparation fails, record the exact error and keep the machine-level readiness blocker open.
- The current machine-level blocker is no longer model-cache preparation; it is live operator playback quality, helper signing / Transparency, Consent, and Control (TCC) stability, bundled Kokoro first-speaker-output, and by-ear confirmation from the current bundle.

## Honest Completion Rule

Do not call VoiceBar fully usable on the current Mac until:

- `bash scripts/package-app.sh` succeeds on a full-Xcode machine and the produced bundle is installed from Finder
- first real text-to-speech (TTS) model preparation succeeds
- real playback on the operator Mac succeeds without long-form buffering, cut-outs, or permission-loop failures
- the normal default path is provably using Kokoro-backed Quick on this Mac rather than silently routing common reads back into Premium
- Services, launch-at-login, hotkeys, and floating-controller focus are validated from a real `.app` bundle
- signed-release limitations are cleared or explicitly accepted as operator constraints
