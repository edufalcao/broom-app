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

    // MARK: - strictMatch

    @Test func strictMatchExactID() {
        #expect(BundleIDMatcher.strictMatch(candidate: "com.spotify.client", against: installed))
    }

    @Test func strictMatchReverseDNSPrefix() {
        #expect(BundleIDMatcher.strictMatch(candidate: "com.spotify.client.helper", against: installed))
    }

    @Test func strictMatchRejectsSubstringOnly() {
        #expect(!BundleIDMatcher.strictMatch(candidate: "Chrome", against: installed))
    }

    @Test func strictMatchRejectsNormalizedOnly() {
        let ids: Set<String> = ["com.some-app.thing"]
        #expect(!BundleIDMatcher.strictMatch(candidate: "com.someapp.thing", against: ids))
    }

    @Test func strictMatchIsCaseInsensitive() {
        #expect(BundleIDMatcher.strictMatch(candidate: "COM.SPOTIFY.CLIENT", against: installed))
    }

    @Test func strictMatchEmptyCandidate() {
        #expect(!BundleIDMatcher.strictMatch(candidate: "", against: installed))
    }

    @Test func strictMatchEmptyInstalled() {
        #expect(!BundleIDMatcher.strictMatch(candidate: "com.spotify.client", against: []))
    }

    // MARK: - broadMatch

    @Test func broadMatchExactID() {
        #expect(BundleIDMatcher.broadMatch(candidate: "com.spotify.client", against: installed))
    }

    @Test func broadMatchReverseDNSPrefix() {
        #expect(BundleIDMatcher.broadMatch(candidate: "com.spotify.client.helper", against: installed))
    }

    @Test func broadMatchSubstring() {
        #expect(BundleIDMatcher.broadMatch(candidate: "Chrome", against: installed))
    }

    @Test func broadMatchNormalized() {
        let ids: Set<String> = ["com.some-app.thing"]
        #expect(BundleIDMatcher.broadMatch(candidate: "com.someapp.thing", against: ids))
    }

    @Test func broadMatchEmptyCandidate() {
        #expect(!BundleIDMatcher.broadMatch(candidate: "", against: installed))
    }

    @Test func broadMatchEmptyInstalled() {
        #expect(!BundleIDMatcher.broadMatch(candidate: "com.spotify.client", against: []))
    }
}
