<#
.SYNOPSIS
  Generates Windows Terminal command-palette entries from your configs.

.DESCRIPTION
  Writes JSON fragment files that Windows Terminal loads at startup:
    %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\WorkflowPalette\*.json
  Nothing is written to settings.json, so the generated entries stay
  machine-local and never end up in the dotfiles repo.

  Sources (each one becomes its own fragment file):
    core.json        Regenerate entry and a few Windows Terminal actions
    psmux.json       "# wt:" marker comments in ~/.psmux.conf
    config-win.json  files managed by chezmoi on Windows
    tmux.json        "# wt:" marker comments in WSL ~/.config/tmux/tmux.conf
    config-wsl.json  files managed by chezmoi in WSL, plus WSL tool launchers

  Marker syntax, anywhere in tmux.conf or .psmux.conf:
    # wt: prefix f | Jump to project (sessionizer)
    # wt: root M-` | Scratch popup
  "prefix" entries type the prefix key and then the key; "root" entries type
  the key alone. The entry types into whichever pane is focused.

.PARAMETER Windows
  Regenerate the Windows-side fragments (core, psmux, config-win).
.PARAMETER Wsl
  Regenerate the WSL-side fragments (tmux, config-wsl). Starts WSL if needed.
.PARAMETER All
  Both of the above.
.PARAMETER IfChanged
  With -Windows: skip the work when no Windows-side source changed since the
  last run. Meant for the PowerShell profile, so startup stays fast.
.PARAMETER Distro
  WSL distro to read from. Defaults to the default distro.
