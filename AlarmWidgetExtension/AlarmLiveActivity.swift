//
//  AlarmLiveActivity.swift
//  AlarmWidgetExtension
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - shown when user long-presses
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isRinging ? "alarm.fill" : "alarm")
                        .font(.title2)
                        .foregroundColor(context.state.isRinging ? .red : .orange)
                        .symbolEffect(.pulse, isActive: context.state.isRinging)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.alarmTimeString)
                        .font(.title2.monospacedDigit())
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.alarmLabel)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isRinging {
                        Text("Alarm Ringing!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    } else {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(timerInterval: Date()...context.state.alarmTime, countsDown: true)
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            } compactLeading: {
                // Compact leading - minimal view
                Image(systemName: context.state.isRinging ? "alarm.fill" : "alarm")
                    .foregroundColor(context.state.isRinging ? .red : .orange)
                    .symbolEffect(.pulse, isActive: context.state.isRinging)
            } compactTrailing: {
                // Compact trailing - shows alarm time
                if context.state.isRinging {
                    Text("!")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                } else {
                    Text(context.attributes.alarmTimeString)
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            } minimal: {
                // Minimal view - just the icon
                Image(systemName: context.state.isRinging ? "alarm.fill" : "alarm")
                    .foregroundColor(context.state.isRinging ? .red : .orange)
                    .symbolEffect(.pulse, isActive: context.state.isRinging)
            }
        }
    }
}

// Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Alarm icon
            Image(systemName: context.state.isRinging ? "alarm.fill" : "alarm")
                .font(.largeTitle)
                .foregroundColor(context.state.isRinging ? .red : .orange)
                .symbolEffect(.pulse, isActive: context.state.isRinging)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.alarmLabel)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(context.attributes.alarmTimeString)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()

            // Status indicator
            if context.state.isRinging {
                Text("Ringing")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
        }
        .padding()
    }
}

// Preview
#Preview("Live Activity", as: .content, using: AlarmActivityAttributes(
    alarmId: "preview",
    alarmLabel: "Wake Up",
    alarmTimeString: "7:00 AM"
)) {
    AlarmLiveActivity()
} contentStates: {
    AlarmActivityAttributes.ContentState(
        alarmTime: Date().addingTimeInterval(3600),
        timeRemaining: 3600,
        isRinging: false
    )
    AlarmActivityAttributes.ContentState(
        alarmTime: Date(),
        timeRemaining: 0,
        isRinging: true
    )
}
