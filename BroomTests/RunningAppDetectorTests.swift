import Foundation
import Testing
@testable import Broom

@Suite("RunningAppDetector")
struct RunningAppDetectorTests {
    @Test func matchesBrowserCachePathToRunningApp() {
        let item = CleanableItem(
            path: URL(fileURLWithPath: "/Users/test/Library/Caches/Google/Chrome/Default/Cache"),
            name: "Chrome",
            size: 100
        )
        let app = RunningApplicationInfo(
            bundleIdentifier: "com.google.chrome",
            localizedName: "google chrome"
        )

        #expect(RunningAppDetector.matches(item: item, runningApplication: app))
    }

    @Test func doesNotMatchUnrelatedItems() {
        let item = CleanableItem(
            path: URL(fileURLWithPath: "/Users/test/Library/Caches/Homebrew"),
            name: "Homebrew",
            size: 100
        )
        let app = RunningApplicationInfo(
            bundleIdentifier: "com.google.chrome",
            localizedName: "google chrome"
        )

        #expect(!RunningAppDetector.matches(item: item, runningApplication: app))
    }
}
