import AppKit
import Foundation

enum PermissionChecker {
    static var hasFullDiskAccess: Bool {
        // Use POSIX open() to get precise error codes.
        // FileManager.isReadableFile and fileExists are unreliable
        // with TCC-protected paths — they may return false even when
        // the file exists, or true when we can't actually read it.
        let home = NSHomeDirectory()
        let testPaths = [
            home + "/Library/Safari/CloudTabs.db",
            home + "/Library/Safari/Bookmarks.plist",
        ]

        for path in testPaths {
            let fd = open(path, O_RDONLY)
            if fd != -1 {
                close(fd)
                return true // We could open it — FDA is granted
            }
            // EACCES/EPERM = file exists but TCC blocks access (no FDA)
            if errno == EACCES || errno == EPERM {
                return false
            }
            // ENOENT = file doesn't exist on this system, try next path
        }

        // None of the test files exist — can't determine FDA status.
        // Hide the banner to avoid a misleading warning.
        return true
    }

    static func requestFullDiskAccess() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }

    static func canAccessPath(_ path: URL) -> Bool {
        FileManager.default.isReadableFile(atPath: path.path)
    }
}
