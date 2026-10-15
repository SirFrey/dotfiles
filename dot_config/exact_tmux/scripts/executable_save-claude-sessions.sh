#!/usr/bin/env bash
# Record which Claude conversation each pane is running, next to every
# tmux-resurrect save.
#
# Run as @resurrect-hook-post-save-all. The save file only knows a pane ran
# `claude`, so restore-claude-sessions.sh would have to guess the conversation
# from the pane's cwd, and panes sharing a cwd get each other's conversations.
# tmux-agent-sidebar keeps the exact id in @pane_session_id (fed by Claude's
# hooks); this writes it to <save file>.claude as
#   session <TAB> window <TAB> pane <TAB> session-id
# keyed exactly like the save file. Side files whose save is gone are pruned.
set -uo pipefail
shopt -s nullglob

dir=""
for d in "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect" "$HOME/.tmux/resurrect"; do
	if [ -f "$d/last" ]; then dir="$d"; break; fi
done
[ -n "$dir" ] || exit 0
save="$(readlink -f "$dir/last")"
[ -f "$save" ] || exit 0

# resurrect keeps the previous save when nothing changed, so this can rewrite
# the side file of an older save; that's intended, ids change without layout
# changes (e.g. /clear starts a new conversation in the same pane).
tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{@pane_agent}	#{@pane_session_id}' |
	awk -F '\t' '$4 == "claude" && $5 != "" { print $1 "\t" $2 "\t" $3 "\t" $5 }' >"$save.claude"

for f in "$dir"/*.claude; do
	[ -e "${f%.claude}" ] || rm -f "$f"
done
