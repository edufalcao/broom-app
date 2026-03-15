import Foundation
import Testing
@testable import Broom

@Suite("LargeFileScanner")
struct LargeFileScannerTests {
    @Test func findsFilesAboveThreshold() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "LargeFileScan")
        defer { try? FileManager.default.removeItem(at: dir) }

        // Create a file larger than threshold
        let bigFile = dir.appendingPathComponent("big.dmg")
        let bigData = Data(repeating: 0x42, count: 200_000)
        try bigData.write(to: bigFile)

        // Create a file smaller than threshold
        let smallFile = dir.appendingPathComponent("small.txt")
        try "hello".data(using: .utf8)?.write(to: smallFile)

        let scanner = LargeFileScanner()
        var foundFiles: [LargeFile] = []

        for await progress in scanner.scan(root: dir, minimumSize: 100_000) {
            if case .complete(let files) = progress {
                foundFiles = files
            }
        }

        #expect(foundFiles.count == 1)
        #expect(foundFiles.first?.name == "big.dmg")
        #expect(foundFiles.first!.size >= 200_000)
    }

    @Test func returnsEmptyWhenNoLargeFiles() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "LargeFileScanEmpty")
        defer { try? FileManager.default.removeItem(at: dir) }

        let smallFile = dir.appendingPathComponent("tiny.txt")
        try "hi".data(using: .utf8)?.write(to: smallFile)

        let scanner = LargeFileScanner()
        var foundFiles: [LargeFile] = []

        for await progress in scanner.scan(root: dir, minimumSize: 1_000_000) {
            if case .complete(let files) = progress {
                foundFiles = files
            }
        }

        #expect(foundFiles.isEmpty)
    }

    @Test func resultsSortedBySizeDescending() async throws {
        let dir = try TestSupport.makeTempDirectory(prefix: "LargeFileScanSort")
        defer { try? FileManager.default.removeItem(at: dir) }

        let medium = dir.appendingPathComponent("medium.bin")
        try Data(repeating: 0x01, count: 150_000).write(to: medium)

        let large = dir.appendingPathComponent("large.bin")
        try Data(repeating: 0x02, count: 300_000).write(to: large)

        let scanner = LargeFileScanner()
        var foundFiles: [LargeFile] = []

        for await progress in scanner.scan(root: dir, minimumSize: 100_000) {
            if case .complete(let files) = progress {
                foundFiles = files
            }
        }

        #expect(foundFiles.count == 2)
        #expect(foundFiles[0].name == "large.bin")
        #expect(foundFiles[1].name == "medium.bin")
    }
}
