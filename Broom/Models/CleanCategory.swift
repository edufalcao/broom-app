import Foundation

struct CleanCategory: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    var items: [CleanableItem]
    var isSelected: Bool
    let defaultSelected: Bool

    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var itemCount: Int { items.count }
    var selectedCount: Int { items.filter(\.isSelected).count }
    var isMixed: Bool { selectedCount > 0 && selectedCount < itemCount }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        items: [CleanableItem],
        defaultSelected: Bool = true
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        if defaultSelected {
            self.items = items
        } else {
            self.items = items.map { item in
                var item = item
                item.isSelected = false
                return item
            }
        }
        self.defaultSelected = defaultSelected
        self.isSelected = defaultSelected
    }
}
