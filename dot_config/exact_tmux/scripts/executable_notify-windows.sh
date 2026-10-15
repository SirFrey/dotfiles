#!/usr/bin/env bash
# Windows toast when a Claude pane finishes or needs input.
#
# Run by tmux-agent-indicator as @agent-indicator-notification-command, which
# sets AGENT_STATE (needs-input|done), AGENT_SESSION and AGENT_WINDOW; TMUX_PANE
# is inherited from the Claude process whose hook fired. Skipped when that pane
# is already in front of you (active pane, active window, session shown on a
# focused client). tmux only knows "focused" because focus-events is on.
set -uo pipefail

pane="${TMUX_PANE:-}"

looking_at_it() {
	[ -n "$pane" ] || return 1
	local sess active
	IFS=$'\t' read -r sess active < <(tmux display -p -t "$pane" '#{session_name}	#{&&:#{window_active},#{pane_active}}') || return 1
	[ "$active" = 1 ] || return 1
	tmux list-clients -F '#{client_session}	#{client_flags}' |
		awk -F '\t' -v s="$sess" '$1 == s && $2 ~ /focused/ { f = 1 } END { exit !f }'
}
looking_at_it && exit 0

case "${AGENT_STATE:-}" in
needs-input) title="Claude needs you" ;;
done) title="Claude finished" ;;
*) exit 0 ;;
esac
body="${AGENT_WINDOW:-?} · ${AGENT_SESSION:-?}"

# Text travels as env vars (WSLENV forwards them to Windows) and is XML-escaped
# in PowerShell, so quotes or <> in a task title can't break the toast markup.
# The AUMID is Windows PowerShell's own, which is registered on every install.
ps_script=$(cat <<'PSEOF'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$t = [Security.SecurityElement]::Escape($env:TOAST_TITLE)
$b = [Security.SecurityElement]::Escape($env:TOAST_BODY)
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template=""ToastGeneric""><text>$t</text><text>$b</text></binding></visual></toast>")
$app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
PSEOF
)
enc=$(printf '%s' "$ps_script" | iconv -f utf-8 -t utf-16le | base64 -w0)

TOAST_TITLE="$title" TOAST_BODY="$body" WSLENV="${WSLENV:+$WSLENV:}TOAST_TITLE:TOAST_BODY" \
	powershell.exe -NoProfile -NonInteractive -EncodedCommand "$enc" >/dev/null 2>&1
