# VoiceBar First-Run Guide

## Install Status

VoiceBar is currently source-first for developers and technical users. Signed, notarized Mac builds are planned for a later release. Preview builds may be provided for testers, but macOS may require manual approval because they are not Developer ID notarized yet.

Use this guide after launching `VoiceBar.app` from a source build or ad-hoc preview artifact.

## macOS Gatekeeper

Unsigned preview artifacts may be blocked on first launch. If macOS says it cannot verify the app developer, treat that as expected for the current preview path.

Technical testers can review the app location and then approve launch from:

- `System Settings > Privacy & Security`
- the warning entry for the recently blocked `VoiceBar.app`
- `Open Anyway`, if the tester intentionally trusts the local preview build

Do not use this manual approval flow as a public-user install claim. It exists only because current preview artifacts are not Developer ID notarized yet.

## Microphone Permission

VoiceBar needs Microphone permission for dictation.

Tester steps:

- Launch the real `VoiceBar.app` bundle, not only `swift run`.
- Start a dictation action from the app.
- Grant Microphone permission when macOS prompts.
- If permission was denied, open `System Settings > Privacy & Security > Microphone` and enable VoiceBar.
- Relaunch VoiceBar after changing permission state if dictation does not start.

## Accessibility Permission

VoiceBar needs Accessibility permission for text insertion, selected-text reading, and selected-text workflows.

Tester steps:

- Open `System Settings > Privacy & Security > Accessibility`.
- Add or enable the launched `VoiceBar.app`.
- If multiple VoiceBar rows appear after rebuilds, remove stale rows and add the current app bundle again.
- Relaunch VoiceBar after changing Accessibility access.

Ad-hoc signed rebuilds can appear as a new trust target to macOS and may require fresh Microphone and Accessibility grants. That is a known macOS Transparency, Consent, and Control (TCC) limitation until a stable Developer ID signed build exists.

## Function Key Behavior

Function key (Fn) push-to-speak support depends on macOS, keyboard firmware, keyboard settings, and conflicts with other apps.

Tester steps:

- Check `System Settings > Keyboard`.
- Check whether Function key (Fn) or Globe key is assigned to emoji, input source switching, system dictation, or another system action.
- Quit other apps that may intercept Function key (Fn) if testing VoiceBar Function key (Fn) mode.
- Use fallback shortcuts such as Option+Period or a configured F13-F19 key if Function key (Fn) press or release is not reliably detected.

Only mark Function key (Fn) support verified when installed-app logs show press, release, capture, and dictation pipeline completion for the current bundle.

## Local whisper.cpp

VoiceBar uses local `whisper.cpp` for speech-to-text dictation.

Setup:

```bash
bash scripts/setup-whisper-runtime.sh
```

Expected behavior:

- The runtime is stored under the VoiceBar application-support runtime area.
- Downloaded speech-to-text models are local dependencies, not repository files.
- Dictation quality and latency depend on model size, hardware, microphone quality, and background noise.

## Ollama Formatter Mode

VoiceBar can use Ollama for local formatting when formatter mode is enabled.

Tester steps:

- Install Ollama separately.
- Start the Ollama service.
- Pull or configure the formatter model expected by VoiceBar settings.
- Keep fallback behavior enabled so dictation can still insert text if formatting times out or the local model is unavailable.

Formatter mode is optional. Plain Text mode remains the lower-latency fallback path.

## Kokoro Or Text-To-Speech Runtime Setup

The current Quick text-to-speech path prefers the local Kokoro runtime when configured.

Setup:

```bash
bash scripts/setup-kokoro-runtime.sh
```

Expected behavior:

- Relaunch VoiceBar after setup if it was already open.
- Quick mode should use the Kokoro-backed path when the local runtime exists.
- Premium remains an advanced or fallback text-to-speech path.
- External text-to-speech runtime and model artifacts may have separate license terms.

## First Smoke Test

Use synthetic text only when testing public or shareable artifacts.

Suggested first pass:

- Launch `VoiceBar.app`.
- Confirm the menu bar item appears.
- Confirm Microphone permission can be granted.
- Confirm Accessibility permission can be granted.
- Run Read Clipboard with synthetic text.
- Run one short dictation in Plain Text mode.
- Try Function key (Fn) only after fallback shortcuts are known to work.
