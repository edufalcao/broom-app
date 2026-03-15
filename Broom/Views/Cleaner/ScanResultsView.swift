import SwiftUI

struct ScanResultsView: View {
    @Bindable var viewModel: ScanViewModel
    @State private var selectedCategory: CleanCategory?
    @State private var expandedOrphanIDs: Set<UUID> = []

    var body: some View {
        if let selectedCategory {
            CategoryDetailView(
                category: selectedCategory,
                viewModel: viewModel,
                onBack: { self.selectedCategory = nil }
            )
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                if let result = viewModel.scanResult {
                    if result.totalSize == 0 {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "No junk found!",
                            subtitle: "Your system is clean."
                        )
                    } else {
                        Text("Found \(SizeFormatter.format(result.totalSize)) of junk")
                            .font(.title2.bold())
                        Text("Scanned in \(String(format: "%.1f", result.scanDuration))s")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding()

            Divider()

            // Categories
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let result = viewModel.scanResult {
                        ForEach(result.categories) { category in
                            CategoryRowView(
                                category: category,
                                onToggle: { viewModel.toggleCategory(category.id) },
                                onTap: { selectedCategory = category }
                            )
                            .padding(.horizontal)

                            Divider().padding(.leading, 52)
                        }

                        if !result.orphanedApps.isEmpty {
                            Divider()
                                .padding(.vertical, 8)

                            Text("App Leftovers")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 4)

                            ForEach(result.orphanedApps) { orphan in
                                orphanRow(orphan)
                                    .padding(.horizontal)
                                if expandedOrphanIDs.contains(orphan.id) {
                                    orphanLocations(orphan)
                                        .padding(.horizontal)
                                        .padding(.bottom, 8)
                                }
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // Footer
            HStack {
                Text("Selected: \(SizeFormatter.format(viewModel.selectedSize))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: { viewModel.reset() }) {
                    Label("Re-scan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button(action: { viewModel.startClean() }) {
                    Label("Clean Selected", systemImage: "trash")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedItems == 0)
            }
            .padding()
        }
    }

    private func orphanRow(_ orphan: OrphanedApp) -> some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { orphan.isSelected },
                set: { _ in viewModel.toggleOrphan(orphan.id) }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            Image(systemName: "archivebox")
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(orphan.appName)
                    ConfidenceBadge(confidence: orphan.confidence)
                }
                Text("\(orphan.locationCount) leftover locations")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            SizeLabel(bytes: orphan.totalSize)

            Image(systemName: expandedOrphanIDs.contains(orphan.id) ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if expandedOrphanIDs.contains(orphan.id) {
                expandedOrphanIDs.remove(orphan.id)
            } else {
                expandedOrphanIDs.insert(orphan.id)
            }
        }
    }

    private func orphanLocations(_ orphan: OrphanedApp) -> some View {
        VStack(spacing: 0) {
            ForEach(orphan.locations) { location in
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { location.isSelected },
                        set: { _ in viewModel.toggleOrphanLocation(location.id, in: orphan.id) }
                    )) {
                        EmptyView()
                    }
                    .toggleStyle(.checkbox)

                    Image(systemName: "folder")
                        .frame(width: 20)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .lineLimit(1)
                        Text(location.path.path)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }

                    Spacer()

                    SizeLabel(bytes: location.size)
                }
                .padding(.vertical, 4)

                if location.id != orphan.locations.last?.id {
                    Divider().padding(.leading, 40)
                }
            }
        }
    }
}
