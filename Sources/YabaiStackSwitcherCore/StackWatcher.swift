import Foundation

final class StackWatcher {
    private let client: YabaiClient
    private let queue = DispatchQueue(label: "yabai.stacks.watcher", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var debounceItem: DispatchWorkItem?
    private var lastSignature: [String] = []
    private var cachedDisplays: [YabaiDisplay] = []
    private var displaysQueriedAt: Date = .distantPast
    private var refreshing = false
    var onChange: (([Stack], [YabaiDisplay]) -> Void)?

    init(client: YabaiClient) {
        self.client = client
    }

    func start(intervalMs: Int = 1000) {
        stop()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(intervalMs))
        t.setEventHandler { [weak self] in self?.refresh() }
        t.resume()
        self.timer = t
        refresh()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        debounceItem?.cancel()
        debounceItem = nil
    }

    func refreshNow() {
        queue.async { [weak self] in self?.refresh() }
    }

    func refreshDebounced(delay: TimeInterval = 0.03) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.debounceItem?.cancel()
            let item = DispatchWorkItem { [weak self] in self?.refresh() }
            self.debounceItem = item
            self.queue.asyncAfter(deadline: .now() + delay, execute: item)
        }
    }

    func refresh() {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }

        let windows: [YabaiWindow]
        do { windows = try client.queryWindows() } catch { return }

        if Date().timeIntervalSince(displaysQueriedAt) > 5 {
            if let d = try? client.queryDisplays() { cachedDisplays = d }
            displaysQueriedAt = Date()
        }

        let stacks = groupStacks(windows: windows).filter { $0.windows.count >= 2 }
        let signature = stacks.map {
            "\($0.key)|[\($0.windowIds.map(String.init).joined(separator: ","))]|\($0.focusedWindowId ?? -1)|\($0.isOnVisibleSpace ? 1 : 0)"
        }
        if signature != lastSignature {
            lastSignature = signature
            let displays = cachedDisplays
            DispatchQueue.main.async { [weak self] in
                self?.onChange?(stacks, displays)
            }
        }
    }

    func groupStacks(windows: [YabaiWindow]) -> [Stack] {
        let stacked = windows.filter {
            $0.stackIndex > 0 && !$0.isMinimized && !$0.isHidden
        }
        var groups: [String: [YabaiWindow]] = [:]
        for w in stacked {
            let k = "\(w.space)|\(ri(w.frame.x))|\(ri(w.frame.y))|\(ri(w.frame.w))|\(ri(w.frame.h))"
            groups[k, default: []].append(w)
        }
        var stacks: [Stack] = []
        for (k, ws) in groups {
            let ordered = ws.sorted { $0.stackIndex < $1.stackIndex }
            guard let first = ordered.first else { continue }
            let focused = ordered.first(where: { $0.hasFocus })?.id
            let visible = ordered.contains { $0.isVisible }
            stacks.append(Stack(key: k, space: first.space, display: first.display,
                                frame: first.frame, windows: ordered,
                                focusedWindowId: focused, isOnVisibleSpace: visible))
        }
        return stacks.sorted { $0.key < $1.key }
    }
}

private func ri(_ v: Double) -> Int { Int(v.rounded()) }
