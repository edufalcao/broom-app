import SwiftUI

struct CleanerView: View {
    @Bindable var viewModel: ScanViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                IdleView(onScan: { viewModel.startScan() })

            case .scanning(let progress, let category, let found):
                ScanningView(
                    progress: progress,
                    currentCategory: category,
                    foundSoFar: found,
                    onCancel: { viewModel.cancelScan() }
                )

            case .results:
                ScanResultsView(viewModel: viewModel)

            case .cleaning(let progress, let item, let cleaned, let total):
                CleanProgressView(
                    progress: progress,
                    currentItem: item,
                    cleanedCount: cleaned,
                    totalCount: total
                )

            case .done(let freed, let cleaned, let failed):
                CleanDoneView(
                    freedBytes: freed,
                    itemsCleaned: cleaned,
                    itemsFailed: failed,
                    onScanAgain: { viewModel.reset() }
                )

            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                    Text(message)
                        .foregroundStyle(.secondary)
                    Button("Try Again") { viewModel.reset() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .confirmationDialog(
            "Clean \(viewModel.confirmationItems) items?",
            isPresented: $viewModel.showCleanConfirmation
        ) {
            Button("Clean (\(SizeFormatter.format(viewModel.confirmationSize)))", role: .destructive) {
                viewModel.confirmClean()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Files will be deleted using your current cleaning preference.")
        }
        .alert(
            "Some selected items belong to running apps",
            isPresented: $viewModel.showRunningAppsAlert
        ) {
            Button("Skip Running Apps") {
                viewModel.skipRunningAppsAndConfirm()
            }
            Button("Clean Anyway", role: .destructive) {
                viewModel.cleanRunningAppsAnyway()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.runningAppsInSelection.joined(separator: ", "))
        }
    }
}
