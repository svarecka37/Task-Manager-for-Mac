//
//  TaskManagerUITests.swift
//  TaskManagerUITests
//
//  Created by Maty Pierník on 10.11.2025.
//

import XCTest

final class TaskManagerUITests: XCTestCase {

    override func setUpWithError() throws {

        continueAfterFailure = false

    }

    override func tearDownWithError() throws {

    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        // Verify main title exists. Try a few strategies to make the check robust on macOS:
        // 1) visible static text label "Task Manager"
        // 2) static text with accessibility identifier "mainTitle"
        // 3) static text inside the first window
        let titleByLabel = app.staticTexts["Task Manager"].firstMatch
        let titleById = app.staticTexts["mainTitle"].firstMatch
        let windowTitle = app.windows.firstMatch.staticTexts["Task Manager"].firstMatch
    let anyElementById = app.descendants(matching: .any).matching(identifier: "mainTitleElement").firstMatch

        let found = titleByLabel.waitForExistence(timeout: 8)
            || titleById.waitForExistence(timeout: 2)
            || windowTitle.waitForExistence(timeout: 2)
            || anyElementById.waitForExistence(timeout: 2)

        XCTAssertTrue(found, "Main title should exist")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
