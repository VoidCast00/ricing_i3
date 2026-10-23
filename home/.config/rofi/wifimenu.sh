#!/usr/bin/env bash
# rofi Wi-Fi menu (NetworkManager / nmcli)
#   connect to saved networks, new ones (asks for password, or username + password
#   for WPA-Enterprise), disconnect, rescan, turn wifi on/off

ic() { printf "\\U$1"; }

notify() { notify-send -u "${2:-low}" -h string:x-dunst-stack-tag:wifi "$(ic 000F05A9)  Wi-Fi" "$1"; }

# names made only of spaces / Hangul fillers (U+3164) render as blank
filler="$(printf '\u3164')"
invisible() { local v="${1//"$filler"/}"; [[ -z "${v//[[:space:]]/}" ]]; }

esc() { local s="${1//&/&amp;}"; s="${s//</&lt;}"; printf '%s' "${s//>/&gt;}"; }

menu() {   # menu PROMPT LINES [extra rofi args] — prints the picked row index
    rofi -dmenu -i -markup-rows -format i -p "$1" \
         -theme-str "window { width: 440px; } listview { lines: $2; }" "${@:3}"
}

ask() {    # ask PROMPT MESSAGE [-password] — free text input, no list
    rofi -dmenu -p "$1" -mesg "$2" "${@:3}" \
         -theme-str 'window { width: 440px; } mainbox { children: [ inputbar, message ]; }' </dev/null
}

confirm() { [[ "$(printf 'no\nyes\n' | rofi -dmenu -p "$1?" -theme-str 'window { width: 320px; } listview { lines: 2; }')" == "yes" ]]; }

iface="$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" { print $1; exit }')"

wifi_uuids() { nmcli -t -f UUID,TYPE connection show | awk -F: '$2 == "802-11-wireless" { print $1 }'; }

saved_uuid_for() {
    local uuid ssid
    for uuid in $(wifi_uuids); do
        ssid="$(nmcli -g 802-11-wireless.ssid connection show "$uuid")"
        [[ "${ssid//\\:/:}" == "$1" ]] && { echo "$uuid"; return; }
    done
}

# --- wifi off: only offer to turn it on
if [[ "$(nmcli radio wifi)" != "enabled" ]]; then
    [[ -n "$(printf '%s\n' "$(ic 000F05A9)  turn wifi on" | menu "wifi" 1)" ]] &&
        nmcli radio wifi on && notify "turned on"
    exit
fi

# --- collect networks, strongest per name first
rows=("$(ic 000F0450)  rescan" "$(ic 000F05AA)  turn wifi off")
ssids=() bssids=() secs=() inuse=()
active=""
declare -A seen
while IFS= read -r line; do
    line="${line//\\:/$'\x01'}"
    IFS=: read -r use signal security bssid ssid <<<"$line"
    bssid="${bssid//$'\x01'/:}"
    ssid="${ssid//$'\x01'/:}"
    [[ -z "$ssid" || -n "${seen[$ssid]}" ]] && continue
    seen[$ssid]=1

    if   (( signal >= 75 )); then bars="$(ic 000F0928)"
    elif (( signal >= 50 )); then bars="$(ic 000F0925)"
    elif (( signal >= 25 )); then bars="$(ic 000F0922)"
    else                          bars="$(ic 000F091F)"
    fi

    invisible "$ssid" && name="<i>(invisible name)</i>" || name="$(esc "$ssid")"
    [[ -n "$security" && "$security" != "--" ]] && lock="  $(ic 000F033E)" || lock=""

    [[ "$use" == "*" ]] && active="${#rows[@]}"
    rows+=("$bars  $name$lock  <span fgalpha='55%'>$signal%</span>")
    ssids+=("$ssid") bssids+=("$bssid") secs+=("$security") inuse+=("$use")
done < <(nmcli -t -e yes -f IN-USE,SIGNAL,SECURITY,BSSID,SSID device wifi list --rescan auto)

pick="$(printf '%s\n' "${rows[@]}" | menu "wifi" 10 ${active:+-a "$active"})"
[[ -z "$pick" ]] && exit

case "$pick" in
    0) nmcli device wifi rescan 2>/dev/null; sleep 2; exec "$0" ;;
    1) nmcli radio wifi off && notify "turned off"; exit ;;
esac

i=$(( pick - 2 ))
ssid="${ssids[$i]}" bssid="${bssids[$i]}" security="${secs[$i]}"
invisible "$ssid" && label="(invisible name)" || label="$(esc "$ssid")"

# --- already connected: offer to disconnect
if [[ "${inuse[$i]}" == "*" ]]; then
    confirm "disconnect" && nmcli device disconnect "$iface" >/dev/null && notify "disconnected"
    exit
fi

# --- saved network: just bring it up
if uuid="$(saved_uuid_for "$ssid")" && [[ -n "$uuid" ]]; then
    notify "connecting to $label…"
    if err="$(nmcli connection up uuid "$uuid" 2>&1)"; then
        notify "connected to $label"
    else
        notify "couldn't connect to $label"$'\n'"${err##*Error: }" critical
    fi
    exit
fi

# --- new network
before="$(wifi_uuids)"
if [[ "$security" == *802.1X* ]]; then
    user="$(ask "username" "$label — WPA-Enterprise login")" || exit
    [[ -z "$user" ]] && exit
    pass="$(ask "password" "$label — password for $(esc "$user")" -password)" || exit
    notify "connecting to $label…"
    err="$(nmcli connection add type wifi ifname "$iface" con-name "$ssid" ssid "$ssid" \
               wifi-sec.key-mgmt wpa-eap 802-1x.eap peap 802-1x.phase2-auth mschapv2 \
               802-1x.identity "$user" 802-1x.password "$pass" 2>&1 &&
           nmcli connection up id "$ssid" 2>&1)"
elif [[ -n "$security" && "$security" != "--" ]]; then
    pass="$(ask "password" "$label" -password)" || exit
    [[ -z "$pass" ]] && exit
    notify "connecting to $label…"
    err="$(nmcli device wifi connect "$bssid" password "$pass" 2>&1)"
else
    notify "connecting to $label…"
    err="$(nmcli device wifi connect "$bssid" 2>&1)"
fi
status=$?

if (( status == 0 )); then
    notify "connected to $label"
else
    # don't keep a half-made profile with a wrong password around
    for u in $(wifi_uuids); do
        grep -qx "$u" <<<"$before" || nmcli connection delete uuid "$u" >/dev/null 2>&1
    done
    notify "couldn't connect to $label"$'\n'"${err##*Error: }" critical
fi
