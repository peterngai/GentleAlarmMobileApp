//
//  AudioService.swift
//  GentleAlarmMobileApp
//

import Foundation
import AVFoundation

@Observable
final class AudioService {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var alarmCheckTimer: Timer?
    private var currentVolume: Float = 0.0
    private var targetVolume: Float = 1.0
    private var volumeIncrement: Float = 0.0
    private var wasInterrupted = false

    // Background audio state
    private(set) var isBackgroundAudioActive = false
    private var pendingAlarmTime: Date?
    private var pendingAlarmSound: AlarmSound?
    private var pendingFadeInDuration: Int?
    private var onAlarmTrigger: (() -> Void)?

    // Failsafe alarm state
    private var failsafeTimer: Timer?
    private var failsafeEnabled = false
    private var failsafeMinutes: Int = 5
    private(set) var isFailsafeActive = false

    // Pending failsafe settings for background alarm
    private var pendingFailsafeEnabled: Bool?
    private var pendingFailsafeMinutes: Int?

    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    var isAmbientPlaying: Bool {
        ambientPlayer?.isPlaying ?? false
    }

    private init() {
        configureAudioSession()
        setupInterruptionHandling()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use .playback for background audio, .duckOthers to lower other audio
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Audio was interrupted (e.g., phone call)
            wasInterrupted = true
        case .ended:
            // Interruption ended, resume if we were playing
            if wasInterrupted {
                wasInterrupted = false
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        configureAudioSession()
                        audioPlayer?.play()
                    }
                }
            }
        @unknown default:
            break
        }
    }

    func playAlarm(sound: AlarmSound, fadeInDuration: Int, failsafeEnabled: Bool = false, failsafeMinutes: Int = 5) {
        stopAlarm()
        configureAudioSession()

        // Store failsafe settings
        self.failsafeEnabled = failsafeEnabled
        self.failsafeMinutes = failsafeMinutes
        self.isFailsafeActive = false

        // Try to load bundled sound file, fall back to system sound
        guard let url = getSoundURL(for: sound) else {
            print("Could not find sound file for: \(sound.rawValue)")
            playSystemSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = 0.0  // Start at zero
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            startFadeIn(duration: fadeInDuration)

            // Start failsafe timer if enabled
            if failsafeEnabled {
                startFailsafeTimer()
            }
        } catch {
            print("Failed to play audio: \(error)")
            playSystemSound()
        }
    }

    private func getSoundURL(for sound: AlarmSound) -> URL? {
        // First try to find bundled sound file
        let extensions = ["m4a", "caf", "mp3", "wav", "aiff"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) {
                return url
            }
        }

        // Fall back to a default system sound path if available
        // iOS doesn't expose system sounds directly, so we'll use a bundled default
        if let url = Bundle.main.url(forResource: "default_alarm", withExtension: "m4a") {
            return url
        }

        return nil
    }

    private func playSystemSound() {
        // Fallback: play a system sound using AudioServicesPlaySystemSound
        // Sound ID 1005 is a default alarm-like sound
        AudioServicesPlayAlertSound(SystemSoundID(1005))

        // Set up a timer to repeat the system sound
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard self?.isPlaying != false else { return }
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }

    private var fadeStartTime: Date?
    private var fadeDurationSeconds: TimeInterval = 0

    // Exponent for volume curve: 1.0 = linear, 2.0 = quadratic, 3.0 = cubic
    // Higher values = slower start, faster finish
    private let volumeCurveExponent: Double = 2.5

    private func startFadeIn(duration: Int) {
        // Time-based fade-in: calculate volume based on elapsed time
        // This ensures consistent fade even if timer intervals are inconsistent
        fadeDurationSeconds = Double(duration * 60)
        fadeStartTime = Date()
        currentVolume = 0.0

        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] timer in
            guard let self = self,
                  let startTime = self.fadeStartTime else {
                timer.invalidate()
                return
            }

            // Calculate volume based on elapsed time
            let elapsed = Date().timeIntervalSince(startTime)
            let linearProgress = min(elapsed / self.fadeDurationSeconds, 1.0)

            // Apply exponential curve: progress^exponent
            // This creates a gentle start that accelerates over time
            // Example with exponent 2.5:
            //   10% time elapsed → ~3% volume
            //   25% time elapsed → ~10% volume
            //   50% time elapsed → ~18% volume
            //   75% time elapsed → ~49% volume
            //   100% time elapsed → 100% volume
            let exponentialProgress = pow(linearProgress, self.volumeCurveExponent)
            self.currentVolume = Float(exponentialProgress) * self.targetVolume

            self.audioPlayer?.volume = self.currentVolume

            if linearProgress >= 1.0 {
                // Fade complete - lock volume at maximum
                self.currentVolume = self.targetVolume
                self.audioPlayer?.volume = self.targetVolume
                self.fadeStartTime = nil
                self.fadeCompleted = true
                timer.invalidate()
            }
        }

        // Keep timer running in common run loop mode for better background execution
        if let timer = fadeTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // Flag to track if fade has completed (volume should stay at max)
    private var fadeCompleted = false

    /// Ensures volume stays at target level - call this periodically if needed
    func ensureMaxVolume() {
        if fadeCompleted, let player = audioPlayer, player.isPlaying {
            player.volume = targetVolume
        }
    }

    func stopAlarm() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        fadeStartTime = nil
        fadeCompleted = false
        failsafeTimer?.invalidate()
        failsafeTimer = nil
        failsafeEnabled = false
        isFailsafeActive = false
        audioPlayer?.stop()
        audioPlayer = nil
        currentVolume = 0.0
    }

    // MARK: - Failsafe Alarm

    private func startFailsafeTimer() {
        failsafeTimer?.invalidate()

        let failsafeSeconds = Double(failsafeMinutes * 60)
        print("Failsafe timer started: will trigger in \(failsafeMinutes) minutes")

        failsafeTimer = Timer.scheduledTimer(withTimeInterval: failsafeSeconds, repeats: false) { [weak self] _ in
            self?.triggerFailsafeAlarm()
        }

        // Keep timer running in common run loop mode for background execution
        if let timer = failsafeTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func triggerFailsafeAlarm() {
        print("Failsafe alarm triggered!")

        isFailsafeActive = true

        // Stop the fade timer if still running
        fadeTimer?.invalidate()
        fadeTimer = nil
        fadeStartTime = nil
        fadeCompleted = true

        // Stop current audio player
        audioPlayer?.stop()
        audioPlayer = nil

        // Load and play the clock-alarm sound at full volume
        guard let url = getSoundURL(for: .clockAlarm) else {
            print("Could not find failsafe sound file (clock-alarm)")
            // Fallback to system sound at full volume
            playSystemSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = 1.0  // Full volume immediately
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            currentVolume = 1.0
            print("Failsafe alarm playing at full volume")
        } catch {
            print("Failed to play failsafe audio: \(error)")
            playSystemSound()
        }
    }

    func previewSound(_ sound: AlarmSound) {
        stopAlarm()
        configureAudioSession()

        guard let url = getSoundURL(for: sound) else {
            AudioServicesPlayAlertSound(SystemSoundID(1005))
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0  // Play once
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            // Stop after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.stopAlarm()
            }
        } catch {
            print("Failed to preview sound: \(error)")
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }
    }

    // MARK: - Background Audio for Live Activities

    /// Starts background ambient audio to keep the app alive until the alarm time.
    /// When the alarm time is reached, it automatically transitions to the alarm sound.
    func startBackgroundAudio(
        until alarmTime: Date,
        alarmSound: AlarmSound,
        fadeInDuration: Int,
        failsafeEnabled: Bool = false,
        failsafeMinutes: Int = 5,
        onTrigger: @escaping () -> Void
    ) {
        // Stop any existing audio
        stopBackgroundAudio()
        stopAlarm()

        // Store pending alarm info
        pendingAlarmTime = alarmTime
        pendingAlarmSound = alarmSound
        pendingFadeInDuration = fadeInDuration
        pendingFailsafeEnabled = failsafeEnabled
        pendingFailsafeMinutes = failsafeMinutes
        onAlarmTrigger = onTrigger

        // Configure audio session for background playback
        configureAudioSession()

        // Start playing silent/ambient audio
        startAmbientAudio()

        // Start timer to check for alarm time
        startAlarmCheckTimer()

        isBackgroundAudioActive = true
        print("Background audio started, alarm scheduled for \(alarmTime)")
    }

    /// Stops the background audio and clears the pending alarm
    func stopBackgroundAudio() {
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = nil

        ambientPlayer?.stop()
        ambientPlayer = nil

        pendingAlarmTime = nil
        pendingAlarmSound = nil
        pendingFadeInDuration = nil
        pendingFailsafeEnabled = nil
        pendingFailsafeMinutes = nil
        onAlarmTrigger = nil

        isBackgroundAudioActive = false
        print("Background audio stopped")
    }

    private func startAmbientAudio() {
        // Try to load a silent audio file, or create one programmatically
        // First, check if we have a bundled silent/ambient audio file
        if let url = Bundle.main.url(forResource: "silence", withExtension: "m4a") ??
                     Bundle.main.url(forResource: "ambient", withExtension: "m4a") {
            do {
                ambientPlayer = try AVAudioPlayer(contentsOf: url)
                ambientPlayer?.numberOfLoops = -1  // Loop indefinitely
                ambientPlayer?.volume = 0.01  // Nearly silent
                ambientPlayer?.prepareToPlay()
                ambientPlayer?.play()
                return
            } catch {
                print("Failed to play ambient audio file: \(error)")
            }
        }

        // Fallback: Use a very short system sound and replay it periodically
        // This is less ideal but keeps the audio session active
        playMinimalAudio()
    }

    private func playMinimalAudio() {
        // Play the alarm sound at near-zero volume to keep audio session alive
        // This is a fallback if no silent audio file is available
        if let url = getSoundURL(for: .morningBirds) {
            do {
                ambientPlayer = try AVAudioPlayer(contentsOf: url)
                ambientPlayer?.numberOfLoops = -1
                ambientPlayer?.volume = 0.001  // Essentially inaudible
                ambientPlayer?.prepareToPlay()
                ambientPlayer?.play()
            } catch {
                print("Failed to create minimal audio player: \(error)")
            }
        }
    }

    private func startAlarmCheckTimer() {
        // Check every second if it's time for the alarm
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self,
                  let alarmTime = self.pendingAlarmTime else {
                timer.invalidate()
                return
            }

            let now = Date()
            if now >= alarmTime {
                timer.invalidate()
                self.triggerScheduledAlarm()
            }
        }

        // Keep timer running in common run loop mode for background execution
        if let timer = alarmCheckTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func triggerScheduledAlarm() {
        guard let sound = pendingAlarmSound,
              let fadeIn = pendingFadeInDuration else {
            return
        }

        // Capture failsafe settings before clearing
        let failsafe = pendingFailsafeEnabled ?? false
        let failsafeMins = pendingFailsafeMinutes ?? 5

        // Stop ambient audio
        ambientPlayer?.stop()
        ambientPlayer = nil

        // Clear pending state
        let callback = onAlarmTrigger
        pendingAlarmTime = nil
        pendingAlarmSound = nil
        pendingFadeInDuration = nil
        pendingFailsafeEnabled = nil
        pendingFailsafeMinutes = nil
        onAlarmTrigger = nil
        isBackgroundAudioActive = false

        // Play the actual alarm with failsafe settings
        playAlarm(sound: sound, fadeInDuration: fadeIn, failsafeEnabled: failsafe, failsafeMinutes: failsafeMins)

        // Notify the manager
        DispatchQueue.main.async {
            callback?()
        }

        print("Alarm triggered from background audio!")
    }

    /// Updates the pending alarm time (useful for snooze or schedule changes)
    func updatePendingAlarmTime(_ newTime: Date) {
        pendingAlarmTime = newTime
    }

    /// Check if there's a pending alarm and return the time
    var pendingAlarm: Date? {
        return pendingAlarmTime
    }
}
