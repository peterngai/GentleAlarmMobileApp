//
//  AlarmManagerTests.swift
//  GentleAlarmMobileAppTests
//

import XCTest
@testable import GentleAlarmMobileApp

final class AlarmManagerTests: XCTestCase {

    var alarmManager: AlarmManager!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "savedAlarms")
        alarmManager = AlarmManager()
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "savedAlarms")
        alarmManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertTrue(alarmManager.alarms.isEmpty)
        XCTAssertNil(alarmManager.firingAlarm)
        XCTAssertFalse(alarmManager.showingAlarmFiringView)
        XCTAssertFalse(alarmManager.isLiveActivityActive)
    }

    // MARK: - CRUD Operations Tests

    func testAddAlarm() {
        let alarm = Alarm(label: "Test Alarm")

        alarmManager.addAlarm(alarm)

        XCTAssertEqual(alarmManager.alarms.count, 1)
        XCTAssertEqual(alarmManager.alarms.first?.label, "Test Alarm")
    }

    func testAddMultipleAlarms() {
        let alarm1 = Alarm(label: "Alarm 1")
        let alarm2 = Alarm(label: "Alarm 2")
        let alarm3 = Alarm(label: "Alarm 3")

        alarmManager.addAlarm(alarm1)
        alarmManager.addAlarm(alarm2)
        alarmManager.addAlarm(alarm3)

        XCTAssertEqual(alarmManager.alarms.count, 3)
    }

    func testUpdateAlarm() {
        var alarm = Alarm(label: "Original Label")
        alarmManager.addAlarm(alarm)

        alarm.label = "Updated Label"
        alarmManager.updateAlarm(alarm)

        XCTAssertEqual(alarmManager.alarms.count, 1)
        XCTAssertEqual(alarmManager.alarms.first?.label, "Updated Label")
    }

    func testUpdateAlarmSound() {
        var alarm = Alarm(sound: .morningBirds)
        alarmManager.addAlarm(alarm)

        alarm.sound = .morningBirds
        alarmManager.updateAlarm(alarm)

        XCTAssertEqual(alarmManager.alarms.first?.sound, .morningBirds)
    }

    func testUpdateAlarmFadeInDuration() {
        var alarm = Alarm(fadeInDuration: 3)
        alarmManager.addAlarm(alarm)

        alarm.fadeInDuration = 5
        alarmManager.updateAlarm(alarm)

        XCTAssertEqual(alarmManager.alarms.first?.fadeInDuration, 5)
    }

    func testUpdateNonexistentAlarm() {
        let alarm1 = Alarm(label: "Existing")
        alarmManager.addAlarm(alarm1)

        let alarm2 = Alarm(label: "Nonexistent")
        alarmManager.updateAlarm(alarm2)

        // Should not add the nonexistent alarm
        XCTAssertEqual(alarmManager.alarms.count, 1)
        XCTAssertEqual(alarmManager.alarms.first?.label, "Existing")
    }

    func testDeleteAlarm() {
        let alarm = Alarm(label: "To Delete")
        alarmManager.addAlarm(alarm)
        XCTAssertEqual(alarmManager.alarms.count, 1)

        alarmManager.deleteAlarm(alarm)

        XCTAssertEqual(alarmManager.alarms.count, 0)
    }

    func testDeleteAlarmFromMultiple() {
        let alarm1 = Alarm(label: "Keep 1")
        let alarm2 = Alarm(label: "Delete")
        let alarm3 = Alarm(label: "Keep 2")

        alarmManager.addAlarm(alarm1)
        alarmManager.addAlarm(alarm2)
        alarmManager.addAlarm(alarm3)

        alarmManager.deleteAlarm(alarm2)

        XCTAssertEqual(alarmManager.alarms.count, 2)
        XCTAssertFalse(alarmManager.alarms.contains(where: { $0.label == "Delete" }))
        XCTAssertTrue(alarmManager.alarms.contains(where: { $0.label == "Keep 1" }))
        XCTAssertTrue(alarmManager.alarms.contains(where: { $0.label == "Keep 2" }))
    }

    func testDeleteAlarmsAtOffsets() {
        let alarm1 = Alarm(label: "Alarm 1")
        let alarm2 = Alarm(label: "Alarm 2")
        let alarm3 = Alarm(label: "Alarm 3")

        alarmManager.addAlarm(alarm1)
        alarmManager.addAlarm(alarm2)
        alarmManager.addAlarm(alarm3)

        alarmManager.deleteAlarms(at: IndexSet(integer: 1))

        XCTAssertEqual(alarmManager.alarms.count, 2)
        XCTAssertEqual(alarmManager.alarms[0].label, "Alarm 1")
        XCTAssertEqual(alarmManager.alarms[1].label, "Alarm 3")
    }

    func testDeleteMultipleAlarmsAtOffsets() {
        let alarm1 = Alarm(label: "Alarm 1")
        let alarm2 = Alarm(label: "Alarm 2")
        let alarm3 = Alarm(label: "Alarm 3")

        alarmManager.addAlarm(alarm1)
        alarmManager.addAlarm(alarm2)
        alarmManager.addAlarm(alarm3)

        alarmManager.deleteAlarms(at: IndexSet([0, 2]))

        XCTAssertEqual(alarmManager.alarms.count, 1)
        XCTAssertEqual(alarmManager.alarms[0].label, "Alarm 2")
    }

    // MARK: - Toggle Tests

    func testToggleAlarmOn() {
        let alarm = Alarm(isEnabled: false)
        alarmManager.addAlarm(alarm)

        alarmManager.toggleAlarm(alarm)

        XCTAssertTrue(alarmManager.alarms.first?.isEnabled ?? false)
    }

    func testToggleAlarmOff() {
        let alarm = Alarm(isEnabled: true)
        alarmManager.addAlarm(alarm)

        alarmManager.toggleAlarm(alarm)

        XCTAssertFalse(alarmManager.alarms.first?.isEnabled ?? true)
    }

    func testToggleAlarmMultipleTimes() {
        let alarm = Alarm(isEnabled: false)
        alarmManager.addAlarm(alarm)

        alarmManager.toggleAlarm(alarm)
        XCTAssertTrue(alarmManager.alarms.first?.isEnabled ?? false)

        alarmManager.toggleAlarm(alarmManager.alarms.first!)
        XCTAssertFalse(alarmManager.alarms.first?.isEnabled ?? true)

        alarmManager.toggleAlarm(alarmManager.alarms.first!)
        XCTAssertTrue(alarmManager.alarms.first?.isEnabled ?? false)
    }

    // MARK: - Next Alarm Tests

    func testNextAlarmWithNoAlarms() {
        XCTAssertNil(alarmManager.nextAlarm)
    }

    func testNextAlarmWithDisabledAlarms() {
        let alarm = Alarm(isEnabled: false)
        alarmManager.addAlarm(alarm)

        XCTAssertNil(alarmManager.nextAlarm)
    }

    func testNextAlarmWithSingleEnabledAlarm() {
        let calendar = Calendar.current
        let futureTime = calendar.date(byAdding: .hour, value: 1, to: Date())!
        let alarm = Alarm(time: futureTime, isEnabled: true)
        alarmManager.addAlarm(alarm)

        XCTAssertNotNil(alarmManager.nextAlarm)
        XCTAssertEqual(alarmManager.nextAlarm?.id, alarm.id)
    }

    func testNextAlarmSelectsEarliest() {
        let calendar = Calendar.current
        let now = Date()

        let laterTime = calendar.date(byAdding: .hour, value: 3, to: now)!
        let earlierTime = calendar.date(byAdding: .hour, value: 1, to: now)!

        let laterAlarm = Alarm(time: laterTime, label: "Later", isEnabled: true)
        let earlierAlarm = Alarm(time: earlierTime, label: "Earlier", isEnabled: true)

        alarmManager.addAlarm(laterAlarm)
        alarmManager.addAlarm(earlierAlarm)

        XCTAssertEqual(alarmManager.nextAlarm?.label, "Earlier")
    }

    func testNextAlarmIgnoresDisabled() {
        let calendar = Calendar.current
        let now = Date()

        let earlierTime = calendar.date(byAdding: .hour, value: 1, to: now)!
        let laterTime = calendar.date(byAdding: .hour, value: 2, to: now)!

        let disabledEarlier = Alarm(time: earlierTime, label: "Disabled Earlier", isEnabled: false)
        let enabledLater = Alarm(time: laterTime, label: "Enabled Later", isEnabled: true)

        alarmManager.addAlarm(disabledEarlier)
        alarmManager.addAlarm(enabledLater)

        XCTAssertEqual(alarmManager.nextAlarm?.label, "Enabled Later")
    }

    // MARK: - Next Alarm Description Tests

    func testNextAlarmDescriptionWithNoAlarms() {
        XCTAssertNil(alarmManager.nextAlarmDescription)
    }

    func testNextAlarmDescriptionLessThanMinute() {
        let calendar = Calendar.current
        let futureTime = calendar.date(byAdding: .second, value: 30, to: Date())!
        let alarm = Alarm(time: futureTime, isEnabled: true)
        alarmManager.addAlarm(alarm)

        XCTAssertEqual(alarmManager.nextAlarmDescription, "in less than a minute")
    }

    func testNextAlarmDescriptionMinutes() {
        let calendar = Calendar.current
        let futureTime = calendar.date(byAdding: .minute, value: 30, to: Date())!
        let alarm = Alarm(time: futureTime, isEnabled: true)
        alarmManager.addAlarm(alarm)

        let description = alarmManager.nextAlarmDescription
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("minute"))
    }

    func testNextAlarmDescriptionHours() {
        let calendar = Calendar.current
        let futureTime = calendar.date(byAdding: .hour, value: 2, to: Date())!
        let alarm = Alarm(time: futureTime, isEnabled: true)
        alarmManager.addAlarm(alarm)

        let description = alarmManager.nextAlarmDescription
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("hour"))
    }

    // MARK: - Fire Alarm Tests

    func testFireAlarmWithExistingAlarm() {
        let alarm = Alarm(label: "Test Fire")
        alarmManager.addAlarm(alarm)

        alarmManager.fireAlarm(
            id: alarm.id.uuidString,
            sound: alarm.sound.rawValue,
            fadeInDuration: alarm.fadeInDuration,
            snoozeDuration: alarm.snoozeDuration
        )

        XCTAssertNotNil(alarmManager.firingAlarm)
        XCTAssertEqual(alarmManager.firingAlarm?.label, "Test Fire")
        XCTAssertTrue(alarmManager.showingAlarmFiringView)
    }

    func testFireAlarmWithNonexistentAlarm() {
        let fakeId = UUID().uuidString

        alarmManager.fireAlarm(
            id: fakeId,
            sound: AlarmSound.morningBirds.rawValue,
            fadeInDuration: 3,
            snoozeDuration: 5
        )

        XCTAssertNotNil(alarmManager.firingAlarm)
        XCTAssertEqual(alarmManager.firingAlarm?.label, "Alarm")
        XCTAssertTrue(alarmManager.showingAlarmFiringView)
    }

    // MARK: - Dismiss Alarm Tests

    func testDismissOneTimeAlarm() {
        let alarm = Alarm(label: "One Time", isEnabled: true, repeatDays: [])
        alarmManager.addAlarm(alarm)

        alarmManager.fireAlarm(
            id: alarm.id.uuidString,
            sound: alarm.sound.rawValue,
            fadeInDuration: alarm.fadeInDuration,
            snoozeDuration: alarm.snoozeDuration
        )

        alarmManager.dismissAlarm()

        XCTAssertNil(alarmManager.firingAlarm)
        XCTAssertFalse(alarmManager.showingAlarmFiringView)
        // One-time alarm should be disabled after dismiss
        XCTAssertFalse(alarmManager.alarms.first?.isEnabled ?? true)
    }

    func testDismissRepeatingAlarm() {
        let alarm = Alarm(label: "Repeating", isEnabled: true, repeatDays: [.monday, .friday])
        alarmManager.addAlarm(alarm)

        alarmManager.fireAlarm(
            id: alarm.id.uuidString,
            sound: alarm.sound.rawValue,
            fadeInDuration: alarm.fadeInDuration,
            snoozeDuration: alarm.snoozeDuration
        )

        alarmManager.dismissAlarm()

        XCTAssertNil(alarmManager.firingAlarm)
        XCTAssertFalse(alarmManager.showingAlarmFiringView)
        // Repeating alarm should stay enabled after dismiss
        XCTAssertTrue(alarmManager.alarms.first?.isEnabled ?? false)
    }

    // MARK: - Snooze Alarm Tests

    func testSnoozeAlarm() {
        let alarm = Alarm(label: "Snooze Test", snoozeDuration: 5)
        alarmManager.addAlarm(alarm)

        alarmManager.fireAlarm(
            id: alarm.id.uuidString,
            sound: alarm.sound.rawValue,
            fadeInDuration: alarm.fadeInDuration,
            snoozeDuration: alarm.snoozeDuration
        )

        alarmManager.snoozeAlarm()

        XCTAssertNil(alarmManager.firingAlarm)
        XCTAssertFalse(alarmManager.showingAlarmFiringView)
    }

    // MARK: - Persistence Tests

    func testAlarmsPersistAcrossInstances() {
        let alarm = Alarm(label: "Persistent Alarm")
        alarmManager.addAlarm(alarm)

        // Create a new instance (simulating app restart)
        let newManager = AlarmManager()

        XCTAssertEqual(newManager.alarms.count, 1)
        XCTAssertEqual(newManager.alarms.first?.label, "Persistent Alarm")
    }

    func testMultipleAlarmsPersist() {
        let alarm1 = Alarm(label: "Alarm 1", sound: .morningBirds)
        let alarm2 = Alarm(label: "Alarm 2", sound: .morningBirds)

        alarmManager.addAlarm(alarm1)
        alarmManager.addAlarm(alarm2)

        let newManager = AlarmManager()

        XCTAssertEqual(newManager.alarms.count, 2)
    }

    func testDeletedAlarmDoesNotPersist() {
        let alarm = Alarm(label: "To Delete")
        alarmManager.addAlarm(alarm)
        alarmManager.deleteAlarm(alarm)

        let newManager = AlarmManager()

        XCTAssertEqual(newManager.alarms.count, 0)
    }

    func testUpdatedAlarmPersists() {
        var alarm = Alarm(label: "Original")
        alarmManager.addAlarm(alarm)

        alarm.label = "Updated"
        alarmManager.updateAlarm(alarm)

        let newManager = AlarmManager()

        XCTAssertEqual(newManager.alarms.first?.label, "Updated")
    }

    // MARK: - Live Activity State Tests

    func testIsLiveActivityActiveInitiallyFalse() {
        XCTAssertFalse(alarmManager.isLiveActivityActive)
    }
}