#>
[CmdletBinding()]
param(
    [switch]$Windows,
    [switch]$Wsl,
    [switch]$All,
    [switch]$IfChanged,
    [string]$Distro
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
if ($All) { $Windows = $true; $Wsl = $true }
if (-not ($Windows -or $Wsl)) { $Windows = $true; $Wsl = $true }

$FragmentDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\WorkflowPalette'
$StateFile = Join-Path $FragmentDir '.windows-signature'
$ScriptPath = $PSCommandPath
New-Item -ItemType Directory -Force -Path $FragmentDir | Out-Null

# ---------------------------------------------------------------- helpers

function Write-Fragment([string]$Name, [object[]]$Actions) {
    $path = Join-Path $FragmentDir "$Name.json"
    $Actions = @($Actions | Where-Object { $null -ne $_ })
    $json = [ordered]@{ actions = $Actions } | ConvertTo-Json -Depth 8
    $tmp = "$path.tmp"
    Set-Content -LiteralPath $tmp -Value $json -Encoding utf8NoBOM
    Move-Item -LiteralPath $tmp -Destination $path -Force
    Write-Host ("{0,-16} {1,3} entries" -f "$Name.json", @($Actions).Count)
}

function New-Action([string]$Id, [string]$Name, [hashtable]$Command) {
    [ordered]@{ name = $Name; id = "WorkflowPalette.$Id"; command = $Command }
}

function Get-IdSlug([string]$Text) {
    ($Text -replace '[^A-Za-z0-9]+', '-').Trim('-').ToLowerInvariant()
}

# Bytes a terminal sends for a tmux-style key name; $null when unsupported.
function ConvertTo-KeyBytes([string]$Key) {
    $esc = [char]27
    $named = @{
        'Tab' = "`t"; 'Space' = ' '; 'Enter' = "`r"; 'Escape' = "$esc"; 'BSpace' = [string][char]127
        'Up' = "$esc[A"; 'Down' = "$esc[B"; 'Right' = "$esc[C"; 'Left' = "$esc[D"
        'Home' = "$esc[H"; 'End' = "$esc[F"; 'PPage' = "$esc[5~"; 'NPage' = "$esc[6~"
        'F1' = "${esc}OP"; 'F2' = "${esc}OQ"; 'F3' = "${esc}OR"; 'F4' = "${esc}OS"
        'F5' = "$esc[15~"; 'F6' = "$esc[17~"; 'F7' = "$esc[18~"; 'F8' = "$esc[19~"
        'F9' = "$esc[20~"; 'F10' = "$esc[21~"; 'F11' = "$esc[23~"; 'F12' = "$esc[24~"
    }
    if ($Key -match '^M-(.+)$') {
        $rest = ConvertTo-KeyBytes $Matches[1]
        if ($null -eq $rest) { return $null }
        return "$esc$rest"
    }
    if ($Key -cmatch '^C-(.)$') {
        $c = [char]::ToUpperInvariant([char]$Matches[1])
        if ($c -eq ' ') { return [string][char]0 }
        $code = [int]$c
        if ($code -ge 64 -and $code -le 95) { return [string][char]($code - 64) }
        return $null
    }
    if ($Key -eq 'C-Space') { return [string][char]0 }
    if ($named.ContainsKey($Key)) { return $named[$Key] }
    if ($Key.Length -eq 1) { return $Key }
    return $null
}

# Palette entries from "# wt: <table> <key> | <description>" markers.
function Get-MarkerActions([string]$ConfigText, [string]$Group, [string]$IdPrefix) {
    $prefixKey = 'C-b'
    $m = [regex]::Match($ConfigText, '(?m)^\s*set(?:-option)?\s+(?:-\w+\s+)*prefix\s+(\S+)')
    if ($m.Success -and $m.Groups[1].Value -ne 'None') { $prefixKey = $m.Groups[1].Value }
    $prefixBytes = ConvertTo-KeyBytes $prefixKey

    $actions = @()
    $seen = @{}
    foreach ($line in $ConfigText -split "`r?`n") {
        $mm = [regex]::Match($line, '^\s*#\s*wt:\s*(prefix|root)\s+(\S+)\s*\|\s*(.+?)\s*$')
        if (-not $mm.Success) { continue }
        $table, $key, $desc = $mm.Groups[1].Value, $mm.Groups[2].Value, $mm.Groups[3].Value
        $bytes = ConvertTo-KeyBytes $key
        if ($null -eq $bytes) { Write-Warning "${Group}: can't type key '$key' ($desc), skipped"; continue }
        if ($table -eq 'prefix') { $bytes = $prefixBytes + $bytes }
        $id = "$IdPrefix." + (Get-IdSlug $desc)
        if ($seen.ContainsKey($id)) { continue }
        $seen[$id] = $true
        $actions += New-Action $id "${Group}: $desc" @{ action = 'sendInput'; input = $bytes }
    }
    return $actions
}

# Config files worth listing from `chezmoi managed` (relative to home).
# $Side drops files that belong to the other OS: both chezmoi repos mirror
# much of the same tree, so each side also manages the other side's files.
function Select-ConfigFiles([string[]]$Paths, [string]$Side) {
    $skip = @(
        '^\.config/nvim/(?!init\.lua$)'   # every plugin file would drown the list
        '/(agents|commands)/'             # prompt libraries, not configuration
        '\.bak', '\.keep$', '(^|/)(README|LICENSE|AGENTS)(\.md)?$'
        '\.(jpg|jpeg|png|gif|ico)$', '(^|/)\.gitignore$'
    )
    $skip += switch ($Side) {
        'Win' { '^\.(zshrc|bashrc|spaceshiprc\.zsh)$', '^\.config/tmux/', '^\.local/scripts/', '^\.claude/' }
        'WSL' { '^AppData/', '^\.wslconfig$', '^\.config/yasb/' }
    }
    $Paths | Where-Object { $p = $_; $p -and -not ($skip | Where-Object { $p -match $_ }) }
}

# Windows configs that may not be in chezmoi; listed only where they exist.
$ExtraWindowsConfigs = @(
    '.psmux.conf'
    '.glzr/glazewm/config.yaml'
    '.config/powershell/profile.ps1'
    '.wezterm.lua'
    '.config/wt-palette/wt-palette.ps1'
)

function Format-ConfigName([string]$RelPath, [string]$Side) {
    $leaf = Split-Path $RelPath -Leaf
    $dir = Split-Path $RelPath -Parent
    if ($dir) { "Config ($Side): $leaf  -  ~/$($dir -replace '\\','/')" } else { "Config ($Side): $leaf" }
}

# ---------------------------------------------------------------- Windows side

function Get-WindowsSignature {
    $items = @(
        $ScriptPath
        (Join-Path $HOME '.psmux.conf')
        (Join-Path $HOME '.local\share\chezmoi\.git\index')
        (Join-Path $HOME '.local\share\chezmoi\.git\HEAD')
    )
    ($items | ForEach-Object {
            if (Test-Path -LiteralPath $_) { "$_=$((Get-Item -LiteralPath $_).LastWriteTimeUtc.Ticks)" } else { "$_=missing" }
        }) -join ';'
}

function Update-WindowsFragments {
    # core: regenerate + Windows Terminal actions
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if (-not $pwsh) { $pwsh = 'pwsh.exe' }
    Write-Fragment 'core' @(
        New-Action 'regenerate' 'Palette: Regenerate entries' @{
            action = 'newTab'; tabTitle = 'wt-palette'
            commandline = "`"$pwsh`" -NoProfile -File `"$ScriptPath`" -All"
        }
        New-Action 'export' 'Terminal: Save scrollback to file' @{ action = 'exportBuffer' }
    )

    # psmux markers
    $psmuxConf = Join-Path $HOME '.psmux.conf'
    $psmux = @()
    if (Test-Path -LiteralPath $psmuxConf) {
        $psmux = Get-MarkerActions (Get-Content -LiteralPath $psmuxConf -Raw -Encoding utf8) 'psmux' 'psmux'
    }
    Write-Fragment 'psmux' $psmux

    # chezmoi-managed Windows configs, opened in nvim
    $configs = @()
    if (Get-Command chezmoi -ErrorAction SilentlyContinue) {
        $editor = if (Get-Command nvim -ErrorAction SilentlyContinue) { 'nvim' } else { 'notepad' }
        $managed = @(chezmoi managed --include files --path-style relative 2>$null)
        $paths = @(Select-ConfigFiles ($managed + $ExtraWindowsConfigs) 'Win') | Sort-Object -Unique
        foreach ($rel in $paths) {
            $full = Join-Path $HOME ($rel -replace '/', '\')
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
            $configs += New-Action ("cfg.win." + (Get-IdSlug $rel)) (Format-ConfigName $rel 'Win') @{
                action = 'newTab'; tabTitle = (Split-Path $rel -Leaf)
                commandline = "$editor `"$full`""
            }
        }
    }
    Write-Fragment 'config-win' $configs
}

# ---------------------------------------------------------------- WSL side

function Invoke-Wsl([string]$Script) {
    # The script goes through a temp file so no quoting survives two shells.
    # It runs in the user's interactive login shell, so PATH matches a normal
    # terminal (linuxbrew, zinit tools, chezmoi, ...).
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "wt-palette-$PID.sh"
    Set-Content -LiteralPath $tmp -Value ($Script -replace "`r`n", "`n") -Encoding utf8NoBOM -NoNewline
    try {
        $wslArgs = @()
        if ($Distro) { $wslArgs += @('-d', $Distro) }
        $runner = 'f=$(wslpath -u "$1"); sh_=$(getent passwd "$(id -un)" | cut -d: -f7); exec "${sh_:-/bin/sh}" -lic ". \"$f\"" </dev/null'
        & wsl.exe @wslArgs -e sh -c $runner _ $tmp 2>$null
    }
    finally { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
}

function Update-WslFragments {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return }
    $distroArgs = if ($Distro) { "-d $Distro " } else { '' }

    # One round trip: tmux.conf, managed files, user shell, available tools.
    $out = Invoke-Wsl @'
printf '@@SHELL\n%s\n' "$(getent passwd "$(id -un)" | cut -d: -f7)"
printf '@@TOOLS\n'; for t in lazygit btop yazi htop k9s; do command -v "$t" >/dev/null 2>&1 && echo "$t"; done
printf '@@MANAGED\n'; command -v chezmoi >/dev/null 2>&1 && chezmoi managed --include files --path-style relative 2>/dev/null | while IFS= read -r p; do [ -f "$HOME/$p" ] && printf '%s\n' "$p"; done
printf '@@TMUXCONF\n'; cat "$HOME/.config/tmux/tmux.conf" 2>/dev/null || cat "$HOME/.tmux.conf" 2>/dev/null
'@
    $sections = @{}
    $current = $null
    foreach ($line in ($out -split "`r?`n")) {
        if ($line -match '^@@(\w+)$') { $current = $Matches[1]; $sections[$current] = [Collections.Generic.List[string]]::new(); continue }
        if ($current) { $sections[$current].Add($line) }
    }
    $shell = ($sections['SHELL'] | Where-Object { $_ } | Select-Object -First 1)
    if (-not $shell) { $shell = '/bin/sh' }
    $launch = { param($cmd) "wsl.exe ${distroArgs}--cd ~ -- $shell -lic `"$cmd`"" }

    # tmux markers
    $tmuxText = ($sections['TMUXCONF'] -join "`n")
    Write-Fragment 'tmux' (Get-MarkerActions $tmuxText 'tmux' 'tmux')

    # chezmoi-managed WSL configs + tool launchers
    $entries = @()
    foreach ($rel in (Select-ConfigFiles @($sections['MANAGED']) 'WSL')) {
        $entries += New-Action ("cfg.wsl." + (Get-IdSlug $rel)) (Format-ConfigName $rel 'WSL') @{
            action = 'newTab'; tabTitle = (Split-Path $rel -Leaf)
            commandline = (& $launch "nvim ~/$rel")
        }
    }
    foreach ($tool in @($sections['TOOLS'] | Where-Object { $_ })) {
        $entries += New-Action "launch.$tool" "Launch (WSL): $tool" @{
            action = 'newTab'; tabTitle = $tool; commandline = (& $launch $tool)
        }
    }
    Write-Fragment 'config-wsl' $entries
}

# ---------------------------------------------------------------- main

if ($Windows) {
    $sig = Get-WindowsSignature
    $old = if (Test-Path -LiteralPath $StateFile) { Get-Content -LiteralPath $StateFile -Raw } else { '' }
    if (-not $IfChanged -or $sig -ne $old.Trim()) {
        Update-WindowsFragments
        Set-Content -LiteralPath $StateFile -Value $sig -Encoding utf8NoBOM
    }
}
if ($Wsl) { Update-WslFragments }
