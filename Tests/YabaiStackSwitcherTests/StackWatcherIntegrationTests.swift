import XCTest
@testable import YabaiStackSwitcherCore

final class StackWatcherIntegrationTests: XCTestCase {

    private let twoStackedWindows = """
    [
      {"id":1,"pid":1,"app":"A","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
       "space":1,"display":1,"stack-index":1,"has-focus":true,
       "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
      {"id":2,"pid":2,"app":"B","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
       "space":1,"display":1,"stack-index":2,"has-focus":false,
       "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
    ]
    """

    private let singleDisplay = """
    [{"id":1,"index":1,"frame":{"x":0,"y":0,"w":1440,"h":900}}]
    """

    func testRefreshFiresOnChangeForStacksWithTwoOrMoreWindows() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows,
                                 displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        let exp = XCTestExpectation(description: "onChange fired")
        var capturedStacks: [Stack] = []
        var capturedDisplays: [YabaiDisplay] = []

        watcher.onChange = { stacks, displays in
            capturedStacks = stacks
            capturedDisplays = displays
            exp.fulfill()
        }

        watcher.refresh()
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(capturedStacks.count, 1)
        XCTAssertEqual(capturedStacks[0].windowIds, [1, 2])
        XCTAssertEqual(capturedStacks[0].focusedWindowId, 1)
        XCTAssertTrue(capturedStacks[0].isOnVisibleSpace)
        XCTAssertEqual(capturedDisplays.count, 1)
        XCTAssertEqual(capturedDisplays[0].index, 1)
    }

    func testRefreshFiltersOutStacksWithFewerThanTwoWindows() throws {
        let windowsJSON = """
        [
          {"id":1,"pid":1,"app":"A","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":1,"has-focus":true,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
          {"id":2,"pid":2,"app":"B","title":"","frame":{"x":500,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":1,"has-focus":false,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
        ]
        """
        let stub = try StubYabai(windowsJSON: windowsJSON, displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        let exp = XCTestExpectation(description: "onChange should not fire")
        exp.isInverted = true

        watcher.onChange = { _, _ in exp.fulfill() }

        watcher.refresh()
        wait(for: [exp], timeout: 0.5)
    }

    func testRefreshDoesNotRefireOnUnchangedState() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows,
                                 displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        var callCount = 0
        let firstExp = XCTestExpectation(description: "first onChange")

        watcher.onChange = { _, _ in
            callCount += 1
            firstExp.fulfill()
        }

        watcher.refresh()
        wait(for: [firstExp], timeout: 2.0)
        XCTAssertEqual(callCount, 1)

        let noFireExp = XCTestExpectation(description: "should not refire")
        noFireExp.isInverted = true
        watcher.onChange = { _, _ in noFireExp.fulfill() }

        watcher.refresh()
        wait(for: [noFireExp], timeout: 0.5)
        XCTAssertEqual(callCount, 1)
    }

    func testRefreshRefiresWhenFocusedWindowChanges() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows,
                                 displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        var callCount = 0
        var lastFocused: Int?
        let firstExp = XCTestExpectation(description: "first")

        watcher.onChange = { stacks, _ in
            callCount += 1
            lastFocused = stacks.first?.focusedWindowId
            firstExp.fulfill()
        }

        watcher.refresh()
        wait(for: [firstExp], timeout: 2.0)
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(lastFocused, 1)

        let changedJSON = """
        [
          {"id":1,"pid":1,"app":"A","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":1,"has-focus":false,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
          {"id":2,"pid":2,"app":"B","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":2,"has-focus":true,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
        ]
        """
        try stub.setWindows(changedJSON)

        let secondExp = XCTestExpectation(description: "second")
        watcher.onChange = { stacks, _ in
            callCount += 1
            lastFocused = stacks.first?.focusedWindowId
            secondExp.fulfill()
        }

        watcher.refresh()
        wait(for: [secondExp], timeout: 2.0)
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(lastFocused, 2)
    }

    func testRefreshRefiresWhenWindowIsAddedToStack() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows,
                                 displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        var callCount = 0
        var lastWindowIds: [Int] = []
        let firstExp = XCTestExpectation(description: "first")

        watcher.onChange = { stacks, _ in
            callCount += 1
            lastWindowIds = stacks.first?.windowIds ?? []
            firstExp.fulfill()
        }

        watcher.refresh()
        wait(for: [firstExp], timeout: 2.0)
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(lastWindowIds, [1, 2])

        let threeWindows = """
        [
          {"id":1,"pid":1,"app":"A","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":1,"has-focus":true,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
          {"id":2,"pid":2,"app":"B","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":2,"has-focus":false,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
          {"id":3,"pid":3,"app":"C","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
           "space":1,"display":1,"stack-index":3,"has-focus":false,
           "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
        ]
        """
        try stub.setWindows(threeWindows)

        let secondExp = XCTestExpectation(description: "second")
        watcher.onChange = { stacks, _ in
            callCount += 1
            lastWindowIds = stacks.first?.windowIds ?? []
            secondExp.fulfill()
        }

        watcher.refresh()
        wait(for: [secondExp], timeout: 2.0)
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(lastWindowIds, [1, 2, 3])
    }

    func testRefreshDoesNotFireWhenYabaiErrors() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows)
        try stub.setErrorMode(true)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        let exp = XCTestExpectation(description: "should not fire on error")
        exp.isInverted = true

        watcher.onChange = { _, _ in exp.fulfill() }

        watcher.refresh()
        wait(for: [exp], timeout: 0.5)
    }

    func testRefreshPassesDisplaysToOnChange() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows,
                                 displaysJSON: singleDisplay)
        let client = YabaiClient(yabaiURL: stub.url)
        let watcher = StackWatcher(client: client)

        let exp = XCTestExpectation(description: "onChange")
        var capturedDisplays: [YabaiDisplay] = []

        watcher.onChange = { _, displays in
            capturedDisplays = displays
            exp.fulfill()
        }

        watcher.refresh()
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(capturedDisplays.count, 1)
        XCTAssertEqual(capturedDisplays[0].frame.w, 1440)
    }
}
