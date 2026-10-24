#!/usr/bin/env bash
# Mouse / touchpad speed slider (libinput Accel Speed -1.00 … +1.00) + acceleration on/off, per device.
#   mousesens.sh         rofi: pick a device (skipped if there's only one), then ← → to slide — applies live, Esc when done
#   mousesens.sh apply   apply saved settings to connected devices
#   mousesens.sh watch   apply now and again whenever a device is plugged in (run at login)
# Saved per device in ~/.config/mousesens/devices.conf as: name<TAB>speed<TAB>profile

export LC_ALL=C   # xinput needs 0.30, not 0,30
conf="$HOME/.config/mousesens/devices.conf"
mkdir -p "${conf%/*}"; [[ -e "$conf" ]] || : > "$conf"

step=0.10   # ← →
fine=0.02   # Shift+← →

mouse_icon=$'\U000F037D'
pad_icon=$'\U000F0507'
notify() { notify-send -u low -h string:x-dunst-stack-tag:mousesens "$mouse_icon  Mouse" "$1"; }
esc() { local s="${1//&/&amp;}"; s="${s//</&lt;}"; printf '%s' "${s//>/&gt;}"; }

# connected libinput pointers as id<TAB>name<TAB>shown, one name per physical device:
# a mouse often shows up as several xinput devices ("Razer X", "Razer X Mouse", …), so they're grouped by
# vendor:product; built-in PS/2 / I2C "mouse" ghosts get shown=0 (touchpads and USB/Bluetooth mice stay 1)
devices() {
    local id props node sys kind
    for id in $(xinput list --id-only); do
        props="$(xinput list-props "$id" 2>/dev/null)"
        [[ "$props" == *"libinput Accel Speed ("* ]] || continue
        node="$(sed -n 's/.*Device Node ([0-9]*):[[:space:]]*"\(.*\)"/\1/p' <<<"$props")"
        sys="/sys/class/input/${node##*/}/device/id"
        [[ "$props" == *"libinput Tapping Enabled ("* ]] && kind=touchpad || kind=mouse
        printf '%s\t%s:%s:%s:%s\t%s\n' "$id" "$(<"$sys/bustype")" "$(<"$sys/vendor")" "$(<"$sys/product")" \
            "$kind" "$(xinput list --name-only "$id")"
    done 2>/dev/null | awk -F'\t' '
        function clean(n,  a) {   # "DELL0A20:00 0488:101A Touchpad" -> "Touchpad", "Razer Razer X" -> "Razer X"
            sub(/^[[:alnum:]]+:[[:xdigit:]]+ [[:xdigit:]]+:[[:xdigit:]]+ /, "", n)
            split(n, a, " "); if (a[1] == a[2]) n = substr(n, length(a[1]) + 2)
            return n
        }
        {
            id[NR] = $1; key[NR] = $2; split($2, k, ":")
            c = clean($3); if (!($2 in name) || length(c) < length(name[$2])) name[$2] = c
            keep[NR] = (k[4] == "touchpad" || k[1] == "0003" || k[1] == "0005"); any += keep[NR]
        }
        END { for (i = 1; i <= NR; i++) print id[i] "\t" name[key[i]] "\t" (keep[i] || !any) }'
}

ids_for() { awk -F'\t' -v n="$1" '$2 == n { print $1 }' <<<"$devlist"; }

is_touchpad() { xinput list-props "$1" | grep -q 'libinput Tapping Enabled ('; }

get_speed() {
    printf '%+.2f' "$(xinput list-props "$1" | sed -n 's/.*libinput Accel Speed ([0-9]*):[[:space:]]*//p')"
}

get_profile() {   # Profile Enabled is "adaptive, flat[, custom]"
    local v; v="$(xinput list-props "$1" | sed -n 's/.*libinput Accel Profile Enabled ([0-9]*):[[:space:]]*//p')"
    [[ "${v%%,*}" == "1" ]] && echo adaptive || echo flat
}

set_dev() {   # set_dev ID SPEED PROFILE
    local n vals
    xinput set-prop "$1" "libinput Accel Speed" "$2"
    n="$(xinput list-props "$1" | sed -n 's/.*libinput Accel Profile Enabled ([0-9]*):[[:space:]]*//p' | tr -cd ',' | wc -c)"
    [[ "$3" == "adaptive" ]] && vals="1 0" || vals="0 1"
    (( n >= 2 )) && vals+=" 0"   # newer libinput also has a "custom" profile slot
    xinput set-prop "$1" "libinput Accel Profile Enabled" $vals
}

set_name() {  # set_name NAME SPEED PROFILE — every device with that name, then save
    local id rest
    for id in $(ids_for "$1"); do set_dev "$id" "$2" "$3"; done
    rest="$(awk -F'\t' -v n="$1" '$1 != n' "$conf")"
    { [[ -n "$rest" ]] && printf '%s\n' "$rest"; printf '%s\t%s\t%s\n' "$1" "$2" "$3"; } > "$conf"
}

apply() {
    local name speed profile id
    devlist="$(devices)"
    while IFS=$'\t' read -r name speed profile; do
        [[ -z "$name" ]] && continue
        for id in $(ids_for "$name"); do set_dev "$id" "$speed" "$profile"; done
    done < "$conf"
}

clamp() { awk "BEGIN { x = $1; "'if (x > 1) x = 1; if (x < -1) x = -1; printf "%+.2f", x }'; }

