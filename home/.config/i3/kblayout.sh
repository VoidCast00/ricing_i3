#!/usr/bin/env bash
# Toggle keyboard layout: English (US) <-> Slovak (QWERTY)

if setxkbmap -query | grep -qE '^layout:\s+us$'; then
    setxkbmap -layout sk -variant qwerty
    name="Slovak (QWERTY)"
else
    setxkbmap -layout us
    name="English (US)"
fi

notify-send -u low -t 1200 \
    -h string:x-dunst-stack-tag:kblayout \
    $'\U000F030C  Keyboard' "$name"
