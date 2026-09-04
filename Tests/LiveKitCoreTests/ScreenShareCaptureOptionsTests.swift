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
import Testing

@Suite("Screen share capture options")
struct ScreenShareCaptureOptionsTests {
    @Test("current process audio exclusion participates in option identity")
    func currentProcessAudioExclusionIdentity() {
        let includedAudio = ScreenShareCaptureOptions(
            includeCurrentApplication: true,
            excludeCurrentProcessAudio: false
        )
        let excludedAudio = ScreenShareCaptureOptions(
            includeCurrentApplication: true,
            excludeCurrentProcessAudio: true
        )

        #expect(includedAudio != excludedAudio)
        #expect(excludedAudio.excludeCurrentProcessAudio)
    }
}
