import XCTest

final class blockblastUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeToModeToClassicGameFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.buttons["home.playButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 3))
        playButton.tap()

        let classicButton = app.buttons["mode.classic.start"]
        XCTAssertTrue(classicButton.waitForExistence(timeout: 3))
        classicButton.tap()

        let pauseButton = app.buttons["game.pauseButton"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 4))
    }

    @MainActor
    func testSettingsTogglesAreReachable() throws {
        let app = XCUIApplication()
        app.launch()

        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        let soundToggle = app.switches["settings.soundToggle"]
        XCTAssertTrue(soundToggle.waitForExistence(timeout: 3))

        let initialValue = String(describing: soundToggle.value)
        soundToggle.tap()
        let newValue = String(describing: soundToggle.value)
        XCTAssertNotEqual(initialValue, newValue)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
