#!/usr/bin/env bash
# Open the current pane's whole scrollback in nvim, in a popup.
#
# Bound to prefix+v. Copy mode is fine for a quick look; this is for when you
# want real search, text objects, yanking with your nvim mappings, or :w to keep
# a Claude transcript / build log. The file is a throwaway copy, deleted when
# nvim exits. Wrapped lines are joined (-J) so long lines stay whole.
set -uo pipefail

pane="$1"
client="$2"
dir="$3"

file="$(mktemp "${TMPDIR:-/tmp}/tmux-scrollback.XXXXXX")"
# capture-pane pads the visible screen with empty lines; drop the trailing ones.
tmux capture-pane -p -J -S - -t "$pane" |
	awk 'NF { last = NR } { line[NR] = $0 } END { for (i = 1; i <= last; i++) print line[i] }' >"$file"

# display-popup blocks until the popup closes (nvim quit, or popup killed), so
# cleaning up afterwards covers every way out.
tmux display-popup -c "$client" -E -w 90% -h 90% -d "$dir" -T " scrollback " \
	"nvim -n + '$file'"
rm -f "$file"
