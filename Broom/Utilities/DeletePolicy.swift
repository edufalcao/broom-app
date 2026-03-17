import Foundation

enum DeleteContext {
    case genericClean
    case explicitUninstall
}

enum DeleteBlockReason: String, Sendable {
    case protectedSystemPath
    case protectedDataFamily
    case unsafeSymlink
    case missingPath
    case permissionDenied
    case pathNotAbsolute
}

enum DeleteValidationResult: Sendable {
    case allowed
    case blocked(DeleteBlockReason)
}

enum DeletePolicy {
    private static let protectedSystemPrefixes = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/Library/Apple",
        "/private/var/db",
    ]

    static func validate(path: URL, context: DeleteContext) -> DeleteValidationResult {
        let filePath = path.standardizedFileURL.path

        guard filePath.hasPrefix("/") else {
            return .blocked(.pathNotAbsolute)
        }

        if let systemBlock = checkSystemPrefix(filePath, context: context) {
            return systemBlock
        }

        let fm = FileManager.default
        guard fm.fileExists(atPath: filePath) else {
            return .blocked(.missingPath)
        }

        if let symlinkBlock = checkSymlinkSafety(path, fileManager: fm) {
            return symlinkBlock
        }

        if context == .genericClean && ProtectedDataPolicy.isProtected(path: path) {
            return .blocked(.protectedDataFamily)
        }

        let parentDir = path.deletingLastPathComponent().path
        if !fm.isWritableFile(atPath: parentDir) {
            return .blocked(.permissionDenied)
        }

        return .allowed
    }

    private static func checkSystemPrefix(_ filePath: String, context: DeleteContext) -> DeleteValidationResult? {
        for prefix in protectedSystemPrefixes {
            guard filePath.hasPrefix(prefix) else { continue }

            if prefix == "/private/var/db" && context == .explicitUninstall {
                let receiptsPrefix = "/private/var/db/receipts"
                if filePath.hasPrefix(receiptsPrefix) {
                    continue
                }
            }

            return .blocked(.protectedSystemPath)
        }
        return nil
    }

    private static func checkSymlinkSafety(_ path: URL, fileManager: FileManager) -> DeleteValidationResult? {
        let originalPath = path.path
        guard let attrs = try? fileManager.attributesOfItem(atPath: originalPath),
              let fileType = attrs[.type] as? FileAttributeType,
              fileType == .typeSymbolicLink
        else {
            return nil
        }

        guard let resolved = try? fileManager.destinationOfSymbolicLink(atPath: originalPath) else {
            return nil
        }

        let resolvedPath: String
        if resolved.hasPrefix("/") {
            resolvedPath = resolved
        } else {
            let parent = (originalPath as NSString).deletingLastPathComponent
            resolvedPath = (parent as NSString).appendingPathComponent(resolved)
        }

        for prefix in protectedSystemPrefixes {
            if resolvedPath.hasPrefix(prefix) {
                return .blocked(.unsafeSymlink)
            }
        }

        return nil
    }
}
