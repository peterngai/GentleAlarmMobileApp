//
//  AlarmSound.swift
//  GentleAlarmMobileApp
//

import Foundation

enum AlarmSound: String, CaseIterable, Codable, Identifiable {
    case morningBirds = "morning_birds"
    case oceanWaves = "ocean-waves"
    case clockAlarm = "clock-alarm"

    var id: String { rawValue }

    /// Sounds that should be shown in the picker (excludes failsafe-only sounds)
    static var selectableSounds: [AlarmSound] {
        allCases.filter { $0 != .clockAlarm }
    }

    /// Whether this sound is only for failsafe use
    var isFailsafeOnly: Bool {
        self == .clockAlarm
    }

    var displayName: String {
        switch self {
        case .morningBirds: return "Morning Birds"
        case .oceanWaves: return "Ocean Waves"
        case .clockAlarm: return "Clock Alarm"
        }
    }

    var description: String {
        switch self {
        case .morningBirds: return "Nature sounds"
        case .oceanWaves: return "Calm waves"
        case .clockAlarm: return "Loud failsafe alarm"
        }
    }

    var systemSoundName: String {
        switch self {
        case .morningBirds: return "Birds"
        case .oceanWaves: return "Waves"
        case .clockAlarm: return "Alarm"
        }
    }
}
