import Foundation
import Darwin

final class SignalNotifier {
    static let shared = SignalNotifier()

    private let signalNo: Int32 = SIGUSR1
    private let moveSignalNo: Int32 = SIGUSR2
    private let queue = DispatchQueue(label: "yabai.stacks.signal", qos: .userInitiated)
    private var source: DispatchSourceSignal?
    private var moveSource: DispatchSourceSignal?
    private var termSource: DispatchSourceSignal?
    private var onSignal: (() -> Void)?
    private var onMove: (() -> Void)?

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
    private let moveLabel = "yss-window_moved-move"

    private init() {
        self.client = YabaiClient()
        self.pid = ProcessInfo.processInfo.processIdentifier
    }

    func start(onSignal: @escaping () -> Void, onMove: @escaping () -> Void) {
        self.onSignal = onSignal
        self.onMove = onMove

        signal(signalNo, SIG_IGN)
        let src = DispatchSource.makeSignalSource(signal: signalNo, queue: queue)
        src.setEventHandler { [weak self] in self?.onSignal?() }
        src.resume()
        self.source = src

        signal(moveSignalNo, SIG_IGN)
        let msrc = DispatchSource.makeSignalSource(signal: moveSignalNo, queue: queue)
        msrc.setEventHandler { [weak self] in self?.onMove?() }
        msrc.resume()
        self.moveSource = msrc

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
        moveSource?.cancel()
        moveSource = nil
        termSource?.cancel()
        termSource = nil
        onSignal = nil
        onMove = nil
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
        // Dedicated heartbeat for interactive window moves, dispatched as SIGUSR2 so
        // the drag watcher can react to motion without re-querying on every event.
        let moveAction = "kill -USR2 \(pid) 2>/dev/null"
        _ = try? client.run(["-m", "signal", "--remove", moveLabel])
        _ = try? client.run(["-m", "signal", "--add",
                             "event=window_moved", "action=\(moveAction)", "label=\(moveLabel)"])
    }

    private func unregisterSignals() {
        guard client.yabaiURL != nil else { return }
        for ev in events {
            _ = try? client.run(["-m", "signal", "--remove", "\(labelPrefix)-\(ev)"])
        }
        _ = try? client.run(["-m", "signal", "--remove", moveLabel])
    }
}
