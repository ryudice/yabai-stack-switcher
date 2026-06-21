import XCTest
@testable import YabaiStackSwitcherCore

final class ModelsTests: XCTestCase {

    func testYabaiWindowDecodesKebabCaseKeys() throws {
        let json = """
        {
          "id": 123,
          "pid": 456,
          "app": "Safari",
          "title": "Apple",
          "frame": { "x": 10.0, "y": 20.0, "w": 1440.0, "h": 900.0 },
          "space": 1,
          "display": 1,
          "stack-index": 2,
          "has-focus": true,
          "is-visible": false,
          "is-minimized": true,
          "is-hidden": true,
          "is-floating": true
        }
        """
        let window = try JSONDecoder().decode(YabaiWindow.self, from: Data(json.utf8))

        XCTAssertEqual(window.id, 123)
        XCTAssertEqual(window.pid, 456)
        XCTAssertEqual(window.app, "Safari")
        XCTAssertEqual(window.title, "Apple")
        XCTAssertEqual(window.frame, YabaiFrame(x: 10, y: 20, w: 1440, h: 900))
        XCTAssertEqual(window.space, 1)
        XCTAssertEqual(window.display, 1)
        XCTAssertEqual(window.stackIndex, 2)
        XCTAssertTrue(window.hasFocus)
        XCTAssertFalse(window.isVisible)
        XCTAssertTrue(window.isMinimized)
        XCTAssertTrue(window.isHidden)
        XCTAssertTrue(window.isFloating)
    }

    func testDecodesWindowArray() throws {
        let json = """
        [
          { "id": 1, "pid": 1, "app": "A", "title": "", "frame": {"x":0,"y":0,"w":1,"h":1},
            "space": 1, "display": 1, "stack-index": 0, "has-focus": false,
            "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false },
          { "id": 2, "pid": 2, "app": "B", "title": "", "frame": {"x":0,"y":0,"w":1,"h":1},
            "space": 1, "display": 1, "stack-index": 1, "has-focus": true,
            "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false }
        ]
        """
        let windows = try JSONDecoder().decode([YabaiWindow].self, from: Data(json.utf8))
        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows.map(\.id), [1, 2])
        XCTAssertEqual(windows[1].stackIndex, 1)
        XCTAssertTrue(windows[1].hasFocus)
    }

    func testIgnoresUnknownKeys() throws {
        let json = """
        {
          "id": 7, "pid": 1, "app": "A", "title": "", "frame": {"x":0,"y":0,"w":1,"h":1},
          "space": 1, "display": 1, "stack-index": 0, "has-focus": false,
          "is-visible": true, "is-minimized": false, "is-hidden": false, "is-floating": false,
          "extra-field": "ignored", "another": 42
        }
        """
        let window = try JSONDecoder().decode(YabaiWindow.self, from: Data(json.utf8))
        XCTAssertEqual(window.id, 7)
    }

    func testEmptyArrayDecodesToEmpty() throws {
        let windows = try JSONDecoder().decode([YabaiWindow].self, from: Data("[]".utf8))
        XCTAssertEqual(windows, [])
    }

    func testYabaiDisplayDecodes() throws {
        let json = """
        { "id": 1, "index": 1, "frame": { "x": 0.0, "y": 0.0, "w": 1440.0, "h": 900.0 } }
        """
        let display = try JSONDecoder().decode(YabaiDisplay.self, from: Data(json.utf8))
        XCTAssertEqual(display.id, 1)
        XCTAssertEqual(display.index, 1)
        XCTAssertEqual(display.frame, YabaiFrame(x: 0, y: 0, w: 1440, h: 900))
    }

    func testRoundTripEncodeDecode() throws {
        let original = makeWindow(id: 99, stackIndex: 3, hasFocus: true, isFloating: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(YabaiWindow.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testStackWindowIdsPreservesOrder() {
        let stack = Stack(key: "k", space: 1, display: 1,
                          frame: YabaiFrame(x: 0, y: 0, w: 1, h: 1),
                          windows: [makeWindow(id: 10), makeWindow(id: 20), makeWindow(id: 30)],
                          focusedWindowId: 20, isOnVisibleSpace: true)
        XCTAssertEqual(stack.windowIds, [10, 20, 30])
    }

    func testYabaiFrameEquatable() {
        XCTAssertEqual(YabaiFrame(x: 1, y: 2, w: 3, h: 4), YabaiFrame(x: 1, y: 2, w: 3, h: 4))
        XCTAssertNotEqual(YabaiFrame(x: 1, y: 2, w: 3, h: 4), YabaiFrame(x: 1, y: 2, w: 3, h: 5))
    }
}
