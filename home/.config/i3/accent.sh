#!/usr/bin/env bash
# Accent color picker — re-themes i3 borders, polybar, rofi, dunst and the lock screen.
#   accent.sh            rofi menu: pick a preset or type any hex (#rrggbb)
#   accent.sh '#83a598'  set it directly

cfg="$HOME/.config"
current="$(grep -oP '^set \$accent\s+\K#[0-9a-fA-F]{6}' "$cfg/i3/config")"

presets=(
    "orange #fe8019"
    "yellow #fabd2f"
    "green  #b8bb26"
    "aqua   #8ec07c"
    "blue   #83a598"
    "purple #d3869b"
    "red    #fb4934"
    "gray   #a89984"
)

if [[ -n "${1:-}" ]]; then
    input="$1"
else
    input="$(for p in "${presets[@]}"; do
                 printf '<span foreground="%s">████</span>  %s\n' "${p##* }" "$p"
             done |
             rofi -dmenu -i -markup-rows -p "accent" \
                  -mesg "current <span foreground='$current'>████</span> $current — pick one or type a hex like #458588" \
                  -theme-str 'window { width: 520px; } listview { lines: 8; }')"
    [[ -z "$input" ]] && exit 0
fi

# take the last hex code in the input: works for a picked row or typed text
hex="$(grep -oiE '#?[0-9a-f]{6}' <<<"$input" | tail -n1 | tr -d '#' | tr 'A-F' 'a-f')"
if [[ ! "$hex" =~ ^[0-9a-f]{6}$ ]]; then
    notify-send -u normal "Accent color" "\"$input\" is not a hex color — use #rrggbb"
    exit 1
fi

# --follow-symlinks: the configs are symlinks into ~/ricing, keep them that way
sedi() { sed -i --follow-symlinks -E "$@"; }
sedi "s/^(set \\\$accent\s+)#[0-9a-fA-F]{6}/\1#$hex/" "$cfg/i3/config"
sedi "s/^(accent\s+= )#[0-9a-fA-F]{6}/\1#$hex/" "$cfg/polybar/config.ini"
sedi "s/^(\s+accent: )#[0-9a-fA-F]{6};/\1#$hex;/" "$cfg/rofi/themes/gruvbox-dark-custom.rasi"
sedi "s/^accent=[0-9a-fA-F]{6}/accent=$hex/" "$cfg/i3/lock.sh"
sedi -e "/^\[global\]/,/^\[/ s/^(\s+highlight = )\"#[0-9a-fA-F]{6}\"/\1\"#$hex\"/" \
     -e "/^\[urgency_normal\]/,/^\[/ s/^(\s+frame_color = )\"#[0-9a-fA-F]{6}\"/\1\"#$hex\"/" \
     "$cfg/dunst/dunstrc"

i3-msg reload >/dev/null
"$cfg/polybar/launch.sh"
dunstctl reload
notify-send "Accent color" "<span foreground='#$hex'>████</span>  #$hex"
