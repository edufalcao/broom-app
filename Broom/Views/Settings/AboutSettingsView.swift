import AppKit
import SwiftUI

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ReleaseNotes.currentVersion
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            // App info (fixed)
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                Text("Broom")
                    .font(.title2.bold())

                VStack(spacing: 4) {
                    Text("Version \(version) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("A free, open-source macOS system cleaner")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("License: MIT")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()

            Divider()

            // Release notes (scrollable, fixed height)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("What's New in \(ReleaseNotes.currentVersion)")
                        .font(.headline)
                    Spacer()
                    Text("Released \(ReleaseNotes.currentReleaseDate)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(ReleaseNotes.sections) { section in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(section.title)
                                    .font(.subheadline.bold())

                                ForEach(section.items, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        Text(item)
                                            .font(.callout)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}
