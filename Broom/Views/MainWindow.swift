import SwiftUI

struct MainWindow: View {
    @State private var selectedSection: SidebarSection? = .cleaner
    @State private var scanViewModel = ScanViewModel()
    @State private var uninstallerViewModel = UninstallerViewModel()

    enum SidebarSection: String, CaseIterable, Hashable {
        case cleaner = "Clean"
        case uninstaller = "Apps"

        var icon: String {
            switch self {
            case .cleaner: return "magnifyingglass"
            case .uninstaller: return "shippingbox"
            }
        }
    }

    private func isSectionBusy(_ section: SidebarSection) -> Bool {
        switch section {
        case .cleaner: return scanViewModel.state.isBusy
        case .uninstaller: return uninstallerViewModel.state == .loading
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
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
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 200)
        } detail: {
            switch selectedSection {
            case .cleaner, nil:
                CleanerView(viewModel: scanViewModel)
            case .uninstaller:
                UninstallerView(viewModel: uninstallerViewModel)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .startScan)) { _ in
            selectedSection = .cleaner
            if case .idle = scanViewModel.state {
                scanViewModel.startScan()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDroppedOnDock)) { notification in
            if let url = notification.object as? URL {
                selectedSection = .uninstaller
                uninstallerViewModel.handleAppDrop(url: url)
            }
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}
