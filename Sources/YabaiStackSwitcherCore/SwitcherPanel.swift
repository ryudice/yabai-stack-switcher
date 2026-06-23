import AppKit

// MARK: - IconCell

final class IconCell: NSView {
    let windowId: Int
    private let app: String
    private let title: String
    private let image: NSImage?
    private var isFocused: Bool
    private var isHovered: Bool = false
    private var dragStart: NSPoint?
    private var isDragging = false
    private let dragThreshold: CGFloat = 4
    var onFocus: ((Int) -> Void)?
    var onUnstack: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onDragBegin: (() -> Void)?
    var onDrag: ((CGFloat) -> Void)?
    var onHoverStart: ((Int, NSRect) -> Void)?
    var onHoverEnd: (() -> Void)?

    init(window: YabaiWindow, isFocused: Bool) {
        self.windowId = window.id
        self.app = window.app
        self.title = window.title
        self.isFocused = isFocused
        self.image = NSRunningApplication(processIdentifier: pid_t(window.pid))?.icon
        super.init(frame: .zero)
        wantsLayer = true
        toolTip = "\(window.app) — \(window.title)\n  right-click: remove from stack\n  middle-click: close"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setFocused(_ f: Bool) {
        guard f != isFocused else { return }
        isFocused = f
        needsDisplay = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for ta in trackingAreas { removeTrackingArea(ta) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                        owner: self, userInfo: nil))
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseEntered(with: NSEvent) {
        isHovered = true
        needsDisplay = true
        onHoverStart?(windowId, self.frame)
    }
    override func mouseExited(with: NSEvent) {
        isHovered = false
        needsDisplay = true
        onHoverEnd?()
    }

    override func mouseDown(with: NSEvent) {
        dragStart = NSEvent.mouseLocation
        isDragging = false
        NSCursor.closedHand.push()
    }

    override func mouseDragged(with: NSEvent) {
        guard let start = dragStart else { return }
        let dx = NSEvent.mouseLocation.x - start.x
        if !isDragging {
            guard abs(dx) > dragThreshold else { return }
            isDragging = true
            onDragBegin?()
        }
        onDrag?(dx)
    }

    override func mouseUp(with: NSEvent) {
        NSCursor.pop()
        let wasDragging = isDragging
        dragStart = nil
        isDragging = false
        if !wasDragging { onFocus?(windowId) }
    }

    override func rightMouseDown(with event: NSEvent) {
        onUnstack?(windowId)
    }

    override func otherMouseUp(with event: NSEvent) {
        if event.buttonNumber == 2 {
            onClose?(windowId)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)

        if isFocused {
            NSColor.controlAccentColor.withAlphaComponent(0.32).setFill()
            path.fill()
            NSColor.controlAccentColor.setStroke()
            path.lineWidth = 1.5
            path.stroke()
        } else if isHovered {
            NSColor.white.withAlphaComponent(0.18).setFill()
            path.fill()
        }

        let side: CGFloat = 22
        let imgRect = NSRect(x: bounds.midX - side / 2, y: bounds.midY - side / 2, width: side, height: side)
        if let img = image {
            img.size = imgRect.size
            img.draw(in: imgRect)
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
            let letter = String(app.prefix(1).uppercased())
            let s = letter as NSString
            let size = s.size(withAttributes: attrs)
            s.draw(at: NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2), withAttributes: attrs)
        }
    }
}

// MARK: - SwitcherBarView

final class SwitcherBarView: NSView {
    private var cells: [IconCell] = []
    private let padding: CGFloat = 5
    private let spacing: CGFloat = 4
    private let cellSize: CGFloat = 30
    var onFocus: ((Int) -> Void)?
    var onUnstack: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onDragBegin: (() -> Void)?
    var onDrag: ((CGFloat) -> Void)?
    var onHoverStart: ((Int, NSRect) -> Void)?
    var onHoverEnd: (() -> Void)?

    func sizeFor(count: Int) -> NSSize {
        let n = max(count, 1)
        return NSSize(width: CGFloat(n) * cellSize + CGFloat(max(n - 1, 0)) * spacing + padding * 2,
                      height: cellSize + padding * 2)
    }

    func configure(stack: Stack) {
        let newIds = Set(stack.windowIds)
        let curIds = Set(cells.map(\.windowId))
        if newIds != curIds {
            onHoverEnd?()
            cells.forEach { $0.removeFromSuperview() }
            cells = stack.windows.map { w in
                let cell = IconCell(window: w, isFocused: stack.focusedWindowId == w.id)
                cell.onFocus = { [weak self] id in self?.onFocus?(id) }
                cell.onUnstack = { [weak self] id in self?.onUnstack?(id) }
                cell.onClose = { [weak self] id in self?.onClose?(id) }
                cell.onDragBegin = { [weak self] in self?.onDragBegin?() }
                cell.onDrag = { [weak self] dx in self?.onDrag?(dx) }
                cell.onHoverStart = { [weak self] id, frame in self?.onHoverStart?(id, frame) }
                cell.onHoverEnd = { [weak self] in self?.onHoverEnd?() }
                addSubview(cell)
                return cell
            }
        } else {
            for cell in cells { cell.setFocused(stack.focusedWindowId == cell.windowId) }
        }
        layoutCells()
        needsDisplay = true
    }

    private func layoutCells() {
        var x = padding
        for cell in cells {
            cell.frame = NSRect(x: x, y: padding, width: cellSize, height: cellSize)
            x += cellSize + spacing
        }
    }

