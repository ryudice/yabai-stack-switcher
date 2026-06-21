import Foundation
import AppKit

enum AppSettings {
    static let didChangeNotification = Notification.Name("yssSettingsDidChange")

    private static let barOffsetXKey = "barOffsetX"
    private static let barOffsetYKey = "barOffsetY"

    static let defaultBarOffsetX: CGFloat = 6
    static let defaultBarOffsetY: CGFloat = 6

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

    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: barOffsetXKey)
        UserDefaults.standard.removeObject(forKey: barOffsetYKey)
        postChange()
    }

    private static func postChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
