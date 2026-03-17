import Foundation
import os

enum DeleteResult: Sendable {
    case success(path: URL, freedBytes: Int64)
    case blocked(path: URL, reason: DeleteBlockReason)
    case failed(path: URL, error: String)
}

enum SafeDelete {
    static func moveToTrash(
        _ url: URL,
        context: DeleteContext = .genericClean,
        expectedSize: Int64 = 0
    ) -> DeleteResult {
        switch DeletePolicy.validate(path: url, context: context) {
        case .blocked(let reason):
            Log.cleaner.info("Blocked trash of \(url.path): \(reason.rawValue)")
            return .blocked(path: url, reason: reason)
        case .allowed:
            break
        }

        do {
            var resultingURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
            Log.cleaner.info("Trashed: \(url.path)")
            return .success(path: url, freedBytes: expectedSize)
        } catch {
            Log.cleaner.error("Failed to trash \(url.path): \(error.localizedDescription)")
            return .failed(path: url, error: error.localizedDescription)
        }
    }

    static func deletePermanently(
        _ url: URL,
        context: DeleteContext = .genericClean,
        expectedSize: Int64 = 0
    ) -> DeleteResult {
        switch DeletePolicy.validate(path: url, context: context) {
        case .blocked(let reason):
            Log.cleaner.info("Blocked delete of \(url.path): \(reason.rawValue)")
            return .blocked(path: url, reason: reason)
        case .allowed:
            break
        }

        do {
            try FileManager.default.removeItem(at: url)
            Log.cleaner.info("Deleted: \(url.path)")
            return .success(path: url, freedBytes: expectedSize)
        } catch {
            Log.cleaner.error("Failed to delete \(url.path): \(error.localizedDescription)")
            return .failed(path: url, error: error.localizedDescription)
        }
    }
}
