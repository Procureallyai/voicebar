# VoiceBar Dictation Rescue Buffer

Last updated: 2026-05-08

## Purpose

VoiceBar saves each completed dictation locally before it tries to insert text into the focused application.

This protects the operator from the most common loss case: a long dictation finishes, but the cursor was in the wrong place or the target application did not receive the paste as expected.

## Current Behaviour

- VoiceBar stores the final formatted insertion text before the paste attempt.
- VoiceBar also stores the raw transcript when available, so formatter mistakes can be recovered.
- The history is local-only under the VoiceBar Application Support folder.
- The default retention limit is the last 50 dictations.
- Operators can change the retention limit from Settings.
- Operators can clear the entire history from Settings.
- Diagnostics remain private-text-free. They record character counts, storage result, formatter path, and redacted entry tokens, not dictated text.

## Recovery Actions

The menu bar app now exposes:

- Copy Last Dictation
- Retry Insert Last Dictation
- Show Recent Dictations

The floating controller also shows a short confirmation after successful dictation, such as:

```text
Inserted 1,240 characters. Copy again / Open history.
```

## Settings

Settings > Dictation includes:

- Save Recent Dictations for Recovery
- retention limit control
- recent dictation cards
- per-entry Copy and Retry Insert actions
- raw transcript disclosure for recovery review
- Clear History

## Privacy Posture

The rescue buffer deliberately stores dictated text because recovery requires the actual text. That makes it useful, but sensitive.

The control is local-only and operator-managed:

- no dictated text is written to diagnostics
- no dictated text is sent to hosted services by this feature
- no dictated text is copied to the system clipboard unless the operator chooses Copy Last Dictation or a paste fallback is needed
- no recovered or formatted text can create executable action authority

Executable actions remain governed by the existing trust boundary: only the raw spoken transcript can authorize a configured enabled action trigger.

## Manual Verification

Use synthetic, non-private text.

1. Enable Save Recent Dictations for Recovery.
2. Dictate a paragraph into a safe editor.
3. Confirm Settings > Dictation shows the formatted text and raw transcript.
4. Confirm Copy Last Dictation places the formatted text on the clipboard.
5. Confirm Retry Insert Last Dictation inserts the saved formatted text without running an action.
6. Confirm Clear History removes entries.
7. Confirm diagnostics show counts and redacted tokens only.

## Known Limits

- VoiceBar cannot always prove that the target application inserted text in the intended cursor location.
- The buffer protects against loss, but it does not replace operator review for sensitive dictation.
- The current history view is intentionally simple; richer search, pinning, and per-entry deletion are future improvements.
