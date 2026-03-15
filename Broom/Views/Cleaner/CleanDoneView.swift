import SwiftUI

struct CleanDoneView: View {
    let freedBytes: Int64
    let itemsCleaned: Int
    let itemsFailed: Int
    let onScanAgain: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("All clean!")
                .font(.title2.bold())

            Text("Freed \(SizeFormatter.format(freedBytes)) of disk space")
                .font(.subheadline)

            Text("\(itemsCleaned) items moved to Trash")
                .font(.caption)
                .foregroundStyle(.secondary)

            if itemsFailed > 0 {
                Text("\(itemsFailed) items could not be removed")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button(action: onScanAgain) {
                Label("Scan Again", systemImage: "arrow.clockwise")
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
