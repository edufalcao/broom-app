import SwiftUI

struct AppRowView: View {
    let app: InstalledApp
    var sortOrder: UninstallerViewModel.SortOrder = .name

    private var secondaryText: String {
        switch sortOrder {
        case .lastUsed:
            if let date = app.lastUsedDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return formatter.localizedString(for: date, relativeTo: Date())
            }
            return "Unknown"
        case .name, .size:
            return app.formattedTotalSize
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(icon: app.icon, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)

                if app.isProtected {
                    Text("System App")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text(secondaryText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .opacity(app.isProtected ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.name), \(secondaryText)\(app.isProtected ? ", System App" : "")")
    }
}
