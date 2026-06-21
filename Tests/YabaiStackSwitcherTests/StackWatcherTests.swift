import XCTest
@testable import YabaiStackSwitcherCore

final class StackWatcherTests: XCTestCase {

    private func makeWatcher() -> StackWatcher { StackWatcher(client: YabaiClient()) }

    func testEmptyWindowsYieldsNoStacks() {
        XCTAssertEqual(makeWatcher().groupStacks(windows: []), [])
    }

    func testNonStackedWindowsAreExcluded() {
        let windows = [
            makeWindow(id: 1, stackIndex: 0),
            makeWindow(id: 2, stackIndex: 0)
        ]
        XCTAssertEqual(makeWatcher().groupStacks(windows: windows), [])
    }

    func testMinimizedAndHiddenWindowsAreExcluded() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1),
            makeWindow(id: 2, frame: frame, stackIndex: 2, isMinimized: true),
            makeWindow(id: 3, frame: frame, stackIndex: 3, isHidden: true)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks[0].windowIds, [1])
    }

    func testFloatingStackedWindowsAreIncluded() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1, isFloating: true),
            makeWindow(id: 2, frame: frame, stackIndex: 2, isFloating: true)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks[0].windowIds, [1, 2])
    }

    func testWindowsOnSameSpaceAndFrameAreGrouped() {
        let frame = YabaiFrame(x: 100, y: 100, w: 800, h: 600)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 2),
            makeWindow(id: 2, frame: frame, stackIndex: 1),
            makeWindow(id: 3, frame: frame, stackIndex: 3)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks[0].windowIds, [2, 1, 3])
    }

    func testDifferentSpacesProduceDifferentStacks() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, space: 1, stackIndex: 1),
            makeWindow(id: 2, frame: frame, space: 1, stackIndex: 2),
            makeWindow(id: 3, frame: frame, space: 2, stackIndex: 1),
            makeWindow(id: 4, frame: frame, space: 2, stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 2)
        XCTAssertEqual(Set(stacks.map { $0.space }), [1, 2])
    }

    func testDifferentFramesProduceDifferentStacks() {
        let windows = [
            makeWindow(id: 1, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), stackIndex: 1),
            makeWindow(id: 2, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), stackIndex: 2),
            makeWindow(id: 3, frame: YabaiFrame(x: 500, y: 0, w: 100, h: 100), stackIndex: 1),
            makeWindow(id: 4, frame: YabaiFrame(x: 500, y: 0, w: 100, h: 100), stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 2)
    }

    func testStacksAreSortedByKeyAscending() {
        let windows = [
            makeWindow(id: 1, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), space: 3, stackIndex: 1),
            makeWindow(id: 2, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), space: 3, stackIndex: 2),
            makeWindow(id: 3, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), space: 1, stackIndex: 1),
            makeWindow(id: 4, frame: YabaiFrame(x: 0, y: 0, w: 100, h: 100), space: 1, stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 2)
        XCTAssertLessThan(stacks[0].key, stacks[1].key)
        XCTAssertEqual(stacks[0].space, 1)
        XCTAssertEqual(stacks[1].space, 3)
    }

    func testFocusedWindowIdIsDetected() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1, hasFocus: false),
            makeWindow(id: 2, frame: frame, stackIndex: 2, hasFocus: true),
            makeWindow(id: 3, frame: frame, stackIndex: 3, hasFocus: false)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks[0].focusedWindowId, 2)
    }

    func testFocusedWindowIdIsNilWhenNoneFocused() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1),
            makeWindow(id: 2, frame: frame, stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertNil(stacks[0].focusedWindowId)
    }

    func testIsOnVisibleSpaceTrueWhenAnyVisible() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1, isVisible: false),
            makeWindow(id: 2, frame: frame, stackIndex: 2, isVisible: true)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertTrue(stacks[0].isOnVisibleSpace)
    }

    func testIsOnVisibleSpaceFalseWhenAllHidden() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [
            makeWindow(id: 1, frame: frame, stackIndex: 1, isVisible: false),
            makeWindow(id: 2, frame: frame, stackIndex: 2, isVisible: false)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertFalse(stacks[0].isOnVisibleSpace)
    }

    func testStackMetadataComesFromFirstOrderedWindow() {
        let frame = YabaiFrame(x: 250, y: 300, w: 800, h: 600)
        let windows = [
            makeWindow(id: 1, frame: frame, space: 2, display: 2, stackIndex: 3),
            makeWindow(id: 2, frame: frame, space: 2, display: 2, stackIndex: 1)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks[0].space, 2)
        XCTAssertEqual(stacks[0].display, 2)
        XCTAssertEqual(stacks[0].frame, frame)
    }

    func testFramesThatRoundToSameIntAreGrouped() {
        let windows = [
            makeWindow(id: 1, frame: YabaiFrame(x: 100.3, y: 0, w: 100, h: 100), stackIndex: 1),
            makeWindow(id: 2, frame: YabaiFrame(x: 100.4, y: 0, w: 100, h: 100), stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 1)
    }

    func testFramesThatRoundToDifferentIntsAreSplit() {
        let windows = [
            makeWindow(id: 1, frame: YabaiFrame(x: 100.4, y: 0, w: 100, h: 100), stackIndex: 1),
            makeWindow(id: 2, frame: YabaiFrame(x: 100.6, y: 0, w: 100, h: 100), stackIndex: 2)
        ]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 2)
    }

    func testSingleWindowStackIsReturnedByGroupStacks() {
        let frame = YabaiFrame(x: 0, y: 0, w: 100, h: 100)
        let windows = [makeWindow(id: 1, frame: frame, stackIndex: 1)]
        let stacks = makeWatcher().groupStacks(windows: windows)
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks[0].windowIds, [1])
    }
}
