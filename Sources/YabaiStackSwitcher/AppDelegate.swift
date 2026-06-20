import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let client = YabaiClient()
    private var watcher: StackWatcher!
    private var dragWatcher: DragWatcher!
    private let stackMode = StackModeOverlay()
    private var panels: [String: SwitcherPanel] = [:]
    private var savedMouseModifier: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make Shift the yabai move modifier so a single Shift-drag both moves the
        // window and arms Create Stack Mode. The previous value is restored on quit.
        savedMouseModifier = client.configGet("mouse_modifier")
        client.configSet("mouse_modifier", "shift")

        watcher = StackWatcher(client: client)
        watcher.onChange = { [weak self] stacks, displays in
            self?.updatePanels(stacks: stacks, displays: displays)
        }
        watcher.start()

        dragWatcher = DragWatcher(client: client)
        dragWatcher.onDragStart = { [weak self] dragged, targets, displays in
            self?.stackMode.begin(dragged: dragged, targets: targets, displays: displays)
        }
        dragWatcher.onDragTick = { [weak self] activeId in
            self?.stackMode.setActiveTarget(activeId)
        }
        dragWatcher.onDragEnd = { [weak self] targetId in
            self?.stackMode.end()
            if let id = targetId {
                self?.client.stackOnto(targetWindowId: id)
            }
        }

        SignalNotifier.shared.start(
            onSignal: { [weak self] in self?.watcher.refreshDebounced() },
            onMove: { [weak self] in self?.dragWatcher.onMove() }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        SignalNotifier.shared.stop()
        dragWatcher?.stop()
        watcher?.stop()
        stackMode.end()
        if let prev = savedMouseModifier {
            client.configSet("mouse_modifier", prev)
        }
    }

    private func updatePanels(stacks: [Stack], displays: [YabaiDisplay]) {
        let screens = NSScreen.screens
        let keys = Set(stacks.map(\.key))

        for (k, p) in panels where !keys.contains(k) {
            p.hide()
            panels.removeValue(forKey: k)
        }

        for stack in stacks {
            if let existing = panels[stack.key] {
                existing.update(stack: stack, displays: displays, screens: screens)
            } else {
                let p = SwitcherPanel(stack: stack, displays: displays, screens: screens)
                p.onFocus = { [weak self] id in self?.client.focus(windowId: id) }
                panels[stack.key] = p
            }
            let panel = panels[stack.key]!
            if stack.isOnVisibleSpace { panel.show() } else { panel.hide() }
        }
    }
}
