import SwiftUI

struct LargeFileRowView: View {
    let file: LargeFile
    let onToggle: () -> Void
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { file.isSelected },
                set: { _ in onToggle() }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            Image(systemName: iconForFile(file.name))
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.directoryPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            Text(file.modifiedDate, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)

            SizeLabel(bytes: file.size)

            Button(action: onReveal) {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Reveal in Finder")
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(file.name), \(SizeFormatter.format(file.size))")
        .accessibilityHint(file.isSelected ? "Selected for deletion" : "Not selected")
    }

    private func iconForFile(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "dmg", "iso", "img": return "opticaldisc"
        case "zip", "tar", "gz", "bz2", "rar", "7z": return "doc.zipper"
        case "mp4", "mov", "avi", "mkv", "m4v": return "film"
        case "mp3", "wav", "aac", "flac", "m4a": return "music.note"
        case "app": return "app"
        case "pkg", "installer": return "shippingbox"
        default: return "doc"
        }
    }
}
