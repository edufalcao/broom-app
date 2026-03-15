import Foundation
import Testing
@testable import Broom

@Suite("AppRouter")
struct AppRouterTests {
    @MainActor
    @Test func defaultsToCleanerSection() {
        let router = AppRouter()
        #expect(router.selectedSection == .cleaner)
        #expect(router.pendingAction == nil)
    }

    @MainActor
    @Test func switchesSections() {
        let router = AppRouter()

        router.selectedSection = .uninstaller
        #expect(router.selectedSection == .uninstaller)

        router.selectedSection = .largeFiles
        #expect(router.selectedSection == .largeFiles)

        router.selectedSection = .cleaner
        #expect(router.selectedSection == .cleaner)
    }

    @MainActor
    @Test func startScanAction() {
        let router = AppRouter()
        router.pendingAction = .startScan
        #expect(router.pendingAction == .startScan)

        router.pendingAction = nil
        #expect(router.pendingAction == nil)
    }

    @MainActor
    @Test func appDroppedAction() {
        let router = AppRouter()
        let url = URL(fileURLWithPath: "/tmp/Test.app")
        router.pendingAction = .appDropped(url)
        #expect(router.pendingAction == .appDropped(url))
    }

    @MainActor
    @Test func pendingActionsAreEquatable() {
        let url = URL(fileURLWithPath: "/tmp/A.app")
        #expect(AppRouter.PendingAction.startScan == AppRouter.PendingAction.startScan)
        #expect(AppRouter.PendingAction.appDropped(url) == AppRouter.PendingAction.appDropped(url))
        #expect(AppRouter.PendingAction.startScan != AppRouter.PendingAction.appDropped(url))
    }
}
