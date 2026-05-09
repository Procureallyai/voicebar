# VoiceBar v2 Dictation And Actions Requirements

## Purpose

VoiceBar v2 adds local dictation, formatter cleanup, snippets, and deterministic allowlisted actions without weakening the truthful local-first v1 reading contract.

## Product Boundaries

- v1 remains the reading product
- v2 adds dictation, insertion, formatting, snippets, and action routing
- v3 is only a future phase for open-source preparation, security scrub, repo cleanup, and public-release hardening
- v2 must not quietly widen into arbitrary shell execution, cloud transcription, or a broad server sidecar

## Machine Target

- MacBook Pro M1 Max
- 32 GB RAM
- Apple silicon local execution only
- English-first dictation
- direct-distribution utility first

## Approved Runtime Direction

- speech-to-text: `whisper.cpp`
- formatter/router host: local Ollama
- formatter/router low-latency baseline: `llama3.2:3b`
- formatter/router optional high-quality/manual fallback: `gpt-oss:20b`
- benchmark challenger only if needed: `mistral-small3.1`
- do not introduce Qwen as the default formatter/router unless direct evidence later forces it
- if schema-based formatter latency is still impractical on this Mac, keep dictation usable by falling back to snippet-expanded insertion and exact allowlisted trigger matching only

## Dictation UX Requirements

- support a native dictation action and hotkey from the menu bar app
- capture microphone audio locally
- transcribe locally with practical chunking / silence handling for day-to-day dictation
- allow insertion at the current cursor/target app when the operator keeps that setting enabled
- keep audio confirmation optional rather than mandatory for every dictation result
- keep the result insertion path native and practical on macOS

## Formatter Requirements

- use a structured prompt and schema contract, not a vague free-form cleanup prompt
- preserve meaning
- remove filler only when it is obviously safe
- restore punctuation and sentence boundaries
- support paragraphing, bullet formatting, and email-like shaping when the dictation clearly implies it
- avoid over-editing factual content
- prefer deterministic behavior with low temperature
- keep rolling context available for short local continuity without inventing content

## Structured Output Contract

The formatter must return deterministic structured data that includes:

- `cleanedText`
- `formattedText`
- `detectedMode`
- `snippetApplications`
- `actionCandidates`
- `shouldInsertText`
- optional confidence/gating fields

See [voicebar-v2-formatter-prompt-contract.md](./voicebar-v2-formatter-prompt-contract.md) for the canonical schema contract.

## Snippet Requirements

- support operator-defined phrase expansions
- store snippets locally in a clear operator-editable JSON file
- seed a few sample entries but keep them editable
- apply snippets safely within the dictation/formatting pipeline
- track which snippets were applied in the structured output
- support a private snippet import workflow that previews before applying, writes count-only private reports, creates a rollback backup, and never commits private snippet values
- import command-text snippets as text expansion only unless a future explicit lane maps a separate deterministic allowlisted action
- quarantine sensitive-secret snippets by default
- preserve multiline snippet expansions
- keep repository examples synthetic only, especially for contact-email, link, command-text, and sensitive-secret categories

## Action Requirements

- support phrase-triggered local actions such as `open example local notes`
- actions must map to an explicit allowlisted local action registry
- actions run only named operator-configured scripts or commands
- the LLM may classify possible action candidates, but the deterministic router decides whether a trusted action exists
- the app must not execute arbitrary shell text from model output
- include operator-visible confirmation / safety settings where needed
- document the security model clearly for future open-source preparation

## Storage Requirements

- dictation snippets: VoiceBar application-support `dictation-snippets.json`
- action registry: VoiceBar application-support `dictation-actions.json`
- dictation rescue history: VoiceBar application-support `dictation-history.json`, storing recent raw and formatted dictations locally for operator recovery
- private snippet import source: local-only private application-support directory
- private snippet import reports: local-only report directory below the private application-support directory
- whisper.cpp runtime root: VoiceBar application-support runtime directory
- whisper.cpp model root: VoiceBar application-support runtime models directory

## Truthfulness Requirements

- do not call v2 complete just because build/test/package succeed
- benchmark the real formatter model on this Mac for cold start, warm latency, structured-output reliability, and action classification stability
- Prompt 017 live testing currently showed raw Ollama generation responding while schema-based formatter requests timed out for `gpt-oss:20b`, `mistral-small3.1`, and `llama3.2:3b`; keep that limitation explicit until a practical structured model loop is proven
- if a machine-only or by-ear claim cannot be directly proven from the current surface, mark it `Unverified`
- keep signing/notarization/distribution truth separate from launcher convenience

## Future V3 Note

Future v3 may include:

- security scrub
- sensitive-data review
- repo cleanup
- open-source README and packaging hardening

Those items are not implemented by v2 itself.
