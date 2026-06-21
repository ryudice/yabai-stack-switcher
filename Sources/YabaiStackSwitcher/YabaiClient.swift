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
