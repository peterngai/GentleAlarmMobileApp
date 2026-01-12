//
//  GentleAlarmMobileAppApp.swift
//  GentleAlarmMobileApp
//

import SwiftUI
import UserNotifications

@main
struct GentleAlarmMobileApp: App {
    @State private var alarmManager = AlarmManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(alarmManager)
                .onAppear {
                    appDelegate.alarmManager = alarmManager
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var alarmManager: AlarmManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if let alarmId = userInfo["alarmId"] as? String,
           let sound = userInfo["sound"] as? String,
           let fadeInDuration = userInfo["fadeInDuration"] as? Int,
           let snoozeDuration = userInfo["snoozeDuration"] as? Int {
            DispatchQueue.main.async {
                self.alarmManager?.fireAlarm(
                    id: alarmId,
                    sound: sound,
                    fadeInDuration: fadeInDuration,
                    snoozeDuration: snoozeDuration
                )
            }
        }

        // Don't show the notification banner since we're showing our own UI
        completionHandler([])
    }

    // Called when user interacts with notification (app in background or closed)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case NotificationService.snoozeActionIdentifier:
            handleSnooze(userInfo: userInfo)

        case NotificationService.dismissActionIdentifier:
            handleDismiss(userInfo: userInfo)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification - show alarm firing view
            if let alarmId = userInfo["alarmId"] as? String,
               let sound = userInfo["sound"] as? String,
               let fadeInDuration = userInfo["fadeInDuration"] as? Int,
               let snoozeDuration = userInfo["snoozeDuration"] as? Int {
                DispatchQueue.main.async {
                    self.alarmManager?.fireAlarm(
                        id: alarmId,
                        sound: sound,
                        fadeInDuration: fadeInDuration,
                        snoozeDuration: snoozeDuration
                    )
                }
            }

        default:
            break
        }

        completionHandler()
    }

    private func handleSnooze(userInfo: [AnyHashable: Any]) {
        guard let alarmId = userInfo["alarmId"] as? String,
              let sound = userInfo["sound"] as? String,
              let fadeInDuration = userInfo["fadeInDuration"] as? Int,
              let snoozeDuration = userInfo["snoozeDuration"] as? Int else {
            return
        }

        let alarm = Alarm(
            id: UUID(uuidString: alarmId) ?? UUID(),
            sound: AlarmSound(rawValue: sound) ?? .morningBirds,
            fadeInDuration: fadeInDuration,
            snoozeDuration: snoozeDuration
        )

        Task {
            await NotificationService.shared.scheduleSnooze(for: alarm)
        }
    }

    private func handleDismiss(userInfo: [AnyHashable: Any]) {
        guard let alarmId = userInfo["alarmId"] as? String else {
            return
        }

        // If it's a one-time alarm, disable it
        DispatchQueue.main.async {
            if let alarm = self.alarmManager?.alarms.first(where: { $0.id.uuidString == alarmId }) {
                if alarm.repeatDays.isEmpty {
                    self.alarmManager?.toggleAlarm(alarm)
                } else {
                    // Reschedule for next occurrence
                    Task {
                        await NotificationService.shared.scheduleAlarm(alarm)
                    }
                }
            }
        }
    }
}
