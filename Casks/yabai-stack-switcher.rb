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
    system_command "defaults",
                   args: ["write", "/Library/Preferences/loginwindow",
                          "AutoLaunchedApplicationDictionary", "-array-add",
                          '{Path="/Applications/YabaiStackSwitcher.app";}'],
                   sudo: true
  end

  uninstall_postflight do
    system_command "/bin/bash",
                   args: ["-c",
                          'tmp=$(mktemp) && defaults export /Library/Preferences/loginwindow "$tmp" && ' \
                          '/usr/bin/python3 -c ' \
                          '"import plistlib,sys; d=plistlib.load(open(sys.argv[1],\"rb\")); ' \
                          'd[\"AutoLaunchedApplicationDictionary\"]=[e for e in d.get(\"AutoLaunchedApplicationDictionary\",[]) ' \
                          'if e.get(\"Path\")!=\"/Applications/YabaiStackSwitcher.app\"]; ' \
                          'plistlib.dump(d,open(sys.argv[1],\"wb\"))" "$tmp" && ' \
                          'defaults import /Library/Preferences/loginwindow "$tmp" && rm -f "$tmp"'],
                   sudo: true
  end

  zap trash: "~/Library/Preferences/com.yabai.stack-switcher.plist"
end
