import SwiftUI

struct CategoryDetailView: View {
    let category: CleanCategory
    @Bindable var viewModel: ScanViewModel
    let onBack: () -> Void

    private var liveCategory: CleanCategory? {
        viewModel.scanResult?.categories.first { $0.id == category.id }
    }

    private var hasConfidenceItems: Bool {
        guard let cat = liveCategory else { return false }
        return cat.items.contains { $0.confidence != nil }
    }

    private var standardItems: [CleanableItem] {
        guard let cat = liveCategory else { return [] }
        if !hasConfidenceItems { return cat.items }
        return cat.items.filter { $0.confidence != .low }
    }

    private var lowConfidenceItems: [CleanableItem] {
        guard let cat = liveCategory, hasConfidenceItems else { return [] }
        return cat.items.filter { $0.confidence == .low }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                        Text(category.name)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                if let cat = liveCategory {
                    Text(SizeFormatter.format(cat.totalSize))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Select All
            if let cat = liveCategory {
                HStack {
                    Toggle("Select All", isOn: Binding(
                        get: { cat.isSelected },
                        set: { _ in viewModel.toggleCategory(category.id) }
                    ))
                    .toggleStyle(.checkbox)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Items
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(standardItems) { item in
                            itemRow(item)
                        }

                        if !lowConfidenceItems.isEmpty {
                            HStack {
                                Text("Lower confidence")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

                            ForEach(lowConfidenceItems) { item in
                                itemRow(item)
                                    .opacity(0.7)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                // Footer
                HStack {
                    Text("Selected: \(SizeFormatter.format(cat.selectedSize)) of \(SizeFormatter.format(cat.totalSize))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            }
        }
    }

    private func itemRow(_ item: CleanableItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { item.isSelected },
                    set: { _ in viewModel.toggleItem(item.id, in: category.id) }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .lineLimit(1)
                        if let confidence = item.confidence {
                            ConfidenceBadge(confidence: confidence)
                        }
                    }
                    Text(item.path.path)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .help(item.path.path)
                }

                Spacer()

                SizeLabel(bytes: item.size)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider().padding(.leading, 40)
        }
    }
}
