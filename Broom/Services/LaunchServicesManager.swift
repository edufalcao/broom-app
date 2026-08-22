import Foundation
import os

struct LaunchServicesManager {
    private static let lsregisterPath = "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

    func unregisterApp(at bundlePath: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.lsregisterPath)
        process.arguments = ["-u", bundlePath.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            Log.uninstaller.warning("Failed to unregister app from LaunchServices: \(error.localizedDescription)")
            return false
        }

        let success = process.terminationStatus == 0
        if success {
            Log.uninstaller.info("Unregistered app from LaunchServices: \(bundlePath.path)")
        } else {
            Log.uninstaller.warning("lsregister -u exited with status \(process.terminationStatus) for \(bundlePath.path)")
        }
        return success
    }

    func refreshDatabase() async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.lsregisterPath)
        process.arguments = ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            Log.uninstaller.warning("Failed to launch lsregister: \(error.localizedDescription)")
            return false
        }

        let exitStatus = await withTaskGroup(of: Int32?.self) { group in
            group.addTask {
                process.waitUntilExit()
                return process.terminationStatus
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return nil }
                if process.isRunning {
                    process.terminate()
                }
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }

        if exitStatus == nil {
            Log.uninstaller.warning("lsregister timed out after 10 seconds")
            return false
        }

        let success = exitStatus == 0
        if success {
            Log.uninstaller.info("LaunchServices database refreshed")
        } else {
            Log.uninstaller.warning("lsregister exited with status \(exitStatus ?? -1)")
        }
        return success
    }
}
