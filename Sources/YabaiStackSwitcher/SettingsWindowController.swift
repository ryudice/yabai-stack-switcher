import AppKit

final class SettingsWindowController {
    private let window: NSWindow
    private var xOffsetSlider: NSSlider!
    private var yOffsetSlider: NSSlider!
    private var xOffsetField: NSTextField!
    private var yOffsetField: NSTextField!
    private var previewSizeSlider: NSSlider!
    private var previewSizeField: NSTextField!

    init() {
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        let w = NSWindow(contentRect: content.bounds,
                         styleMask: [.titled, .closable, .miniaturizable],
                         backing: .buffered, defer: false)
        w.title = "Yabai Stack Switcher Settings"
        w.contentView = content
        w.isReleasedWhenClosed = false
        w.center()
        self.window = w
        layoutControls(in: content)
        syncControlsFromSettings()
    }

    func show() {
        syncControlsFromSettings()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Layout

    private func layoutControls(in view: NSView) {
        let offsetLabel = NSTextField(labelWithString: "Bar offset")
        offsetLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let xRow = makeRow(label: "Horizontal",
                           min: -50, max: 50,
                           sliderAction: #selector(xSliderChanged),
                           field: &xOffsetSlider,
                           valueField: &xOffsetField)
        let yRow = makeRow(label: "Vertical",
                           min: -50, max: 50,
                           sliderAction: #selector(ySliderChanged),
                           field: &yOffsetSlider,
                           valueField: &yOffsetField)

        let previewLabel = NSTextField(labelWithString: "Window preview")
        previewLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let previewRow = makeRow(label: "Max size",
                                 min: Double(AppSettings.minPreviewMaxDim),
                                 max: Double(AppSettings.maxPreviewMaxDim),
                                 sliderAction: #selector(previewSizeSliderChanged),
                                 field: &previewSizeSlider,
                                 valueField: &previewSizeField)

        let resetButton = NSButton(title: "Reset to Defaults",
                                    target: self,
                                    action: #selector(resetToDefaults))
        resetButton.bezelStyle = .rounded

        let stack = NSStackView(views: [offsetLabel, xRow, yRow, previewLabel, previewRow, resetButton])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            xRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            yRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            previewRow.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func makeRow(label: String,
                         min: Double, max: Double,
                         sliderAction: Selector,
                         field: inout NSSlider!,
                         valueField: inout NSTextField!) -> NSView {
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.alignment = .right
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let slider = NSSlider(value: 0, minValue: min, maxValue: max,
                              target: self, action: sliderAction)
        slider.isContinuous = true
        slider.translatesAutoresizingMaskIntoConstraints = false
        field = slider

        let valueLabel = NSTextField(labelWithString: "0")
        valueLabel.alignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true
        valueField = valueLabel

        let row = NSStackView(views: [titleLabel, slider, valueLabel])
        row.orientation = .horizontal
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }

    // MARK: - Actions

    @objc private func xSliderChanged() {
        let v = xOffsetSlider.doubleValue
        xOffsetField.stringValue = String(Int(v))
        AppSettings.barOffsetX = CGFloat(v)
    }

    @objc private func ySliderChanged() {
        let v = yOffsetSlider.doubleValue
        yOffsetField.stringValue = String(Int(v))
        AppSettings.barOffsetY = CGFloat(v)
    }

    @objc private func previewSizeSliderChanged() {
        let v = previewSizeSlider.doubleValue
        previewSizeField.stringValue = String(Int(v))
        AppSettings.previewMaxDim = CGFloat(v)
    }

    @objc private func resetToDefaults() {
        AppSettings.resetToDefaults()
        syncControlsFromSettings()
    }

    private func syncControlsFromSettings() {
        let x = Double(AppSettings.barOffsetX)
        let y = Double(AppSettings.barOffsetY)
        let p = Double(AppSettings.previewMaxDim)
        xOffsetSlider.doubleValue = x
        yOffsetSlider.doubleValue = y
        previewSizeSlider.doubleValue = p
        xOffsetField.stringValue = String(Int(x.rounded()))
        yOffsetField.stringValue = String(Int(y.rounded()))
        previewSizeField.stringValue = String(Int(p.rounded()))
    }
}
