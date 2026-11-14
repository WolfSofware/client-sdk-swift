/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

internal import LiveKitWebRTC

@objcMembers
public final class VideoPublishOptions: NSObject, TrackPublishOptions, Sendable {
    public let name: String?

    /// preferred encoding parameters
    public let encoding: VideoEncoding?

    /// encoding parameters for for screen share
    public let screenShareEncoding: VideoEncoding?

    /// true to enable simulcasting, publishes three tracks at different sizes
    public let simulcast: Bool

    public let simulcastLayers: [VideoParameters]

    public let screenShareSimulcastLayers: [VideoParameters]

    public let preferredCodec: VideoCodec?

    public let preferredBackupCodec: VideoCodec?

    public let degradationPreference: DegradationPreference

    public let streamName: String?

    /// FEC policy of the sender. `nil` leaves libwebrtc's adaptive FEC as is.
    /// Takes effect only where FEC was negotiated; FlexFEC skips simulcast senders.
    public let fecProtection: FecProtection?

    public init(name: String? = nil,
                encoding: VideoEncoding? = nil,
                screenShareEncoding: VideoEncoding? = nil,
                simulcast: Bool = true,
                simulcastLayers: [VideoParameters] = [],
                screenShareSimulcastLayers: [VideoParameters] = [],
                preferredCodec: VideoCodec? = nil,
                preferredBackupCodec: VideoCodec? = nil,
                degradationPreference: DegradationPreference = .auto,
                streamName: String? = nil,
                fecProtection: FecProtection? = nil)
    {
        self.name = name
        self.encoding = encoding
        self.screenShareEncoding = screenShareEncoding
        self.simulcast = simulcast
        self.simulcastLayers = simulcastLayers
        self.screenShareSimulcastLayers = screenShareSimulcastLayers
        self.preferredCodec = preferredCodec
        self.preferredBackupCodec = preferredBackupCodec
        self.degradationPreference = degradationPreference
        self.streamName = streamName
        self.fecProtection = fecProtection
    }

    // MARK: - Equal

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return name == other.name &&
            encoding == other.encoding &&
            screenShareEncoding == other.screenShareEncoding &&
            simulcast == other.simulcast &&
            simulcastLayers == other.simulcastLayers &&
            screenShareSimulcastLayers == other.screenShareSimulcastLayers &&
            preferredCodec == other.preferredCodec &&
            preferredBackupCodec == other.preferredBackupCodec &&
            degradationPreference == other.degradationPreference &&
            streamName == other.streamName &&
            fecProtection == other.fecProtection
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(encoding)
        hasher.combine(screenShareEncoding)
        hasher.combine(simulcast)
        hasher.combine(simulcastLayers)
        hasher.combine(screenShareSimulcastLayers)
        hasher.combine(preferredCodec)
        hasher.combine(preferredBackupCodec)
        hasher.combine(degradationPreference)
        hasher.combine(streamName)
        hasher.combine(fecProtection)
        return hasher.finalize()
    }
}

/// Sender-level FEC policy (`RtpParameters::fec_protection`, webrtc-sdk/webrtc#329).
public struct FecProtection: Hashable, Sendable {
    public enum Mode: Sendable {
        /// Derived from the observed loss and RTT (libwebrtc's default).
        case adaptive
        /// Always `protectionFactor`, regardless of loss and RTT.
        case fixed
        /// Adaptive, but never below `protectionFactor`.
        case minimum
        /// No FEC packets, without renegotiation.
        case disabled
    }

    public let mode: Mode
    /// 0...1
    public let protectionFactor: Double
    /// Defaults to `protectionFactor`.
    public let keyFrameProtectionFactor: Double?
    /// 1...6 frames per FEC block. More frames make small frames cheaper to
    /// protect at the cost of that many frames of recovery delay.
    public let maxFecFrames: Int?

    public init(mode: Mode, protectionFactor: Double = 0, keyFrameProtectionFactor: Double? = nil, maxFecFrames: Int? = nil) {
        self.mode = mode
        self.protectionFactor = protectionFactor
        self.keyFrameProtectionFactor = keyFrameProtectionFactor
        self.maxFecFrames = maxFecFrames
    }
}

extension FecProtection {
    func toRTCType() -> LKRTCRtpFecProtection {
        let result = LKRTCRtpFecProtection()
        result.mode = switch mode {
        case .adaptive: .adaptive
        case .fixed: .fixed
        case .minimum: .minimum
        case .disabled: .disabled
        }
        result.protectionFactor = protectionFactor
        result.keyFrameProtectionFactor = keyFrameProtectionFactor.map { NSNumber(value: $0) }
        result.maxFecFrames = maxFecFrames.map { NSNumber(value: $0) }
        return result
    }
}
