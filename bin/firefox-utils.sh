#!/usr/bin/env bash
ff_data="$HOME/.mozilla/firefox"
ff_dots="$ff_data/dots"
imgname="newtab-bg.jpg"

usage() {
	cat <<\EOF
Usage:
  firefoxutil [options] <parameters>

Options:
  --link-dots               Link files at ~/.mozilla/firefox/dots into
                            existing profile(s).

  --set-newtab-bg <path>    Change newtab wallpaper (requires custom css that already
                            alters background-image to newtab-bg.jpg).
EOF
	exit
}

log() {
	printf "$(basename "$0"): %s\n" "$1"
}

linkdots() {
	local src="$1"
	local dest="$2"

	for f_src in "$src"/*; do
		f_dest="$(printf ${f_src%/*} | sed "s|$src|$dest|")"
		log "linking $f_src to $f_dest"
		if [[ "$(stat -c %h -- "$f_dest")" -gt 1 ]]; then
			ln -srf "$f_src" "$f_dest"
		else
			ln -sr "$f_src" "$f_dest"
		fi
	done
}

set_newtab_bg() {
	local img="$1"

	if [ ! -f "$img" ]; then
		log "Please provide a file" >&2
		log "example: firefox-utils --set-newtab-bg ~/Pictures/coolwallpaper.jpg" >&2
		exit 1
	fi

	log "Searching for \"background-image: url($imgname)\"..."
	grep -l -r "url($imgname)" $ff_data | while read -r filepath; do
		if ! (grep -q '/chrome/' <<<$filepath); then
			continue
		fi

		target="${filepath%/*}/$imgname"
		log "Found: $filepath"
		log "copying $img to $target"
		cp -f "$img" "$target"
		chmod 644 "$target"
	done

	log "done"
}

search_and_linkdots() {
	if [[ ! -d "$ff_dots" ]]; then
		log "no firefox dotfiles detected at $ff_dots" >&2
		exit 1
	fi

	awk '/\[/{prefix=$0; next} $1{print prefix $0}' "$ff_data/profiles.ini" | grep Path | sed -e 's/.*Path=//g' | while read profile; do
		if [[ -f $ff_data/$profile/prefs.js ]]; then
			linkdots "$ff_dots" "$ff_data/$profile"
		fi
	done
}

parsed=$(getopt -o '' --longoptions=link-dots,set-newtab-bg --name "$0" -- "$@")
if [ $? -ne 0 ]; then
	log 'Invalid argument, exiting.' >&2
	usage
	exit 1
fi

eval set -- "$parsed"
unset parsed

if [[ ! -f "$ff_data/profiles.ini" ]]; then
	log "no firefox profile detected, open firefox first." >&2
	exit 1
fi

while true; do
	case "$1" in
	"--link-dots")
		search_and_linkdots
		exit $?
		;;
	"--set-newtab-bg")
		set_newtab_bg "$3"
		exit $?
		;;
	"-h" | "--help")
		usage
		exit
		;;
	"--")
		shift
		break
		;;
	esac
done
