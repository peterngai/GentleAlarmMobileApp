//
//  AboutView.swift
//  GentleAlarmMobileApp
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let privacyPolicyURL = URL(string: "https://peterngai.github.io/GentleAlarmMobileApp/PRIVACY")!
    private let githubURL = URL(string: "https://github.com/peterngai/GentleAlarmMobileApp")!

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
                    Link(destination: privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: githubURL) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
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
