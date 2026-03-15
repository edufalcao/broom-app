import Testing
@testable import Broom

@Suite("BundleIDMatcher")
struct BundleIDMatcherTests {
    let installed: Set<String> = [
        "com.spotify.client",
        "com.google.chrome",
        "com.tinyspeck.slackmacgap",
        "com.apple.safari",
    ]

    @Test func exactMatch() {
        #expect(BundleIDMatcher.matches(directoryName: "com.spotify.client", againstInstalled: installed))
    }

    @Test func prefixMatch() {
        #expect(BundleIDMatcher.matches(directoryName: "com.spotify.client.helper", againstInstalled: installed))
    }

    @Test func noFalsePositiveForUnknown() {
        #expect(!BundleIDMatcher.matches(directoryName: "com.unknownapp.foo", againstInstalled: installed))
    }

    @Test func inferAppNameFromBundleID() {
        #expect(BundleIDMatcher.inferAppName(from: "com.spotify.client") == "client")
    }

    @Test func inferAppNameFromSimpleName() {
        #expect(BundleIDMatcher.inferAppName(from: "Slack") == "Slack")
    }

    @Test func substringMatch() {
        // "chrome" should match com.google.chrome
        #expect(BundleIDMatcher.matches(directoryName: "Chrome", againstInstalled: installed))
    }
}
