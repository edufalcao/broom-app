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
                var errors: [CleanError] = []
                let total = items.count

                for (index, item) in items.enumerated() {
                    if Task.isCancelled { break }

                    continuation.yield(.progress(
                        current: index + 1,
                        total: total,
                        currentPath: item.name
                    ))

                    let result: Result<Void, Error>
                    if moveToTrash {
                        result = SafeDelete.moveToTrash(item.path)
                    } else {
                        result = SafeDelete.deletePermanently(item.path)
                    }

                    switch result {
                    case .success:
                        freedBytes += item.size
                        cleaned += 1
                    case .failure(let error):
                        failed += 1
                        errors.append(CleanError(path: item.path, reason: error.localizedDescription))
                    }
                }

                let report = CleanReport(
                    freedBytes: freedBytes,
                    itemsCleaned: cleaned,
                    itemsFailed: failed,
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
    case complete(CleanReport)
}
