#!/usr/bin/env bash
# (Re)start polybar — called from i3 on every reload/restart.

killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

polybar main >>"${XDG_RUNTIME_DIR:-/tmp}/polybar.log" 2>&1 & disown
