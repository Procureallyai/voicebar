#if canImport(TTSKit)
import TTSKit

enum TTSKitBootstrapProbe {
    // We intentionally stop at module import verification in Prompt 002 so we
    // do not invent model-loading behavior before the speech lane is ready.
    static let integrationStatus: String = {
        _ = TTSKit.self
        return "TTSKit imported from argmax-oss-swift v0.18.0. VoiceBar now wires runtime loading on demand, but local model preparation remains unverified until first real engine use on this machine."
    }()
}
#else
enum TTSKitBootstrapProbe {
    static let integrationStatus = "Unverified: TTSKit could not be imported in the current toolchain."
}
#endif
