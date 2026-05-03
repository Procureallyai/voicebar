# Contributing

VoiceBar uses a maintainer-led contribution model.

## Workflow

- Use a fork-and-pull-request workflow for public contributions.
- Do not push directly to `main`.
- Keep pull requests focused and reviewable.
- Use synthetic examples only.
- Do not include private snippets, credentials, logs, screenshots, screen recordings, transcripts, crash reports, local diagnostic dumps, or private repository links.
- VoiceBar is prepared for release under Apache License 2.0. Do not change license files or third-party notices without maintainer approval.

## Review Expectations

- Pull request review is required before merge.
- Required status checks must pass.
- Review conversations must be resolved before merge.
- Security-sensitive changes require explicit security review.
- Automated hosted review may inspect pull requests, but it is an additional review layer rather than the only security gate.
- Substantial or security-sensitive changes require local Codex deep review before they are called merge-ready.

## Local Validation

Run the standard validation path before requesting review:

```bash
git diff --check
bash scripts/build.sh
bash scripts/test.sh
bash scripts/ci.sh
```

For pushed implementation lanes in the private working repository, prompt traceability is also required:

```bash
bash scripts/verify-commit-prompt.sh
```
