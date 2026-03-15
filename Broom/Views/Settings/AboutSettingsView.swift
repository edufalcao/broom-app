import SwiftUI

struct AboutSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Broom")
                .font(.title.bold())

            Text("Version \(version)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("A free, open-source macOS system cleaner")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .frame(maxWidth: 200)

            Text("License: MIT")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
