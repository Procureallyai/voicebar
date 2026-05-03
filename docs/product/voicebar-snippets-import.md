# VoiceBar Snippets Import

## Purpose

VoiceBar can import operator-owned snippets from an approved local private export without committing private snippet values.

## Local Files

- Current VoiceBar snippets: `dictation-snippets.json` in the VoiceBar application-support directory.
- Private snippet export: `wispr-flow-snippets-private-export.json` in the VoiceBar private application-support directory outside the repository.
- Optional redacted manifest: `wispr-flow-snippets-redacted-manifest.json` in the VoiceBar private application-support directory outside the repository.
- Private preview report: `wispr-flow-snippets-preview-report.json` in the private import reports directory outside the repository.
- Private apply report: `wispr-flow-snippets-apply-report.json` in the private import reports directory outside the repository.

## Workflow

1. Open VoiceBar Settings.
2. Open the Dictation tab.
3. Use Local Snippets to create, read, update, delete, enable, disable, and edit local snippets without opening the JavaScript Object Notation (JSON) file.
4. Treat the Label field as the display name only; add the same wording under Trigger Phrases And Aliases if you want to say it aloud.
5. Use Add Label as Trigger or Add Speech Aliases for conservative local helpers instead of editing JavaScript Object Notation (JSON) by hand.
6. Use Show beside Snippets to reveal the editable VoiceBar snippets file when manual file inspection is still needed.
7. Use Preview Import before applying imported snippets.
8. Review the status counts and private report.
9. Use Apply Import when the preview counts are acceptable.
10. Use Reload after manual snippet file edits, import runs, or backup restores.

## Import Rules

- Source trigger text maps to VoiceBar triggers.
- Source expansion text maps to VoiceBar expansion text.
- Source identifiers are stored as metadata so later imports can update the same snippets.
- Existing snippets are matched by source identifier first, then by normalized trigger.
- Multiline expansions are preserved.
- Additional trigger phrases are explicit aliases on the same snippet.
- Labels are display names only and are not implicit triggers.
- Trigger phrases and aliases are the exact phrases VoiceBar listens for after normalization.
- Conservative speech aliases may add deterministic variants such as spacing camel-case labels.
- Speech-to-text recognition variants for operator-critical snippets should be added as explicit aliases after runtime evidence, using synthetic examples in public documentation rather than real operator-specific trigger phrases, and without broad fuzzy matching.
- Deleted source snippets are ignored.
- Sensitive-secret snippets are quarantined by default.
- Command-text snippets are imported only as text expansion.
- VoiceBar does not create actions from imported snippet text.
- Snippet expansion never presses Return, never runs shell commands, and never requires Auto-Run Actions.

## Privacy Rules

- Private snippet values stay outside the repository.
- Repository tests and documentation use synthetic snippets only.
- Contact-email and link snippets must not appear in committed fixtures unless synthetic.
- Preview and apply reports contain counts and metadata only, not raw expansion bodies.
- Show Reports reveals the report directory, not the private source-export directory.

## Rollback

Apply Import creates a timestamped backup beside the current snippets file before writing changes. VoiceBar keeps the newest snippet backups and prunes older backup files after successful writes. Restore by replacing `dictation-snippets.json` with the backup, then use Reload in Settings.
