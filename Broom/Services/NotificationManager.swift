import Foundation
import UserNotifications

enum NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func sendScanComplete(totalSize: Int64) {
        guard UserDefaults.standard.bool(forKey: "showNotifications") else { return }

        let content = UNMutableNotificationContent()
        content.title = "Scan Complete"
        content.body = "Broom found \(SizeFormatter.format(totalSize)) of junk files. Click to review."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "scan-complete",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func sendCleanComplete(freedBytes: Int64) {
        guard UserDefaults.standard.bool(forKey: "showNotifications") else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cleaning Complete"
        content.body = "Freed \(SizeFormatter.format(freedBytes)) of disk space."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "clean-complete",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
