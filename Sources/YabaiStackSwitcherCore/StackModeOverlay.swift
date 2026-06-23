import AppKit

// MARK: - TargetOverlay

final class TargetOverlay {
    let windowId: Int
    private let panel: NSPanel
    private let view: TargetOverlayView
    private(set) var isActive = false

    init(windowId: Int, rect: NSRect) {
        self.windowId = windowId
        let v = TargetOverlayView(frame: .zero)
        self.view = v

        let p = NSPanel(contentRect: NSRect(origin: .zero, size: rect.size),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.isMovable = false
        p.hidesOnDeactivate = false
        p.isFloatingPanel = true
        p.becomesKeyOnlyIfNeeded = false
        p.level = .floating
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        p.contentView = v
        v.frame = NSRect(origin: .zero, size: rect.size)
        p.setFrameOrigin(rect.origin)
        self.panel = p
    }

    func show() { panel.orderFront(nil) }
    func hide() { panel.orderOut(nil) }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        view.isActive = active
        view.needsDisplay = true
    }
}

private final class TargetOverlayView: NSView {
    var isActive = false

    override func draw(_ dirtyRect: NSRect) {
        let inset: CGFloat = 2
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset),
                                xRadius: 10, yRadius: 10)

        let accent = NSColor.controlAccentColor
        accent.withAlphaComponent(isActive ? 0.18 : 0.05).setFill()
        path.fill()

        accent.withAlphaComponent(isActive ? 1.0 : 0.45).setStroke()
        path.lineWidth = isActive ? 4 : 2
        if isActive { path.lineJoinStyle = .round }
        path.stroke()

        // Center drop-zone: a prominent dashed ring marking the stack target.
        let side: CGFloat = isActive ? 64 : 28
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let ringRect = NSRect(x: center.x - side / 2, y: center.y - side / 2,
                              width: side, height: side)
        let ring = NSBezierPath(ovalIn: ringRect)

        if isActive {
            accent.withAlphaComponent(0.92).setFill()
            ring.fill()
            NSColor.white.setStroke()
            ring.lineWidth = 2
            ring.stroke()

            // "Drop to stack" label inside the drop zone.
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let s = "DROP\nTO\nSTACK" as NSString
            let lines = s.components(separatedBy: "\n")
            let lh: CGFloat = 12
            let totalH = lh * CGFloat(lines.count)
            var y = center.y + totalH / 2 - lh
            for line in lines {
                let ls = line as NSString
                let sz = ls.size(withAttributes: attrs)
                ls.draw(at: NSPoint(x: center.x - sz.width / 2, y: y - lh + 2),
                        withAttributes: attrs)
                y -= lh
            }
        } else {
            accent.withAlphaComponent(0.6).setStroke()
            ring.lineWidth = 1.5
            ring.setLineDash([4, 4], count: 2, phase: 0)
            ring.stroke()
        }
    }
}

// MARK: - ModeIndicatorPanel

private final class ModeIndicatorPanel {
    private let panel: NSPanel
    private let view: ModeIndicatorView
    private let size = NSSize(width: 196, height: 30)

    init() {
        let v = ModeIndicatorView(frame: .zero)
        self.view = v
        let p = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovable = false
        p.hidesOnDeactivate = false
        p.isFloatingPanel = true
        p.becomesKeyOnlyIfNeeded = false
        p.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        p.contentView = v
        v.frame = NSRect(origin: .zero, size: size)
        self.panel = p
    }

    func show(on screen: NSScreen) {
        let vf = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: vf.midX - size.width / 2,
                                     y: vf.maxY - size.height - 10))
        panel.orderFront(nil)
    }

    func hide() { panel.orderOut(nil) }
}

private final class ModeIndicatorView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 14, yRadius: 14)
        NSColor.windowBackgroundColor.withAlphaComponent(0.82).setFill()
        path.fill()
        NSColor.controlAccentColor.withAlphaComponent(0.9).setStroke()
        path.lineWidth = 1.5
        path.stroke()

        let accent = NSColor.controlAccentColor
        if let symbol = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "stack") {
            symbol.isTemplate = true
            let side: CGFloat = 16
            let imgRect = NSRect(x: 10, y: bounds.midY - side / 2, width: side, height: side)
            let tinted = symbol.tinted(with: accent)
            tinted.size = imgRect.size
            tinted.draw(in: imgRect)
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        let s = "Create Stack Mode" as NSString
        let textSize = s.size(withAttributes: attrs)
        let textX: CGFloat = 32
        s.draw(at: NSPoint(x: textX, y: bounds.midY - textSize.height / 2), withAttributes: attrs)
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let img = NSImage(size: size)
        img.lockFocus()
        draw(in: NSRect(origin: .zero, size: size),
             from: .zero, operation: .copy, fraction: 1)
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        img.unlockFocus()
        return img
    }
}

// MARK: - StackModeOverlay

final class StackModeOverlay {
    private var indicator: ModeIndicatorPanel?
    private var overlays: [TargetOverlay] = []

    func begin(dragged: YabaiWindow, targets: [YabaiWindow], displays: [YabaiDisplay]) {
        end()

        let screens = NSScreen.screens
        let ind = ModeIndicatorPanel()
        if let screen = SwitcherPanel.screen(forDisplay: dragged.display, screens: screens) {
            ind.show(on: screen)
        }
        indicator = ind

        overlays = targets.compactMap { w in
            guard let tl = SwitcherPanel.topLeft(frame: w.frame, display: w.display,
                                                 displays: displays, screens: screens) else { return nil }
            let rect = NSRect(x: tl.x, y: tl.y - w.frame.h, width: w.frame.w, height: w.frame.h)
            let o = TargetOverlay(windowId: w.id, rect: rect)
            o.show()
            return o
        }
    }

    func setActiveTarget(_ id: Int?) {
        for o in overlays {
            o.setActive(o.windowId == id)
        }
    }

    func end() {
        for o in overlays { o.hide() }
        overlays = []
        indicator?.hide()
        indicator = nil
    }
}
