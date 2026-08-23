import XCTest

final class BroomUITests: XCTestCase {
    @MainActor
    func testMainWindowShowsAllSidebarSections() throws {
        let app = XCUIApplication()
        app.launch()

        for title in ["Clean", "Uninstall", "Artifacts", "Large Files"] {
            XCTAssertTrue(
                app.staticTexts[title].waitForExistence(timeout: 10),
                "Sidebar row '\(title)' not found"
            )
        }
    }

    @MainActor
    func testCleanerShowsScanButton() throws {
        let app = XCUIApplication()
        app.launch()

        let scanButton = app.buttons["cleaner-scan-button"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 10), "Scan button not found in Cleaner")
    }

    @MainActor
    func testSwitchingToUninstallerShowsScanAppsButton() throws {
        let app = XCUIApplication()
        app.launch()

        let uninstallRow = app.staticTexts["Uninstall"]
        XCTAssertTrue(uninstallRow.waitForExistence(timeout: 10))
        uninstallRow.click()

        XCTAssertTrue(
            app.buttons["uninstaller-scan-button"].waitForExistence(timeout: 10),
            "Uninstaller idle view did not appear after selecting the section"
        )
    }

    @MainActor
    func testSwitchingToArtifactsShowsScanButton() throws {
        let app = XCUIApplication()
        app.launch()

        let artifactsRow = app.staticTexts["Artifacts"]
        XCTAssertTrue(artifactsRow.waitForExistence(timeout: 10))
        artifactsRow.click()

        XCTAssertTrue(
            app.buttons["artifacts-scan-button"].waitForExistence(timeout: 10),
            "Project Artifacts idle view did not appear after selecting the section"
        )
    }
}
