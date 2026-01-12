//
//  AlarmRowView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct AlarmRowView: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    Text(alarm.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatDescription)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.orange)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        AlarmRowView(
            alarm: Alarm(
                time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date())!,
                label: "Wake up",
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
            ),
            onToggle: {}
        )

        AlarmRowView(
            alarm: Alarm(
                time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
                label: "Weekend",
                isEnabled: false,
                repeatDays: [.saturday, .sunday]
            ),
            onToggle: {}
        )
    }
}
