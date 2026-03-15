import SwiftUI

struct SafeListSettingsView: View {
    @State private var safeListEntries: [String] = []
    @State private var newEntry = ""
    @State private var selection: String?

    var body: some View {
        VStack(spacing: 0) {
            List(safeListEntries, id: \.self, selection: $selection) { entry in
                Text(entry)
                    .lineLimit(1)
            }
            .frame(minHeight: 150)

            Divider()

            HStack {
                TextField("Path or bundle ID...", text: $newEntry)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    guard !newEntry.isEmpty else { return }
                    safeListEntries.append(newEntry)
                    newEntry = ""
                    saveSafeList()
                }
                .disabled(newEntry.isEmpty)

                Button("Remove") {
                    if let selection {
                        safeListEntries.removeAll { $0 == selection }
                        self.selection = nil
                        saveSafeList()
                    }
                }
                .disabled(selection == nil)
            }
            .padding()
        }
        .onAppear { loadSafeList() }
    }

    private func loadSafeList() {
        let path = Constants.safeListPath
        guard let data = try? Data(contentsOf: path),
              let list = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        safeListEntries = list
    }

    private func saveSafeList() {
        let dir = Constants.appSupportDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        if let data = try? JSONEncoder().encode(safeListEntries) {
            try? data.write(to: Constants.safeListPath)
        }
    }
}
