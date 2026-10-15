#!/usr/bin/env bash
# Gruvbox lock screen (needs i3lock-color). Extra args (e.g. --nofork from xss-lock) are passed through.

font="Hack Nerd Font"
accent=83a598   # rrggbb, set by the accent picker

exec i3lock \
    --blur 8 \
    --clock --indicator \
    --radius 110 --ring-width 7 \
    --inside-color=282828cc --ring-color=504945ff \
    --insidever-color=282828cc --ringver-color=fabd2fff \
    --insidewrong-color=282828cc --ringwrong-color=fb4934ff \
    --line-uses-inside \
    --keyhl-color=${accent}ff --bshl-color=fb4934ff --separator-color=00000000 \
    --time-color=ebdbb2ff --date-color=a89984ff --layout-color=a89984ff \
    --verif-color=fabd2fff --wrong-color=fb4934ff --modif-color=a89984ff \
    --time-str="%H:%M" --date-str="%a %d %b" \
    --time-font="$font" --date-font="$font" --layout-font="$font" \
    --verif-font="$font" --wrong-font="$font" \
    --time-size=40 --date-size=15 --verif-size=18 --wrong-size=18 \
    --verif-text="checking…" --wrong-text="wrong" --noinput-text="empty" \
    --ignore-empty-password --show-failed-attempts \
    "$@"
