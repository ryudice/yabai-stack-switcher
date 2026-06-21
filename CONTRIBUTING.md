# Contributing

Thanks for your interest in contributing to Yabai Stack Switcher! This guide
covers everything you need to get set up and ship a change.

## Project overview

Yabai Stack Switcher is a pure-Swift, AppKit-only macOS accessory app (no
third-party dependencies). It watches yabai for stacked windows and renders a
floating, clickable icon bar at the top-left of each visible stack.

The app lives across these files:

```
Sources/YabaiStackSwitcher/
└── main.swift            # entry point — calls runYabaiStackSwitcher()
Sources/YabaiStackSwitcherCore/
├── AppMain.swift         # public runYabaiStackSwitcher() entry point
├── AppDelegate.swift     # wires watcher + signal notifier together, manages panels
├── Models.swift          # Codable structs for yabai's JSON (windows, displays, stacks)
├── YabaiClient.swift     # thin wrapper over the `yabai` CLI (query + focus)
├── StackWatcher.swift    # polls yabai, groups windows into stacks, diffs state
├── SignalNotifier.swift  # registers yabai signals, receives SIGUSR1/SIGUSR2 pings
├── DragWatcher.swift     # Shift-drag detection for Create Stack Mode
├── StackModeOverlay.swift# the Create Stack Mode overlays + mode indicator
└── SwitcherPanel.swift   # the UI — NSPanel + SwitcherBarView + IconCell
Tests/YabaiStackSwitcherTests/
└── …                     # unit tests (Models, groupStacks, coordinate conversion)
```

The core logic is a library target (`YabaiStackSwitcherCore`) so the test
target can import it; the executable target (`YabaiStackSwitcher`) is a thin
wrapper that calls the public entry point.

### Architecture, at a glance

```
yabai events ──signal──▶ SignalNotifier ──SIGUSR1──▶ StackWatcher.refreshDebounced()
                                                              │
1 s safety poll ──────────────────────────────────────────────┤
                                                              ▼
                                                        StackWatcher.refresh()
                                                              │
                                          yabai -m query --windows / --displays
                                                              │
                                                              ▼
                                                   group into [Stack]
                                                       (diff vs last)
                                                              │
                                                              ▼
                                                   AppDelegate.updatePanels()
                                                              │
                                          create / update / show / hide
                                                              ▼
                                                   SwitcherPanel (per stack)
                                                              │
                                                   SwitcherBarView + IconCell
                                                              │
                                          click ─▶ YabaiClient.focus(id)
                                          drag  ─▶ reposition panel (horizontal)
```

Key design decisions:

- **Signal-driven, poll-backed.** yabai signals (`space_changed`,
  `window_focused`, `window_moved`, `window_resized`, `window_created`,
  `window_destroyed`, `window_minimized`, `window_deminimized`,
  `application_front_switched`) push a `SIGUSR1` to the app, which triggers a
  30 ms-debounced refresh. A 1 s `DispatchSourceTimer` is the safety net. This
  keeps latency at ~120 ms instead of the 250–400 ms a poll-only approach gives.
- **Panel reuse.** Panels are `orderOut` / `orderFront` (hidden / shown), never
  destroyed and recreated across space switches. The user's horizontal drag
  offset persists across repositions via `userDX` in `SwitcherPanel`.
- **Click-through.** `SwitcherBarView.hitTest` returns `nil` for the bar
  background, so only the icon cells are interactive — the rest passes mouse
  events to the windows beneath.
- **No Accessibility/SIP.** Everything goes through `yabai -m` messages and
  `NSRunningApplication(pid).icon`. No private APIs.

## Getting started

### Prerequisites

