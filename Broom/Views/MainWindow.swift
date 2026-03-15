import SwiftUI

struct MainWindow: View {
    @Environment(AppRouter.self) private var router
    @State private var scanViewModel = ScanViewModel()
    @State private var uninstallerViewModel = UninstallerViewModel()
    @State private var largeFilesViewModel = LargeFilesViewModel()

    private var sidebarBackground: Color {
        Color(nsColor: .underPageBackgroundColor)
    }

    private var paneSeparator: Color {
        Color(nsColor: .separatorColor).opacity(0.9)
    }

    private func isSectionBusy(_ section: SidebarSection) -> Bool {
        switch section {
        case .cleaner: return scanViewModel.state.isBusy
        case .uninstaller: return uninstallerViewModel.state == .loading
        case .largeFiles: return largeFilesViewModel.state.isBusy
        }
    }

    var body: some View {
        @Bindable var router = router
        NavigationSplitView {
            List(selection: $router.selectedSection) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    HStack {
                        Label(section.rawValue, systemImage: section.icon)
                        if isSectionBusy(section) {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .tag(section)
                    .accessibilityLabel(section.rawValue)
                    .accessibilityHint("Switch to \(section.rawValue) section")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(sidebarBackground)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(paneSeparator)
                    .frame(width: 1)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            switch router.selectedSection {
            case .cleaner, nil:
                CleanerView(viewModel: scanViewModel)
            case .uninstaller:
                UninstallerView(viewModel: uninstallerViewModel)
            case .largeFiles:
                LargeFilesView(viewModel: largeFilesViewModel)
            }
        }
        .onChange(of: router.pendingAction) { _, action in
            guard let action else { return }
            router.pendingAction = nil
            switch action {
            case .startScan:
                router.selectedSection = .cleaner
                if case .idle = scanViewModel.state {
                    scanViewModel.startScan()
                }
            case .appDropped(let url):
                router.selectedSection = .uninstaller
                uninstallerViewModel.handleAppDrop(url: url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}
