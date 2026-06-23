import AppKit
import CoreGraphics

// MARK: - WindowPreviewPanel

final class WindowPreviewPanel {
    private let panel: NSPanel
    private let previewView: WindowPreviewView
    private var showWorkItem: DispatchWorkItem?
    private var shownWindowId: Int?
    private var maxDim: CGFloat { AppSettings.previewMaxDim }
    private let showDelay: TimeInterval = 0.25

    init() {
        let v = WindowPreviewView(frame: .zero)
        self.previewView = v

        let p = NSPanel(contentRect: NSRect(origin: .zero, size: NSSize(width: 200, height: 140)),
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
        self.panel = p
    }

    func scheduleShow(windowId: Int, above iconRectInScreen: NSRect) {
        cancelShow()
        let work = DispatchWorkItem { [weak self] in
            self?.showNow(windowId: windowId, above: iconRectInScreen)
        }
        showWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + showDelay, execute: work)
    }

    func cancelShow() {
        showWorkItem?.cancel()
        showWorkItem = nil
    }

    func hide() {
        cancelShow()
        if panel.isVisible {
            panel.orderOut(nil)
        }
        shownWindowId = nil
    }

    private func showNow(windowId: Int, above iconRectInScreen: NSRect) {
        guard let cgImage = captureWindow(windowId: windowId) else { return }
        let image = NSImage(cgImage: cgImage,
                            size: NSSize(width: cgImage.width, height: cgImage.height))
        let previewSize = scaledSize(for: cgImage)
        previewView.image = image
        panel.setContentSize(previewSize)
        previewView.frame = NSRect(origin: .zero, size: previewSize)
        position(above: iconRectInScreen, size: previewSize)
        panel.orderFront(nil)
        shownWindowId = windowId
    }

    private func scaledSize(for cgImage: CGImage) -> NSSize {
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        guard w > 0 && h > 0 else { return NSSize(width: maxDim, height: maxDim) }
        let scale = min(maxDim / w, maxDim / h)
        return NSSize(width: ceil(w * scale), height: ceil(h * scale))
    }

    private func position(above iconRect: NSRect, size: NSSize) {
        let screen = NSScreen.screens.first { iconRect.intersects($0.frame) } ?? NSScreen.main
        let vf = screen?.visibleFrame ?? .zero
        let gap: CGFloat = 8
        let centerX = iconRect.midX
        let x = max(vf.minX + 4, min(centerX - size.width / 2, vf.maxX - size.width - 4))
        var y = iconRect.maxY + gap
        if y + size.height > vf.maxY - 4 {
            y = iconRect.minY - gap - size.height
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func captureWindow(windowId: Int) -> CGImage? {
        let windowID = CGWindowID(windowId)
        return CGWindowListCreateImage(
            CGRect.null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming]
        )
    }
}

// MARK: - WindowPreviewView

private final class WindowPreviewView: NSView {
    var image: NSImage? { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.black.withAlphaComponent(0.35).cgColor
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.08).cgColor
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        guard let img = image else { return }
        let iw = img.size.width
        let ih = img.size.height
        guard iw > 0 && ih > 0 else { return }
        let scale = min(bounds.width / iw, bounds.height / ih)
        let w = iw * scale
        let h = ih * scale
        let drawRect = NSRect(x: bounds.midX - w / 2, y: bounds.midY - h / 2, width: w, height: h)
        img.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1)
    }
}
