//
//  AboutView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Privacy Policy")
                        .font(.title.bold())

                    Text("Last updated: January 22, 2026")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Group {
                    Text("Overview")
                        .font(.headline)
                    Text("Gentle Alarm is an alarm clock app that respects your privacy. We do not collect, store, or transmit any personal data.")
                }

                Group {
                    Text("Data Collection")
                        .font(.headline)
                    Text("We do not collect any data. Specifically:")
                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("No personal information is collected")
                        BulletPoint("No usage analytics or tracking")
                        BulletPoint("No advertising or marketing data")
                        BulletPoint("No data is transmitted to external servers")
                    }
                }

                Group {
                    Text("Data Storage")
                        .font(.headline)
                    Text("All app data is stored locally on your device only:")
                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("Alarm settings (times, labels, sounds, repeat schedules) are stored in your device's local storage")
                        BulletPoint("This data never leaves your device")
                        BulletPoint("Uninstalling the app removes all stored data")
                    }
                }

                Group {
                    Text("Permissions")
                        .font(.headline)
                    Text("The app requests the following permissions:")
                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("Notifications: Required to alert you when alarms go off, including critical alerts to ensure alarms can wake you even when Do Not Disturb is enabled")
                        BulletPoint("Background Audio: Used to ensure alarms can sound reliably even when the app is in the background")
                    }
                }

                Group {
                    Text("Third-Party Services")
                        .font(.headline)
                    Text("This app does not use any third-party services, SDKs, or analytics platforms.")
                }

                Group {
                    Text("Contact")
                        .font(.headline)
                    Text("If you have questions about this privacy policy, please contact us at peter@nysoft.net.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("Gentle Alarm")
                            .font(.title2.bold())

                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text("Gentle Alarm wakes you gradually with a fade-in alarm sound. Your alarm data is stored locally on your device and is never transmitted anywhere.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    AboutView()
}

#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}
