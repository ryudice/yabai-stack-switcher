import Foundation
import Darwin

final class SignalNotifier {
    static let shared = SignalNotifier()

    private let signalNo: Int32 = SIGUSR1
    private let queue = DispatchQueue(label: "yabai.stacks.signal", qos: .userInitiated)
    private var source: DispatchSourceSignal?
    private var termSource: DispatchSourceSignal?
    private var onSignal: (() -> Void)?

    private let client: YabaiClient
    private let pid: Int32
    private let labelPrefix = "yss"
    private let events = [
        "space_changed",
        "window_focused",
        "window_moved",
        "window_resized",
        "window_created",
        "window_destroyed",
        "window_minimized",
        "window_deminimized",
        "application_front_switched"
    ]

    private init() {
        self.client = YabaiClient()
        self.pid = ProcessInfo.processInfo.processIdentifier
    }

    func start(onSignal: @escaping () -> Void) {
        self.onSignal = onSignal
        signal(signalNo, SIG_IGN)
        let src = DispatchSource.makeSignalSource(signal: signalNo, queue: queue)
        src.setEventHandler { [weak self] in self?.onSignal?() }
        src.resume()
        self.source = src
        registerSignals()

        signal(SIGTERM, SIG_IGN)
        let term = DispatchSource.makeSignalSource(signal: SIGTERM, queue: queue)
        term.setEventHandler { [weak self] in
            self?.stop()
            DispatchQueue.main.async { exit(0) }
        }
        term.resume()
        self.termSource = term
    }

    func stop() {
        source?.cancel()
        source = nil
        termSource?.cancel()
        termSource = nil
        onSignal = nil
        unregisterSignals()
    }

    private func registerSignals() {
        guard client.yabaiURL != nil else { return }
        let action = "kill -USR1 \(pid) 2>/dev/null"
        for ev in events {
            let label = "\(labelPrefix)-\(ev)"
            _ = try? client.run(["-m", "signal", "--remove", label])
            _ = try? client.run(["-m", "signal", "--add",
                                 "event=\(ev)", "action=\(action)", "label=\(label)"])
        }
    }

    private func unregisterSignals() {
        guard client.yabaiURL != nil else { return }
        for ev in events {
            _ = try? client.run(["-m", "signal", "--remove", "\(labelPrefix)-\(ev)"])
        }
    }
}
