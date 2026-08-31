#!/usr/bin/env bash
# Repair tmux-resurrect's `last` symlink before restore runs.
#
# A hard shutdown (WSL kill, power loss) can truncate the continuum autosave
# mid-write, leaving `last` pointing at a 0-byte file. Resurrect's restore then
# restores nothing, handle_session_0 kills the only session, the server dies,
# and a fresh `tmux` prints [exited]. Run as @resurrect-hook-pre-restore-all:
# if `last` is empty or dangling, repoint it to the newest non-empty save and
# prune truncated saves so they can't be picked again.
set -uo pipefail

dir="$(tmux show -gqv @resurrect-dir)"
dir="${dir/#\~/$HOME}"
if [ -z "$dir" ]; then
	for d in "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect" "$HOME/.tmux/resurrect"; do
		[ -d "$d" ] && { dir="$d"; break; }
	done
fi
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

last="$dir/last"
[ -s "$last" ] && exit 0

good=""
for f in $(command ls -t "$dir"/tmux_resurrect_*.txt 2>/dev/null); do
	[ -s "$f" ] && { good="$f"; break; }
done
[ -n "$good" ] || exit 0

find "$dir" -maxdepth 1 -name 'tmux_resurrect_*.txt' -size 0 -delete
ln -sfn "$(basename "$good")" "$last"
