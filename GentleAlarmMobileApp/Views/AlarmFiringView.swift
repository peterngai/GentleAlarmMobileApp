//
//  AlarmFiringView.swift
//  GentleAlarmMobileApp
//

import SwiftUI
import Combine

struct AlarmFiringView: View {
    @Environment(AlarmManager.self) private var alarmManager

    let alarm: Alarm

    @State private var currentTime = Date()
    @State private var isPulsing = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Night sky background
            NightSkyBackground()

            VStack(spacing: 40) {
                Spacer()

                // Alarm icon with pulse animation
                Image(systemName: "alarm.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                // Current time
                Text(timeString)
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundStyle(.white)

                // Alarm label
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    // Snooze button
                    Button {
                        alarmManager.snoozeAlarm()
                    } label: {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                            Text("Snooze (\(alarm.snoozeDuration) min)")
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Dismiss button
                    Button {
                        alarmManager.dismissAlarm()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Dismiss")
                        }
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isPulsing = true
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    AlarmFiringView(
        alarm: Alarm(
            label: "Wake up",
            snoozeDuration: 5
        )
    )
    .environment(AlarmManager())
}
