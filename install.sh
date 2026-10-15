#!/usr/bin/env bash
# Restore the rice: symlink everything in home/ into $HOME.
#   ./install.sh             link configs only
#   ./install.sh --packages  install packages first, then link
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"

if [[ "${1:-}" == "--packages" ]]; then
    sudo pacman -S --needed - < "$repo/packages.txt"
    if command -v yay >/dev/null; then
        # i3lock-color replaces i3lock — answer yes when asked
        yay -S --needed - < "$repo/aur-packages.txt"
    else
        echo "yay not found — install these from the AUR yourself: $(tr '\n' ' ' < "$repo/aur-packages.txt")"
    fi
fi

cd "$repo/home"
find . -type f -print0 | while IFS= read -r -d '' f; do
    rel="${f#./}"
    src="$repo/home/$rel"
    dst="$HOME/$rel"
    mkdir -p "$(dirname "$dst")"

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        continue                                  # already linked
    elif [[ -f "$dst" && ! -L "$dst" ]] && cmp -s "$src" "$dst"; then
        rm "$dst"                                 # identical copy, no backup needed
    elif [[ -e "$dst" || -L "$dst" ]]; then
        mv "$dst" "$dst.bak-$stamp"
        echo "backed up ~/$rel -> ~/$rel.bak-$stamp"
    fi
    ln -s "$src" "$dst"
    echo "linked ~/$rel"
done

if pgrep -x i3 >/dev/null; then
    i3-msg reload >/dev/null && echo "i3 reloaded"
fi
echo "done"
