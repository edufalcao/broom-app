import SwiftUI

struct LargeFilesSectionView: View {
    enum Mode: String, CaseIterable {
        case largeFiles = "Large Files"
        case installers = "Installers"
    }

    @State private var mode: Mode = .largeFiles
    @Bindable var largeFilesViewModel: LargeFilesViewModel
    @Bindable var installersViewModel: InstallersViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)
            .padding(.vertical, 8)
            .accessibilityIdentifier("large-files-mode-picker")

            Divider()

            switch mode {
            case .largeFiles:
                LargeFilesView(viewModel: largeFilesViewModel)
            case .installers:
                InstallersView(viewModel: installersViewModel)
            }
        }
    }
}
