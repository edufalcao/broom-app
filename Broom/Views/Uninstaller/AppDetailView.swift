import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
    let onToggleBundle: () -> Void
    let onToggleAssociatedFile: (UUID) -> Void
    let onUninstall: () -> Void

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
                            ForEach(app.associatedFiles) { file in
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { file.isSelected },
                                        set: { _ in onToggleAssociatedFile(file.id) }
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
