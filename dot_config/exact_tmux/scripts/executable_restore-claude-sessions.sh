#!/usr/bin/env bash
# Resume Claude Code sessions after a tmux-resurrect restore.
#
# Run as tmux-resurrect's @resurrect-hook-post-restore-all. Reads the resurrect
# save file, finds every pane whose foreground command was `claude` (the
# reliable pane_current_command field, NOT the flaky full-command capture),
# and sends `claude --resume <uuid>` to that exact pane.
#
# The conversation comes from <save file>.claude, written at save time by
# save-claude-sessions.sh with each pane's exact session id. Panes missing from
# it (older saves, or a pane the sidebar hadn't seen yet) fall back to the
# newest session for the pane's cwd that no other pane has claimed.
#
# Reads only Claude's own on-disk session store; writes nothing to settings.
set -uo pipefail

# Locate the resurrect save dir (XDG layout first, then legacy ~/.tmux).
SAVE=""
for d in "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect" "$HOME/.tmux/resurrect"; do
	if [ -f "$d/last" ]; then SAVE="$d/last"; break; fi
done
[ -n "$SAVE" ] || exit 0

projects="$HOME/.claude/projects"

# Exact ids recorded at save time, keyed session:window.pane. Claim them all
# up front so the cwd fallback never hands one of them to another pane.
declare -A known claimed
side="$(readlink -f "$SAVE").claude"
if [ -f "$side" ]; then
	while IFS=$'\t' read -r s w p id; do
		known["$s:$w.$p"]="$id"
		claimed["$id"]=1
	done <"$side"
fi

# Save format is tab-separated. Columns:
#   1 type  2 session  3 window  4 win_active  5 win_flags  6 pane_index
#   7 title  8 :cwd  9 pane_active  10 pane_current_command  11 :full_command
while IFS=$'\t' read -r type session window _wa _wf pane _title cwd _pa cmd _full; do
	[ "$type" = "pane" ] || continue
	[ "$cmd" = "claude" ] || continue

	cwd="${cwd#:}"                            # strip leading ':'
	slug="${cwd//\//-}"; slug="${slug//./-}"  # '/' and '.' -> '-'
	dir="$projects/$slug"
	[ -d "$dir" ] || continue
	target="${session}:${window}.${pane}"

	# `claude --resume` looks the id up under the cwd's project dir, so an
	# exact id only counts if its transcript lives there.
	uuid="${known[$target]:-}"
	if [ -z "$uuid" ] || [ ! -f "$dir/$uuid.jsonl" ]; then
		uuid=""
		while IFS= read -r f; do
			id="$(basename "$f" .jsonl)"
			[ -n "${claimed[$id]:-}" ] && continue
			uuid="$id"
			claimed["$id"]=1
			break
		done < <(command ls -t "$dir"/*.jsonl 2>/dev/null)
	fi
	[ -n "$uuid" ] || continue

	# Don't clobber a pane that already has claude running.
	cur="$(tmux display -p -t "$target" '#{pane_current_command}' 2>/dev/null)" || continue
	[ "$cur" = "claude" ] && continue

	tmux send-keys -t "$target" "claude --resume $uuid" Enter
done <"$SAVE"
