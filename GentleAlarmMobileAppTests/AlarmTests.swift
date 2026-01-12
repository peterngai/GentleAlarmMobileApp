//
//  AlarmTests.swift
//  GentleAlarmMobileAppTests
//

import XCTest
@testable import GentleAlarmMobileApp

final class AlarmTests: XCTestCase {

    // MARK: - Initialization Tests

    func testAlarmDefaultInitialization() {
        let alarm = Alarm()

        XCTAssertNotNil(alarm.id)
        XCTAssertEqual(alarm.label, "Alarm")
        XCTAssertTrue(alarm.isEnabled)
        XCTAssertEqual(alarm.sound, .morningBirds)
        XCTAssertEqual(alarm.fadeInDuration, 3)
        XCTAssertEqual(alarm.snoozeDuration, 5)
        XCTAssertTrue(alarm.repeatDays.isEmpty)
    }

    func testAlarmCustomInitialization() {
        let customTime = Date()
        let customId = UUID()
        let repeatDays: Set<Weekday> = [.monday, .wednesday, .friday]

        let alarm = Alarm(
            id: customId,
            time: customTime,
            label: "Wake Up",
            isEnabled: false,
            sound: .morningBirds,
            fadeInDuration: 5,
            snoozeDuration: 10,
            repeatDays: repeatDays
        )

        XCTAssertEqual(alarm.id, customId)
        XCTAssertEqual(alarm.time, customTime)
        XCTAssertEqual(alarm.label, "Wake Up")
        XCTAssertFalse(alarm.isEnabled)
        XCTAssertEqual(alarm.sound, .morningBirds)
        XCTAssertEqual(alarm.fadeInDuration, 5)
        XCTAssertEqual(alarm.snoozeDuration, 10)
        XCTAssertEqual(alarm.repeatDays, repeatDays)
    }

    // MARK: - Time Component Tests

    func testHourProperty() {
        let calendar = Calendar.current
        let time = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
        let alarm = Alarm(time: time)

        XCTAssertEqual(alarm.hour, 7)
    }

    func testMinuteProperty() {
        let calendar = Calendar.current
        let time = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
        let alarm = Alarm(time: time)

        XCTAssertEqual(alarm.minute, 30)
    }

    func testTimeString() {
        let calendar = Calendar.current
        let time = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!
        let alarm = Alarm(time: time)

        // Time string should contain the hour and minute
        let timeString = alarm.timeString
        XCTAssertTrue(timeString.contains("7") || timeString.contains("07"))
        XCTAssertTrue(timeString.contains("30"))
    }

    // MARK: - Repeat Description Tests

    func testRepeatDescriptionOneTime() {
        let alarm = Alarm(repeatDays: [])
        XCTAssertEqual(alarm.repeatDescription, "One time")
    }

    func testRepeatDescriptionEveryDay() {
        let alarm = Alarm(repeatDays: Set(Weekday.allCases))
        XCTAssertEqual(alarm.repeatDescription, "Every day")
    }

    func testRepeatDescriptionWeekdays() {
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let alarm = Alarm(repeatDays: weekdays)
        XCTAssertEqual(alarm.repeatDescription, "Weekdays")
    }

    func testRepeatDescriptionWeekends() {
        let weekends: Set<Weekday> = [.saturday, .sunday]
        let alarm = Alarm(repeatDays: weekends)
        XCTAssertEqual(alarm.repeatDescription, "Weekends")
    }

    func testRepeatDescriptionCustomDays() {
        let customDays: Set<Weekday> = [.monday, .wednesday, .friday]
        let alarm = Alarm(repeatDays: customDays)
        let description = alarm.repeatDescription

        XCTAssertTrue(description.contains("Mon"))
        XCTAssertTrue(description.contains("Wed"))
        XCTAssertTrue(description.contains("Fri"))
    }

    // MARK: - Next Fire Date Tests (One-Time Alarms)

    func testNextFireDateOneTimeAlarmFutureToday() {
        let calendar = Calendar.current
        let now = Date()

        // Set alarm for 1 hour from now
        let futureTime = calendar.date(byAdding: .hour, value: 1, to: now)!
        let alarm = Alarm(time: futureTime, repeatDays: [])

        let fireDate = alarm.nextFireDate(from: now)

        XCTAssertNotNil(fireDate)
        XCTAssertTrue(fireDate! > now)

        // Should be today
        XCTAssertTrue(calendar.isDate(fireDate!, inSameDayAs: now))
    }

    func testNextFireDateOneTimeAlarmPastToday() {
        let calendar = Calendar.current
        let now = Date()

        // Set alarm for 1 hour ago
        let pastTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        let alarm = Alarm(time: pastTime, repeatDays: [])

        let fireDate = alarm.nextFireDate(from: now)

        XCTAssertNotNil(fireDate)
        XCTAssertTrue(fireDate! > now)

        // Should be tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        XCTAssertTrue(calendar.isDate(fireDate!, inSameDayAs: tomorrow))
    }

    // MARK: - Next Fire Date Tests (Repeating Alarms)

