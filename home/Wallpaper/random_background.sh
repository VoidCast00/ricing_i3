#!/bin/sh

backgrounds="${HOME}/Wallpaper/"
BG_CMD="feh --bg-fill"

monitor_resolutions () {
	# one WIDTHxHEIGHT per active monitor, in the order feh hands out images
	xrandr --listactivemonitors | awk 'NR > 1 { split($3, a, /[\/x+]/); print a[1] "x" a[3] }'
}

get_fitting_image () {
	# We check a directory that contains WIDTHxHEIGHT named subdirectories
	# So if your screen size is 1920x1080 you should have
	# "${backgrounds}/1920x1080"
	# No folder for that size: take any wallpaper, --bg-fill scales it
	find -L "${backgrounds}$1" -type f 2>/dev/null | shuf -n1 | grep . ||
		find -L "$backgrounds" -mindepth 2 -type f \( -iname '*.png' -o -iname '*.jp*g' \) | shuf -n1
}

set_screensaver () {
	# Convert images to png for i3lock if necessary
	# The image is only converted once and cached in the i3 directory
	img=$1
	echo "Set ${img} as i3lock wallpaper"
	png="${img%.*}.png"
	target="${HOME}/.config/i3/$(sha1sum "${img}" | awk '{ print $1 }').png"
	if [ ! -f "$target" ]; then
		if [ "$img" != "$png" ]; then
			echo "Converting source $img to $target"
			convert "$img" "$target"
		else
			cp "$img" "$target"
		fi
	fi
	ln -sf "$target" "${HOME}/.config/i3/i3lock.png"
}

set_background () {
	# a different random image on every monitor
	set --
	for res in $(monitor_resolutions); do
		set -- "$@" "$(get_fitting_image "$res")"
	done
	echo "Set $* as desktop wallpaper"
	$BG_CMD "$@"
}

for cmd in xdpyinfo xrandr feh convert; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "$cmd is not installed, this won't work"
		exit 1
	fi
done

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
	echo "I can't seem to connect to display '$DISPLAY'"
	exit 2
fi

# lock screen image: one fitting the first monitor
img="$(get_fitting_image "$(monitor_resolutions | head -n1)")"

case ${1:-background} in
	screensaver*)
		set_screensaver "$img"
		;;
	background*)
		set_background
		;;
	both*)
		set_background
		set_screensaver "$img"
		;;
esac