bar() {   # bar SPEED — 21-cell slider, one cell per 0.1
    local knob i out=""
    knob="$(awk -v x="$1" 'BEGIN { printf "%d", (x + 1) * 10 + 0.5 }')"
    for (( i = 0; i < knob; i++ )); do out+="━"; done
    out+="<b>●</b><span fgalpha='35%'>"
    for (( i = knob + 1; i <= 20; i++ )); do out+="─"; done
    printf '%s</span>' "$out"
}

slider() {   # slider NAME
    local name="$1" id cur profile accel pick rc idx text sel=0
    local keys=(-kb-move-char-back Control+b -kb-move-char-forward Control+f
                -kb-mode-previous Control+ISO_Left_Tab -kb-mode-next Control+Tab
                -kb-custom-1 Left -kb-custom-2 Right -kb-custom-3 Shift+Left -kb-custom-4 Shift+Right)
    id="$(ids_for "$name" | head -n1)"
    while true; do
        cur="$(get_speed "$id")" || break; profile="$(get_profile "$id")"
        [[ "$profile" == flat ]] && accel="acceleration <b>off</b>  <span fgalpha='55%'>· Enter to turn on</span>" \
                                 || accel="acceleration <b>on</b>  <span fgalpha='55%'>· Enter to turn off</span>"
        # (no digits in the rows, so typing a number never matches one and comes back as custom input)
        pick="$(printf '%s\n' "slow  $(bar "$cur")  fast" "$accel" "reset speed to default" |
            rofi -dmenu -markup-rows -format 'i s' -selected-row "$sel" -p "$cur" "${keys[@]}" \
                 -mesg "<b>$(esc "$name")</b>
<span fgalpha='55%'>← → slide · Shift+← → fine · or type a number + Enter · Esc done</span>" \
                 -theme-str 'window { width: 560px; } listview { lines: 3; }')"
        rc=$?
        idx="${pick%% *}"; text="${pick#* }"
        [[ "$idx" =~ ^[0-9]+$ ]] && sel="$idx"
        case "$rc" in
            10) set_name "$name" "$(clamp "$cur - $step")" "$profile" ;;
            11) set_name "$name" "$(clamp "$cur + $step")" "$profile" ;;
            12) set_name "$name" "$(clamp "$cur - $fine")" "$profile" ;;
            13) set_name "$name" "$(clamp "$cur + $fine")" "$profile" ;;
            0)
                case "$idx" in
                    0) break ;;
                    1) [[ "$profile" == flat ]] && profile=adaptive || profile=flat
                       set_name "$name" "$cur" "$profile" ;;
                    2) set_name "$name" "+0.00" "$profile" ;;
                    *)
                        text="${text//,/.}"; text="${text// /}"
                        if [[ "$text" =~ ^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)$ ]]; then
                            set_name "$name" "$(clamp "$text")" "$profile"
                        else
                            notify "\"$(esc "$text")\" isn't a number — use something like 0.35 or -0.4"
                        fi
                        ;;
                esac
                ;;
            *) break ;;
        esac
    done
    notify "$(esc "$name"): speed $(get_speed "$id"), acceleration $( [[ "$(get_profile "$id")" == flat ]] && echo off || echo on ) — saved"
}

case "${1:-}" in
    apply) apply ;;
    watch)
        exec 9>"${XDG_RUNTIME_DIR:-/tmp}/mousesens.lock"
        flock -n 9 || exit 0                     # already watching
        apply
        udevadm monitor --udev --subsystem-match=input | while read -r line; do
            [[ "$line" == *" add "* ]] || continue
            while read -r -t 1 _; do :; done     # wait until the burst of events settles
            sleep 0.5; apply
        done
        ;;
    *)
        devlist="$(devices)"
        if [[ -z "$devlist" ]]; then notify "no mouse or touchpad found"; exit 1; fi
        all=0
        while true; do
            # shown devices first, then (after "show hidden devices") the built-in ghosts
            mapfile -t names < <(awk -F'\t' -v all="$all" '$3 || all { print $3 "\t" $2 }' <<<"$devlist" |
                                 sort -s -t$'\t' -k1,1r | cut -f2 | awk '!seen[$0]++')
            rows=()
            for n in "${names[@]}"; do
                id="$(ids_for "$n" | head -n1)"
                is_touchpad "$id" && icon="$pad_icon" || icon="$mouse_icon"
                p="$(get_profile "$id")"; [[ "$p" == flat ]] && p="no accel" || p="accel"
                awk -F'\t' -v n="$n" '$2 == n && $3 { f = 1 } END { exit !f }' <<<"$devlist" || p+=" · built-in"
                rows+=("$icon  $(esc "$n")  <span fgalpha='55%'>$(get_speed "$id") · $p</span>")
            done
            (( !all )) && awk -F'\t' '!$3 { f = 1 } END { exit !f }' <<<"$devlist" &&
                rows+=("<span fgalpha='55%'>show hidden devices (built-in PS/2 / I2C)</span>")
            idx="$(printf '%s\n' "${rows[@]}" |
                rofi -dmenu -i -markup-rows -format i -p "device" -no-custom \
                     -mesg "plug a mouse in to see it here" \
                     -theme-str "window { width: 560px; } listview { lines: ${#rows[@]}; }")"
            [[ -z "$idx" ]] && exit 0
            (( idx == ${#names[@]} )) && { all=1; continue; }
            slider "${names[$idx]}"
            break
        done
        ;;
esac
