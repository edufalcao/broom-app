import SwiftUI

struct ScanResultsView: View {
    @Bindable var viewModel: ScanViewModel
    @State private var selectedCategoryID: UUID?

    var body: some View {
        NavigationStack {
            resultsList
                .navigationDestination(item: $selectedCategoryID) { categoryID in
                    if let category = viewModel.scanResult?.categories.first(where: { $0.id == categoryID }) {
                        CategoryDetailView(
                            category: category,
                            viewModel: viewModel,
                            onBack: { selectedCategoryID = nil }
                        )
                        .navigationBarBackButtonHidden()
                    }
                }
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
                        HStack {
                            Toggle("Select All", isOn: Binding(
                                get: { result.categories.allSatisfy(\.isSelected) },
                                set: { newValue in
                                    if newValue { viewModel.selectAll() }
                                    else { viewModel.deselectAll() }
                                }
                            ))
                            .toggleStyle(.checkbox)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)

                        Divider()

                        ForEach(result.categories) { category in
                            CategoryRowView(
                                category: category,
                                onToggle: { viewModel.toggleCategory(category.id) },
                                onTap: { selectedCategoryID = category.id }
                            )
                            .padding(.horizontal)

                            Divider().padding(.leading, 52)
                        }

                        if result.categories.contains(where: { $0.name == "App Leftovers" }) {
                            Text("Only stale, high-confidence leftovers are shown. Recently active or ambiguous items are excluded for safety.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
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
}
