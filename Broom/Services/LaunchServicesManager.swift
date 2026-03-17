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

    func refreshDatabase() -> Bool {
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

        let deadline = DispatchTime.now() + .seconds(10)
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            group.leave()
        }

        if group.wait(timeout: deadline) == .timedOut {
            process.terminate()
            Log.uninstaller.warning("lsregister timed out after 10 seconds")
            return false
        }

        let success = process.terminationStatus == 0
        if success {
            Log.uninstaller.info("LaunchServices database refreshed")
        } else {
            Log.uninstaller.warning("lsregister exited with status \(process.terminationStatus)")
        }
        return success
    }
}
