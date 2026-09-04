// swift-tools-version:6.1
// (Xcode16.3+)

import PackageDescription

let package = Package(
    name: "LiveKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v14),
        .tvOS(.v17),
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
        // Бинарник ПРЯМО здесь, а не отдельным пакетом.
        //
        // Отдельным он быть не может: у нашего форка и у апстримного пакета
        // одно и то же имя `webrtc-xcframework`, а SwiftPM различает пакеты по
        // имени, а не по адресу. Он молча оставлял апстримную сборку — ту, в
        // которой нужного нам класса нет, — и сборка падала на несовпадении
        // делегата.
        //
        // Это наша macOS-сборка m144 + webrtc-sdk/webrtc#282: в ней есть
        // `RTCExternalAudioSource` и исправленный выбор внешнего микрофона.
        .binaryTarget(
            name: "LiveKitWebRTC",
            url: "https://github.com/WolfSofware/webrtc-build/releases/download/wolf-144.7559.11-external-audio-mac-input.2/LiveKitWebRTC.xcframework.zip",
            checksum: "c8e2afc6bd07a0cd97e1798c099b10bfbed4c85e67614b11f5f403b98fa20454",
        ),
        .target(
            name: "LKObjCHelpers",
            publicHeadersPath: "include",
        ),
        .target(
            name: "LiveKit",
            dependencies: [
                "LiveKitWebRTC",
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
