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
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)

                    Text("Broom")
                        .font(.title.bold())

                    VStack(spacing: 4) {
                        Text("Version \(version) (\(buildNumber))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("A free, open-source macOS system cleaner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("License: MIT")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                releaseNotesSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private var releaseNotesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's New in \(ReleaseNotes.currentVersion)")
                .font(.headline)

            Text("Changes since \(ReleaseNotes.previousVersion), released on \(ReleaseNotes.currentReleaseDate).")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(ReleaseNotes.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.subheadline.bold())

                    ForEach(section.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(item)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
