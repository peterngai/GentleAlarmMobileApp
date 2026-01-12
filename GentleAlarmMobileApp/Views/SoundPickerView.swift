//
//  SoundPickerView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct SoundPickerView: View {
    @Binding var selectedSound: AlarmSound
    @State private var previewingSound: AlarmSound?

    private let audioService = AudioService.shared

    var body: some View {
        ZStack {
            NightSkyBackground()

            List {
                Section {
                    ForEach(AlarmSound.allCases) { sound in
                        SoundRow(
                            sound: sound,
                            isSelected: selectedSound == sound,
                            isPreviewing: previewingSound == sound
                        ) {
                            selectedSound = sound
                            previewSound(sound)
                        }
                    }
                } footer: {
                    Text("Tap to preview and select a sound")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            audioService.stopAlarm()
        }
    }

    private func previewSound(_ sound: AlarmSound) {
        previewingSound = sound
        audioService.previewSound(sound)

        // Reset preview state after sound finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if previewingSound == sound {
                previewingSound = nil
            }
        }
    }
}

struct SoundRow: View {
    let sound: AlarmSound
    let isSelected: Bool
    let isPreviewing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sound.displayName)
                        .foregroundStyle(.primary)

                    Text(sound.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPreviewing {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(.orange)
                        .symbolEffect(.variableColor.iterative)
                }

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SoundPickerView(selectedSound: .constant(.morningBirds))
    }
}
