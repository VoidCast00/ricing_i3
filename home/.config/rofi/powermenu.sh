#!/usr/bin/env bash
# rofi power menu — lock / logout / suspend / reboot / shutdown

lock=$'\U000F033E  lock'
logout=$'\U000F0343  logout'
suspend=$'\U000F0904  suspend'
reboot=$'\U000F0709  reboot'
shutdown=$'\U000F0425  shutdown'

menu() {
    rofi -dmenu -i -p "$1" -theme-str "window { width: 320px; } listview { lines: $2; }"
}

confirm() {
    [[ "$(printf 'no\nyes\n' | menu "$1?" 2)" == "yes" ]]
}

choice="$(printf '%s\n' "$lock" "$logout" "$suspend" "$reboot" "$shutdown" | menu "power" 5)"

case "$choice" in
    "$lock")     ~/.config/i3/lock.sh ;;
    "$logout")   confirm "logout"   && i3-msg exit ;;
    "$suspend")  systemctl suspend ;;   # xss-lock locks the screen first
    "$reboot")   confirm "reboot"   && systemctl reboot ;;
    "$shutdown") confirm "shutdown" && systemctl poweroff ;;
esac
