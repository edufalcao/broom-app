import SwiftUI

struct CategoryRowView: View {
    let category: CleanCategory
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { category.isSelected },
                set: { _ in onToggle() }
            )) {
                EmptyView()
            }
            .toggleStyle(.checkbox)

            Image(systemName: category.icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(category.name)

            Spacer()

            SizeLabel(bytes: category.totalSize)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
