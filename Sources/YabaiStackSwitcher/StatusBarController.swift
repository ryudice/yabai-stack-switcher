import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let onSettings: () -> Void
    private let onQuit: () -> Void

    init(onSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.onSettings = onSettings
        self.onQuit = onQuit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureIcon()
        configureMenu()
    }

    private func configureIcon() {
        let button = statusItem.button
        if let symbol = NSImage(systemSymbolName: "square.stack.3d.up",
                                accessibilityDescription: "Yabai Stack Switcher") {
            symbol.isTemplate = true
            button?.image = symbol
        } else {
            button?.title = "⊫"
        }
        button?.toolTip = "Yabai Stack Switcher"
    }

    private func configureMenu() {
        let menu = NSMenu()

        let settings = NSMenuItem(title: "Settings…",
                                   action: #selector(handleSettings),
                                   keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Yabai Stack Switcher",
                               action: #selector(handleQuit),
                               keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func handleSettings() {
        onSettings()
    }

    @objc private func handleQuit() {
        onQuit()
    }
}
