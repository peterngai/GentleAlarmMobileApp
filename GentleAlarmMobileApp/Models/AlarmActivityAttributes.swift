//
//  AlarmActivityAttributes.swift
//  GentleAlarmMobileApp
//

import Foundation
import ActivityKit

struct AlarmActivityAttributes: ActivityAttributes {
    // Static data that doesn't change during the Live Activity
    public struct ContentState: Codable, Hashable {
        var alarmTime: Date
        var timeRemaining: TimeInterval
        var isRinging: Bool
    }

    // Fixed data set when starting the activity
    var alarmId: String
    var alarmLabel: String
    var alarmTimeString: String
}
