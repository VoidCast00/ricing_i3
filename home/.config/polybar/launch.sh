#!/usr/bin/env bash
# (Re)start polybar on every monitor — called from i3 on every reload/restart and by displays.sh.
# The primary monitor gets bar "main" (with the tray), the others get "secondary" (no tray — there can only be one).

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/polybar-launch.lock"
flock 9   # i3 reload and a monitor hotplug can both call this at once

killall -q polybar
# a bar that lost its X connection can hang on shutdown: give it 3 s, then force it
for _ in {1..15}; do pgrep -u "$UID" -x polybar >/dev/null || break; sleep 0.2; done
killall -q -9 polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

log="${XDG_RUNTIME_DIR:-/tmp}/polybar.log"
monitors="$(polybar --list-monitors)"
# no primary set (e.g. fresh xrandr layout) -> the first monitor gets the tray
primary="$(awk -F: '/\(primary\)/ { print $1; exit }' <<<"$monitors")"
[[ -n "$primary" ]] || primary="$(head -n1 <<<"$monitors" | cut -d: -f1)"

for m in $(cut -d: -f1 <<<"$monitors"); do
    [[ "$m" == "$primary" ]] && bar=main || bar=secondary
    # 9>&-: don't hand the lock to the bar, or the next launch waits for it forever
    MONITOR="$m" polybar "$bar" 9>&- >>"$log" 2>&1 & disown
done
