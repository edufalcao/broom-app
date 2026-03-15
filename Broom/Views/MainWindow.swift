import SwiftUI

struct MainWindow: View {
    @State private var selectedSection: SidebarSection? = .cleaner
    @State private var scanViewModel = ScanViewModel()
    @State private var uninstallerViewModel = UninstallerViewModel()
    @State private var largeFilesViewModel = LargeFilesViewModel()
    @State private var showSettings = false

    private var sidebarBackground: Color {
        Color(nsColor: .underPageBackgroundColor)
    }

    private var paneSeparator: Color {
        Color(nsColor: .separatorColor).opacity(0.9)
    }

    enum SidebarSection: String, CaseIterable, Hashable {
        case cleaner = "Clean"
        case uninstaller = "Apps"
        case largeFiles = "Large Files"

        var icon: String {
            switch self {
            case .cleaner: return "magnifyingglass"
            case .uninstaller: return "shippingbox"
            case .largeFiles: return "doc.badge.arrow.up"
            }
        }
    }

    private func isSectionBusy(_ section: SidebarSection) -> Bool {
        switch section {
        case .cleaner: return scanViewModel.state.isBusy
        case .uninstaller: return uninstallerViewModel.state == .loading
        case .largeFiles: return largeFilesViewModel.state.isBusy
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
            switch selectedSection {
            case .cleaner, nil:
                CleanerView(viewModel: scanViewModel)
            case .uninstaller:
                UninstallerView(viewModel: uninstallerViewModel)
            case .largeFiles:
                LargeFilesView(viewModel: largeFilesViewModel)
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
        .onReceive(NotificationCenter.default.publisher(for: .switchToCleanerSection)) { _ in
            selectedSection = .cleaner
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToUninstallerSection)) { _ in
            selectedSection = .uninstaller
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToLargeFilesSection)) { _ in
            selectedSection = .largeFiles
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showSettings = true
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}
