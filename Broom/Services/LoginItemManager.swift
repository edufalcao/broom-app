import Foundation
import os

struct LoginItemManager {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func removeLoginItems(matching bundleID: String) -> [URL] {
        let lowered = bundleID.lowercased()
        let searchDirs = [
            Constants.userLaunchAgents,
            Constants.systemLaunchAgents,
        ]

        var unloaded: [URL] = []

        for dir in searchDirs {
            guard let entries = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries {
                guard entry.pathExtension == "plist",
                      entry.lastPathComponent.lowercased().contains(lowered)
                else { continue }

                if unloadLaunchAgent(at: entry) {
                    unloaded.append(entry)
                }
            }
        }

        let daemonDir = Constants.systemLaunchDaemons
        if let entries = try? fileManager.contentsOfDirectory(
            at: daemonDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for entry in entries {
                guard entry.pathExtension == "plist",
                      entry.lastPathComponent.lowercased().contains(lowered)
                else { continue }

                if unloadLaunchDaemon(at: entry) {
                    unloaded.append(entry)
                }
            }
        }

        return unloaded
    }

    @discardableResult
    func unloadLaunchAgent(at path: URL) -> Bool {
        runLaunchctl(arguments: ["unload", path.path], label: "launch agent", path: path)
    }

    @discardableResult
    func unloadLaunchDaemon(at path: URL) -> Bool {
        runLaunchctl(arguments: ["unload", path.path], label: "launch daemon", path: path)
    }

    private func runLaunchctl(arguments: [String], label: String, path: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Log.uninstaller.warning("Failed to unload \(label) at \(path.path): \(error.localizedDescription)")
            return false
        }

        let success = process.terminationStatus == 0
        if success {
            Log.uninstaller.info("Unloaded \(label): \(path.path)")
        } else {
            Log.uninstaller.warning("launchctl unload exited with status \(process.terminationStatus) for \(path.path)")
        }
        return success
    }
}
