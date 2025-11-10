//
//  TaskManagerTests.swift
//  TaskManagerTests
//
//  Created by Maty Pierník on 10.11.2025.
//

import XCTest
@testable import TaskManager

final class TaskManagerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testProcessParser() throws {
        // sample ps output (header + two lines)
        let sample = "PID PPID COMMAND %CPU %MEM\n1234 1 /usr/bin/foo 12.3 1.0\n5678 123 /Applications/Bar.app/Contents/MacOS/Bar 0.5 2.2\n"
        let parsed = ProcessStore.parsePS(output: sample)
        XCTAssertEqual(parsed.count, 2)

        let first = parsed[0]
        XCTAssertEqual(first.pid, 1234)
        XCTAssertEqual(first.ppid, 1)
        XCTAssertEqual(first.name, "/usr/bin/foo")
        XCTAssertEqual(first.cpu, 12.3, accuracy: 0.001)
        XCTAssertEqual(first.mem, 1.0, accuracy: 0.001)

        let second = parsed[1]
        XCTAssertEqual(second.pid, 5678)
        XCTAssertEqual(second.ppid, 123)
        XCTAssertEqual(second.name, "/Applications/Bar.app/Contents/MacOS/Bar")
        XCTAssertEqual(second.cpu, 0.5, accuracy: 0.001)
        XCTAssertEqual(second.mem, 2.2, accuracy: 0.001)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
