//
//  ContentView.swift
//  GentleAlarmMobileApp
//

import SwiftUI
import Combine

// MARK: - Star Model
struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let twinkleSpeed: Double
}

// MARK: - Twinkling Star View
struct TwinklingStarView: View {
    let star: Star
    @State private var isGlowing = false

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: star.size, height: star.size)
            .opacity(isGlowing ? star.opacity : star.opacity * 0.3)
            .blur(radius: star.size > 2 ? 0.5 : 0)
            .position(x: star.x, y: star.y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: star.twinkleSpeed)
                    .repeatForever(autoreverses: true)
                ) {
                    isGlowing = true
                }
            }
    }
}

// MARK: - Star Field View
struct StarFieldView: View {
    let stars: [Star]

    init(starCount: Int = 100) {
        var generatedStars: [Star] = []
        for _ in 0..<starCount {
            let star = Star(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.5...1.0),
                twinkleSpeed: Double.random(in: 0.5...2.5)
            )
            generatedStars.append(star)
        }
        self.stars = generatedStars
    }

    var body: some View {
        Canvas { context, size in
            // Draw non-animated background stars
        }
        .overlay {
            ForEach(stars) { star in
                TwinklingStarView(star: star)
            }
        }
    }
}

// MARK: - Night Sky Background
struct NightSkyBackground: View {
    var starCount: Int = 80

    var body: some View {
        ZStack {
            // Dark navy gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.05, blue: 0.15),
                    Color(red: 0.05, green: 0.08, blue: 0.22),
                    Color(red: 0.08, green: 0.12, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Twinkling stars
            StarFieldView(starCount: starCount)
        }
        .ignoresSafeArea()
    }
}

struct ContentView: View {
    @Environment(AlarmManager.self) private var alarmManager
    @State private var showingAddAlarm = false
    @State private var showingAbout = false
    @State private var selectedAlarm: Alarm?
    @State private var showLowVolumeAlert = false
    @State private var pendingAlarmForSleepMode: Alarm?
    @State private var currentVolume: Float = 1.0

    private let volumeThreshold: Float = 0.75  // 75% threshold
    private let volumeCheckTimer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // Night sky background (reduced stars during Sleep Mode to save battery)
                NightSkyBackground(starCount: alarmManager.isLiveActivityActive ? 20 : 80)

                if alarmManager.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListView
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentVolume < volumeThreshold {
                        lowVolumeBanner
                    } else {
                        Button {
                            showingAbout = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title3)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView(alarm: nil)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(item: $selectedAlarm) { alarm in
                AlarmEditView(alarm: alarm)
            }
            .fullScreenCover(isPresented: Binding(
                get: { alarmManager.showingAlarmFiringView },
                set: { alarmManager.showingAlarmFiringView = $0 }
            )) {
                if let alarm = alarmManager.firingAlarm {
                    AlarmFiringView(alarm: alarm)
                }
            }
            .alert("Volume is Low", isPresented: $showLowVolumeAlert) {
                Button("Turn Up Volume", role: .cancel) { }
                Button("Start Anyway") {
                    if let alarm = pendingAlarmForSleepMode {
                        alarmManager.startLiveActivity(for: alarm)
                    }
                }
            } message: {
                Text("Your volume is set low. You might not hear your alarm.")
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await alarmManager.requestNotificationPermissions()
        }
        .onAppear {
            currentVolume = AudioService.shared.getCurrentVolume()
        }
        .onReceive(volumeCheckTimer) { _ in
            currentVolume = AudioService.shared.getCurrentVolume()
        }
    }

    private var lowVolumeBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "speaker.wave.1.fill")
                .foregroundStyle(.orange)
                .font(.subheadline)
            Text("Volume: \(Int(currentVolume * 100))%")
                .font(.subheadline)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
        .fixedSize()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("No Alarms")
                .font(.title2)
                .fontWeight(.medium)

            Text("Tap + to create your first alarm")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var alarmListView: some View {
        List {
            // Sleep Mode / Live Activity Section
            if alarmManager.isLiveActivityActive {
                Section {
                    sleepModeActiveView
                }
            } else if let nextAlarm = alarmManager.nextAlarm, nextAlarm.isEnabled {
                Section {
                    sleepModeButton(for: nextAlarm)
                }
            }

            if let nextAlarmDesc = alarmManager.nextAlarmDescription {
                Section {
                    HStack {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(.orange)
                        Text("Next alarm \(nextAlarmDesc)")
                            .font(.subheadline)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }

            Section {
                ForEach(alarmManager.alarms) { alarm in
                    AlarmRowView(alarm: alarm) {
                        alarmManager.toggleAlarm(alarm)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAlarm = alarm
                    }
                }
                .onDelete { offsets in
                    alarmManager.deleteAlarms(at: offsets)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private var sleepModeActiveView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(.yellow)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Mode Active")
                    .font(.headline)
                Text("Alarm will sound even on silent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                alarmManager.stopLiveActivityAndAudio()
            } label: {
                Text("Stop")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.8), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    private func sleepModeButton(for alarm: Alarm) -> some View {
        Button {
            let volume = AudioService.shared.getCurrentVolume()
            if volume < volumeThreshold {
                pendingAlarmForSleepMode = alarm
                showLowVolumeAlert = true
            } else {
                alarmManager.startLiveActivity(for: alarm)
            }
        } label: {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.cyan)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Sleep Mode")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Alarm will sound even on silent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.15), Color.indigo.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

#Preview {
    ContentView()
        .environment(AlarmManager())
}
