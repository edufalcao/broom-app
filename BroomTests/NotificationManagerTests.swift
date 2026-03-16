import Foundation
import Testing
@testable import Broom

@Suite("NotificationManager")
struct NotificationManagerTests {
    @Test func defaultsNotificationsToEnabled() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        #expect(NotificationManager.notificationsEnabled(userDefaults: defaults) == true)
    }

    @Test func respectsStoredNotificationPreference() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "showNotifications")
        #expect(NotificationManager.notificationsEnabled(userDefaults: defaults) == false)
    }
}
