#!/usr/bin/env bash
# Resume Claude Code sessions after a tmux-resurrect restore.
#
# Run as tmux-resurrect's @resurrect-hook-post-restore-all. Reads the resurrect
# save file, finds every pane whose foreground command was `claude` (the
# reliable pane_current_command field, NOT the flaky full-command capture),
# maps each pane's cwd to its newest Claude session under ~/.claude/projects,
# and sends `claude --resume <uuid>` to that exact pane.
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

# Multiple claude panes can share a cwd; hand each the next-newest distinct
# session (newest-first) instead of resuming the same one everywhere.
declare -A used

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

	# Pick the (used[cwd]+1)-th newest session for this cwd.
	n="${used[$cwd]:-0}"
	uuid="$(command ls -t "$dir"/*.jsonl 2>/dev/null | sed -n "$((n + 1))p")"
	used[$cwd]=$((n + 1))
	[ -n "$uuid" ] || continue
	uuid="$(basename "$uuid" .jsonl)"

	target="${session}:${window}.${pane}"
	# Don't clobber a pane that already has claude running.
	cur="$(tmux display -p -t "$target" '#{pane_current_command}' 2>/dev/null)" || continue
	[ "$cur" = "claude" ] && continue

	tmux send-keys -t "$target" "claude --resume $uuid" Enter
done < "$SAVE"
