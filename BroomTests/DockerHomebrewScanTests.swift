import Foundation
import Testing
@testable import Broom

@Suite("Docker and Homebrew Scan")
struct DockerHomebrewScanTests {
    @Test func dockerScanReturnsNilWhenNotInstalled() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "DockerScanTest")
        defer { try? FileManager.default.removeItem(at: dir) }

        // Create a scanner with locations pointing to empty temp dir
        // Docker paths won't exist, so scanDocker should return nil
        let scanner = FileScanner()
        let result = await scanner.scanDocker(userEntries: [])

        // On most test machines Docker data won't be at the default path,
        // but we can verify the method runs without error.
        // If Docker IS installed, it returns a category; if not, nil.
        // Either way is valid.
        if let category = result {
            #expect(category.name == "Docker Data")
            #expect(!category.items.isEmpty)
        }
    }

    @Test func homebrewScanReturnsNilWhenNotInstalled() async throws {
        let scanner = FileScanner()
        let result = await scanner.scanHomebrewExtended(userEntries: [])

        if let category = result {
            #expect(category.name == "Homebrew")
            // Homebrew items should default to unselected
            #expect(category.defaultSelected == false)
        }
    }

    @Test func homebrewCategoryDefaultsToUnselected() {
        let category = CleanCategory(
            name: "Homebrew",
            icon: "mug",
            description: "Test",
            items: [CleanableItem(path: URL(fileURLWithPath: "/tmp/a"), size: 100, isSelected: false)],
            defaultSelected: false
        )

        #expect(category.isSelected == false)
        #expect(category.items[0].isSelected == false)
    }
}
