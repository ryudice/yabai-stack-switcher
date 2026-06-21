import Foundation
@testable import YabaiStackSwitcherCore

func makeWindow(
    id: Int,
    pid: Int = 1,
    app: String = "App",
    title: String = "",
    frame: YabaiFrame = YabaiFrame(x: 0, y: 0, w: 800, h: 600),
    space: Int = 1,
    display: Int = 1,
    stackIndex: Int = 0,
    hasFocus: Bool = false,
    isVisible: Bool = true,
    isMinimized: Bool = false,
    isHidden: Bool = false,
    isFloating: Bool = false
) -> YabaiWindow {
    YabaiWindow(id: id, pid: pid, app: app, title: title, frame: frame,
                space: space, display: display, stackIndex: stackIndex,
                hasFocus: hasFocus, isVisible: isVisible,
                isMinimized: isMinimized, isHidden: isHidden,
                isFloating: isFloating)
}
