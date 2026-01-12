//
//  AlarmSoundTests.swift
//  GentleAlarmMobileAppTests
//

import XCTest
@testable import GentleAlarmMobileApp

final class AlarmSoundTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAlarmSoundRawValues() {
        XCTAssertEqual(AlarmSound.morningBirds.rawValue, "morning_birds")
        XCTAssertEqual(AlarmSound.oceanWaves.rawValue, "ocean-waves")
        XCTAssertEqual(AlarmSound.zeldaFairyFountain.rawValue, "zelda-fairy-fountain")
        XCTAssertEqual(AlarmSound.clockAlarm.rawValue, "clock-alarm")
    }

    // MARK: - Display Name Tests

    func testAlarmSoundDisplayNames() {
        XCTAssertEqual(AlarmSound.morningBirds.displayName, "Morning Birds")
        XCTAssertEqual(AlarmSound.oceanWaves.displayName, "Ocean Waves")
        XCTAssertEqual(AlarmSound.zeldaFairyFountain.displayName, "Zelda Fairy Fountain")
        XCTAssertEqual(AlarmSound.clockAlarm.displayName, "Clock Alarm")
    }

    // MARK: - Description Tests

    func testAlarmSoundDescriptions() {
        XCTAssertEqual(AlarmSound.morningBirds.description, "Nature sounds")
        XCTAssertEqual(AlarmSound.oceanWaves.description, "Calm waves")
        XCTAssertEqual(AlarmSound.zeldaFairyFountain.description, "Magical harp melody")
        XCTAssertEqual(AlarmSound.clockAlarm.description, "Loud failsafe alarm")
    }

    // MARK: - System Sound Name Tests

    func testAlarmSoundSystemSoundNames() {
        XCTAssertEqual(AlarmSound.morningBirds.systemSoundName, "Birds")
        XCTAssertEqual(AlarmSound.oceanWaves.systemSoundName, "Waves")
        XCTAssertEqual(AlarmSound.zeldaFairyFountain.systemSoundName, "Harp")
        XCTAssertEqual(AlarmSound.clockAlarm.systemSoundName, "Alarm")
    }

    // MARK: - Identifiable Tests

    func testAlarmSoundIdentifiable() {
        for sound in AlarmSound.allCases {
            XCTAssertEqual(sound.id, sound.rawValue)
        }
    }

    // MARK: - CaseIterable Tests

    func testAlarmSoundAllCasesCount() {
        XCTAssertEqual(AlarmSound.allCases.count, 4)
    }

    func testAlarmSoundAllCasesContainsAll() {
        let allCases = AlarmSound.allCases

        XCTAssertTrue(allCases.contains(.morningBirds))
        XCTAssertTrue(allCases.contains(.oceanWaves))
        XCTAssertTrue(allCases.contains(.zeldaFairyFountain))
        XCTAssertTrue(allCases.contains(.clockAlarm))
    }

    // MARK: - Selectable Sounds Tests

    func testSelectableSoundsExcludesFailsafe() {
        let selectable = AlarmSound.selectableSounds
        XCTAssertEqual(selectable.count, 3)
        XCTAssertFalse(selectable.contains(.clockAlarm))
        XCTAssertTrue(selectable.contains(.morningBirds))
        XCTAssertTrue(selectable.contains(.oceanWaves))
        XCTAssertTrue(selectable.contains(.zeldaFairyFountain))
    }

    func testIsFailsafeOnly() {
        XCTAssertTrue(AlarmSound.clockAlarm.isFailsafeOnly)
        XCTAssertFalse(AlarmSound.morningBirds.isFailsafeOnly)
        XCTAssertFalse(AlarmSound.oceanWaves.isFailsafeOnly)
        XCTAssertFalse(AlarmSound.zeldaFairyFountain.isFailsafeOnly)
    }

    // MARK: - Codable Tests

    func testAlarmSoundEncodingDecoding() throws {
        for sound in AlarmSound.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(sound)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(AlarmSound.self, from: data)

            XCTAssertEqual(sound, decoded)
        }
    }

    func testAlarmSoundDecodingFromRawValue() throws {
        let jsonString = "\"morning_birds\""
        let data = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AlarmSound.self, from: data)

        XCTAssertEqual(decoded, .morningBirds)
    }

    // MARK: - Initialization from Raw Value Tests

    func testAlarmSoundInitFromValidRawValue() {
        XCTAssertEqual(AlarmSound(rawValue: "morning_birds"), .morningBirds)
        XCTAssertEqual(AlarmSound(rawValue: "ocean-waves"), .oceanWaves)
        XCTAssertEqual(AlarmSound(rawValue: "zelda-fairy-fountain"), .zeldaFairyFountain)
        XCTAssertEqual(AlarmSound(rawValue: "clock-alarm"), .clockAlarm)
    }

    func testAlarmSoundInitFromInvalidRawValue() {
        XCTAssertNil(AlarmSound(rawValue: "invalid_sound"))
        XCTAssertNil(AlarmSound(rawValue: ""))
        XCTAssertNil(AlarmSound(rawValue: "MORNING_BIRDS"))
    }
}
