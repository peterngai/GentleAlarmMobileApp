//
//  AlarmEditView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct AlarmEditView: View {
    @Environment(AlarmManager.self) private var alarmManager
    @Environment(\.dismiss) private var dismiss

    let alarm: Alarm?

    @State private var time: Date
    @State private var label: String
    @State private var sound: AlarmSound
    @State private var fadeInDuration: Int
    @State private var snoozeDuration: Int
    @State private var repeatDays: Set<Weekday>
    @State private var failsafeEnabled: Bool
    @State private var failsafeMinutes: Int

    private var isEditing: Bool { alarm != nil }

    init(alarm: Alarm?) {
        self.alarm = alarm

        let defaultTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

        _time = State(initialValue: alarm?.time ?? defaultTime)
        _label = State(initialValue: alarm?.label ?? "Alarm")
        _sound = State(initialValue: alarm?.sound ?? .morningBirds)
        _fadeInDuration = State(initialValue: alarm?.fadeInDuration ?? 3)
        _snoozeDuration = State(initialValue: alarm?.snoozeDuration ?? 5)
        _repeatDays = State(initialValue: alarm?.repeatDays ?? [])
        _failsafeEnabled = State(initialValue: alarm?.failsafeEnabled ?? false)
        _failsafeMinutes = State(initialValue: alarm?.failsafeMinutes ?? 5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                Form {
                // Time Picker
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }

                // Label
                Section("Label") {
                    TextField("Alarm name", text: $label)
                }

                // Repeat Days
                Section("Repeat") {
                    RepeatDaysPicker(selectedDays: $repeatDays)
                }

                // Sound
                Section("Sound") {
                    NavigationLink {
                        SoundPickerView(selectedSound: $sound)
                    } label: {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text(sound.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Fade In Duration
                Section {
                    Picker("Fade In", selection: $fadeInDuration) {
                        ForEach(1...10, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                } header: {
                    Text("Gradual Volume")
                } footer: {
                    Text("Volume increases from 0% to 100% over this duration")
                }

                // Snooze Duration
                Section("Snooze") {
                    Picker("Snooze Duration", selection: $snoozeDuration) {
                        Text("1 min").tag(1)
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                    }
                }

                // Failsafe Alarm
                Section {
                    Toggle("Enable Failsafe", isOn: $failsafeEnabled)

                    if failsafeEnabled {
                        Picker("Trigger After", selection: $failsafeMinutes) {
                            Text("1 min").tag(1)
                            Text("2 min").tag(2)
                            Text("3 min").tag(3)
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                        }
                    }
                } header: {
                    Text("Failsafe Alarm")
                } footer: {
                    Text("If enabled, a loud backup alarm will play at full volume after the specified time if you haven't dismissed the alarm")
                }

                // Delete Button (only when editing)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let alarm = alarm {
                                alarmManager.deleteAlarm(alarm)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Alarm")
                                Spacer()
                            }
                        }
                    }
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Alarm" : "Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveAlarm() {
        if let existingAlarm = alarm {
            var updated = existingAlarm
            updated.time = time
            updated.label = label.isEmpty ? "Alarm" : label
            updated.sound = sound
            updated.fadeInDuration = fadeInDuration
            updated.snoozeDuration = snoozeDuration
            updated.repeatDays = repeatDays
            updated.failsafeEnabled = failsafeEnabled
            updated.failsafeMinutes = failsafeMinutes
            alarmManager.updateAlarm(updated)
        } else {
            let newAlarm = Alarm(
                time: time,
                label: label.isEmpty ? "Alarm" : label,
                isEnabled: true,
                sound: sound,
                fadeInDuration: fadeInDuration,
                snoozeDuration: snoozeDuration,
                repeatDays: repeatDays,
                failsafeEnabled: failsafeEnabled,
                failsafeMinutes: failsafeMinutes
            )
            alarmManager.addAlarm(newAlarm)
        }
    }
}

struct RepeatDaysPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                DayButton(
                    day: day,
                    isSelected: selectedDays.contains(day)
                ) {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.initial)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AlarmEditView(alarm: nil)
        .environment(AlarmManager())
}
