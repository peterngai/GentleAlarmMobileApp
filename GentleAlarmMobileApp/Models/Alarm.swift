//
//  Alarm.swift
//  GentleAlarmMobileApp
//

import Foundation

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var initial: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var label: String
    var isEnabled: Bool
    var sound: AlarmSound
    var fadeInDuration: Int  // Minutes for 0-100% volume
    var snoozeDuration: Int  // Minutes
    var repeatDays: Set<Weekday>
    var failsafeEnabled: Bool  // Whether to play loud backup alarm
    var failsafeMinutes: Int   // Minutes after alarm starts before failsafe triggers

    init(
        id: UUID = UUID(),
        time: Date = Date(),
        label: String = "Alarm",
        isEnabled: Bool = true,
        sound: AlarmSound = .morningBirds,
        fadeInDuration: Int = 3,
        snoozeDuration: Int = 5,
        repeatDays: Set<Weekday> = [],
        failsafeEnabled: Bool = false,
        failsafeMinutes: Int = 5
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.sound = sound
        self.fadeInDuration = fadeInDuration
        self.snoozeDuration = snoozeDuration
        self.repeatDays = repeatDays
        self.failsafeEnabled = failsafeEnabled
        self.failsafeMinutes = failsafeMinutes
    }

    var hour: Int {
        Calendar.current.component(.hour, from: time)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: time)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }

    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "One time"
        } else if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Weekdays"
        } else if repeatDays == [.saturday, .sunday] {
            return "Weekends"
        } else {
            let sorted = repeatDays.sorted { $0.rawValue < $1.rawValue }
            return sorted.map { $0.shortName }.joined(separator: ", ")
        }
    }

    func nextFireDate(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)

        if repeatDays.isEmpty {
            // One-time alarm: find next occurrence of this time
            components.second = 0
            if let todayAlarm = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now) {
                if todayAlarm > now {
                    return todayAlarm
                } else {
                    // Tomorrow
                    return calendar.date(byAdding: .day, value: 1, to: todayAlarm)
                }
            }
        } else {
            // Repeating alarm: find next matching weekday
            for dayOffset in 0..<8 {
                if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) {
                    let weekday = calendar.component(.weekday, from: futureDate)
                    if let day = Weekday(rawValue: weekday), repeatDays.contains(day) {
                        if let alarmTime = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: futureDate) {
                            if alarmTime > now {
                                return alarmTime
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}
