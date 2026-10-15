#!/usr/bin/env bash
# Keep tmux-agent-sidebar out of tmux-resurrect's way.
#
# pre  (@resurrect-hook-pre-restore-all): drop the sidebar plugin's
#      after-new-window hook for the duration of the restore. Resurrect
#      rebuilds windows with `new-window`; the hook would inject a sidebar
#      pane into each one before the saved panes exist, so the saved layout
#      no longer matches the pane count, tmux rejects it, and panes land
#      wherever the raw splits put them.
# post (@resurrect-hook-post-restore-all): panes that were sidebars at save
#      time come back as plain shells (their command is not in
#      @resurrect-processes). Respawn each one in place as a sidebar so the
#      restored layout and pane indices stay exact, then re-source the plugin
#      conf to reinstall the hook.
set -uo pipefail

plugin_dir="$HOME/.config/tmux/plugins/tmux-agent-sidebar"
bin="$(tmux show -gqv @agent_sidebar_bin)"
[ -n "$bin" ] && [ -x "$bin" ] || exit 0

case "${1:-}" in
pre)
	tmux show-hooks -g after-new-window |
		awk '/@agent_sidebar_bin/ && /toggle --create-only/ { print $1 }' |
		xargs -rn1 tmux set-hook -gu
	;;
post)
	save=""
	for d in "$(tmux show -gqv @resurrect-dir)" "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect" "$HOME/.tmux/resurrect"; do
		d="${d/#\~/$HOME}"
		[ -n "$d" ] && [ -f "$d/last" ] && { save="$d/last"; break; }
	done
	if [ -n "$save" ]; then
		# Save format is tab-separated; see restore-claude-sessions.sh for columns.
		while IFS=$'\t' read -r type session window _wa _wf pane _title cwd _pa cmd _full; do
			[ "$type" = "pane" ] && [ "$cmd" = "tmux-agent-sidebar" ] || continue
			target="${session}:${window}.${pane}"
			cur="$(tmux display -p -t "$target" '#{pane_current_command}' 2>/dev/null)" || continue
			[ "$cur" = "tmux-agent-sidebar" ] && continue
			tmux respawn-pane -k -t "$target" -c "${cwd#:}" "$bin"
			tmux set -p -t "$target" @pane_role sidebar
		done <"$save"
	fi
	tmux source-file "$plugin_dir/agent-sidebar.conf"
	;;
esac
