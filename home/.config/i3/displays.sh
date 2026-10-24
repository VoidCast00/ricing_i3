#!/usr/bin/env bash
# Monitor hotplug: turn on newly plugged monitors, turn off unplugged ones, then redo bars + wallpaper.
#   displays.sh         apply now (Super+P / the display key)
#   displays.sh watch   apply whenever a monitor is plugged in / out (run at login)
# A new monitor is placed right of the rightmost one; outputs that are already on keep their layout
# (so anything set up by hand with xrandr / arandr stays put).

apply() {
    local q out right=""
    q="$(xrandr --query)"

    # unplugged but still holding a mode -> off
    for out in $(awk '/ disconnected [0-9]+x[0-9]+\+/ { print $1 }' <<<"$q"); do
        xrandr --output "$out" --off
    done

    # rightmost active output, to place new ones next to it
    right="$(xrandr --listactivemonitors | awk 'NR > 1 { split($3, a, /[\/x+]/); x = a[5] + a[1]
                                                        if (x > max) { max = x; o = $NF } } END { print o }')"

    # plugged in but off (no geometry after "connected [primary]") -> on, right of the rest
    for out in $(awk '/ connected/ && !/ connected (primary )?[0-9]+x[0-9]+\+/ { print $1 }' <<<"$q"); do
        if [[ -n "$right" ]]; then
            xrandr --output "$out" --auto --right-of "$right"
        else
            xrandr --output "$out" --auto --primary
        fi
        right="$out"
    done

    ~/.config/polybar/launch.sh
    ~/Wallpaper/random_background.sh
}

case "${1:-}" in
    watch)
        exec 9>"${XDG_RUNTIME_DIR:-/tmp}/displays.lock"
        flock -n 9 || exit 0                     # already watching
        udevadm monitor --udev --subsystem-match=drm | while read -r line; do
            [[ "$line" == *" change "* ]] || continue
            while read -r -t 1 _; do :; done     # wait until the burst of events settles
            sleep 0.5; apply
        done
        ;;
    *)
        apply
        ;;
esac
