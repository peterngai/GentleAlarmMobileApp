//
//  AlarmManager.swift
//  GentleAlarmMobileApp
//

import Foundation
import SwiftUI
import ActivityKit

@Observable
final class AlarmManager {
    private static let storageKey = "savedAlarms"

    var alarms: [Alarm] = []
    var firingAlarm: Alarm?
    var showingAlarmFiringView = false

    // Live Activity state
    private(set) var currentActivity: Activity<AlarmActivityAttributes>?
    var isLiveActivityActive: Bool {
        currentActivity != nil
    }

    private let audioService = AudioService.shared
    private let notificationService = NotificationService.shared

    init() {
        loadAlarms()
    }

    // MARK: - Persistence

    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return
        }

        do {
            alarms = try JSONDecoder().decode([Alarm].self, from: data)
        } catch {
            print("Failed to load alarms: \(error)")
        }
    }

    private func saveAlarms() {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("Failed to save alarms: \(error)")
        }
    }

    // MARK: - CRUD Operations

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()

        if alarm.isEnabled {
            handleAlarmEnabled(alarm)
        }
    }

    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()

            // Restart Live Activity if alarm is enabled and within 8 hours
            if alarm.isEnabled {
                handleAlarmEnabled(alarm)
            } else {
                stopLiveActivityAndAudio()
            }
        }
    }

    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        stopLiveActivityAndAudio()
    }

    func deleteAlarms(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        saveAlarms()
        stopLiveActivityAndAudio()
    }

    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()

            let updatedAlarm = alarms[index]
            if updatedAlarm.isEnabled {
                // Start Live Activity (handles alarm via background audio)
                handleAlarmEnabled(updatedAlarm)
            } else {
                // Stop Live Activity if this was the active alarm
                if currentActivity != nil {
                    stopLiveActivityAndAudio()
                }
            }
        }
    }

    // MARK: - Alarm Firing

    func fireAlarm(id: String, sound: String, fadeInDuration: Int, snoozeDuration: Int, failsafeEnabled: Bool = false, failsafeMinutes: Int = 5) {
        if let alarm = alarms.first(where: { $0.id.uuidString == id }) {
            firingAlarm = alarm
        } else {
            // Create a temporary alarm object for notification-based firing
            firingAlarm = Alarm(
                id: UUID(uuidString: id) ?? UUID(),
                label: "Alarm",
                sound: AlarmSound(rawValue: sound) ?? .morningBirds,
                fadeInDuration: fadeInDuration,
                snoozeDuration: snoozeDuration,
                failsafeEnabled: failsafeEnabled,
                failsafeMinutes: failsafeMinutes
            )
        }

        showingAlarmFiringView = true
        audioService.playAlarm(
            sound: firingAlarm?.sound ?? .morningBirds,
            fadeInDuration: fadeInDuration,
            failsafeEnabled: firingAlarm?.failsafeEnabled ?? failsafeEnabled,
            failsafeMinutes: firingAlarm?.failsafeMinutes ?? failsafeMinutes
        )
    }

    func snoozeAlarm() {
        audioService.stopAlarm()
        stopLiveActivityAndAudio()

        if let alarm = firingAlarm {
            // Start a new Live Activity for the snooze period
            let snoozeDate = Date().addingTimeInterval(Double(alarm.snoozeDuration * 60))
            var snoozedAlarm = alarm
            snoozedAlarm.time = snoozeDate

            // Start Live Activity for snooze
            startLiveActivity(for: snoozedAlarm)
        }

        showingAlarmFiringView = false
        firingAlarm = nil
    }

    func dismissAlarm() {
        audioService.stopAlarm()
        stopLiveActivityAndAudio()

        if let alarm = firingAlarm {
            if alarm.repeatDays.isEmpty {
                // One-time alarm: disable it
                if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                    alarms[index].isEnabled = false
                    saveAlarms()
                }
            } else {
                // Repeating alarm: auto-restart Sleep Mode for next occurrence
                // Small delay to let the current Live Activity end cleanly
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.startLiveActivity(for: alarm)
                }
            }
        }

        showingAlarmFiringView = false
        firingAlarm = nil
    }

    // MARK: - Computed Properties

    var nextAlarm: Alarm? {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        return enabledAlarms.min { a, b in
            guard let dateA = a.nextFireDate(), let dateB = b.nextFireDate() else {
                return false
            }
            return dateA < dateB
        }
    }

    var nextAlarmDescription: String? {
        guard let alarm = nextAlarm, let fireDate = alarm.nextFireDate() else {
            return nil
        }

        let now = Date()
        let interval = fireDate.timeIntervalSince(now)

        if interval < 60 {
            return "in less than a minute"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "in \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes == 0 {
                return "in \(hours) hour\(hours == 1 ? "" : "s")"
            }
            return "in \(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: fireDate)
        }
    }

    // MARK: - Initialization

    func requestNotificationPermissions() async {
        _ = await notificationService.requestAuthorization()
    }

    func rescheduleAllAlarms() {
        Task {
            for alarm in alarms where alarm.isEnabled {
                await notificationService.scheduleAlarm(alarm)
            }
        }
    }

    // MARK: - Live Activity & Background Audio

    /// Starts a Live Activity for the given alarm with background audio.
    /// This keeps the app alive in the background and displays in Dynamic Island.
    func startLiveActivity(for alarm: Alarm) {
        guard let fireDate = alarm.nextFireDate() else {
            print("Cannot start Live Activity: no fire date for alarm")
            return
        }

        // Check if Live Activities are available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // End any existing activity
        endLiveActivity()

        // Create the activity attributes
        let attributes = AlarmActivityAttributes(
            alarmId: alarm.id.uuidString,
            alarmLabel: alarm.label,
            alarmTimeString: alarm.timeString
        )

        let initialState = AlarmActivityAttributes.ContentState(
            alarmTime: fireDate,
            timeRemaining: fireDate.timeIntervalSince(Date()),
            isRinging: false
        )

        do {
            // Request the Live Activity
            let activity = try Activity<AlarmActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: fireDate.addingTimeInterval(60)),
                pushType: nil
            )

            currentActivity = activity
            print("Started Live Activity: \(activity.id)")

            // Start background audio to keep the app alive
            audioService.startBackgroundAudio(
                until: fireDate,
                alarmSound: alarm.sound,
                fadeInDuration: alarm.fadeInDuration,
                failsafeEnabled: alarm.failsafeEnabled,
                failsafeMinutes: alarm.failsafeMinutes
            ) { [weak self] in
                // Called when the alarm triggers
                self?.handleBackgroundAlarmTrigger(alarm: alarm)
            }

            // Update the Live Activity state periodically
            startLiveActivityUpdates(for: alarm, fireDate: fireDate)

        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Ends the current Live Activity and stops background audio
    func endLiveActivity() {
        guard let activity = currentActivity else { return }

        // Stop background audio
        audioService.stopBackgroundAudio()

        // End the Live Activity
        Task {
            let finalState = AlarmActivityAttributes.ContentState(
                alarmTime: Date(),
                timeRemaining: 0,
                isRinging: false
            )
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        currentActivity = nil
        print("Ended Live Activity")
    }

    private func handleBackgroundAlarmTrigger(alarm: Alarm) {
        // Update Live Activity to show ringing state
        if let activity = currentActivity {
            Task {
                let ringingState = AlarmActivityAttributes.ContentState(
                    alarmTime: Date(),
                    timeRemaining: 0,
                    isRinging: true
                )
                await activity.update(.init(state: ringingState, staleDate: nil))
            }
        }

        // Note: playAlarm is already called by triggerScheduledAlarm() in AudioService
        // with the failsafe parameters, so we don't need to call it again here

        // Show the alarm firing UI
        DispatchQueue.main.async { [weak self] in
            self?.firingAlarm = alarm
            self?.showingAlarmFiringView = true
        }
    }

    private var liveActivityUpdateTimer: Timer?

    private func startLiveActivityUpdates(for alarm: Alarm, fireDate: Date) {
        liveActivityUpdateTimer?.invalidate()

        // Update every 30 seconds to keep the countdown accurate
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] timer in
            guard let self = self,
                  let activity = self.currentActivity else {
                timer.invalidate()
                return
            }

            let now = Date()
            if now >= fireDate {
                timer.invalidate()
                return
            }

            let newState = AlarmActivityAttributes.ContentState(
                alarmTime: fireDate,
                timeRemaining: fireDate.timeIntervalSince(now),
                isRinging: false
            )

            Task {
                await activity.update(.init(state: newState, staleDate: fireDate.addingTimeInterval(60)))
            }
        }
    }

    /// Call this when the user enables an alarm to start a Live Activity
    func handleAlarmEnabled(_ alarm: Alarm) {
        guard alarm.nextFireDate() != nil else { return }

        // Always start Live Activity when alarm is enabled
        startLiveActivity(for: alarm)
    }

    /// Stops the Live Activity and background audio, used when dismissing or snoozing
    func stopLiveActivityAndAudio() {
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil
        endLiveActivity()
    }
}
