import SwiftUI

struct InstallersView: View {
    @Bindable var viewModel: InstallersViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView

            case .scanning(let found):
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning for installer files...")
                        .font(.headline)
                    Text("Found \(found) so far")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Cancel") { viewModel.cancelScan() }
                        .buttonStyle(.bordered)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

            case .results:
                resultsView

            case .done(let freed, let cleaned):
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Freed \(SizeFormatter.format(freed))")
                        .font(.title3.bold())
                    Text("\(cleaned) installers moved to Trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Scan Again") { viewModel.reset() }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
        .confirmationDialog(
            "Move \(viewModel.selectedCount) installers to Trash?",
            isPresented: $viewModel.showCleanConfirmation
        ) {
            Button("Move to Trash (\(SizeFormatter.format(viewModel.selectedSize)))", role: .destructive) {
                viewModel.confirmClean()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Installer files can be re-downloaded if you need them again.")
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shippingbox.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Find leftover installer files in Downloads, Desktop, and Documents")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Text("Disk images, packages, and archives containing apps. Files newer than a few days are skipped so you never lose an installer you just downloaded.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Button(action: { viewModel.startScan() }) {
                Label("Scan for Installers", systemImage: "magnifyingglass")
                    .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("installers-scan-button")

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Found \(viewModel.files.count) installer files")
                        .font(.title3.bold())
                    Text("Total: \(SizeFormatter.format(viewModel.totalSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            Divider()

            if viewModel.files.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No installer files found",
                    subtitle: "Nothing old enough to offer was found in your scanned folders."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.sortedFiles) { file in
                            LargeFileRowView(
                                file: file,
                                onToggle: { viewModel.toggleFile(file.id) },
                                onReveal: { viewModel.revealInFinder(file) }
                            )
                            .padding(.horizontal)
                            Divider().padding(.leading, 40)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            HStack {
                Text("Selected: \(viewModel.selectedCount) files (\(SizeFormatter.format(viewModel.selectedSize)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: { viewModel.reset() }) {
                    Label("Re-scan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.startClean() }) {
                    Label("Move to Trash", systemImage: "trash")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedCount == 0)
            }
            .padding()
        }
    }
}
