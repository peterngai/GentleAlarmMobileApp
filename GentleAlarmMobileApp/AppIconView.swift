//
//  AppIconView.swift
//  GentleAlarmMobileApp
//
//  This view renders the app icon design.
//  To export: Run in preview, take a screenshot at 1024x1024, add to Assets.
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Dark gradient background with sunrise hint at bottom
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.08, blue: 0.12),
                    Color(red: 0.15, green: 0.1, blue: 0.12),
                    Color(red: 0.25, green: 0.12, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Sunrise glow at bottom
            RadialGradient(
                colors: [
                    Color.orange.opacity(0.4),
                    Color.orange.opacity(0.1),
                    Color.clear
                ],
                center: .bottom,
                startRadius: size * 0.05,
                endRadius: size * 0.6
            )

            // Content - bird overlapping alarm clock from upper left
            ZStack {
                // Alarm clock (centered, slightly down-right)
                Image(systemName: "alarm.fill")
                    .font(.system(size: size * 0.55, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, Color(red: 1.0, green: 0.4, blue: 0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.6), radius: size * 0.04)
                    .offset(x: size * 0.1, y: size * 0.06)

                // Bird overlapping upper-left of alarm
                HStack(spacing: size * 0.02) {
                    // Bird (facing right, toward the alarm)
                    Image(systemName: "bird.fill")
                        .font(.system(size: size * 0.5, weight: .regular))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.9),
                                    Color(red: 0.2, green: 0.6, blue: 0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.6), radius: size * 0.03)

                    // Sound waves (chirping)
                    SoundWaves(size: size, color: Color(red: 0.4, green: 0.8, blue: 0.9))
                }
                .offset(x: -size * 0.12, y: -size * 0.1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237)) // iOS icon radius
    }
}

// Sound waves emanating from bird
struct SoundWaves: View {
    let size: CGFloat
    var color: Color = .yellow

    var body: some View {
        HStack(spacing: size * 0.015) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.9 - Double(i) * 0.2),
                                color.opacity(0.7 - Double(i) * 0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: size * 0.015,
                        height: size * (0.05 + CGFloat(i) * 0.03)
                    )
            }
        }
    }
}

#Preview("App Icon 1024") {
    AppIconView(size: 1024)
}

#Preview("App Icon 180") {
    AppIconView(size: 180)
}

#Preview("App Icon 60") {
    AppIconView(size: 60)
}
