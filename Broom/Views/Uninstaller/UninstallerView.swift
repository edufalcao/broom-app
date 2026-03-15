import SwiftUI
import UniformTypeIdentifiers

struct UninstallerView: View {
    @Bindable var viewModel: UninstallerViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                VStack {
                    ProgressView("Loading apps...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { viewModel.loadApps() }

            case .ready:
                mainContent

            case .uninstalling(let progress, let item):
                VStack(spacing: 20) {
                    Spacer()
                    Text("Uninstalling...")
                        .font(.headline)
                    ProgressView(value: progress)
                        .frame(maxWidth: 300)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .done(let freed, let cleaned, let failed):
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Uninstall complete")
                        .font(.title3.bold())
                    Text("Freed \(SizeFormatter.format(freed))")
                        .foregroundStyle(.secondary)
                    if failed > 0 {
                        Text("\(failed) items could not be removed")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .confirmationDialog(
            "Uninstall \(viewModel.uninstallPlan?.app.name ?? "")?",
            isPresented: $viewModel.showUninstallConfirmation
        ) {
            Button("Uninstall", role: .destructive) {
                viewModel.confirmUninstall()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelUninstall()
            }
        } message: {
            if let plan = viewModel.uninstallPlan {
                Text("This will remove \(plan.filesToRemove.count) files totaling \(SizeFormatter.format(plan.totalSize)). Files will be moved to Trash.")
            }
        }
        .alert(
            "\(viewModel.uninstallPlan?.app.name ?? "") is running",
            isPresented: $viewModel.showRunningAppAlert
        ) {
            Button("Quit and Uninstall", role: .destructive) {
                viewModel.quitAndUninstall()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelUninstall()
            }
        } message: {
            Text("The app must be quit before it can be uninstalled.")
        }
    }

    private var mainContent: some View {
        HSplitView {
            // Left: App list
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search apps...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)

                Divider()

                // Sort
                HStack {
                    Text("Sort:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $viewModel.sortOrder) {
                        ForEach(UninstallerViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                // List
                List(viewModel.filteredApps, selection: Binding(
                    get: { viewModel.selectedApp },
                    set: { app in
                        if let app { viewModel.selectApp(app) }
                    }
                )) { app in
                    AppRowView(app: app, sortOrder: viewModel.sortOrder)
                        .tag(app)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

            // Right: Detail
            if let app = viewModel.selectedApp {
                AppDetailView(
                    app: app,
                    onUninstall: { viewModel.prepareUninstall() }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Select an app to view details")
                        .foregroundStyle(.secondary)
                    Text("or drop a .app here to uninstall")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                }
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    viewModel.handleAppDrop(url: url)
                }
            }
        }
        return true
    }
}
