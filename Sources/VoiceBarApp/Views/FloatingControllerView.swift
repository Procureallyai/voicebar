import SwiftUI

struct FloatingControllerView: View {
    let snapshot: FloatingControllerSnapshot
    let onPauseResume: () -> Void
    let onStop: () -> Void
    let onReplay: () -> Void
    let onCopyLastDictation: () -> Void
    let onOpenDictationHistory: () -> Void
    let onDismiss: () -> Void
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.statusText)
                        .font(.headline)
                    Text(snapshot.detailText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .voiceBarPointingCursor()
            }

            HStack {
                Label(snapshot.engineText, systemImage: "cpu")
                Spacer()
                Label(snapshot.voiceText, systemImage: "waveform.and.person.filled")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if snapshot.isDictationRecording || snapshot.isDictationProcessing {
                HStack(spacing: 8) {
                    Circle()
                        .fill(snapshot.isDictationRecording ? Color.red : Color.orange)
                        .frame(width: 10, height: 10)
                        .scaleEffect(snapshot.isDictationRecording && pulse ? 1.35 : 1)
                        .opacity(snapshot.isDictationRecording && pulse ? 0.55 : 1)
                        .animation(
                            snapshot.isDictationRecording
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .default,
                            value: pulse
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.isDictationRecording ? "Listening" : "Transcribing")
                            .font(.callout.weight(.semibold))
                        Text(snapshot.isDictationRecording
                            ? (snapshot.dictationAutomaticallyStopsOnSilence
                                ? "Speak naturally. VoiceBar will stop after a short pause."
                                : "Release the shortcut to insert dictation.")
                            : "Finishing the previous dictation before another one can start.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if snapshot.isDictationProcessing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .onAppear {
                    pulse = true
                }
                .onDisappear {
                    pulse = false
                }

                if snapshot.isDictationProcessing {
                    HStack(spacing: 8) {
                        Label(snapshot.formatterModelText, systemImage: "brain")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if snapshot.formatterUsedFallback {
                            Label("Fallback Used", systemImage: "bolt.horizontal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button(snapshot.pauseResumeTitle) {
                    onPauseResume()
                }
                .buttonStyle(.borderedProminent)
                .disabled(snapshot.canPauseResume == false)
                .voiceBarPointingCursor()

                Button("Stop") {
                    onStop()
                }
                .buttonStyle(.bordered)
                .disabled(snapshot.canStop == false)
                .voiceBarPointingCursor()

                Button("Replay") {
                    onReplay()
                }
                .buttonStyle(.bordered)
                .disabled(snapshot.canReplay == false)
                .voiceBarPointingCursor()
            }

            if let dictationRecoveryText = snapshot.dictationRecoveryText {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dictationRecoveryText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Button("Copy Again") {
                            onCopyLastDictation()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(snapshot.canCopyLastDictation == false)
                        .voiceBarPointingCursor()

                        Button("Open History") {
                            onOpenDictationHistory()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .voiceBarPointingCursor()
                    }
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .frame(width: 320)
    }
}
