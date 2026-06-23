import XCTest
@testable import YabaiStackSwitcherCore

final class YabaiClientIntegrationTests: XCTestCase {

    private let twoStackedWindows = """
    [
      {"id":1,"pid":1,"app":"Safari","title":"Hello","frame":{"x":0,"y":0,"w":800,"h":600},
       "space":1,"display":1,"stack-index":1,"has-focus":true,
       "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false},
      {"id":2,"pid":2,"app":"Terminal","title":"","frame":{"x":0,"y":0,"w":800,"h":600},
       "space":1,"display":1,"stack-index":2,"has-focus":false,
       "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
    ]
    """

    private let twoDisplays = """
    [
      {"id":1,"index":1,"frame":{"x":0,"y":0,"w":1440,"h":900}},
      {"id":2,"index":2,"frame":{"x":1440,"y":0,"w":1920,"h":1080}}
    ]
    """

    func testQueryWindowsDecodesRealProcessOutput() throws {
        let stub = try StubYabai(windowsJSON: twoStackedWindows)
        let client = YabaiClient(yabaiURL: stub.url)

        let windows = try client.queryWindows()
        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].app, "Safari")
        XCTAssertEqual(windows[1].stackIndex, 2)
        XCTAssertTrue(windows[0].hasFocus)
    }

    func testQueryWindowsEmptyArray() throws {
        let stub = try StubYabai(windowsJSON: "[]")
        let client = YabaiClient(yabaiURL: stub.url)
        XCTAssertEqual(try client.queryWindows(), [])
    }

    func testQueryWindowsEmptyStringReturnsEmpty() throws {
        let stub = try StubYabai(windowsJSON: "")
        let client = YabaiClient(yabaiURL: stub.url)
        XCTAssertEqual(try client.queryWindows(), [])
    }

    func testQueryFocusedWindowDecodesSingleObject() throws {
        let json = """
        {"id":42,"pid":1,"app":"Safari","title":"Focused","frame":{"x":0,"y":0,"w":800,"h":600},
         "space":1,"display":1,"stack-index":1,"has-focus":true,
         "is-visible":true,"is-minimized":false,"is-hidden":false,"is-floating":false}
        """
        let stub = try StubYabai(focusedJSON: json)
        let client = YabaiClient(yabaiURL: stub.url)

        let window = try client.queryFocusedWindow()
        XCTAssertEqual(window.id, 42)
        XCTAssertEqual(window.app, "Safari")
    }

    func testQueryDisplaysDecodesRealProcessOutput() throws {
        let stub = try StubYabai(displaysJSON: twoDisplays)
        let client = YabaiClient(yabaiURL: stub.url)

        let displays = try client.queryDisplays()
        XCTAssertEqual(displays.count, 2)
        XCTAssertEqual(displays[0].index, 1)
        XCTAssertEqual(displays[1].frame.w, 1920)
    }

    func testRunThrowsExitOnNonZeroStatus() throws {
        let stub = try StubYabai()
        try stub.setErrorMode(true)
        let client = YabaiClient(yabaiURL: stub.url)

        XCTAssertThrowsError(try client.run(["-m", "query", "--windows"])) { error in
            if case YabaiError.exit(1) = error {
                // expected
            } else {
                XCTFail("Expected YabaiError.exit(1), got \(error)")
            }
        }
    }

    func testRunThrowsNotFoundWhenURLIsNil() {
        let client = YabaiClient(yabaiURL: nil)
        XCTAssertThrowsError(try client.run(["-m", "query", "--windows"])) { error in
            if case YabaiError.notFound = error {
                // expected
            } else {
                XCTFail("Expected YabaiError.notFound, got \(error)")
            }
        }
    }

    func testConfigGetReturnsValueFromStub() throws {
        let stub = try StubYabai(configValue: "shift")
        let client = YabaiClient(yabaiURL: stub.url)
        XCTAssertEqual(client.configGet("mouse_modifier"), "shift")
    }

    func testConfigGetReturnsNilWhenURLIsNil() {
        let client = YabaiClient(yabaiURL: nil)
        XCTAssertNil(client.configGet("mouse_modifier"))
    }
}
