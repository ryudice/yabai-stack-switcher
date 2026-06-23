import Foundation

enum YabaiError: Error {
    case notFound
    case exit(Int32)
}

final class YabaiClient {
    let yabaiURL: URL?

    init() {
        self.yabaiURL = Self.locate()
    }

    init(yabaiURL: URL?) {
        self.yabaiURL = yabaiURL
    }

    static func locate() -> URL? {
        let candidates = ["/opt/homebrew/bin/yabai", "/usr/local/bin/yabai"]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) {
            return URL(fileURLWithPath: c)
        }
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            for dir in path.split(separator: ":") {
                let p = "\(dir)/yabai"
                if FileManager.default.isExecutableFile(atPath: p) {
                    return URL(fileURLWithPath: p)
                }
            }
        }
        return nil
    }

    @discardableResult
    func run(_ args: [String]) throws -> String {
        guard let url = yabaiURL else { throw YabaiError.notFound }
        let p = Process()
        p.executableURL = url
        p.arguments = args
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        try p.run()
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard p.terminationStatus == 0 else { throw YabaiError.exit(p.terminationStatus) }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func queryWindows() throws -> [YabaiWindow] {
        let raw = try run(["-m", "query", "--windows"])
        guard !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([YabaiWindow].self, from: Data(raw.utf8))
    }

    func queryFocusedWindow() throws -> YabaiWindow {
        let raw = try run(["-m", "query", "--windows", "--window"])
        return try JSONDecoder().decode(YabaiWindow.self, from: Data(raw.utf8))
    }

    func queryDisplays() throws -> [YabaiDisplay] {
        let raw = try run(["-m", "query", "--displays"])
        guard !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([YabaiDisplay].self, from: Data(raw.utf8))
    }

    func querySpaces() throws -> [YabaiSpace] {
        let raw = try run(["-m", "query", "--spaces"])
        guard !raw.isEmpty else { return [] }
        return try JSONDecoder().decode([YabaiSpace].self, from: Data(raw.utf8))
    }

    func focus(windowId: Int) {
        guard let url = yabaiURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = url
            p.arguments = ["-m", "window", "--focus", String(windowId)]
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }

    func stackOnto(targetWindowId: Int) {
        guard let url = yabaiURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = url
            p.arguments = ["-m", "window", "--stack", String(targetWindowId)]
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }

    func close(windowId: Int) {
        guard let url = yabaiURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = url
            p.arguments = ["-m", "window", "--close", String(windowId)]
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }

    func unstack(windowId: Int) {
        guard yabaiURL != nil else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let windows = try? self.queryWindows(),
                  let target = windows.first(where: { $0.id == windowId }) else { return }

            let spaces = (try? self.querySpaces()) ?? []
            let spaceType = spaces.first(where: { $0.index == target.space })?.type ?? "stack"

            if spaceType == "bsp",
               let sibling = windows.first(where: {
                   $0.id != windowId && $0.space == target.space &&
                   $0.stackIndex == 0 && !$0.isFloating && !$0.isMinimized && !$0.isHidden
               }),
               self.warpSync(windowId: windowId, targetId: sibling.id) {
                return
            }
            let orig = target.frame
            self.floatSync(windowId: windowId)
            if spaceType == "stack" {
                self.resizeAndCenterSync(windowId: windowId, within: orig)
            }
        }
    }

    @discardableResult
    private func warpSync(windowId: Int, targetId: Int) -> Bool {
        guard let url = yabaiURL else { return false }
        let p = Process()
        p.executableURL = url
        p.arguments = ["-m", "window", String(windowId), "--warp", String(targetId)]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        do { try p.run() } catch { return false }
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    private func floatSync(windowId: Int) {
        guard let url = yabaiURL else { return }
        let p = Process()
        p.executableURL = url
        p.arguments = ["-m", "window", String(windowId), "--toggle", "float"]
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        try? p.run()
        p.waitUntilExit()
    }

    private func resizeAndCenterSync(windowId: Int, within frame: YabaiFrame) {
        guard let url = yabaiURL else { return }
        let newW = Int((frame.w * 0.5).rounded())
        let newH = Int((frame.h * 0.5).rounded())
        let newX = Int((frame.x + (frame.w * 0.25)).rounded())
        let newY = Int((frame.y + (frame.h * 0.25)).rounded())

        let resize = Process()
        resize.executableURL = url
        resize.arguments = ["-m", "window", String(windowId), "--resize", "abs:\(newW):\(newH)"]
        resize.standardOutput = Pipe()
        resize.standardError = Pipe()
        try? resize.run()
        resize.waitUntilExit()

        let move = Process()
        move.executableURL = url
        move.arguments = ["-m", "window", String(windowId), "--move", "abs:\(newX):\(newY)"]
        move.standardOutput = Pipe()
        move.standardError = Pipe()
        try? move.run()
        move.waitUntilExit()
    }

    func configGet(_ key: String) -> String? {
        guard let url = yabaiURL else { return nil }
        let p = Process()
        p.executableURL = url
        p.arguments = ["-m", "config", key]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let raw = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func configSet(_ key: String, _ value: String) {
        guard let url = yabaiURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = url
            p.arguments = ["-m", "config", key, value]
            p.standardOutput = Pipe()
            p.standardError = Pipe()
            try? p.run()
            p.waitUntilExit()
        }
    }
}
