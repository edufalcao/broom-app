import SwiftUI

struct IdleView: View {
    let onScan: () -> Void
    @State private var showFDABanner = false
    @AppStorage("fdaBannerDismissed") private var bannerDismissed = false

    private var lastScanText: String {
        guard let date = UserDefaults.standard.object(forKey: "lastScanDate") as? Date else {
            return "Never scanned"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last scan: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    var body: some View {
        VStack(spacing: 24) {
            if showFDABanner {
                PermissionBanner {
                    withAnimation {
                        showFDABanner = false
                        bannerDismissed = true
                    }
                }
                .padding(.top)
            }

            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Button(action: onScan) {
                Label("Scan System", systemImage: "magnifyingglass")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text(lastScanText)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear { checkFDA() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkFDA()
        }
    }

    private func checkFDA() {
        if bannerDismissed { return }
        let hasFDA = PermissionChecker.hasFullDiskAccess
        withAnimation {
            showFDABanner = !hasFDA
        }
    }
}
