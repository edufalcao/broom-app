import SwiftUI

struct CleanProgressView: View {
    let progress: Double
    let currentItem: String
    let cleanedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Cleaning...")
                .font(.headline)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)

            Text(currentItem)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("\(cleanedCount) of \(totalCount) items cleaned")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
