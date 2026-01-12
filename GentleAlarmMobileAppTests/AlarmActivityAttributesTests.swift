//
//  AlarmActivityAttributesTests.swift
//  GentleAlarmMobileAppTests
//

import XCTest
@testable import GentleAlarmMobileApp

final class AlarmActivityAttributesTests: XCTestCase {

    // MARK: - AlarmActivityAttributes Tests

    func testAttributesInitialization() {
        let attributes = AlarmActivityAttributes(
            alarmId: "test-id-123",
            alarmLabel: "Wake Up",
            alarmTimeString: "7:00 AM"
        )

        XCTAssertEqual(attributes.alarmId, "test-id-123")
        XCTAssertEqual(attributes.alarmLabel, "Wake Up")
        XCTAssertEqual(attributes.alarmTimeString, "7:00 AM")
    }

    func testAttributesWithDifferentValues() {
        let attributes = AlarmActivityAttributes(
            alarmId: UUID().uuidString,
            alarmLabel: "Morning Workout",
            alarmTimeString: "5:30 AM"
        )

        XCTAssertFalse(attributes.alarmId.isEmpty)
        XCTAssertEqual(attributes.alarmLabel, "Morning Workout")
        XCTAssertEqual(attributes.alarmTimeString, "5:30 AM")
    }

    func testAttributesWithEmptyLabel() {
        let attributes = AlarmActivityAttributes(
            alarmId: "empty-label-test",
            alarmLabel: "",
            alarmTimeString: "12:00 PM"
        )

        XCTAssertEqual(attributes.alarmLabel, "")
    }

    // MARK: - ContentState Tests

    func testContentStateInitialization() {
        let alarmTime = Date()
        let state = AlarmActivityAttributes.ContentState(
            alarmTime: alarmTime,
            timeRemaining: 3600,
            isRinging: false
        )

        XCTAssertEqual(state.alarmTime, alarmTime)
        XCTAssertEqual(state.timeRemaining, 3600)
        XCTAssertFalse(state.isRinging)
    }

    func testContentStateRinging() {
        let state = AlarmActivityAttributes.ContentState(
            alarmTime: Date(),
            timeRemaining: 0,
            isRinging: true
        )

        XCTAssertTrue(state.isRinging)
        XCTAssertEqual(state.timeRemaining, 0)
    }

    func testContentStateNotRinging() {
        let state = AlarmActivityAttributes.ContentState(
            alarmTime: Date().addingTimeInterval(3600),
            timeRemaining: 3600,
            isRinging: false
        )

        XCTAssertFalse(state.isRinging)
        XCTAssertEqual(state.timeRemaining, 3600)
    }

    // MARK: - ContentState Codable Tests

    func testContentStateCodable() throws {
        let originalState = AlarmActivityAttributes.ContentState(
            alarmTime: Date(),
            timeRemaining: 1800,
            isRinging: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalState)

        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(AlarmActivityAttributes.ContentState.self, from: data)

        XCTAssertEqual(originalState.timeRemaining, decodedState.timeRemaining)
        XCTAssertEqual(originalState.isRinging, decodedState.isRinging)
    }

    func testContentStateCodableRinging() throws {
        let originalState = AlarmActivityAttributes.ContentState(
            alarmTime: Date(),
            timeRemaining: 0,
            isRinging: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalState)

        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(AlarmActivityAttributes.ContentState.self, from: data)

        XCTAssertTrue(decodedState.isRinging)
    }

    // MARK: - ContentState Hashable Tests

    func testContentStateHashable() {
        let state1 = AlarmActivityAttributes.ContentState(
            alarmTime: Date(timeIntervalSince1970: 1000),
            timeRemaining: 3600,
            isRinging: false
        )

        let state2 = AlarmActivityAttributes.ContentState(
            alarmTime: Date(timeIntervalSince1970: 1000),
            timeRemaining: 3600,
            isRinging: false
        )

        XCTAssertEqual(state1.hashValue, state2.hashValue)
    }

    func testContentStateInSet() {
        let state1 = AlarmActivityAttributes.ContentState(
            alarmTime: Date(timeIntervalSince1970: 1000),
            timeRemaining: 3600,
            isRinging: false
        )

        let state2 = AlarmActivityAttributes.ContentState(
            alarmTime: Date(timeIntervalSince1970: 2000),
            timeRemaining: 1800,
            isRinging: true
        )

        var set: Set<AlarmActivityAttributes.ContentState> = []
        set.insert(state1)
        set.insert(state2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Time Remaining Tests

    func testContentStateVariousTimeRemaining() {
        let testCases: [TimeInterval] = [0, 60, 300, 3600, 7200, 86400]

        for timeRemaining in testCases {
            let state = AlarmActivityAttributes.ContentState(
                alarmTime: Date().addingTimeInterval(timeRemaining),
                timeRemaining: timeRemaining,
                isRinging: timeRemaining == 0
            )

            XCTAssertEqual(state.timeRemaining, timeRemaining)
        }
    }

    // MARK: - Edge Cases

    func testContentStateNegativeTimeRemaining() {
        // This could happen if the alarm time has passed
        let state = AlarmActivityAttributes.ContentState(
            alarmTime: Date().addingTimeInterval(-60),
            timeRemaining: -60,
            isRinging: true
        )

        XCTAssertEqual(state.timeRemaining, -60)
        XCTAssertTrue(state.isRinging)
    }

    func testAttributesWithSpecialCharactersInLabel() {
        let attributes = AlarmActivityAttributes(
            alarmId: "special-chars",
            alarmLabel: "🌅 Rise & Shine! 🔔",
            alarmTimeString: "6:30 AM"
        )

        XCTAssertEqual(attributes.alarmLabel, "🌅 Rise & Shine! 🔔")
    }

    func testAttributesWithLongLabel() {
        let longLabel = String(repeating: "A", count: 1000)
        let attributes = AlarmActivityAttributes(
            alarmId: "long-label",
            alarmLabel: longLabel,
            alarmTimeString: "8:00 AM"
        )

        XCTAssertEqual(attributes.alarmLabel.count, 1000)
    }
}
