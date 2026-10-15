#!/usr/bin/env bash
# Jump to the next Claude pane that needs you, across all sessions.
#
# Bound to prefix+u. Priority: waiting (permission prompt / question), then
# error, then finished-but-unseen (@pane_attention). Within that order, a
# repeat press moves to the entry after the current pane, so presses cycle
# through every candidate instead of bouncing between the first two.
#
# Reads tmux-agent-sidebar's documented pane options (@pane_status,
# @pane_attention); no state of its own.
set -uo pipefail

client="$1"
current="$2"

target="$(tmux list-panes -a -F '#{pane_id}	#{@pane_status}	#{@pane_attention}' |
	awk -F '\t' -v cur="$current" '
		$2 == "waiting"                            { w[nw++] = $1 }
		$2 == "error"                              { e[ne++] = $1 }
		$2 != "waiting" && $2 != "error" && $3 == "1" { d[nd++] = $1 }
		END {
			n = 0
			for (i = 0; i < nw; i++) list[n++] = w[i]
			for (i = 0; i < ne; i++) list[n++] = e[i]
			for (i = 0; i < nd; i++) list[n++] = d[i]
			if (n == 0) exit
			pos = -1
			for (i = 0; i < n; i++) if (list[i] == cur) pos = i
			if (pos < 0) print list[0]
			else if (n > 1) print list[(pos + 1) % n]
		}')"

if [ -z "$target" ]; then
	tmux display-message -c "$client" "No Claude needs you right now"
	exit 0
fi

tmux switch-client -c "$client" -t "$target"
tmux select-window -t "$target"
tmux select-pane -t "$target"