    func testNextFireDateRepeatingAlarmToday() {
        let calendar = Calendar.current
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)

        guard let weekday = Weekday(rawValue: todayWeekday) else {
            XCTFail("Could not determine today's weekday")
            return
        }

        // Set alarm for 1 hour from now, repeating today
        let futureTime = calendar.date(byAdding: .hour, value: 1, to: now)!
        let alarm = Alarm(time: futureTime, repeatDays: [weekday])

        let fireDate = alarm.nextFireDate(from: now)

        XCTAssertNotNil(fireDate)
        XCTAssertTrue(fireDate! > now)
        XCTAssertTrue(calendar.isDate(fireDate!, inSameDayAs: now))
    }

    func testNextFireDateRepeatingAlarmNextWeek() {
        let calendar = Calendar.current
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)

        // Find a weekday that's not today
        let otherWeekday = Weekday.allCases.first { $0.rawValue != todayWeekday }!

        // Set alarm for 1 hour ago with repeat on a different day
        let pastTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        let alarm = Alarm(time: pastTime, repeatDays: [otherWeekday])

        let fireDate = alarm.nextFireDate(from: now)

        XCTAssertNotNil(fireDate)
        XCTAssertTrue(fireDate! > now)

        // Verify it's on the correct weekday
        let fireDateWeekday = calendar.component(.weekday, from: fireDate!)
        XCTAssertEqual(fireDateWeekday, otherWeekday.rawValue)
    }

    // MARK: - Codable Tests

    func testAlarmEncodingDecoding() throws {
        let originalAlarm = Alarm(
            time: Date(),
            label: "Test Alarm",
            isEnabled: true,
            sound: .oceanWaves,
            fadeInDuration: 4,
            snoozeDuration: 8,
            repeatDays: [.monday, .friday]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalAlarm)

        let decoder = JSONDecoder()
        let decodedAlarm = try decoder.decode(Alarm.self, from: data)

        XCTAssertEqual(originalAlarm.id, decodedAlarm.id)
        XCTAssertEqual(originalAlarm.label, decodedAlarm.label)
        XCTAssertEqual(originalAlarm.isEnabled, decodedAlarm.isEnabled)
        XCTAssertEqual(originalAlarm.sound, decodedAlarm.sound)
        XCTAssertEqual(originalAlarm.fadeInDuration, decodedAlarm.fadeInDuration)
        XCTAssertEqual(originalAlarm.snoozeDuration, decodedAlarm.snoozeDuration)
        XCTAssertEqual(originalAlarm.repeatDays, decodedAlarm.repeatDays)
    }

    // MARK: - Equatable Tests

    func testAlarmEquality() {
        let id = UUID()
        let time = Date()

        let alarm1 = Alarm(id: id, time: time, label: "Test")
        let alarm2 = Alarm(id: id, time: time, label: "Test")

        XCTAssertEqual(alarm1, alarm2)
    }

    func testAlarmInequality() {
        let alarm1 = Alarm(label: "Test 1")
        let alarm2 = Alarm(label: "Test 2")

        XCTAssertNotEqual(alarm1, alarm2)
    }
}

// MARK: - Weekday Tests

final class WeekdayTests: XCTestCase {

    func testWeekdayRawValues() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.monday.rawValue, 2)
        XCTAssertEqual(Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(Weekday.thursday.rawValue, 5)
        XCTAssertEqual(Weekday.friday.rawValue, 6)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }

    func testWeekdayShortNames() {
        XCTAssertEqual(Weekday.sunday.shortName, "Sun")
        XCTAssertEqual(Weekday.monday.shortName, "Mon")
        XCTAssertEqual(Weekday.tuesday.shortName, "Tue")
        XCTAssertEqual(Weekday.wednesday.shortName, "Wed")
        XCTAssertEqual(Weekday.thursday.shortName, "Thu")
        XCTAssertEqual(Weekday.friday.shortName, "Fri")
        XCTAssertEqual(Weekday.saturday.shortName, "Sat")
    }

    func testWeekdayInitials() {
        XCTAssertEqual(Weekday.sunday.initial, "S")
        XCTAssertEqual(Weekday.monday.initial, "M")
        XCTAssertEqual(Weekday.tuesday.initial, "T")
        XCTAssertEqual(Weekday.wednesday.initial, "W")
        XCTAssertEqual(Weekday.thursday.initial, "T")
        XCTAssertEqual(Weekday.friday.initial, "F")
        XCTAssertEqual(Weekday.saturday.initial, "S")
    }

    func testWeekdayIdentifiable() {
        for weekday in Weekday.allCases {
            XCTAssertEqual(weekday.id, weekday.rawValue)
        }
    }

    func testWeekdayAllCasesCount() {
        XCTAssertEqual(Weekday.allCases.count, 7)
    }

    func testWeekdayCodable() throws {
        let weekday = Weekday.wednesday

        let encoder = JSONEncoder()
        let data = try encoder.encode(weekday)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Weekday.self, from: data)

        XCTAssertEqual(weekday, decoded)
    }
}
