import Foundation
import Testing
@testable import Broom

@Suite("FileCleaner")
struct FileCleanerTests {
    @Test func deletesFilesPermanentlyWhenRequested() async throws {
        let directory = try TestSupport.makeTempDirectory()
        let file = directory.appendingPathComponent("cache.dat")
        try TestSupport.writeFile(at: file)

        let cleaner = FileCleaner()
        var finalReport: CleanReport?

        for await progress in cleaner.clean(
            items: [CleanableItem(path: file, size: 9)],
            moveToTrash: false
        ) {
            if case .complete(let report) = progress {
                finalReport = report
            }
        }

        #expect(FileManager.default.fileExists(atPath: file.path) == false)
        #expect(finalReport?.itemsCleaned == 1)
        #expect(finalReport?.itemsFailed == 0)
    }
}
