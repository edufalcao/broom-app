import SwiftUI

struct AppDetailView: View {
    let app: InstalledApp
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
            if app.associatedFiles.isEmpty {
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

                        ForEach(app.associatedFiles) { file in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .frame(width: 20)
                                    .foregroundStyle(.secondary)
                                Text(file.name)
                                    .lineLimit(1)
                                Spacer()
                                SizeLabel(bytes: file.size)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)

                            Divider().padding(.leading, 40)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Total: \(app.formattedTotalSize)")
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
                }
            }
            .padding()
        }
    }
}
