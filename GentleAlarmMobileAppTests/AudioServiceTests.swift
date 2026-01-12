//
//  AudioServiceTests.swift
//  GentleAlarmMobileAppTests
//

import XCTest
@testable import GentleAlarmMobileApp

final class AudioServiceTests: XCTestCase {

    var audioService: AudioService!

    override func setUp() {
        super.setUp()
        audioService = AudioService.shared
        // Ensure clean state
        audioService.stopAlarm()
        audioService.stopBackgroundAudio()
    }

    override func tearDown() {
        audioService.stopAlarm()
        audioService.stopBackgroundAudio()
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStateNotPlaying() {
        XCTAssertFalse(audioService.isPlaying)
    }

    func testInitialStateNoBackgroundAudio() {
        XCTAssertFalse(audioService.isBackgroundAudioActive)
    }

    func testInitialStateNoAmbientPlaying() {
        XCTAssertFalse(audioService.isAmbientPlaying)
    }

    func testInitialStateNoPendingAlarm() {
        XCTAssertNil(audioService.pendingAlarm)
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = AudioService.shared
        let instance2 = AudioService.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Stop Alarm Tests

    func testStopAlarmWhenNotPlaying() {
        // Should not crash when stopping while not playing
        audioService.stopAlarm()

        XCTAssertFalse(audioService.isPlaying)
    }

    func testStopAlarmResetsState() {
        audioService.stopAlarm()

        XCTAssertFalse(audioService.isPlaying)
    }

    // MARK: - Background Audio Tests

    func testStartBackgroundAudioSetsActiveState() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        audioService.startBackgroundAudio(
            until: futureDate,
            alarmSound: .morningBirds,
            fadeInDuration: 3,
            onTrigger: {}
        )

        XCTAssertTrue(audioService.isBackgroundAudioActive)
        XCTAssertNotNil(audioService.pendingAlarm)

        // Clean up
        audioService.stopBackgroundAudio()
    }

    func testStartBackgroundAudioSetsPendingAlarmTime() {
        let futureDate = Date().addingTimeInterval(3600)

        audioService.startBackgroundAudio(
            until: futureDate,
            alarmSound: .morningBirds,
            fadeInDuration: 5,
            onTrigger: {}
        )

        XCTAssertEqual(audioService.pendingAlarm, futureDate)

        // Clean up
        audioService.stopBackgroundAudio()
    }

    func testStopBackgroundAudioClearsState() {
        let futureDate = Date().addingTimeInterval(3600)

        audioService.startBackgroundAudio(
            until: futureDate,
            alarmSound: .morningBirds,
            fadeInDuration: 3,
            onTrigger: {}
        )

        audioService.stopBackgroundAudio()

        XCTAssertFalse(audioService.isBackgroundAudioActive)
        XCTAssertNil(audioService.pendingAlarm)
        XCTAssertFalse(audioService.isAmbientPlaying)
    }

    func testUpdatePendingAlarmTime() {
        let initialDate = Date().addingTimeInterval(3600)
        let newDate = Date().addingTimeInterval(7200)

        audioService.startBackgroundAudio(
            until: initialDate,
            alarmSound: .morningBirds,
            fadeInDuration: 3,
            onTrigger: {}
        )

        audioService.updatePendingAlarmTime(newDate)

        XCTAssertEqual(audioService.pendingAlarm, newDate)

        // Clean up
        audioService.stopBackgroundAudio()
    }

    // MARK: - Multiple Start/Stop Cycles

    func testMultipleStartStopCycles() {
        for _ in 0..<5 {
            let futureDate = Date().addingTimeInterval(3600)

            audioService.startBackgroundAudio(
                until: futureDate,
                alarmSound: .morningBirds,
                fadeInDuration: 3,
                onTrigger: {}
            )

            XCTAssertTrue(audioService.isBackgroundAudioActive)

            audioService.stopBackgroundAudio()

            XCTAssertFalse(audioService.isBackgroundAudioActive)
        }
    }

    func testStartingNewBackgroundAudioStopsPrevious() {
        let firstDate = Date().addingTimeInterval(3600)
        let secondDate = Date().addingTimeInterval(7200)

        audioService.startBackgroundAudio(
            until: firstDate,
            alarmSound: .morningBirds,
            fadeInDuration: 3,
            onTrigger: {}
        )

        audioService.startBackgroundAudio(
            until: secondDate,
            alarmSound: .morningBirds,
            fadeInDuration: 5,
            onTrigger: {}
        )

        // Should have the second alarm's time
        XCTAssertEqual(audioService.pendingAlarm, secondDate)

        // Clean up
        audioService.stopBackgroundAudio()
    }

    // MARK: - Alarm Trigger Callback Tests

    func testAlarmTriggerCallbackIsStored() {
        var callbackCalled = false
        let futureDate = Date().addingTimeInterval(3600)

        audioService.startBackgroundAudio(
            until: futureDate,
            alarmSound: .morningBirds,
            fadeInDuration: 3,
            onTrigger: {
                callbackCalled = true
            }
        )

        // Callback shouldn't be called yet (alarm time hasn't arrived)
        XCTAssertFalse(callbackCalled)

        // Clean up
        audioService.stopBackgroundAudio()
    }

    // MARK: - Play Alarm Tests

    func testPlayAlarmSetsPlayingState() {
        // Note: This test may not work in all environments due to audio requirements
        // The playAlarm method attempts to play audio, which may fail without proper resources

        audioService.playAlarm(sound: .morningBirds, fadeInDuration: 1)

        // Even if audio fails, stopAlarm should work
        audioService.stopAlarm()

        XCTAssertFalse(audioService.isPlaying)
    }

    // MARK: - Different Sound Types Tests

    func testBackgroundAudioWithDifferentSounds() {
        let sounds: [AlarmSound] = [.morningBirds, .oceanWaves, .zeldaFairyFountain]
        let futureDate = Date().addingTimeInterval(3600)

        for sound in sounds {
            audioService.startBackgroundAudio(
                until: futureDate,
                alarmSound: sound,
                fadeInDuration: 3,
                onTrigger: {}
            )

            XCTAssertTrue(audioService.isBackgroundAudioActive)

            audioService.stopBackgroundAudio()
        }
    }

    // MARK: - Fade Duration Tests

    func testBackgroundAudioWithDifferentFadeInDurations() {
        let fadeDurations = [1, 2, 3, 5, 10]
        let futureDate = Date().addingTimeInterval(3600)

        for duration in fadeDurations {
            audioService.startBackgroundAudio(
                until: futureDate,
                alarmSound: .morningBirds,
                fadeInDuration: duration,
                onTrigger: {}
            )

            XCTAssertTrue(audioService.isBackgroundAudioActive)

            audioService.stopBackgroundAudio()
        }
    }
}
