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

@testable import LiveKit
import LiveKitWebRTC
import Testing

/// FlexFEC is offered and sent unconditionally; the server decides whether it engages.
@Suite(.tags(.networking)) struct FlexFECTests {
    private final class StubDelegate: TransportDelegate {
        func transport(_: Transport, didUpdateState _: LKRTCPeerConnectionState) {}
        func transport(_: Transport, didGenerateIceCandidate _: IceCandidate) {}
        func transport(_: Transport, didOpenDataChannel _: LKRTCDataChannel) {}
        func transport(_: Transport, didAddTrack _: RTCMediaTrack, rtpReceiver _: RTCReceiver, streamIds _: [String]) {}
        func transport(_: Transport, didRemoveTrackWithId _: String) {}
        func transportShouldNegotiate(_: Transport) {}
    }

    @Test func videoOfferAdvertisesAndSendsFlexFEC() async throws {
        let transport = try await Transport(config: .liveKitDefault(),
                                            target: .publisher,
                                            primary: true,
                                            delegate: StubDelegate())
        defer { Task { await transport.close() } }

        try await RTC.run {
            let track = RTC.createVideoTrack(source: RTC.createVideoSource(forScreenShare: true))
            _ = try transport.addTransceiver(with: track, transceiverInit: LKRTCRtpTransceiverInit())
        }
        let sdp = try await transport.createOffer().sdp

        #expect(sdp.contains("flexfec-03"), "advertised: WebRTC-FlexFEC-03-Advertised")
        #expect(sdp.contains("a=ssrc-group:FEC-FR"), "sent: WebRTC-FlexFEC-03")
    }

    /// The policy reaches the native sender and survives the read-modify-write
    /// of other parameter updates (degradation preference, subscribed qualities).
    @Test func fecProtectionReachesSenderAndSurvivesOtherUpdates() async throws {
        let transport = try await Transport(config: .liveKitDefault(),
                                            target: .publisher,
                                            primary: true,
                                            delegate: StubDelegate())
        defer { Task { await transport.close() } }

        let fec = try await RTC.run {
            let track = RTC.createVideoTrack(source: RTC.createVideoSource(forScreenShare: true))
            let transInit = LKRTCRtpTransceiverInit()
            transInit.direction = .sendOnly
            let sender = try transport.addTransceiver(with: track, transceiverInit: transInit).sender
            sender.set(fecProtection: FecProtection(mode: .minimum, protectionFactor: 0.1, maxFecFrames: 3))
            sender.set(degradationPreference: .maintainResolution)
            sender.set(fecProtection: nil)
            return sender.parameters.fecProtection.map {
                ($0.mode, $0.protectionFactor, $0.maxFecFrames?.intValue, $0.keyFrameProtectionFactor?.doubleValue)
            }
        }

        let got = try #require(fec, "fecProtection is lost on the sender")
        #expect(got.0 == .minimum)
        #expect(got.1 == 0.1)
        #expect(got.2 == 3)
        #expect(got.3 == nil)
    }
}
