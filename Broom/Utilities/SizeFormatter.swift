import Foundation

enum SizeFormatter {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    static func format(_ bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }
}
