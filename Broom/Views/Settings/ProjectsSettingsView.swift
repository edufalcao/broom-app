import SwiftUI

struct ProjectsSettingsView: View {
    /// Empty list means "use the built-in default roots".
    @State private var roots: [String]
    @State private var newRoot = ""
    @State private var usingDefaults: Bool

    init() {
        let stored = UserDefaults.standard.stringArray(
            forKey: Constants.projectArtifactRootsKey
        ) ?? []
        _roots = State(initialValue: stored)
        _usingDefaults = State(initialValue: stored.isEmpty)
    }

    var body: some View {
        Form {
            Toggle("Use default locations (Projects, dev, GitHub, …)", isOn: $usingDefaults)
                .onChange(of: usingDefaults) { _, newValue in
                    if newValue { roots = [] }
                    save()
                }
            Text("Scans your project folders for regenerable build artifacts like node_modules and target.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !usingDefaults {
                ForEach(roots, id: \.self) { root in
                    HStack {
                        Text(root)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            roots.removeAll { $0 == root }
                            save()
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                HStack {
                    TextField("~/path/to/projects", text: $newRoot)
                    Button("Add") {
                        let trimmed = newRoot.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        roots.append(trimmed)
                        newRoot = ""
                        save()
                    }
                    .disabled(newRoot.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding()
    }

    private func save() {
        UserDefaults.standard.set(roots, forKey: Constants.projectArtifactRootsKey)
    }
}
