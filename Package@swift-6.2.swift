// swift-tools-version:6.2
// (Xcode26.0+)

import PackageDescription

let package = Package(
    name: "LiveKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v14),
        .tvOS(.v17),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "LiveKit",
            targets: ["LiveKit"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/livekit/livekit-uniffi-xcframework.git", exact: "0.0.6"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.0"),
        // Only used for DocC generation
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    ],
    targets: [
        // Тот же macOS-бинарник, что и в `Package.swift`: с внешним
        // аудиоисточником и исправленным выбором внешнего микрофона.
        //
        // Манифеста ДВА, и свежие toolchain'ы читают именно этот. Правка
        // только в `Package.swift` не действует вовсе, а выглядит как «Xcode
        // держится за старую зависимость» — я на это потратил час.
        .binaryTarget(
            name: "LiveKitWebRTCMacInput",
            url: "https://github.com/WolfSofware/webrtc-build/releases/download/wolf-144.7559.11-external-audio-mac-input.5/LiveKitWebRTC-v5.xcframework.zip",
            checksum: "5a45e4dc399cda8d2d0227aff945306b7fe8bddc44ab32ef4fc3a4825f04be40",
        ),
        .target(
            name: "LKObjCHelpers",
            publicHeadersPath: "include",
        ),
        .target(
            name: "LiveKit",
            dependencies: [
                "LiveKitWebRTCMacInput",
                .product(name: "LiveKitUniFFI", package: "livekit-uniffi-xcframework"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                "LKObjCHelpers",
            ],
            exclude: [
                "Broadcast/NOTICE",
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
        ),
        .target(
            name: "LiveKitTestSupport",
            dependencies: [
                "LiveKit",
            ],
            path: "Tests/LiveKitTestSupport",
        ),
        .testTarget(
            name: "LiveKitCoreTests",
            dependencies: [
                "LiveKit",
                "LiveKitTestSupport",
            ],
        ),
        .testTarget(
            name: "LiveKitAudioTests",
            dependencies: [
                "LiveKit",
                "LiveKitTestSupport",
            ],
        ),
        .testTarget(
            name: "LiveKitObjCTests",
            dependencies: [
                "LiveKit",
                "LiveKitTestSupport",
            ],
        ),
    ],
    swiftLanguageModes: [.v5, .v6],
)
