import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let client = YabaiClient()
    private var watcher: StackWatcher!
    private var panels: [String: SwitcherPanel] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        watcher = StackWatcher(client: client)
        watcher.onChange = { [weak self] stacks, displays in
            self?.updatePanels(stacks: stacks, displays: displays)
        }
        watcher.start()

        SignalNotifier.shared.start { [weak self] in
            self?.watcher.refreshDebounced()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        SignalNotifier.shared.stop()
        watcher?.stop()
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
