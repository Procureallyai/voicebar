# VoiceBar Noise-Isolation Roadmap

## Purpose

This document records the current noisy-background dictation limitation and future hardening path.

## Current Truth

VoiceBar currently relies on microphone capture plus local speech-to-text.

Noisy backgrounds can degrade transcription quality. The current app does not claim fully hardened noisy-background dictation.

For best current results:

- Use a quieter environment.
- Use a headset microphone.
- Use system-level microphone noise isolation where available.

VoiceBar does not currently claim programmatic control of Apple Voice Isolation.

## Product Limitation

Current noisy-background dictation is a documented limitation, not a solved release feature.

Noise can affect:

- speech detection
- transcription accuracy
- silence detection
- stop timing
- formatter confidence and cleanup quality

## Roadmap

Planned improvement options:

- microphone input selector
- input level meter
- configurable silence threshold
- noise gate
- high-pass filter
- automatic gain control
- stronger voice activity detection
- optional noise suppression using WebRTC Audio Processing or RNNoise after license and dependency review
- noisy-background benchmark samples
- telemetry for noise floor, peak level, stop reason, and transcription confidence where available

## Acceptance Tests To Add

Future noisy-background acceptance should include:

- quiet room baseline dictation sample
- steady background noise sample
- intermittent keyboard and room-noise sample
- headset microphone comparison
- built-in microphone comparison
- stop-reason verification for manual stop, silence stop, and maximum-duration stop
- private-text-free telemetry review for noise floor, peak level, stop reason, and transcription confidence where available

Do not use private snippets, real transcripts, private recordings, or operator-identifying audio in public acceptance material.
