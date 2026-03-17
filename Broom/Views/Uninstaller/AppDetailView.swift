import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
    let onToggleBundle: () -> Void
    let onToggleAssociatedFile: (UUID) -> Void
    let onUninstall: () -> Void

    private var groupedFiles: [(key: String, items: [CleanableItem])] {
        let grouped = Dictionary(grouping: app.associatedFiles) { file in
            file.source?.rawValue ?? "Other"
        }
        let order: [String] = UninstallArtifactSource.allCases.map(\.rawValue) + ["Other"]
        return order.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (key: key, items: items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 8) {
                AppIconView(icon: app.icon, size: 64)

                Text(app.name)
                    .font(.title2.bold())

                if !app.version.isEmpty {
                    Text("Version \(app.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lastUsed = app.lastUsedDate {
                    Text("Last used: \(lastUsed, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(app.bundleIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding()

            Divider()

            // Associated files
            if !app.associatedFilesLoaded {
                VStack(spacing: 8) {
                    Spacer()
                    Text("Loading associated files...")
                        .foregroundStyle(.secondary)
                    ProgressView()
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // The .app bundle
                        HStack {
                            Toggle(isOn: Binding(
                                get: { app.bundleIsSelected },
                                set: { _ in onToggleBundle() }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(.checkbox)

                            Image(systemName: "app.fill")
                                .frame(width: 20)
                                .foregroundStyle(.secondary)
                            Text("\(app.name).app")
                            Spacer()
                            SizeLabel(bytes: app.bundleSize)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)

                        Divider().padding(.leading, 40)

                        if app.associatedFiles.isEmpty {
                            HStack {
                                Text("No additional support files found")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        } else {
                            ForEach(groupedFiles, id: \.key) { group in
                                ArtifactGroupView(
                                    title: group.key,
                                    items: group.items,
                                    onToggleItem: onToggleAssociatedFile,
                                    onToggleAll: {
                                        for item in group.items {
                                            onToggleAssociatedFile(item.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Selected: \(app.formattedSelectedSize)")
                    .font(.subheadline.bold())

                Spacer()

                if app.isProtected {
                    Text(app.isAppleApp ? "Apple apps cannot be uninstalled" : "System apps cannot be uninstalled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button(action: onUninstall) {
                        Label("Uninstall", systemImage: "trash")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(app.selectedItemCount == 0)
                }
            }
            .padding()
        }
    }
}

private struct ArtifactGroupView: View {
    let title: String
    let items: [CleanableItem]
    let onToggleItem: (UUID) -> Void
    let onToggleAll: () -> Void

    private var allSelected: Bool { items.allSatisfy(\.isSelected) }
    private var groupSize: Int64 { items.reduce(0) { $0 + $1.size } }

    var body: some View {
        // Section header
        HStack(spacing: 6) {
            Toggle(isOn: Binding(
                get: { allSelected },
                set: { _ in onToggleAll() }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text("\(items.count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()

            Text(SizeFormatter.format(groupSize))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

        ForEach(items) { file in
            HStack {
                Toggle(isOn: Binding(
                    get: { file.isSelected },
                    set: { _ in onToggleItem(file.id) }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)

                Image(systemName: "folder.fill")
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .lineLimit(1)
                    Text(file.path.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                Spacer()
                SizeLabel(bytes: file.size)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider().padding(.leading, 40)
        }
    }
}
