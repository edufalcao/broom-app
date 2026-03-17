import SwiftUI

struct UninstallerView: View {
    @Bindable var viewModel: UninstallerViewModel

    private var listPaneBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    private var detailPaneBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    private var paneSeparator: Color {
        Color(nsColor: .separatorColor).opacity(0.9)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Browse and uninstall apps")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Scan your installed apps to view their associated files and cleanly remove them.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    Button(action: { viewModel.scanApps() }) {
                        Label("Scan Apps", systemImage: "magnifyingglass")
                            .frame(minWidth: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loading:
                VStack {
                    ProgressView("Loading apps...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .ready:
                mainContent

            case .uninstalling(let progress, let item, let phase):
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: phaseIcon(phase))
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse, isActive: true)
                    if let phase {
                        Text(UninstallerViewModel.phaseDescription(phase))
                            .font(.headline)
                    } else {
                        Text("Uninstalling...")
                            .font(.headline)
                    }
                    ProgressView(value: progress)
                        .frame(maxWidth: 300)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .done(let freed, _, let failed):
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
                    Button("Back to apps list") {
                        viewModel.state = .ready
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
        .sheet(isPresented: $viewModel.showUninstallConfirmation) {
            if let plan = viewModel.uninstallPlan {
                UninstallConfirmView(
                    plan: plan,
                    moveToTrash: $viewModel.moveToTrashForUninstall,
                    onConfirm: { viewModel.confirmUninstall() },
                    onCancel: { viewModel.cancelUninstall() }
                )
            }
        }
        .alert(
            "\(viewModel.uninstallPlan?.app.name ?? "") is running",
            isPresented: $viewModel.showRunningAppAlert
        ) {
            Button("Quit and Uninstall", role: .destructive) {
                viewModel.quitAndUninstall()
            }
            Button("Force Quit and Uninstall", role: .destructive) {
                viewModel.forceQuitAndUninstall()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelUninstall()
            }
        } message: {
            Text("The app must be quit before it can be uninstalled. You can force quit it if a normal quit does not work.")
        }
        .alert(
            "Force quit \(viewModel.uninstallPlan?.app.name ?? "app")?",
            isPresented: $viewModel.showForceQuitAlert
        ) {
            Button("Force Quit and Continue", role: .destructive) {
                viewModel.forceQuitAndUninstall()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelUninstall()
            }
        } message: {
            Text("The app did not quit cleanly. Force quitting may interrupt unsaved work.")
        }
    }

    private func phaseIcon(_ phase: UninstallPhase?) -> String {
        switch phase {
        case .unloadingLaunchItems: return "gearshape.arrow.triangle.2.circlepath"
        case .removingLoginItems: return "person.badge.minus"
        case .deletingFiles: return "trash"
        case .cleaningMetadata: return "paintbrush"
        case .refreshingDatabase: return "arrow.triangle.2.circlepath"
        case nil: return "trash"
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
                if viewModel.filteredApps.isEmpty {
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No apps found",
                        subtitle: "Drop an app here to open its uninstall preview."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                    .scrollContentBackground(.hidden)
                    .background(listPaneBackground)
                }

                Divider()

                HStack {
                    Button {
                        viewModel.reloadApps()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(8)
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            .background(listPaneBackground)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(paneSeparator)
                    .frame(width: 1)
            }

            // Right: Detail
            Group {
                if let app = viewModel.selectedApp {
                    AppDetailView(
                        app: app,
                        onToggleBundle: { viewModel.toggleBundleSelection() },
                        onToggleAssociatedFile: { viewModel.toggleAssociatedFile($0) },
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
                }
            }
            .background(detailPaneBackground)
        }
        .background(detailPaneBackground)
        .dropDestination(for: URL.self) { urls, _ in
            for url in urls where url.pathExtension == "app" {
                viewModel.handleAppDrop(url: url)
            }
            return !urls.isEmpty
        }
    }
}
