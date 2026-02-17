# Gentle Alarm Mobile App

A feature-rich iOS alarm clock application built with SwiftUI, featuring gradual volume fade-in, Live Activities support, and a failsafe alarm system.

## Features

- **Gradual Wake-Up**: Exponential volume curve (power 2.5) for a gentler wake experience
- **Live Activities**: Dynamic Island and Lock Screen integration for real-time countdown
- **Failsafe Alarm**: Secondary high-volume alarm triggers if the primary alarm is ignored
- **Flexible Scheduling**: One-time, daily, weekdays, weekends, or custom day selection
- **Multiple Alarm Sounds**: 6 selectable sounds including nature and classic tones
- **Snooze Support**: Configurable snooze duration (1, 5, 10, or 15 minutes)
- **Background Reliability**: Audio session management keeps alarms firing even when app is backgrounded

## Prerequisites

- **macOS**: Ventura 14.0 or later
- **Xcode**: 15.0 or later
- **iOS Device/Simulator**: iOS 16.0+ (for Live Activities support)
- **Apple Developer Account**: Required for device deployment and code signing

## Project Structure

```
GentleAlarmMobileApp/
├── GentleAlarmMobileApp/           # Main app target
│   ├── Models/                     # Data models (Alarm, AlarmSound, etc.)
│   ├── ViewModels/                 # AlarmManager state management
│   ├── Views/                      # SwiftUI views
│   ├── Services/                   # Audio and Notification services
│   └── Resources/Sounds/           # Bundled alarm sounds
├── AlarmWidgetExtension/           # Widget for Dynamic Island
├── GentleAlarmMobileAppTests/      # Unit tests
└── GenerateIcon.swift              # App icon generation script
```

## Building the Project

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/GentleAlarmMobileApp.git
cd GentleAlarmMobileApp
```

### 2. Open in Xcode

```bash
open GentleAlarmMobileApp.xcodeproj
```

### 3. Configure Code Signing

1. Select the `GentleAlarmMobileApp` project in the Navigator
2. Select each target (`GentleAlarmMobileApp`, `AlarmWidgetExtension`)
3. Under **Signing & Capabilities**, select your Development Team
4. Update the Bundle Identifier if needed (currently `com.nysoft.gentlealarm`)

### 4. Build and Run

**For Simulator:**
```bash
xcodebuild -project GentleAlarmMobileApp.xcodeproj \
           -scheme GentleAlarmMobileApp \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build
```

**For Device:**
```bash
xcodebuild -project GentleAlarmMobileApp.xcodeproj \
           -scheme GentleAlarmMobileApp \
           -destination 'generic/platform=iOS' \
           build
```

Or simply press `Cmd + R` in Xcode.

### 5. Run Tests

```bash
xcodebuild test -project GentleAlarmMobileApp.xcodeproj \
                -scheme GentleAlarmMobileApp \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Deployment

### TestFlight Deployment

1. **Archive the App**
   - In Xcode: Product > Archive
   - Or via command line:
   ```bash
   xcodebuild -project GentleAlarmMobileApp.xcodeproj \
              -scheme GentleAlarmMobileApp \
              -destination 'generic/platform=iOS' \
              -archivePath build/GentleAlarmMobileApp.xcarchive \
              archive
   ```

2. **Export for Distribution**
   ```bash
   xcodebuild -exportArchive \
              -archivePath build/GentleAlarmMobileApp.xcarchive \
              -exportPath build/export \
              -exportOptionsPlist ExportOptions.plist
   ```

3. **Upload to App Store Connect**
   - Open Xcode Organizer (Window > Organizer)
   - Select the archive and click "Distribute App"
   - Choose "App Store Connect" > "Upload"
   - Or use `xcrun altool` / Transporter app

### App Store Deployment

1. Complete all App Store Connect metadata (screenshots, description, etc.)
2. Submit the uploaded build for review
3. Ensure you have appropriate privacy policy for notification permissions

## Configuration

### Info.plist Settings

The app requires these key configurations (already set):

```xml
<!-- Live Activities Support -->
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>

<!-- Background Audio -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Notification Categories

The app registers these notification actions:
- **ALARM_CATEGORY**: Main alarm notification category
- **SNOOZE_ACTION**: Snooze the alarm
- **DISMISS_ACTION**: Dismiss the alarm

## Intricacies & Important Considerations

### Background Audio Reliability

The app uses a clever technique to maintain background execution: it plays a near-silent audio file (`silence.m4a`) on loop. This keeps the app process alive so timers can fire accurately. Without this, iOS would suspend the app and alarms could be delayed.

**Key file:** `AudioService.swift` - `startBackgroundAudio()`

### Exponential Volume Fade-In

Rather than a linear volume increase, the app uses an exponential curve with exponent 2.5:
```swift
let volume = pow(progress, 2.5)
```
This creates a more natural wake-up experience where volume increases slowly at first, then more rapidly.

### Failsafe Alarm System

If the user doesn't acknowledge the alarm within a configurable timeout (default: 5 minutes), a failsafe alarm triggers at maximum volume using the `clock-alarm.m4a` sound. This ensures users don't oversleep.

**Key file:** `AudioService.swift` - `startFailsafeTimer()`

### Live Activity Lifecycle

Live Activities require careful state management:
- Activities must be ended explicitly to prevent orphaned Dynamic Island displays
- The app updates activity state every 30 seconds while an alarm is pending
- When the alarm fires, the activity transitions to a "ringing" state

**Key file:** `AlarmManager.swift` - `startLiveActivity()`, `endLiveActivity()`

### Notification Permission Handling

The app requests notification permissions on first launch. If denied:
- Alarms will still fire within the app
- Background/locked screen notifications won't appear
- Consider prompting users to enable in Settings if denied

### Timer Precision

The alarm check timer uses `.common` RunLoop mode:
```swift
Timer.scheduledTimer(...).tolerance = 0.5
RunLoop.current.add(timer, forMode: .common)
```
This ensures timers fire even during UI interactions like scrolling.

### Audio Session Configuration

The audio session is configured for playback with ducking:
```swift
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
```
This means other audio (music, podcasts) will be lowered when the alarm plays.

### Data Persistence

Alarms are stored in UserDefaults as JSON under the key `"savedAlarms"`. For production apps with many alarms, consider migrating to Core Data or SwiftData.

### Widget Extension App Groups

If you need to share data between the main app and widget extension, you'll need to:
1. Enable App Groups capability on both targets
2. Use a shared UserDefaults suite:
   ```swift
   UserDefaults(suiteName: "group.com.nysoft.gentlealarm")
   ```

## Generating the App Icon

A Swift script is included to programmatically generate the app icon:

```bash
swift GenerateIcon.swift
```

This creates a 1024x1024 PNG with the app's signature dark gradient and warm glow design.

## Troubleshooting

### Alarms Not Firing in Background

1. Ensure background audio is enabled in capabilities
2. Check that `silence.m4a` exists in the bundle
3. Verify audio session is properly configured

### Live Activities Not Showing

1. Confirm iOS 16.1+ on device
2. Check Live Activities is enabled in Settings > [App Name]
3. Verify `NSSupportsLiveActivities` is `true` in Info.plist

### Code Signing Issues

1. Ensure valid Apple Developer membership
2. Check that all targets have the same Team ID
3. Try: Product > Clean Build Folder, then rebuild

### Widget Not Appearing

1. Long-press home screen > tap "+" to add widget
2. Search for "GentleAlarmMobileApp"
3. Ensure widget extension target is included in build scheme

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]
