import AppKit

let bundleId = Bundle.main.bundleIdentifier ?? "com.yabai.stack-switcher"
let myPid = ProcessInfo.processInfo.processIdentifier
if let existing = NSWorkspace.shared.runningApplications.first(where: {
    $0.bundleIdentifier == bundleId && $0.processIdentifier != myPid
}) {
    existing.activate()
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
