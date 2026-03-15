import SwiftUI

struct SizeLabel: View {
    let bytes: Int64

    private var color: Color {
        if bytes > 1_000_000_000 { return .red }
        if bytes > 100_000_000 { return .orange }
        return .secondary
    }

    var body: some View {
        Text(SizeFormatter.format(bytes))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
