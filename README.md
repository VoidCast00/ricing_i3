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
| `Super+Shift+A`     | accent color picker (preset or any hex) |
| `Super+Alt+K`       | toggle keyboard layout: US ↔ Slovak (QWERTY) |
| `Super+Shift+R`     | restart i3 (and bar)   |
| Brightness keys     | brightness ±5%         |

Bar: left-click the power profile to cycle saver → balanced → perf, right-click to pick one.
