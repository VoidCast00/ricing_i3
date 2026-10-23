#!/usr/bin/env bash
# Keep running with the lid closed (downloads etc. continue).
# Holds a logind "handle-lid-switch" inhibitor while on — no sudo needed.
#   lidawake.sh          print the bar label
#   lidawake.sh toggle   turn on / off

pidfile="${XDG_RUNTIME_DIR:-/tmp}/lidawake.pid"
coffee=$'\U000F0176'
sleep_icon=$'\U000F04B2'

on() { [[ -f "$pidfile" ]] && kill -0 "$(<"$pidfile")" 2>/dev/null; }

notify() { notify-send -u low -h string:x-dunst-stack-tag:lidawake "$coffee  Lid" "$1"; }

case "${1:-}" in
    toggle)
        if on; then
            kill "$(<"$pidfile")"
            rm -f "$pidfile"
            notify "off — closing the lid suspends again"
        else
            setsid systemd-inhibit --what=handle-lid-switch --who="lidawake" \
                --why="Keep running with the lid closed" --mode=block sleep infinity >/dev/null 2>&1 &
            echo $! > "$pidfile"
            notify "awake — closing the lid won't suspend"
        fi
        polybar-msg action lidawake hook 0 >/dev/null 2>&1
        ;;
    *)
        if on; then
            echo "%{F#fabd2f}$coffee%{F-} awake"
        else
            echo "%{F#a89984}$sleep_icon%{F-}"
        fi
        ;;
esac
