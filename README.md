# Yabai Stack Switcher

A small macOS menu-bar-free app that shows a floating icon switcher on top of
[yabai](https://github.com/koekeishiya/yabai) window stacks. Each stacked window
gets an icon; click one to instantly focus that window. The bar sits at the
top-left of the stack and can be dragged horizontally to wherever you like.

<p align="center"><em>The focused window is highlighted with an accent ring.</em></p>

## Features

- **One icon per stacked window** — uses each app's own icon.
- **Click to switch** — focus the window you clicked, instantly.
- **Drag horizontally** — grab the bar and slide it left/right; it stays where
  you put it and stays clamped to the screen edges.
- **Focused-window highlight** — an accent ring marks the current window.
- **Appears instantly** — driven by yabai signals, not polling, so the bar shows
  up ~120 ms after you switch to a stack's space.
- **One bar per stack** — on every display, wherever you have stacks.
- **Create Stack Mode** — hold **Shift** while dragging a yabai window to light up
  a "Create Stack Mode" indicator and outline every other window on the space as a
  drop target. The target under your cursor is emphasized with a center drop-zone
  ring; release on a target's center and yabai stacks the windows. Works alongside
  yabai's normal drag-to-swap (no Shift = swap as usual).
- **Stays out of the way** — no Dock icon, never steals keyboard focus, and the
  bar background is click-through so you can still click the traffic-light
  buttons of the window underneath.
- **No special permissions** — doesn't require Accessibility or SIP changes; it
  only talks to yabai via its message API.

## Requirements

- macOS 12 or later
- [yabai](https://github.com/koekeishiya/yabai) v7+ installed and running

## Install

### Option A — Homebrew (recommended)

```sh
brew tap YOUR_GITHUB_USER/tap
brew install --cask yabai-stack-switcher
```

This also installs yabai if you don't have it (the cask declares it as a
dependency). To upgrade later:

```sh
brew upgrade --cask yabai-stack-switcher
```

### Option B — Build from source

You need the Swift toolchain (comes with Xcode Command Line Tools):

```sh
xcode-select --install   # if you don't already have it
```

Clone and build a double-clickable `.app`:

```sh
git clone <repo-url>
cd yabai-stack-switcher
make bundle              # produces YabaiStackSwitcher.app
open YabaiStackSwitcher.app
```

Or build and run directly from the terminal (no `.app` needed):

```sh
make run
```

### Option C — Pre-built release

Download the latest `YabaiStackSwitcher-<version>.zip` from
[Releases](../../releases), unzip, drag the `.app` to `/Applications`, and
double-click.

## Start at login

Add `YabaiStackSwitcher.app` to
**System Settings → General → Login Items & Extensions → Login Items**.

## Usage

1. Make sure yabai is running and you have at least two windows stacked on the
   same space.
2. Switch to that space — the icon bar appears at the top-left of the stack.
3. Click an icon to focus that window.
4. Drag the bar horizontally to reposition it; the position persists while the
   app runs.

### Create Stack Mode

Hold **Shift** while you drag a yabai window to enter Create Stack Mode:

1. Press and hold **Shift**, then drag a window with yabai's normal move modifier
   (Option by default).
2. A "Create Stack Mode" badge appears at the top of the screen and every other
   window on the space is outlined as a drop target.
3. The target under your cursor is emphasized and shows a center drop-zone ring —
   that ring marks where yabai will accept a stack drop.
4. Release the window over a target's center ring; yabai stacks the two windows.
5. Release **Shift** (or stop dragging) and the overlays disappear.

Stacking itself is handled by yabai's native drop-on-center behavior — the app
only adds the visual mode and target highlighting. Without Shift, dragging
behaves exactly as yabai normally does (swap, not stack).

### Stacking windows in yabai

If you're new to yabai stacking, you can stack windows by dragging one onto the
center of another, or via yabai messages:

```sh
yabai -m window --stack next      # stack the focused window onto the next one
yabai -m window --focus stack.next   # cycle within a stack (keyboard)
```

This app gives you a clickable alternative to the keyboard commands.

## yabai signals

On launch the app registers yabai signals (labelled `yss-*`) so it updates the
moment windows change. These are automatically cleaned up when the app quits. If
the app is force-killed, stale signals are reclaimed on the next launch. You can
inspect them at any time:

```sh
yabai -m signal --list             # look for yss-* labels
```

## Troubleshooting

**The bar doesn't appear.**
- Confirm yabai is running: `yabai -m query --windows` should print JSON.
- Confirm you have a stack (≥ 2 windows with `stack-index > 0`) on the visible
  space: `yabai -m query --windows | jq '[.[] | select(."stack-index" > 0)]'`
- The bar only shows for stacks on the **currently visible** space.

**The bar appears but clicking doesn't switch windows.**
- Make sure the app is still running. It registers as an accessory (no Dock
  icon), so check Activity Monitor or `pgrep -f YabaiStackSwitcher`.

**Stale signals after a crash.**
- Just relaunch the app — it removes any orphaned `yss-*` signals before
  re-registering.

## Uninstall

1. Quit the app (Activity Monitor → quit `YabaiStackSwitcher`, or
   `pkill -f YabaiStackSwitcher`).
2. Remove it from Login Items if you added it.
3. Delete `YabaiStackSwitcher.app`.

Any yabai signals are removed automatically on quit.

## License

MIT
