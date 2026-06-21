# frozen_string_literal: true

cask "yabai-stack-switcher" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/YOUR_GITHUB_USER/yabai-stack-switcher/releases/download/v#{version}/YabaiStackSwitcher-#{version}.zip"
  name "Yabai Stack Switcher"
  desc "Floating icon switcher for yabai stacked windows"
  homepage "https://github.com/YOUR_GITHUB_USER/yabai-stack-switcher"

  depends_on formula: "yabai"

  app "YabaiStackSwitcher.app"

  postflight do
    system_command "osascript",
                   args: ["-e", 'tell application "System Events"',
                          "-e", "try",
                          "-e", 'delete login item "Yabai Stack Switcher"',
                          "-e", "end try",
                          "-e", 'make login item at end with properties {path:"/Applications/YabaiStackSwitcher.app", hidden:false}',
                          "-e", "end tell"]
  end

  uninstall_postflight do
    system_command "osascript",
                   args: ["-e", 'tell application "System Events"',
                          "-e", "try",
                          "-e", 'delete login item "Yabai Stack Switcher"',
                          "-e", "end try",
                          "-e", "end tell"]
  end

  zap trash: "~/Library/Preferences/com.yabai.stack-switcher.plist"
end
