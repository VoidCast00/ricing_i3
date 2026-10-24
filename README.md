# Ricing (on my specific machine - Manjaro)

| Part          | Tool                         | Config                                  |
|---------------|------------------------------|-----------------------------------------|
| Window manager| i3                           | `home/.config/i3/config`                |
| Bar           | polybar                      | `home/.config/polybar/`                 |
| Launcher      | rofi                         | `home/.config/rofi/`                    |
| Notifications | dunst                        | `home/.config/dunst/dunstrc`            |
| Lock screen   | i3lock-color (+ xss-lock)    | `home/.config/i3/lock.sh`               |
| Terminal      | kitty                        | `home/.config/kitty/`                   |
| Wallpaper     | feh, random on every reload  | `home/Wallpaper/`                       |

## Restore

```sh
git clone https://github.com/VoidCast00/ricing_i3/ ~/ricing
cd ~/ricing
./install.sh --packages   # installs packages (pacman + yay) links configs
```


- `wlp0s20f3` (wifi), `enp0s31f6` (ethernet)
- `BAT0` / `AC` (battery)
- `intel_backlight` (brightness)

## Keys

| Keys                | Action                 |
|---------------------|------------------------|
| `Super+Enter`       | kitty                  |
| `Super+Space`       | rofi app launcher      |
| `Super+Shift+E`     | power menu (lock / logout / suspend / reboot / shutdown) |
| `Super+Shift+L`     | lock screen            |
| `Super+Shift+W`     | Wi-Fi menu (also: click the Wi-Fi icon on the bar) |
| `Super+Shift+M`     | mouse / touchpad speed slider: ← → to slide (Shift = fine), applies live (also: mouse icon top-right on the bar) |
| `Super+Shift+A`     | accent color picker (preset or any hex) |
| `Super+Alt+K`       | toggle keyboard layout: US ↔ Slovak (QWERTY) |
| `Super+Shift+←↓↑→`  | move window (also onto the next monitor) |
| `Super+Ctrl+←↓↑→`   | move the whole workspace to the monitor in that direction |
| `Super+P` / display key | re-detect monitors (normally automatic on plug / unplug) |
| `Super+Shift+R`     | restart i3 (and bar)   |
| Brightness keys     | brightness ±5%         |

Multiple monitors: a plugged-in monitor turns on right of the others (`home/.config/i3/displays.sh`), every monitor gets its own bar
(the tray only on the primary) and its own random wallpaper. Layouts set by hand with `xrandr` / `arandr` are kept.

Cursor: pick the theme in **Customize Look and Feel** (lxappearance) → *Mouse Cursor* tab; size is set in `home/.Xresources`.

Bar: left-click the power profile to cycle saver → balanced → perf, right-click to pick one.
Click the zZ icon to keep the laptop running with the lid closed (yellow cup = awake); click again to go back to normal.
