import Foundation
import os

enum SafeDelete {
    static func moveToTrash(_ url: URL) -> Result<Void, Error> {
        do {
            var resultingURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
            Log.cleaner.info("Trashed: \(url.path)")
            return .success(())
        } catch {
            Log.cleaner.error("Failed to trash \(url.path): \(error.localizedDescription)")
            return .failure(error)
        }
    }

    static func deletePermanently(_ url: URL) -> Result<Void, Error> {
        do {
            try FileManager.default.removeItem(at: url)
            Log.cleaner.info("Deleted: \(url.path)")
            return .success(())
        } catch {
            Log.cleaner.error("Failed to delete \(url.path): \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
