import Foundation

struct YabaiFrame: Codable, Equatable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double
}

struct YabaiWindow: Codable, Equatable {
    var id: Int
    var pid: Int
    var app: String
    var title: String
    var frame: YabaiFrame
    var space: Int
    var display: Int
    var stackIndex: Int
    var hasFocus: Bool
    var isVisible: Bool
    var isMinimized: Bool
    var isHidden: Bool
    var isFloating: Bool

    enum CodingKeys: String, CodingKey {
        case id, pid, app, title, frame, space, display
        case stackIndex = "stack-index"
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
        case isMinimized = "is-minimized"
        case isHidden = "is-hidden"
        case isFloating = "is-floating"
    }
}

struct YabaiDisplay: Codable, Equatable {
    var id: Int
    var index: Int
    var frame: YabaiFrame
}

struct YabaiSpace: Codable, Equatable {
    var id: Int
    var index: Int
    var label: String
    var type: String
    var display: Int
    var windows: [Int]
}

struct Stack: Equatable {
    var key: String
    var space: Int
    var display: Int
    var frame: YabaiFrame
    var windows: [YabaiWindow]
    var focusedWindowId: Int?
    var isOnVisibleSpace: Bool

    var windowIds: [Int] { windows.map(\.id) }
}
