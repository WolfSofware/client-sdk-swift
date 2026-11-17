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

#if os(macOS) && canImport(ScreenCaptureKit)

import CoreVideo
import Foundation
@testable import LiveKit
import LiveKitWebRTC
import Testing

/// What WebRTC hands on when it scales a screen frame down by itself (under load, with
/// maintain-framerate): the part of the raw capture buffer that reaches the encoder.
@Suite struct ScreenFrameAdaptationTests {
    private final class Sink: NSObject, LKRTCVideoRenderer, @unchecked Sendable {
        var last: LKRTCCVPixelBuffer?
        func setSize(_: CGSize) {}
        func renderFrame(_ frame: LKRTCVideoFrame?) {
            if let buffer = frame?.buffer as? LKRTCCVPixelBuffer { last = buffer }
        }
    }

    /// The buffer WebRTC delivers for `buffer` once its adapter is capped at `width`×`height`.
    private func delivered(_ buffer: LKRTCCVPixelBuffer, cappedAt width: Int32, _ height: Int32) -> LKRTCCVPixelBuffer? {
        let source = RTC.createVideoSource(forScreenShare: true)
        let track = RTC.createVideoTrack(source: source)
        let sink = Sink()
        track.add(sink)
        source.adaptOutputFormat(toWidth: width, height: height, fps: 30)
        source.capturer(LKRTCVideoCapturer(), didCapture: LKRTCVideoFrame(buffer: buffer, rotation: ._0, timeStampNs: 1_000_000_000))
        track.remove(sink)
        return sink.last
    }

    private func rawBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 400, 200, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, nil, &pixelBuffer)
        return try #require(pixelBuffer)
    }

    @Test("a pre-scaled buffer loses all but a corner when WebRTC scales it down")
    func preScaledBufferIsCroppedToACorner() throws {
        // The way frames used to be built: content 400×200 already scaled to 200×100.
        let preScaled = try LKRTCCVPixelBuffer(pixelBuffer: rawBuffer(), adaptedWidth: 200, adaptedHeight: 100,
                                               cropWidth: 400, cropHeight: 200, cropX: 0, cropY: 0)
        let out = try #require(delivered(preScaled, cappedAt: 100, 50))
        // Crop coordinates of the 200×100 frame land on the 400×200 raw buffer.
        #expect(out.cropWidth == 200 && out.cropHeight == 100)
    }

    @Test("a screen frame keeps the whole content when WebRTC scales it down")
    func screenFrameKeepsTheWholeContent() throws {
        let (buffer, target) = try ScreenCapturer.frameBuffer(rawBuffer(),
                                                              contentRect: CGRect(x: 0, y: 0, width: 200, height: 100),
                                                              scaleFactor: 2,
                                                              maxDimension: 100)
        #expect(target.width == 100 && target.height == 50, "the cap keeps the content's aspect ratio")
        // Under load WebRTC goes below our cap: half of it here.
        let out = try #require(delivered(buffer, cappedAt: target.width / 2, target.height / 2))
        // Even-size alignment may trim a few rows; a corner would be half of each side.
        #expect(out.cropWidth >= 380 && out.cropHeight >= 180, "the whole content, not a corner")
        #expect(out.width <= 50 && out.height <= 25, "scaled down by WebRTC")
    }
}

#endif
