import Foundation

struct CleanReport {
    let freedBytes: Int64
    let itemsCleaned: Int
    let itemsFailed: Int
    let errors: [CleanError]
    let duration: TimeInterval

    var formattedFreedSize: String { SizeFormatter.format(freedBytes) }
    var hasErrors: Bool { !errors.isEmpty }
}

struct CleanError {
    let path: URL
    let reason: String
}