    override func layout() {
        super.layout()
        layoutCells()
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10)
        NSColor.windowBackgroundColor.withAlphaComponent(0.55).setFill()
        path.fill()
        NSColor.black.withAlphaComponent(0.25).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    // Click-through: only the icon cells are hit-testable; the surrounding
    // background lets mouse events pass to the windows beneath.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

// MARK: - SwitcherPanel

final class SwitcherPanel {
    let panel: NSPanel
    let barView: SwitcherBarView
    let stackKey: String
    var onFocus: ((Int) -> Void)?
    var onUnstack: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?

    private var offsetX: CGFloat { AppSettings.barOffsetX }
    private var offsetY: CGFloat { AppSettings.barOffsetY }
    private var userDX: CGFloat = 0
    private var lastBaseX: CGFloat = 0
    private var dragStartX: CGFloat = 0
    private var screenVisibleFrame: NSRect = .zero
    private let preview = WindowPreviewPanel()
    init(stack: Stack, displays: [YabaiDisplay], screens: [NSScreen]) {
        self.stackKey = stack.key
        let bar = SwitcherBarView()
        self.barView = bar

        let size = bar.sizeFor(count: stack.windows.count)
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
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        p.contentView = bar
        bar.frame = NSRect(origin: .zero, size: size)
        bar.configure(stack: stack)
        self.panel = p

        bar.onFocus = { [weak self] id in self?.onFocus?(id) }
        bar.onUnstack = { [weak self] id in self?.onUnstack?(id) }
        bar.onClose = { [weak self] id in self?.onClose?(id) }
        bar.onDragBegin = { [weak self] in self?.beginDrag() }
        bar.onDrag = { [weak self] dx in self?.applyDrag(dx: dx) }
        bar.onHoverStart = { [weak self] id, frame in
            self?.handleHoverStart(windowId: id, cellFrameInBarCoords: frame)
        }
        bar.onHoverEnd = { [weak self] in self?.preview.hide() }
        position(stack: stack, displays: displays, screens: screens)
    }

    func show() {
        guard !panel.isVisible else { return }
        panel.orderFront(nil)
    }

    func hide() {
        guard panel.isVisible else { return }
        preview.hide()
        panel.orderOut(nil)
    }

    func update(stack: Stack, displays: [YabaiDisplay], screens: [NSScreen]) {
        barView.configure(stack: stack)
        let size = barView.sizeFor(count: stack.windows.count)
        panel.setContentSize(size)
        barView.frame = NSRect(origin: .zero, size: size)
        position(stack: stack, displays: displays, screens: screens)
    }

    private func position(stack: Stack, displays: [YabaiDisplay], screens: [NSScreen]) {
        guard let top = Self.topLeft(for: stack, displays: displays, screens: screens),
              let scr = Self.screen(for: stack, displays: displays, screens: screens) else { return }
        screenVisibleFrame = scr.visibleFrame
        let h = panel.frame.height
        let baseX = top.x + offsetX
        lastBaseX = baseX
        let x = clampX(baseX + userDX)
        panel.setFrameOrigin(NSPoint(x: x, y: top.y - h - offsetY))
    }

    private func beginDrag() {
        dragStartX = panel.frame.minX
    }

    private func handleHoverStart(windowId: Int, cellFrameInBarCoords: NSRect) {
        let cellFrameInWindow = barView.convert(cellFrameInBarCoords, to: nil)
        let cellFrameInScreen = panel.convertToScreen(cellFrameInWindow)
        preview.scheduleShow(windowId: windowId, above: cellFrameInScreen)
    }

    private func applyDrag(dx: CGFloat) {
        let desired = dragStartX + dx
        let clamped = clampX(desired)
        userDX = clamped - lastBaseX
        panel.setFrameOrigin(NSPoint(x: clamped, y: panel.frame.minY))
    }

    private func clampX(_ x: CGFloat) -> CGFloat {
        let w = panel.frame.width
        var nx = x
        if nx < screenVisibleFrame.minX { nx = screenVisibleFrame.minX }
        if nx + w > screenVisibleFrame.maxX { nx = screenVisibleFrame.maxX - w }
        return nx
    }

    static func screen(for stack: Stack, displays: [YabaiDisplay], screens: [NSScreen]) -> NSScreen? {
        screen(forDisplay: stack.display, screens: screens)
    }

    static func screen(forDisplay display: Int, screens: [NSScreen]) -> NSScreen? {
        (display - 1 >= 0 && display - 1 < screens.count)
            ? screens[display - 1] : screens.first
    }

    static func topLeft(for stack: Stack, displays: [YabaiDisplay], screens: [NSScreen]) -> NSPoint? {
        topLeft(frame: stack.frame, display: stack.display, displays: displays, screens: screens)
    }

    static func topLeft(frame: YabaiFrame, display: Int, displays: [YabaiDisplay], screens: [NSScreen]) -> NSPoint? {
        guard let disp = displays.first(where: { $0.index == display }) ?? displays.first else { return nil }
        let screenFrame: NSRect? = (display - 1 >= 0 && display - 1 < screens.count)
            ? screens[display - 1].frame : screens.first?.frame
        guard let scr = screenFrame else { return nil }
        return topLeftPoint(frame: frame, displayFrame: disp.frame, screenFrame: scr)
    }

    static func topLeftPoint(frame: YabaiFrame, displayFrame: YabaiFrame, screenFrame: NSRect) -> NSPoint {
        let rx = frame.x - displayFrame.x
        let ry = frame.y - displayFrame.y
        return NSPoint(x: screenFrame.minX + rx, y: screenFrame.maxY - ry)
    }
}
