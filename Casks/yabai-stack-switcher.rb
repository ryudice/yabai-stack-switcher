# frozen_string_literal: true

cask "yabai-stack-switcher" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/YOUR_GITHUB_USER/yabai-stack-switcher/releases/download/v#{version}/YabaiStackSwitcher-#{version}.zip"
  name "Yabai Stack Switcher"
  desc "Floating icon switcher for yabai stacked windows"
  homepage "https://github.com/YOUR_GITHUB_USER/yabai-stack-switcher"

  app "YabaiStackSwitcher.app"

  zap trash: "~/Library/Preferences/com.yabai.stack-switcher.plist"
end
