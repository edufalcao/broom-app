import Foundation
import Testing
@testable import Broom

@Suite("ExclusionList")
struct ExclusionListTests {
    @Test func excludesProtectedBundlePrefixes() {
        let path = URL(fileURLWithPath: "/tmp/com.apple.Safari")
        #expect(ExclusionList.isExcluded(path))
    }

    @Test func excludesCustomPathEntries() {
        let entries: Set<String> = ["/tmp/my-safe-path"]
        let path = URL(fileURLWithPath: "/tmp/my-safe-path/child/file")
        #expect(ExclusionList.matchesUserEntry(path, entries: entries))
    }

    @Test func excludesCustomBundleIdentifiers() {
        let entries: Set<String> = ["com.example.safe"]
        let path = URL(fileURLWithPath: "/tmp/com.example.safe.cache")
        #expect(ExclusionList.isExcluded(path, userEntries: entries))
    }

    @Test func doesNotExcludeUnrelatedEntries() {
        let entries: Set<String> = ["com.example.safe"]
        let path = URL(fileURLWithPath: "/tmp/com.example.other")
        #expect(!ExclusionList.isExcluded(path, userEntries: entries))
    }
}
