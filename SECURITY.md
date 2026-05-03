# Security Policy

## Reporting A Vulnerability

Please do not open a public issue for suspected vulnerabilities.

Use private vulnerability reporting if it is enabled on the public repository. If private vulnerability reporting is not available, contact the maintainer through the private reporting channel listed on the public repository profile or project website.

Do not include secrets, private snippet values, personal data, or exploit details in public pull requests, issues, screenshots, recordings, or logs.

## Scope

Security reports are especially relevant for:

- credential or secret exposure
- unsafe command execution
- snippet or action-routing bypasses
- local file path traversal
- unsafe deserialization
- privacy leaks in diagnostics, logs, reports, screenshots, or fixtures
- dependency vulnerabilities
- workflow or repository permission issues

## Project Security Posture

VoiceBar is designed as a local-first macOS utility. Core reading and dictation workflows should not require a cloud text-to-speech or speech-to-text service. Command-text snippets are text expansion only, and executable actions must be explicit, deterministic, allowlisted actions.

Security fixes are reviewed by the maintainer before merge. Automated hosted review may provide an additional pull request review layer, but local Codex deep review remains required for substantial or security-sensitive changes.
