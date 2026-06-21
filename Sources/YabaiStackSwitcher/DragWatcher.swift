import AppKit
import CoreGraphics

final class DragWatcher {
    private let client: YabaiClient
    private let queue = DispatchQueue(label: "yabai.drag.watcher", qos: .userInitiated)

    private var tickTimer: DispatchSourceTimer?
    private var lastHeartbeat: Date = .distantPast
    private var isDragging = false
    private var dragged: YabaiWindow?
    private var targetRects: [TargetRect] = []
    private var displays: [YabaiDisplay] = []
    private var screens: [NSScreen] = []
    private var lastActiveTarget: Int?

    private let heartbeatTimeout: TimeInterval = 0.18
    private let tickIntervalMs: Int = 50

    var onDragStart: ((YabaiWindow, [YabaiWindow], [YabaiDisplay]) -> Void)?
    var onDragTick: ((Int?) -> Void)?
    var onDragEnd: ((Int?) -> Void)?

    init(client: YabaiClient) {
        self.client = client
    }

    func stop() {
        queue.async { [weak self] in self?.endDrag() }
    }

    // Called on every window_moved signal (SIGUSR2).
    func onMove() {
        queue.async { [weak self] in self?.handleHeartbeat() }
    }

    private func handleHeartbeat() {
        lastHeartbeat = Date()
        if !isDragging {
            guard isArmed() else { return }
            beginDrag()
        }
    }

    private func isArmed() -> Bool {
        CGEventSource.flagsState(.hidSystemState).contains(.maskShift)
    }

    private func beginDrag() {
        guard let focused = try? client.queryFocusedWindow() else { return }
        let allWindows = (try? client.queryWindows()) ?? []
        if displays.isEmpty { displays = (try? client.queryDisplays()) ?? [] }
        screens = NSScreen.screens

        let targets = allWindows.filter { w in
            w.id != focused.id &&
            !w.isMinimized && !w.isHidden && w.isVisible &&
            w.space == focused.space &&
            !(w.frame == focused.frame && w.stackIndex > 0 && focused.stackIndex > 0)
        }

        dragged = focused
        targetRects = targets.compactMap { w in
            guard let tl = SwitcherPanel.topLeft(frame: w.frame, display: w.display,
                                                 displays: displays, screens: screens) else { return nil }
            return TargetRect(id: w.id,
                              rect: NSRect(x: tl.x, y: tl.y - w.frame.h, width: w.frame.w, height: w.frame.h))
        }

        isDragging = true
        lastActiveTarget = nil
        startTick()
        let d = displays
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onDragStart?(focused, targets, d)
        }
    }

    private func startTick() {
        stopTick()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(tickIntervalMs))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        tickTimer = t
    }

    private func stopTick() {
        tickTimer?.cancel()
        tickTimer = nil
    }

    private func tick() {
        guard isDragging else { stopTick(); return }

        if !isArmed() || Date().timeIntervalSince(lastHeartbeat) > heartbeatTimeout {
            endDrag()
            return
        }

        let rects = targetRects
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let mouse = NSEvent.mouseLocation
            let active = rects.first { $0.rect.contains(mouse) }?.id
            self.lastActiveTarget = active
            self.onDragTick?(active)
        }
    }

    private func endDrag() {
        guard isDragging else { return }
        isDragging = false
        stopTick()
        let target = lastActiveTarget
        let droppedOnShift = isArmed()
        dragged = nil
        targetRects = []
        lastActiveTarget = nil
        DispatchQueue.main.async { [weak self] in
            self?.onDragEnd?(droppedOnShift ? target : nil)
        }
    }
}

private struct TargetRect {
    let id: Int
    let rect: NSRect
}
