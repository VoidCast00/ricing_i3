#!/usr/bin/env bash
# brightness.sh up|down — change backlight by 5% and show a dunst progress bar

case "$1" in
    up)   brightnessctl -q set 5%+ ;;
    down) brightnessctl -q --min-value=1 set 5%- ;;
    *)    echo "usage: $0 up|down" >&2; exit 1 ;;
esac

pct="$(brightnessctl -m | cut -d, -f4 | tr -d %)"

# the stack tag makes each press replace the previous popup instead of piling up
notify-send -u low -t 1500 \
    -h string:x-dunst-stack-tag:brightness \
    -h "int:value:$pct" \
    $'\U000F00E0  Brightness' "$pct%"
