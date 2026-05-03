# VoiceBar v2 Formatter Prompt Contract

## Purpose

This document defines the deterministic formatter/router contract for the local dictation pipeline.

## Runtime Assumptions

- formatter host: local Ollama
- target low-latency baseline: `llama3.2:3b`
- optional high-quality/manual fallback: `gpt-oss:20b`
- temperature: low / deterministic
- output mode: structured JSON matching the schema below
- if the formatter does not answer promptly on the operator Mac, VoiceBar falls back to snippet-expanded insertion and exact allowlisted action matching rather than blocking dictation

## Formatter Intent

The formatter should:

- preserve meaning
- remove obvious filler only when safe
- restore punctuation and sentence boundaries
- choose light formatting that matches the requested mode
- keep action candidates conservative
- avoid inventing shell commands, facts, or structure the user did not imply

## Request Shape

The request payload should include:

- raw transcript text
- requested formatting mode
- currently configured formatter model identifier
- rolling context summary when available
- known snippets
- known actions
- frontmost bundle identifier when available

## Response Schema

```json
{
  "cleanedText": "string",
  "formattedText": "string",
  "detectedMode": "dictation | command | mixed",
  "snippetApplications": [
    {
      "snippetID": "string",
      "trigger": "string",
      "expansion": "string"
    }
  ],
  "actionCandidates": [
    {
      "actionID": "string",
      "triggerPhrase": "string",
      "confidence": 0.0
    }
  ],
  "shouldInsertText": true,
  "confidence": 0.0
}
```

## Field Semantics

- `cleanedText`
  - minimally cleaned text with filler removed only when obviously safe
- `formattedText`
  - insertion-ready output after punctuation and light formatting
- `detectedMode`
  - `dictation` for normal text insertion
  - `command` for likely action-only input
  - `mixed` for text plus a likely trusted action
- `snippetApplications`
  - snippets actually applied or strongly suggested by the formatter
- `actionCandidates`
  - structured, conservative action candidates only
- `shouldInsertText`
  - whether VoiceBar should insert the formatted text at the cursor when insertion is enabled
- `confidence`
  - optional overall confidence for gating or operator review

## Safety Split

- The formatter may classify or suggest action candidates.
- The deterministic action router decides whether a trusted action definition exists.
- The executor only runs allowlisted operator-configured scripts.
- Free-form model text must never be executed as shell input.

## Example Prompt Rules

- return only JSON matching the schema
- prefer exact spoken trigger phrases over paraphrased commands
- keep `actionCandidates` empty when uncertain
- do not mark an action when the utterance is ordinary prose
- avoid over-formatting short fragments

## Validation Expectations

- test schema decoding
- test deterministic snippet expansion alignment
- test action routing split between model suggestion and deterministic registry
- benchmark cold start and warm latency on the target machine
- keep the current Prompt 017 benchmark truth explicit: raw Ollama generation responded locally, while schema-based formatter requests timed out for `gpt-oss:20b`, `mistral-small3.1`, and `llama3.2:3b`
- keep any unresolved operator-fit questions labeled `Unverified`
