import SwiftUI

struct CategoryRowView: View {
    let category: CleanCategory
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if category.isMixed {
                    // Mixed state: show a minus/dash checkbox
                    Button(action: onToggle) {
                        Image(systemName: "minus.square.fill")
                            .foregroundStyle(.tint)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                } else {
                    Toggle(isOn: Binding(
                        get: { category.isSelected },
                        set: { _ in onToggle() }
                    )) {
                        EmptyView()
                    }
                    .toggleStyle(.checkbox)
                }

                Image(systemName: category.icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)

                Text(category.name)
                    .foregroundStyle(.primary)

                Spacer()

                SizeLabel(bytes: category.totalSize)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name), \(SizeFormatter.format(category.totalSize))")
        .accessibilityValue(category.isMixed ? "Partially selected" : (category.isSelected ? "Selected" : "Not selected"))
        .accessibilityHint("Activate to view individual items")
    }
}
