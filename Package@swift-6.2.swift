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
        // LK-Prefixed Dynamic WebRTC XCFramework
        .package(url: "https://github.com/livekit/livekit-uniffi-xcframework.git", exact: "0.1.9"),
        // Test-only: conformance oracle for the nanopb facades.
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.0"),
        // Only used for DocC generation
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.3.0"),
    ],
    targets: [
        // Наша сборка libwebrtc: M150 + webrtc-sdk/webrtc#292 (CustomAudioSource)
        // + правки входа звука на macOS. Ветка WolfSofware/webrtc
        // `wolf/custom-audio-m150`, собрана в WolfSofware/webrtc-build.
        // Вольют #292 — возвращаемся на livekit/webrtc-xcframework.
        .binaryTarget(
            name: "LiveKitWebRTC",
            url: "https://github.com/WolfSofware/webrtc-build/releases/download/wolf-150.7871.02-custom-audio-mac-input.1/LiveKitWebRTC.xcframework.zip",
            checksum: "06a12f0bf766df695d250686aa0f7e7aff2fc33ef5a82c4e27271524b25b7717",
        ),
        .target(
            name: "CLiveKitProto",
            exclude: ["LICENSE-nanopb.txt", "module.modulemap"],
            publicHeadersPath: "include",
            cSettings: [
                // ABI defines live in include/lk_pb_config.h (included from
                // pb.h); lk_abi_check.c guards them at compile time.
                .headerSearchPath("include"),
            ],
        ),
        .target(
            name: "LiveKitNanopb",
            dependencies: ["CLiveKitProto"],
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
                "LiveKitNanopb",
                "LKObjCHelpers",
            ],
            exclude: [
                "Broadcast/NOTICE",
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
        ),
        .testTarget(
            // SwiftProtobuf is a test-only conformance oracle here: the same
            // protos are compiled with protoc-gen-swift so every nanopb-encoded
            // payload can be verified against a second, independent implementation.
            name: "LiveKitNanopbTests",
            dependencies: [
                "LiveKit",
                "LiveKitNanopb",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
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
