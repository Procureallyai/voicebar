# VoiceBar v1 Operator Requirements

## Product Context

- Product: `VoiceBar`
- Platform target: native macOS utility
- Runtime target: macOS 15+
- Development target: Xcode 16+
- Target hardware: MacBook Pro M1 Max, 32 GB RAM, 1 TB SSD
- Primary use case: long-form reading of Codex outputs, browser text, Slack, Gmail, docs, notes, and general selected text across macOS
- Language: English only for v1
- Priority order:
  - natural human speech with emotion, cadence, and pleasant pacing
  - low friction across apps
  - low ongoing cost with no cloud dependency
- Distribution posture: direct-distribution utility first, not Mac App Store-first

## Boundary With V2

- v1 is the reading product
- v1 does not include speech-to-text dictation, formatter routing, snippets, or phrase-triggered local actions as completed baseline features
- those capabilities belong to the v2 phase and should stay documented separately

## Non-Negotiable Decisions

- Default engine on this M1 Max when Kokoro is configured = local Kokoro-backed `Quick`
- Premium remains `TTSKit + Qwen3-TTS 1.7B CustomVoice` as an explicit advanced / fallback path on this hardware
- Quick preferred engine when configured = local Kokoro runtime
- Quick fallback when Kokoro is not configured = `TTSKit + Qwen3-TTS 0.6B CustomVoice`
- Do not use raw `Qwen3-TTS 1.7B VoiceDesign` or `1.7B Base` in v1
- Do not add any broader Python, Node, or server sidecar in v1 beyond the narrow local Kokoro Quick-path exception
- The controlled local Python sidecar for Kokoro Quick is now part of the truthful local runtime contract because the operator approved that exception to reach a working local solution
- Do not make the app depend on any cloud TTS API for core functionality
- Everything should run locally on Apple silicon
- Hugging Face is allowed only for model download, caching, version pinning, and developer tooling, not as a runtime cloud dependency

## Required App Shape

- native Swift / SwiftUI menu bar app
- global hotkeys
- tiny floating playback controller
- settings window
- macOS Service for selected text
- accessibility-based selected-text capture
- explicit clipboard fallback
- local on-device TTS via TTSKit or an explicitly approved local sidecar runtime

## Required Architecture Layers

- App shell
- `TextCaptureService`
- `TextNormalizationService`
- `PronunciationService`
- `SpeechEngine` protocol
- `TTSKitPremiumEngine`
- `TTSKitQuickEngine`
- `KokoroPythonSpeechEngine` (when the local runtime is configured)
- `PlaybackController`
- `AppProfileStore`
- Diagnostics / Benchmark panel

## Text Capture Requirements

The capture order is fixed:

1. accessibility path first
2. macOS Service path second
3. explicit clipboard path third
4. optional experimental copy fallback last and disabled by default

### Accessibility Path

- Request Accessibility trust on first launch with a clear onboarding explanation
- Inspect the focused UI element
- Attempt to read selected text from accessibility attributes
- If that succeeds, pass the text into normalization and speech
- If not, continue through the fallback chain

### macOS Service Path

- Add a Service named `Read with VoiceBar`
- Accept selected text from other apps
- Read that text immediately
- Document how to enable the Service and assign a keyboard shortcut in macOS Keyboard Shortcuts > Services

### Explicit Clipboard Path

- Add a separate user-triggered command and hotkey for `Read Clipboard`
- Read plain text from the clipboard and speak it
- Never poll the clipboard in the background
- Never read from the clipboard implicitly outside a clear user action

### Experimental Copy Fallback

- Add an advanced setting called `Try copy fallback when selection extraction fails`
- Default it to off
- If enabled and the user triggers `Read Selection`, attempt a best-effort copy fallback
- Preserve pasteboard contents if possible
- Trigger copy only as a user-initiated action
- Restore the prior clipboard if safe
- If the path is too fragile, ship it disabled or partially stubbed without blocking v1

## Speech And UX Requirements

- stream playback immediately
- do not wait for full synthesis unless the user explicitly chooses that mode
- use sentence-boundary chunking
- preserve natural paragraph pauses
- expose `Premium` mode that forces the `1.7B` engine
- expose `Quick` mode that forces the currently configured fast local engine (Kokoro when configured, otherwise the TTSKit `0.6B` fallback)
- expose `Auto` only if its behavior is honest and clearly defined
- default app behavior on this M1 Max should be `Quick` when the Kokoro runtime is configured
- if `Premium` initialization fails, fall back gracefully to `Quick` and notify the user

## Style Presets

- `Warm Explainer`
  - "Read in natural, warm, clear English with calm confidence and subtle emotional cadence."
- `Calm Narrator`
  - "Read slowly and clearly in natural English with gentle pacing and a relaxed tone."
- `Neutral Professional`
  - "Read clearly and naturally in English with professional tone and moderate pace."
