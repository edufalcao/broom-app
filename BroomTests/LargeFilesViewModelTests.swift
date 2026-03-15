import Foundation
import Testing
@testable import Broom

@Suite("LargeFilesViewModel")
struct LargeFilesViewModelTests {
    @Test func toggleFileSelection() async {
        let vm = await LargeFilesViewModel()
        let file = LargeFile(
            path: URL(fileURLWithPath: "/tmp/test.dmg"),
            size: 500_000_000,
            isSelected: false
        )
        await MainActor.run { vm.files = [file] }

        await vm.toggleFile(file.id)
        #expect(await vm.files[0].isSelected == true)
        #expect(await vm.selectedCount == 1)

        await vm.toggleFile(file.id)
        #expect(await vm.files[0].isSelected == false)
        #expect(await vm.selectedCount == 0)
    }

    @Test func selectAllAndDeselectAll() async {
        let vm = await LargeFilesViewModel()
        let files = [
            LargeFile(path: URL(fileURLWithPath: "/tmp/a.dmg"), size: 100_000_000, isSelected: false),
            LargeFile(path: URL(fileURLWithPath: "/tmp/b.dmg"), size: 200_000_000, isSelected: false),
        ]
        await MainActor.run { vm.files = files }

        await vm.selectAll()
        #expect(await vm.selectedCount == 2)
        #expect(await vm.selectedSize == 300_000_000)

        await vm.deselectAll()
        #expect(await vm.selectedCount == 0)
        #expect(await vm.selectedSize == 0)
    }

    @Test func sortedFilesByName() async {
        let vm = await LargeFilesViewModel()
        let files = [
            LargeFile(path: URL(fileURLWithPath: "/tmp/zebra.bin"), size: 100_000_000),
            LargeFile(path: URL(fileURLWithPath: "/tmp/alpha.bin"), size: 200_000_000),
        ]
        await MainActor.run {
            vm.files = files
            vm.sortOrder = .name
        }

        let sorted = await vm.sortedFiles
        #expect(sorted[0].name == "alpha.bin")
        #expect(sorted[1].name == "zebra.bin")
    }

    @Test func resetClearsState() async {
        let vm = await LargeFilesViewModel()
        await MainActor.run {
            vm.files = [LargeFile(path: URL(fileURLWithPath: "/tmp/a"), size: 100)]
            vm.state = .results
        }

        await vm.reset()
        #expect(await vm.files.isEmpty)
        #expect(await vm.state == .idle)
    }
}
