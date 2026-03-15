import Testing
@testable import Broom

@Suite("SizeFormatter")
struct SizeFormatterTests {
    @Test func formatsZeroBytes() {
        let result = SizeFormatter.format(0)
        // Locale-dependent: "Zero KB" or "Zero bytes"
        #expect(result.lowercased().contains("zero"))
    }

    @Test func formatsKilobytes() {
        let result = SizeFormatter.format(1_000)
        #expect(result.contains("KB"))
    }

    @Test func formatsMegabytes() {
        let result = SizeFormatter.format(1_500_000)
        #expect(result.contains("MB"))
        // Should be approximately 1.5 MB
        #expect(result.contains("1"))
    }

    @Test func formatsGigabytes() {
        let result = SizeFormatter.format(1_500_000_000)
        #expect(result.contains("GB"))
    }

    @Test func formatsLargeGigabytes() {
        let result = SizeFormatter.format(10_000_000_000)
        #expect(result.contains("GB"))
        #expect(result.contains("10"))
    }
}
