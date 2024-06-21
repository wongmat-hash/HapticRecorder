//
//  HapticRecorderTests.swift
//  HapticRecorderTests
//
//  Created by Matt Wong on 6/19/24.
//

import XCTest
@testable import HapticRecorder

final class HapticRecorderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRecordingStartsAndStopsSuccessfully() throws {
        // Given
        let recorder = HapticRecorder()

        // When
        recorder.startRecording()
        recorder.stopRecording()

        // Then
        XCTAssertFalse(recorder.isRecording, "Recording should stop when stopRecording() is called.")
    }

    func testRecordingDurationIsAccurate() throws {
        // Given
        let recorder = HapticRecorder()

        // When
        recorder.startRecording()
        // Simulate a recording duration of 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            recorder.stopRecording()
        }

        // Then
        let expectedDuration = 2.0
        let tolerance = 0.1 // Allowable tolerance in seconds
        XCTAssertEqual(recorder.recordedDuration, expectedDuration, accuracy: tolerance, "Recorded duration should be accurate within \(tolerance) seconds.")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            // For example, you can create an instance of HapticRecorder and perform operations to measure performance.
            let _ = HapticRecorder()
        }
    }

}
