import Foundation
import AppKit
import ServiceManagement

enum AppSettings {
    static let didChangeNotification = Notification.Name("yssSettingsDidChange")

    private static let barOffsetXKey = "barOffsetX"
    private static let barOffsetYKey = "barOffsetY"
    private static let previewMaxDimKey = "previewMaxDim"
    private static let hasPromptedLaunchAtLoginKey = "hasPromptedLaunchAtLogin"

    static let defaultBarOffsetX: CGFloat = 6
    static let defaultBarOffsetY: CGFloat = 6
    static let defaultPreviewMaxDim: CGFloat = 240
    static let minPreviewMaxDim: CGFloat = 120
    static let maxPreviewMaxDim: CGFloat = 480

    static var barOffsetX: CGFloat {
        get {
            if let v = UserDefaults.standard.object(forKey: barOffsetXKey) as? Double {
                return CGFloat(v)
            }
            return defaultBarOffsetX
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: barOffsetXKey)
            postChange()
        }
    }

    static var barOffsetY: CGFloat {
        get {
            if let v = UserDefaults.standard.object(forKey: barOffsetYKey) as? Double {
                return CGFloat(v)
            }
            return defaultBarOffsetY
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: barOffsetYKey)
            postChange()
        }
    }

    static var previewMaxDim: CGFloat {
        get {
            if let v = UserDefaults.standard.object(forKey: previewMaxDimKey) as? Double {
                let clamped = max(minPreviewMaxDim, min(maxPreviewMaxDim, CGFloat(v)))
                return clamped
            }
            return defaultPreviewMaxDim
        }
        set {
            let clamped = max(minPreviewMaxDim, min(maxPreviewMaxDim, newValue))
            UserDefaults.standard.set(Double(clamped), forKey: previewMaxDimKey)
            postChange()
        }
    }

    static var hasPromptedLaunchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: hasPromptedLaunchAtLoginKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasPromptedLaunchAtLoginKey) }
    }

    @available(macOS 13, *)
    static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        if #available(macOS 13, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                postChange()
                return true
            } catch {
                postChange()
                return false
            }
        }
        UserDefaults.standard.set(enabled, forKey: "launchAtLoginFallback")
        postChange()
        return false
    }

    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: barOffsetXKey)
        UserDefaults.standard.removeObject(forKey: barOffsetYKey)
        UserDefaults.standard.removeObject(forKey: previewMaxDimKey)
        postChange()
    }

    private static func postChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
