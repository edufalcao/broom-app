import Foundation
import Testing
@testable import Broom

@Suite("ProtectedDataPolicy")
struct ProtectedDataPolicyTests {

    // MARK: - Bundle ID Protection

    @Test func passwordManagerBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.agilebits.onepassword7"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.lastpass.LastPass"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.bitwarden.desktop"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.dashlane.Dashlane"))
    }

    @Test func vpnBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "net.mullvad.vpn"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.nordvpn.osx"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "io.tailscale.ipn.macos"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.wireguard.macos"))
    }

    @Test func browserBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.safari"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.google.chrome"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "org.mozilla.firefox"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "company.thebrowser.browser"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.brave.browser"))
    }

    @Test func aiBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.openai.chatgpt"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.anthropic.claude"))
    }

    @Test func automationBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.raycast.macos"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.runningwithcrayons.alfred"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "org.hammerspoon.Hammerspoon"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.hegenberg.bettertouchtool"))
    }

    @Test func appleSystemBundleIDsAreProtected() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.icloud.photos"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.mobilesync"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.LaunchServices"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.spotlight"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.finder"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.preference.general"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "com.apple.appstore"))
    }

    @Test func appleSystemPathsAreProtected() {
        let launchServicesPath = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.LaunchServices")
        #expect(ProtectedDataPolicy.isProtected(path: launchServicesPath))

        let spotlightPath = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.spotlight")
        #expect(ProtectedDataPolicy.isProtected(path: spotlightPath))
    }

    @Test func unprotectedBundleIDsAreNotProtected() {
        #expect(!ProtectedDataPolicy.isProtected(bundleID: "com.example.randomapp"))
        #expect(!ProtectedDataPolicy.isProtected(bundleID: "com.mycompany.tool"))
        #expect(!ProtectedDataPolicy.isProtected(bundleID: "org.custom.utility"))
    }

    @Test func bundleIDCheckIsCaseInsensitive() {
        #expect(ProtectedDataPolicy.isProtected(bundleID: "COM.AGILEBITS.ONEPASSWORD7"))
        #expect(ProtectedDataPolicy.isProtected(bundleID: "Com.Google.Chrome"))
    }

    // MARK: - Path Protection

    @Test func protectedPathComponentsDetected() {
        let onePasswordPath = URL(fileURLWithPath: "/Users/test/Library/Application Support/1Password")
        #expect(ProtectedDataPolicy.isProtected(path: onePasswordPath))

        let bitwardenPath = URL(fileURLWithPath: "/Users/test/Library/Caches/bitwarden")
        #expect(ProtectedDataPolicy.isProtected(path: bitwardenPath))

        let mullvadPath = URL(fileURLWithPath: "/Users/test/Library/Application Support/mullvadvpn")
        #expect(ProtectedDataPolicy.isProtected(path: mullvadPath))

        let ollamaPath = URL(fileURLWithPath: "/Users/test/Library/Caches/ollama")
        #expect(ProtectedDataPolicy.isProtected(path: ollamaPath))
    }

    @Test func protectedBundleIDInPathDetected() {
        let path = URL(fileURLWithPath: "/Users/test/Library/Caches/com.agilebits.onepassword7")
        #expect(ProtectedDataPolicy.isProtected(path: path))
    }

    @Test func unprotectedPathsAreNotProtected() {
        let normalPath = URL(fileURLWithPath: "/Users/test/Library/Caches/com.example.randomapp")
        #expect(!ProtectedDataPolicy.isProtected(path: normalPath))

        let genericPath = URL(fileURLWithPath: "/Users/test/Library/Application Support/MyApp")
        #expect(!ProtectedDataPolicy.isProtected(path: genericPath))
    }
}
