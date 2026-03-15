import SwiftUI

struct ScanningView: View {
    let progress: Double
    let currentCategory: String
    let foundSoFar: Int64
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Scanning \(currentCategory)...")
                .font(.headline)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)

            Text("Found \(SizeFormatter.format(foundSoFar)) so far")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
