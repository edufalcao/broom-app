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

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                        .opacity(scanViewModel.state.isBusy ? 0.4 : 1.0)
                }

                if scanViewModel.state.isBusy {
                    Section {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Working...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
