#!/bin/sh

backgrounds="${HOME}/Wallpaper/"
BG_CMD="feh --no-xinerama --bg-fill"

get_fitting_image () {
	# We check a directory that contains WIDTHxHEIGHT named subdirectories
	# So if your screen size is 1920x1080 you should have
	# "${backgrounds}/1920x1080"
	resolution=$(xdpyinfo | awk '/dimensions/{print $2}')
	find -L "${backgrounds}${resolution}" -type f | shuf -n1
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
	echo "Set ${1} as desktop wallpaper"
	$BG_CMD "$1"
}

for cmd in xdpyinfo feh convert; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "$cmd is not installed, this won't work"
		exit 1
	fi
done

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
	echo "I can't seem to connect to display '$DISPLAY'"
	exit 2
fi

img="$(get_fitting_image)"

case ${1:-background} in
	screensaver*)
		set_screensaver "$img"
		;;
	background*)
		set_background "$img"
		;;
	both*)
		set_background "$img"
		set_screensaver "$img"
		;;
esac
