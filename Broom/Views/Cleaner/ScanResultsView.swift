import SwiftUI

struct ScanResultsView: View {
    @Bindable var viewModel: ScanViewModel
    @State private var selectedCategory: CleanCategory?

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
