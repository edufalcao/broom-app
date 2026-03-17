import Foundation

struct CleanReport {
    let freedBytes: Int64
    let itemsCleaned: Int
    let itemsFailed: Int
    let itemsBlocked: Int
    let errors: [CleanError]
    let duration: TimeInterval

    var formattedFreedSize: String { SizeFormatter.format(freedBytes) }
    var hasErrors: Bool { !errors.isEmpty }

    init(
        freedBytes: Int64,
        itemsCleaned: Int,
        itemsFailed: Int,
        itemsBlocked: Int = 0,
        errors: [CleanError],
        duration: TimeInterval
    ) {
        self.freedBytes = freedBytes
        self.itemsCleaned = itemsCleaned
        self.itemsFailed = itemsFailed
        self.itemsBlocked = itemsBlocked
        self.errors = errors
        self.duration = duration
    }
}

struct CleanError {
    let path: URL
    let reason: String
}
