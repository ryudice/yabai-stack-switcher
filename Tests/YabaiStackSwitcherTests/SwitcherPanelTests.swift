import XCTest
import AppKit
@testable import YabaiStackSwitcherCore

final class SwitcherPanelTests: XCTestCase {

    private func screen(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
        NSRect(x: x, y: y, width: w, height: h)
    }

    func testTopLeftAtOriginOfFullScreenSingleDisplay() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: 0, y: 0, w: 1440, h: 900),
            displayFrame: YabaiFrame(x: 0, y: 0, w: 1440, h: 900),
            screenFrame: screen(0, 0, 1440, 900)
        )
        XCTAssertEqual(pt.x, 0)
        XCTAssertEqual(pt.y, 900)
    }

    func testTopLeftOffsetsWindowWithinDisplay() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: 100, y: 100, w: 800, h: 600),
            displayFrame: YabaiFrame(x: 0, y: 0, w: 1440, h: 900),
            screenFrame: screen(0, 0, 1440, 900)
        )
        XCTAssertEqual(pt.x, 100)
        XCTAssertEqual(pt.y, 800)
    }

    func testTopLeftFlipsYabaiTopLeftOriginToAppKitBottomLeft() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: 0, y: 0, w: 1, h: 1),
            displayFrame: YabaiFrame(x: 0, y: 0, w: 1440, h: 900),
            screenFrame: screen(0, 0, 1440, 900)
        )
        XCTAssertEqual(pt.y, 900)
    }

    func testTopLeftForSecondaryDisplayToTheRight() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: 1440, y: 0, w: 1920, h: 1080),
            displayFrame: YabaiFrame(x: 1440, y: 0, w: 1920, h: 1080),
            screenFrame: screen(1440, 0, 1920, 1080)
        )
        XCTAssertEqual(pt.x, 1440)
        XCTAssertEqual(pt.y, 1080)
    }

    func testTopLeftForDisplayToTheLeftWithNegativeOrigin() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: -1920, y: 0, w: 1920, h: 1080),
            displayFrame: YabaiFrame(x: -1920, y: 0, w: 1920, h: 1080),
            screenFrame: screen(-1920, 0, 1920, 1080)
        )
        XCTAssertEqual(pt.x, -1920)
        XCTAssertEqual(pt.y, 1080)
    }

    func testTopLeftHandlesNonZeroDisplayOrigin() {
        let pt = SwitcherPanel.topLeftPoint(
            frame: YabaiFrame(x: 0, y: 100, w: 800, h: 600),
            displayFrame: YabaiFrame(x: 0, y: 25, w: 1440, h: 875),
            screenFrame: screen(0, 0, 1440, 900)
        )
        XCTAssertEqual(pt.x, 0)
        XCTAssertEqual(pt.y, 825)
    }

    func testTopLeftReturnsNilWhenDisplaysEmpty() {
        let pt = SwitcherPanel.topLeft(
            frame: YabaiFrame(x: 0, y: 0, w: 1, h: 1),
            display: 1, displays: [], screens: []
        )
        XCTAssertNil(pt)
    }

    func testTopLeftReturnsNilWhenScreensEmpty() {
        let pt = SwitcherPanel.topLeft(
            frame: YabaiFrame(x: 0, y: 0, w: 1, h: 1),
            display: 1,
            displays: [YabaiDisplay(id: 1, index: 1, frame: YabaiFrame(x: 0, y: 0, w: 1440, h: 900))],
            screens: []
        )
        XCTAssertNil(pt)
    }

    func testScreenForDisplayFallsBackToFirstScreen() {
        let screens = SwitcherPanel.screen(forDisplay: 99, screens: [])
        XCTAssertNil(screens)
    }
}