- `Energetic Guide`
  - "Read in natural English with energy, warmth, and slightly faster pacing without sounding rushed."
- `Custom instruction`

## Voice Selection

- expose all built-in available TTSKit voices in settings
- if Quick mode uses an alternative local runtime, document any temporary voice-mapping limits honestly
- choose a reasonable default for English
- make voice switching easy
- persist the chosen voice
- if there is no obvious best default, use a safe one and document that the user should audition voices

## Text Normalization Requirements

- prose-first mode should skip fenced code blocks by default
- optional read-everything mode
- natural markdown headings, bullets, and numbered lists
- shorter speakable URL handling
- more readable file-path handling
- camelCase, snake_case, kebab-case, and repo-name normalization where useful
- acronym spelling where appropriate
- paragraph preservation
- `Headings only` mode
- `Skip inline code` toggle
- avoid reading long raw punctuation runs literally

## Pronunciation Dictionary

- store user-editable pronunciation overrides in `Application Support` as JSON
- support exact text replacements at minimum
- keep the structure easy to extend later
- include sample entries for:
  - Codex
  - Hugging Face
  - Qwen
  - Evidary
  - EU AI Act
- allow per-entry enable / disable
- build a simple settings editor if it is easy
- otherwise ship file-based editing and document the file location

## Per-App Profiles

Use the frontmost bundle identifier and support:

- preferred engine
- preferred style preset
- skip code blocks on or off
- headings-only on or off
- default speaking rate or pacing modifier if available
- whether clipboard fallback is allowed

Ship sensible defaults for:

- Codex app
- web browsers
- Slack
- Mail / Gmail
- Notes / TextEdit

## UI And Diagnostics Requirements

### Menu Bar

- clean `NSStatusItem` menu bar icon
- include:
  - Read Selection
  - Read Clipboard
  - Pause / Resume
  - Stop
  - Replay Last
  - Engine: Premium / Quick / Auto
  - style preset submenu
  - Open Settings
  - Launch at Login
  - Quit

### Floating Controller

- tiny and non-intrusive HUD or panel
- show current state: speaking / paused / idle
- show current engine and voice
- include pause/resume, stop, and replay
- allow dismissal

### Settings Surface

- General
- Voices & Style
- Text Handling
- Per-App Profiles
- Hotkeys
- Diagnostics
- Advanced

### Diagnostics

- warm / cold engine state
- first audio start time
- total generation time
- current engine
- truthful runtime status, not invented metrics

## Performance Requirements

- preload the `1.7B` engine in the background only if the user enables `Preload Premium Engine`
- default that setting to off for the target machine because Kokoro-backed Quick is now the truthful primary path on this Mac
- load the `0.6B` fallback lazily or in the background after startup
- use streaming playback by default
- cancel generation cleanly on stop
- if the system is under serious thermal stress or Premium errors repeatedly, fall back to Quick and show a non-annoying notification

## Implementation Constraints

- native Swift / SwiftUI only for the main app
- very few dependencies beyond Argmax OSS / TTSKit
- no Electron, Tauri, or webview shell
- no cloud service
- do not block local iteration on signing or notarization
- keep the repo ready for later signing and notarization work
- keep the codebase readable and modular

## Required Supporting Assets

- `README.md`
- scripts for build and run
- `.agents/skills/voicebar-dev/SKILL.md`
- optional `agents/openai.yaml` if genuinely useful
- optional model prefetch helper only if it helps and is not a runtime dependency
- tests for normalization, pronunciation dictionary application, per-app profiles, and engine selection logic
- manual QA checklist
- explicit known limitations section

## Hugging Face Guidance

- do not make runtime require a Hugging Face token
- if a prefetch script is added, keep it optional
- if `hf` CLI is present, document how to prefetch or pin model artifacts
- document that Hugging Face tooling is optional developer tooling, not a runtime dependency

## Testing Requirements

- unit tests for text normalization
- unit tests for pronunciation dictionary application
- tests for per-app profile matching logic
- smoke coverage for speech engine selection logic
- honest manual QA checklist for:
  - Codex app selected text
  - Safari or Chrome selected text
  - Slack selected text
  - TextEdit selected text
  - Notes selected text
  - Gmail in browser
  - clipboard reading
  - Service menu invocation
  - pause / resume / stop
  - long markdown with code fences
  - long prose article

## Known Limitations To State Honestly

- some apps expose selection through accessibility better than others
- some apps may require the Service route or clipboard route
- experimental copy fallback may not work everywhere
- first run or first Premium request will be slower because of model download and lazy loading

## Future-Proofing

Design the speech layer behind a protocol so later phases can add:

- raw Qwen3-TTS VoiceDesign sidecar
- raw Qwen3-TTS Base sidecar
- optional OpenAI fallback
- optional browser extension or Safari extension

Do not implement those future extensions in v1 unless they become trivial after the working v1 foundation is complete.
