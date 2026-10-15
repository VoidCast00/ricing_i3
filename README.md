# ricing

My i3 setup on Manjaro: Gruvbox Dark everywhere, thin borders, no gaps.

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
git clone <this repo> ~/ricing
cd ~/ricing
./install.sh --packages   # installs packages (pacman + yay), then links configs
```

`./install.sh` without `--packages` only (re)creates the symlinks. Every file in
`home/` is symlinked to the same path under `~`, so editing `~/.config/...` edits
the repo. Existing files that differ are moved to `*.bak-<timestamp>` first.

New config file? Move it into `home/` at the same path and run `./install.sh`.

## Machine-specific bits

`home/.config/polybar/config.ini` names this laptop's hardware — check these on a
new machine (`ip link`, `ls /sys/class/power_supply /sys/class/backlight`):

- `wlp0s20f3` (wifi), `enp0s31f6` (ethernet)
- `BAT0` / `AC` (battery)
- `intel_backlight` (brightness)

## Keys

| Keys                | Action                 |
|---------------------|------------------------|
| `Super+Enter`       | kitty                  |
| `Super+Space`       | rofi app launcher      |
| `Super+Tab`         | rofi window switcher   |
| `Super+Shift+L`     | lock screen            |
| `Super+Shift+R`     | restart i3 (and bar)   |
