import SwiftUI

struct LargeFilesView: View {
    @Bindable var viewModel: LargeFilesViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView

            case .scanning(let found, let path):
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning for large files...")
                        .font(.headline)
                    Text("Found \(found) files so far")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
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
                    Text("\(cleaned) files moved to Trash")
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
        .confirmationDialog(
            "Move \(viewModel.selectedCount) files to Trash?",
            isPresented: $viewModel.showCleanConfirmation
        ) {
            Button("Move to Trash (\(SizeFormatter.format(viewModel.selectedSize)))", role: .destructive) {
                viewModel.confirmClean()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected files will be moved to Trash.")
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Find large files in your home directory")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Minimum size:")
                    .foregroundStyle(.secondary)
                Picker("", selection: $viewModel.minimumSize) {
                    ForEach(LargeFilesViewModel.MinimumSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .frame(width: 100)
            }

            Button(action: { viewModel.startScan() }) {
                Label("Scan for Large Files", systemImage: "doc.badge.arrow.up")
                    .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Found \(viewModel.files.count) large files")
                        .font(.title3.bold())
                    Text("Total: \(SizeFormatter.format(viewModel.totalSize))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Sort:", selection: $viewModel.sortOrder) {
                    ForEach(LargeFilesViewModel.SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding()

            Divider()

            // File list
            if viewModel.files.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No large files found",
                    subtitle: "No files larger than \(viewModel.minimumSize.label) were found."
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

            // Footer
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
