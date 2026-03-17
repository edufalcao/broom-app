import Foundation
import os

actor FileCleaner: CleanServing {
    nonisolated func clean(items: [CleanableItem], moveToTrash: Bool = true) -> AsyncStream<CleanProgress> {
        AsyncStream { continuation in
            Task {
                let startTime = Date()
                var freedBytes: Int64 = 0
                var cleaned = 0
                var failed = 0
                var blocked = 0
                var errors: [CleanError] = []
                let total = items.count

                for (index, item) in items.enumerated() {
                    if Task.isCancelled { break }

                    continuation.yield(.progress(
                        current: index + 1,
                        total: total,
                        currentPath: item.name
                    ))

                    let result: DeleteResult
                    if moveToTrash {
                        result = SafeDelete.moveToTrash(item.path, context: .genericClean, expectedSize: item.size)
                    } else {
                        result = SafeDelete.deletePermanently(item.path, context: .genericClean, expectedSize: item.size)
                    }

                    switch result {
                    case .success(_, let bytes):
                        freedBytes += bytes
                        cleaned += 1
                    case .blocked(let path, let reason):
                        blocked += 1
                        errors.append(CleanError(path: path, reason: "Blocked: \(reason.rawValue)"))
                    case .failed(let path, let error):
                        failed += 1
                        errors.append(CleanError(path: path, reason: error))
                    }
                }

                let report = CleanReport(
                    freedBytes: freedBytes,
                    itemsCleaned: cleaned,
                    itemsFailed: failed,
                    itemsBlocked: blocked,
                    errors: errors,
                    duration: Date().timeIntervalSince(startTime)
                )
                continuation.yield(.complete(report))
                continuation.finish()
            }
        }
    }
}

enum CleanProgress {
    case progress(current: Int, total: Int, currentPath: String)
    case phase(UninstallPhase)
    case complete(CleanReport)
}
