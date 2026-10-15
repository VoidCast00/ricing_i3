#!/usr/bin/env bash
# Power profile module for polybar (power-profiles-daemon).
#   powerprofile.sh        print the current profile, re-print whenever it changes (tail mode)
#   powerprofile.sh next   cycle power-saver -> balanced -> performance
#   powerprofile.sh menu   pick one with rofi

dest=org.freedesktop.UPower.PowerProfiles
path=/org/freedesktop/UPower/PowerProfiles

saver_icon=$'\U000F032A'
balanced_icon=$'\U000F0F85'
perf_icon=$'\U000F04C5'

get() {
    busctl --system get-property "$dest" "$path" "$dest" ActiveProfile | cut -d'"' -f2
}

show() {
    case "$(get)" in
        power-saver) echo "%{F#b8bb26}$saver_icon%{F-} saver" ;;
        balanced)    echo "%{F#83a598}$balanced_icon%{F-} balanced" ;;
        performance) echo "%{F#fb4934}$perf_icon%{F-} perf" ;;
        *)           echo "?" ;;
    esac
}

case "${1:-}" in
    next)
        case "$(get)" in
            power-saver) next=balanced ;;
            balanced)    next=performance ;;
            *)           next=power-saver ;;
        esac
        powerprofilesctl set "$next"
        ;;
    menu)
        choice="$(printf '%s\n' "$saver_icon  power-saver" "$balanced_icon  balanced" "$perf_icon  performance" |
            rofi -dmenu -i -p "power profile" -theme-str 'window { width: 320px; } listview { lines: 3; }')"
        [[ -n "$choice" ]] && powerprofilesctl set "${choice##* }"
        ;;
    *)
        show
        exec {mon}< <(gdbus monitor --system --dest "$dest" --object-path "$path")
        mon_pid=$!
        # don't leave gdbus running when polybar restarts us
        trap 'kill "$mon_pid" 2>/dev/null' EXIT
        trap 'exit' TERM INT
        while read -r -u "$mon" line; do
            [[ "$line" == *ActiveProfile* ]] && show
        done
        ;;
esac
