import SwiftUI

struct ProjectArtifactsView: View {
    @Bindable var viewModel: ProjectArtifactsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView

            case .scanning(let path, let found):
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Scanning for project artifacts...")
                        .font(.headline)
                    Text("Found \(found) so far")
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

            case .cleaning(let cleaned, let total):
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Cleaning...")
                        .font(.headline)
                    Text("\(cleaned) of \(total)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)

            case .done(let freed, let cleaned):
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Freed \(SizeFormatter.format(freed))")
                        .font(.title3.bold())
                    Text("\(cleaned) artifacts moved to Trash")
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
            "Move \(viewModel.selectedArtifacts.count) artifacts to Trash?",
            isPresented: $viewModel.showCleanConfirmation
        ) {
            Button("Move to Trash (\(SizeFormatter.format(viewModel.selectedSize)))", role: .destructive) {
                viewModel.confirmClean()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Build artifacts are regenerated on the next build. Active projects are re-checked before deletion.")
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Reclaim build artifacts from your projects")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("node_modules, target, .build and other regenerable outputs are grouped by project. Anything modified in the last few days stays deselected.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)

            Button(action: { viewModel.startScan() }) {
                Label("Scan Projects", systemImage: "magnifyingglass")
                    .frame(minWidth: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("artifacts-scan-button")

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Found \(viewModel.allArtifacts.count) artifacts in \(viewModel.groups.count) projects")
                        .font(.title3.bold())
                    Text("Total: \(SizeFormatter.format(viewModel.totalSize)) — active projects start deselected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            Divider()

            if viewModel.groups.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No project artifacts found",
                    subtitle: "Nothing regenerable was found in your configured search roots."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.groups) { group in
                            groupHeader(group)
                            ForEach(group.artifacts) { artifact in
                                artifactRow(artifact)
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            HStack {
                Text("Selected: \(viewModel.selectedArtifacts.count) (\(SizeFormatter.format(viewModel.selectedSize)))")
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
                .disabled(viewModel.selectedArtifacts.isEmpty)
            }
            .padding()
        }
    }

    private func groupHeader(_ group: ProjectGroup) -> some View {
        let allSelected = group.artifacts.allSatisfy(\.isSelected)
        return HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            Text(group.name)
                .font(.headline)
            Text(group.path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Spacer()
            Text(SizeFormatter.format(group.totalSize))
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("", isOn: Binding(
                get: { allSelected },
                set: { newValue in viewModel.setGroup(group, selected: newValue) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private func artifactRow(_ artifact: ProjectArtifact) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { artifact.isSelected },
                set: { _ in viewModel.toggleArtifact(artifact.id) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(artifact.name)
                        .font(.system(.body, design: .monospaced))
                    if artifact.recency != .old {
                        Text(artifact.recency.label)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                Text(artifact.path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(artifact.formattedSize)
                .font(.callout.monospacedDigit())

            Button {
                viewModel.revealInFinder(artifact)
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Reveal in Finder")
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleArtifact(artifact.id) }
    }
}
