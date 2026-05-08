// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceBar",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "VoiceBarCore",
            targets: ["VoiceBarCore"]
        ),
        .executable(
            name: "VoiceBarApp",
            targets: ["VoiceBarApp"]
        ),
        .executable(
            name: "VoiceBarDictationBenchmarks",
            targets: ["VoiceBarDictationBenchmarks"]
        ),
        .executable(
            name: "VoiceBarSmokeTests",
            targets: ["VoiceBarSmokeTests"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", exact: "0.18.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", exact: "1.1.9")
    ],
    targets: [
        .target(
            name: "VoiceBarCore",
            dependencies: [
                .product(name: "TTSKit", package: "argmax-oss-swift"),
                .product(name: "Hub", package: "swift-transformers")
            ]
        ),
        .executableTarget(
            name: "VoiceBarApp",
            dependencies: [
                "VoiceBarCore"
            ]
        ),
        .executableTarget(
            name: "VoiceBarDictationBenchmarks",
            dependencies: ["VoiceBarCore"]
        ),
        .executableTarget(
            name: "VoiceBarSmokeTests",
            dependencies: ["VoiceBarCore"]
        ),
        .testTarget(
            name: "VoiceBarAppTests",
            dependencies: ["VoiceBarApp"]
        ),
        .testTarget(
            name: "VoiceBarCoreTests",
            dependencies: ["VoiceBarCore"]
        )
    ]
)