- macOS 12+
- Swift 5.9+ (Xcode Command Line Tools: `xcode-select --install`)
- [yabai](https://github.com/koekeishiya/yabai) v7+ running on your machine

### Build & run

```sh
git clone <repo-url>
cd yabai-stack-switcher
make run          # debug build + launch from terminal
```

For a release `.app` bundle:

```sh
make bundle       # → YabaiStackSwitcher.app
open YabaiStackSwitcher.app
```

### Creating a test stack

The app only shows a bar for stacks with ≥ 2 windows. To create one quickly:

```sh
open -a "Safari";  open -a "TextEdit"      # two windows
yabai -m window --stack next              # stack them
yabai -m query --windows | jq '[.[] | select(."stack-index" > 0)]'
```

Switch to that space and the bar should appear at the top-left.

## Development workflow

### Build

```sh
swift build               # debug
swift build -c release    # release
swift test                # unit tests (YabaiStackSwitcherTests)
```

Unit tests cover `Models` decoding, `StackWatcher.groupStacks` grouping
behavior, and the `SwitcherPanel` top-left coordinate conversion. When adding a
feature that touches those areas, add or update a test alongside it. Other
behavior is still verified manually (see below); please also test against a live
yabai stack.

### Verifying changes

A quick end-to-end checklist after making changes:

1. `make run` — app launches without errors.
2. `yabai -m signal --list` — shows 9 `yss-*` signals while the app runs.
3. Switch to a space with a stack — the bar appears (~120 ms).
4. Click an icon — yabai focus changes to that window.
5. Drag the bar horizontally — it moves and stays clamped to the screen.
6. Switch away and back — the bar hides and reappears at the same offset.
7. `pkill -f YabaiStackSwitcher` — signals are cleaned up (count drops to 0).

### Useful debugging snippets

Check if the panel is on-screen and where:

```sh
swift -e 'import CoreGraphics
let i = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String:Any]] ?? []
for w in i where (w[kCGWindowOwnerName as String] as? String ?? "").contains("YabaiStack") {
    print(w[kCGWindowBounds as String] ?? [:])
}'
```

Check the current yabai stack state:

```sh
yabai -m query --windows | jq '[.[] | select(."stack-index" > 0) | {id, app, "stack-index", "has-focus", "is-visible"}]'
```

## Code conventions

- **No comments** unless something is genuinely non-obvious. The code should
  read clearly on its own.
- **AppKit-only**, no SwiftUI. The UI is hand-drawn in `NSView.draw(_:)`.
- **No third-party dependencies.** The `Package.swift` has no dependencies —
  keep it that way.
- **Codable models** with explicit `CodingKeys` for yabai's kebab-case JSON keys
  (e.g. `stack-index`, `has-focus`).
- **Coordinate systems:** yabai uses a top-left origin; AppKit uses a
  bottom-left origin. Conversion lives in `SwitcherPanel.topLeft(for:...)` and
  `SwitcherPanel.screen(for:...)`. If you touch positioning, test on a
  multi-display setup.
- **`main` thread for UI.** `StackWatcher` does yabai queries on a background
  queue and dispatches `onChange` to `main`. Keep UI mutations on main.

## Areas ripe for contribution

- **Integration tests.** Unit tests cover `StackWatcher.groupStacks`, `Models`
  decoding, and `SwitcherPanel` coordinate conversion. A great next PR would be
  integration tests that drive `YabaiClient` against a stub `yabai` executable
  (canned JSON fixtures) and exercise the full `StackWatcher.refresh` pipeline.
- **Vertical drag / repositioning.** Currently horizontal-only; a vertical
  component with edge-snap could be useful.
- **Scroll-to-cycle.** Scroll on the bar to cycle through the stack
  (`yabai -m window --focus stack.next/prev`).
- **Window count badge** for stacks with many windows.
- **Config file** for offset, icon size, bar position default, etc.
- **Pre-built release** with GitHub Actions and notarization.

## CI / Releases

Two GitHub Actions workflows live in `.github/workflows/`:

- **`ci.yml`** — runs on every push and PR. Builds the app in release mode,
  bundles the `.app`, and uploads it as a workflow artifact for download.
- **`release.yml`** — triggered by pushing a `v*` tag (e.g. `v1.2.0`). Stamps
  the version into `Info.plist`, builds, zips, optionally notarizes, and creates
  a GitHub Release with the zip attached and auto-generated release notes.

### Cutting a release

```sh
git tag v1.2.0
git push origin v1.2.0
```

The workflow handles the rest. The version in `Info.plist` is derived from the
tag, so there's no need to manually bump it before tagging.

### Notarization (optional)

Notarization is disabled by default. To enable it, set these as repository
variables and secrets:

| Name | Type | Value |
|------|------|-------|
| `ENABLE_NOTARIZATION` | Variable | `true` |
| `APPLE_ID` | Secret | your Apple ID email |
| `APPLE_ID_PASSWORD` | Secret | app-specific password for notarytool |
| `APPLE_TEAM_ID` | Secret | your Apple Developer Team ID |

When enabled, the workflow submits the zip to Apple's notary service, staples
the ticket to the `.app`, and re-zips the stapled bundle for distribution.

### Homebrew tap (optional)

The release workflow can automatically bump the Homebrew cask in a
`homebrew-tap` repo after each release. To enable it:

1. Create a repo named `homebrew-tap` under your GitHub account.
2. Copy `Casks/yabai-stack-switcher.rb` into it (replace
   `YOUR_GITHUB_USER` with your actual GitHub username/org).
3. Create a fine-grained personal access token with **Contents read+write**
   permission on the `homebrew-tap` repo.
4. Add it as a repository secret named `HOMEBREW_TAP_TOKEN`.

When set, the release workflow will clone the tap repo, update the cask's
`version` and `sha256`, commit, and push — so `brew upgrade` picks up new
releases automatically.

Users install via:

```sh
brew tap <your-user>/tap
brew install --cask yabai-stack-switcher
```

## Pull request checklist

- [ ] `swift build -c release` succeeds with no warnings.
- [ ] `swift test` passes.
- [ ] CI workflow passes (test + build + bundle on `macos-14`).
- [ ] Tested against a live yabai stack (see the verification checklist above).
- [ ] No new third-party dependencies.
- [ ] No new comments unless something is genuinely non-obvious.
- [ ] If you touched signals or panel lifecycle, verified signal cleanup on quit
      (`yabai -m signal --list` drops to 0).
- [ ] If you touched positioning, tested on multiple displays if possible.

## Reporting bugs

Please include:

- macOS version
- yabai version (`yabai -v`)
- Output of `yabai -m query --windows | jq '[.[] | select(."stack-index" > 0)]'`
- Steps to reproduce
- What you expected vs. what happened

## License

By contributing, you agree that your contributions are licensed under the MIT
license.
