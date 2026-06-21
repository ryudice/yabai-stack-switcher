import Foundation

final class StubYabai {
    let directory: URL
    let url: URL

    init(windowsJSON: String = "[]",
         displaysJSON: String = "[]",
         focusedJSON: String = "{}",
         configValue: String = "alt") throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let script = """
        #!/bin/bash
        DIR="$(dirname "$0")"
        if [ -f "$DIR/error.flag" ]; then exit 1; fi
        case "$2" in
          query)
            case "$3" in
              --windows)
                if [ "$4" = "--window" ]; then
                  cat "$DIR/focused.json" 2>/dev/null
                else
                  cat "$DIR/windows.json" 2>/dev/null
                fi
                exit 0
                ;;
              --displays)
                cat "$DIR/displays.json" 2>/dev/null
                exit 0
                ;;
            esac
            ;;
          config)
            if [ $# -eq 3 ]; then cat "$DIR/config.txt" 2>/dev/null || echo "alt"; fi
            exit 0
            ;;
        esac
        exit 0
        """

        url = directory.appendingPathComponent("yabai")
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755],
                                              ofItemAtPath: url.path)

        try windowsJSON.write(to: directory.appendingPathComponent("windows.json"),
                              atomically: true, encoding: .utf8)
        try displaysJSON.write(to: directory.appendingPathComponent("displays.json"),
                               atomically: true, encoding: .utf8)
        try focusedJSON.write(to: directory.appendingPathComponent("focused.json"),
                              atomically: true, encoding: .utf8)
        try configValue.write(to: directory.appendingPathComponent("config.txt"),
                              atomically: true, encoding: .utf8)
    }

    func setWindows(_ json: String) throws {
        try json.write(to: directory.appendingPathComponent("windows.json"),
                       atomically: true, encoding: .utf8)
    }

    func setErrorMode(_ enabled: Bool) throws {
        let flag = directory.appendingPathComponent("error.flag")
        if enabled {
            try Data().write(to: flag)
        } else {
            try? FileManager.default.removeItem(at: flag)
        }
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }
}
