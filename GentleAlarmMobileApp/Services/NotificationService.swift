//
//  NotificationService.swift
//  GentleAlarmMobileApp
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    static let snoozeActionIdentifier = "SNOOZE_ACTION"
    static let dismissActionIdentifier = "DISMISS_ACTION"
    static let alarmCategoryIdentifier = "ALARM_CATEGORY"

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            if granted {
                await setupNotificationCategories()
            }
            return granted
        } catch {
            #if DEBUG
            print("Failed to request notification authorization: \(error)")
            #endif
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    private func setupNotificationCategories() async {
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: "Snooze",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionIdentifier,
            title: "Dismiss",
            options: [.destructive]
        )

        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryIdentifier,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }

    func scheduleAlarm(_ alarm: Alarm) async {
        guard alarm.isEnabled else { return }

        // Cancel any existing notifications for this alarm
        await cancelAlarm(alarm)

        guard let fireDate = alarm.nextFireDate() else {
            #if DEBUG
            print("Could not determine next fire date for alarm: \(alarm.id)")
            #endif
            return
        }

        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = "Tap to open alarm with gradual volume"
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "sound": alarm.sound.rawValue,
            "fadeInDuration": alarm.fadeInDuration,
            "snoozeDuration": alarm.snoozeDuration
        ]

        // Use Time Sensitive for higher priority
        content.interruptionLevel = .timeSensitive

        // Try to use a custom sound file, fall back to default critical
        if let soundURL = Bundle.main.url(forResource: alarm.sound.rawValue, withExtension: "m4a") {
            // Custom sound (up to 30 seconds)
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundURL.lastPathComponent))
        } else if let defaultSound = Bundle.main.url(forResource: "alarm_notification", withExtension: "m4a") {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "alarm_notification.m4a"))
        } else {
            // Fall back to default critical sound (louder, repeating)
            content.sound = .default
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            #if DEBUG
            print("Scheduled alarm \(alarm.label) for \(fireDate)")
            #endif
        } catch {
            #if DEBUG
            print("Failed to schedule alarm: \(error)")
            #endif
        }
    }

    func cancelAlarm(_ alarm: Alarm) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [alarm.id.uuidString])
    }

    func scheduleSnooze(for alarm: Alarm) async {
        let content = UNMutableNotificationContent()
        content.title = "\(alarm.label) (Snoozed)"
        content.body = "Tap to open alarm with gradual volume"
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "sound": alarm.sound.rawValue,
            "fadeInDuration": alarm.fadeInDuration,
            "snoozeDuration": alarm.snoozeDuration,
            "isSnoozed": true
        ]

        // Use Time Sensitive for higher priority
        content.interruptionLevel = .timeSensitive

        // Use critical sound for snooze alerts
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(alarm.snoozeDuration * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)-snooze",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            #if DEBUG
            print("Scheduled snooze for \(alarm.snoozeDuration) minutes")
            #endif
        } catch {
            #if DEBUG
            print("Failed to schedule snooze: \(error)")
            #endif
        }
    }

    func cancelSnooze(for alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["\(alarm.id.uuidString)-snooze"]
        )
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
