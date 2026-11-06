Set-Alias v nvim

$env:POSH_GIT_ENABLED = $true

# Controlled Folder Access blocks writes under OneDrive\Documentos, so this
# profile and extra modules live outside it ($PROFILE just dot-sources this file).
# Install modules with: Save-PSResource <name> -Path <the dir below>
$env:PSModulePath = "$HOME\.local\share\powershell\Modules;$env:PSModulePath"

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
# Suggestions from history + tab-completion results, shown as a list (F2 toggles inline).
if (-not [Console]::IsOutputRedirected) {
    Import-Module CompletionPredictor -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
}
if ($env:TERM_PROGRAM -eq "vscode")
{ . "$(code --locate-shell-integration-path pwsh)"
}

# Icons/listings via eza (replaces Terminal-Icons, which cost ~850ms per start).
# `ls`/`la` stay on coreutils: the PSConsoleHostReadLine hook below rewrites them.
function ll { eza -l --icons --git --group-directories-first @args }
function lt { eza --tree --level=2 --icons --group-directories-first @args }

# bat/delta page through Git for Windows' less (not on PATH).
$env:BAT_PAGER = '"C:/Program Files/Git/usr/bin/less.exe" -RF'
$env:DELTA_PAGER = $env:BAT_PAGER

# fzf walks the filesystem itself (no FZF_CTRL_T/ALT_C_COMMAND): PSFzf pipes
# those through PowerShell, and the producer keeps scanning after Esc until it
# has walked the whole tree, freezing input. fzf's own walker stops on exit.
$env:FZF_DEFAULT_OPTS = '--walker-skip=.git,node_modules,AppData,OneDrive'
# PSFzf takes ~700ms to import, so the key handlers load it on first use.
function Invoke-LazyPsFzf([string]$Handler) {
    if (-not (Get-Module PSFzf)) { Import-Module PSFzf }
    & $Handler
}
Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription 'fzf files' -ScriptBlock { Invoke-LazyPsFzf Invoke-FzfPsReadlineHandlerProvider }
Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription 'fzf history' -ScriptBlock { Invoke-LazyPsFzf Invoke-FzfPsReadlineHandlerHistory }
Set-PSReadLineKeyHandler -Chord Alt+c -BriefDescription 'fzf cd' -ScriptBlock {
    $dir = fzf --walker=dir,follow,hidden
    if ($dir) { Set-Location $dir }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

Invoke-Expression (&starship init powershell)
# zoxide wraps the prompt, so it must come after starship. `z foo` / `zi` (fzf picker).
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Report cwd to the terminal via OSC 7 so WezTerm tracks each tab's directory.
# starship no longer emits this itself; it calls Invoke-Starship-PreCommand (if
# defined) every prompt, so we hook there instead of overriding `prompt`.
function Invoke-Starship-PreCommand {
    $p = $executionContext.SessionState.Path.CurrentLocation.Path -replace '\\', '/'
    $esc = [char]27
    Write-Host -NoNewline "$esc]7;file://${env:COMPUTERNAME}/$p$esc\"
}


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
#
# Lazy-loaded (~275ms otherwise): these stubs import the real module on first
# `refreshenv` or `choco <Tab>`; the module then registers its own completer.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  function refreshenv {
    Import-Module $ChocolateyProfile -Global
    Update-SessionEnvironment
  }
  Register-ArgumentCompleter -Native -CommandName choco -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    if (Get-Module chocolateyProfile) { return }
    Import-Module $ChocolateyProfile -Global
    (TabExpansion2 $commandAst.ToString() $cursorPosition).CompletionMatches
  }
}

# nvim
$env:XDG_CONFIG_HOME = "$HOME/.config"

# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
# Inlining the template into the profile shaves off ~10ms (25%).
$script:__COREUTILS__ = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        'arch', 'b2sum', 'base32', 'base64', 'basename',
        'basenc', 'cat', 'cksum', 'comm', 'cp',
        'csplit', 'cut', 'date', 'df', 'dirname',
        'du', 'echo', 'env', 'expr', 'factor',
        'false', 'find', 'fmt', 'fold', 'grep',
        'head', 'hostname', 'join', 'la', 'link',
        'ln', 'ls', 'md5sum', 'mkdir', 'mktemp',
        'mv', 'nl', 'nproc', 'numfmt', 'od',
        'pathchk', 'pr', 'printenv', 'printf', 'ptx',
        'pwd', 'readlink', 'realpath', 'rm', 'rmdir',
        'seq', 'sha1sum', 'sha224sum', 'sha256sum', 'sha384sum',
        'sha512sum', 'shuf', 'sleep', 'sort', 'split',
        'stat', 'sum', 'tac', 'tail', 'tee',
        'test', 'touch', 'tr', 'true', 'truncate',
        'tsort', 'unexpand', 'uniq', 'unlink', 'uptime',
        'wc', 'xargs', 'yes'
    ),
    [System.StringComparer]::OrdinalIgnoreCase
)

$script:__COREUTILS_FAST_SKIP__ = [regex]::new(
    '\b(?:' + ($script:__COREUTILS__ -join '|') + ')\b',
    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor `
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

# Casting the scriptblock to Func<Ast,bool> once and reusing it avoids the
# per-FindAll scriptblock-to-delegate wrapping overhead (~1.7x faster).
$script:__COREUTILS_CMD_PREDICATE__ = [System.Func[System.Management.Automation.Language.Ast, bool]] {
    param($n) $n -is [System.Management.Automation.Language.CommandAst]
}

$script:__COREUTILS_ARG_SPECIAL__ = [char[]] @("'", '"', '`', '$')

# Wrap arguments into quotes. By being a function we can properly handle $variables.
# As per MSVCRT, any `\` before `"` must be doubled to escape them.
function global:__coreutils_q {
    param($s)
    '"' + (([string]$s) -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

# PowerShell tokenizes `*"a"*` as [BareWord] instead of the expected [DoubleQuoted, BareWord, DoubleQuoted].
# To work around that we use... regex. Group 1 = 'single', 2 = "double", 3 = `escape, 4 = bare run.
$script:__COREUTILS_ARG_RX__ = [regex]::new(
    "'((?:[^']|'')*)'|""((?:[^""``]|""""|``.)*)""|``(.)|([^'""``]+)",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:__COREUTILS_ARG_EVAL__ = [System.Text.RegularExpressions.MatchEvaluator] {
    param($m)
    if ($m.Groups[1].Success) {
        # Single-quoted: literal. PS '' -> ', then MSVCRT-quote.
        $body = $m.Groups[1].Value.Replace("''", "'")
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[2].Success) {
        # Double-quoted: collapse PS quote-escapes to raw " / ', let ExpandString
        # resolve `n / `t / $var, then MSVCRT-quote.
        $body = $m.Groups[2].Value.
        Replace('`"', '"').
        Replace("``'", "'").
        Replace('""', '"')
        $body = $ExecutionContext.InvokeCommand.ExpandString($body)
        if ($body -match '^(.*?)(\\+)$') {
            return '"' + ($matches[1] -replace '(\\*)"', '$1$1\"') + '"' + $matches[2]
        }
        return '"' + ($body -replace '(\\*)"', '$1$1\"') + '"'
    }
    if ($m.Groups[3].Success) {
        # Backtick-escaped char outside a string: " -> \"; everything else
        # becomes a one-char quoted region so glob metas stay literal.
        $c = $m.Groups[3].Value
        if ($c -eq '"') {
            return '\"'
        }
        return '"' + $c + '"'
    }
    # Bare run: passed through unquoted so coreutils can glob it; expand $vars.
    return $ExecutionContext.InvokeCommand.ExpandString($m.Groups[4].Value)
}

# PSConsoleHostReadLine override that rewrites coreutils command names to their
# .cmd equivalents after PSReadLine returns (history keeps the original).
#
# Why .cmd over .exe: PSNativeCommandArgumentPassing = 'Windows' results in a behavior
# where passing bare quotes to CreateProcess() is impossible. This prevents us from
# passing "*" as "*" to coreutils and instead will be given as a bare *.
# This causes it to treat it as a glob pattern. "*.cmd" files however are automatically
# treated as PSNativeCommandArgumentPassing = 'Legacy', which preserves quotes.
# It is the only possible workaround and the only way coreutils can work at all.
function PSConsoleHostReadLine {
    [System.Diagnostics.DebuggerHidden()]
    param()

    $lastRunStatus = $?
    Microsoft.PowerShell.Core\Set-StrictMode -Off
    $line = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)

    # If the line contains no coreutils name, we don't need to parse the AST at all.
    if (-not $script:__COREUTILS_FAST_SKIP__.IsMatch($line)) {
        return $line
    }

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($line, [ref]$null, [ref]$null)
    $commands = $ast.FindAll($script:__COREUTILS_CMD_PREDICATE__, $true)

    # Process right-to-left so earlier offsets stay valid after each splice.
    # In-place reverse beats Sort-Object for the typical 1-command line.
    if ($commands.Count -gt 1) {
        $commands = [System.Collections.Generic.List[object]]::new($commands)
        $commands.Reverse()
    }

    foreach ($cmd in $commands) {
        $name = $cmd.GetCommandName()
        if (!$name) {
            continue
        }

        $baseName = $name
        if ($name.EndsWith('.exe') -or $name.EndsWith('.cmd')) {
            $baseName = $name.Substring(0, $name.Length - 4)
        }
        if (!$script:__COREUTILS__.Contains($baseName)) {
            continue
        }

        # ls/la get colour + listing flags injected; la also rewrites to ls.
        $cmdElement = $cmd.CommandElements[0]
        $start = $cmdElement.Extent.StartOffset
        $end = $cmdElement.Extent.EndOffset
        $replacement = "& 'C:\Program Files\coreutils\cmd\"

        switch ($baseName) {
            'la' { $replacement += "ls.cmd' --color=auto -AFhl" }
            'ls' { $replacement += "ls.cmd' --color=auto" }
            default { $replacement += "$baseName.cmd'" }
        }

        # Walk command elements, merging adjacent ones whose extents touch
        # (e.g. `'a'*` parses as [SingleQuoted, BareWord] but is one shell word).
        # The inverse case `*'a'*` parses as a single BareWord whose text
        # contains the embedded quotes, which is why AST-only analysis
        # isn't enough and we still need to re-tokenize the source span.
        $argsStart = $end
        $argsEnd = $cmd.Extent.EndOffset
        $rewrittenArgs = ''
        $elements = $cmd.CommandElements
        $count = $elements.Count
        $i = 1
        while ($i -lt $count) {
            $first = $elements[$i]
            $wordStart = $first.Extent.StartOffset
            $wordEnd = $first.Extent.EndOffset
            $merged = $false
            while ($i + 1 -lt $count -and $elements[$i + 1].Extent.StartOffset -eq $wordEnd) {
                $i++
                $wordEnd = $elements[$i].Extent.EndOffset
                $merged = $true
            }
            $source = $line.Substring($wordStart, $wordEnd - $wordStart)
            $rewrittenArgs += $line.Substring($argsStart, $wordStart - $argsStart)
            $argsStart = $wordEnd
            # IndexOfAny beats running the regex per arg.
            if ($source.IndexOfAny($script:__COREUTILS_ARG_SPECIAL__) -lt 0) {
                $rewrittenArgs += $source
                $i++
                continue
            }
            # A single un-merged PS expression that needs $var resolution
            # (bare $var, "...$var...", $x.Member, $($expr), etc.).
            # Defer evaluation to runtime so the value reaches coreutils as a literal arg.
            # This matches POSIX behaviour where variable expansions don't result in globbing.
            if (-not $merged -and
                ($first -is [System.Management.Automation.Language.VariableExpressionAst] -or
                $first -is [System.Management.Automation.Language.ExpandableStringExpressionAst] -or
                $first -is [System.Management.Automation.Language.MemberExpressionAst])) {
                $rewrittenArgs += '(__coreutils_q ' + $source + ')'
                $i++
                continue
            }
            # Slow path: re-tokenise and re-emit as MSVCRT-style quoting,
            # then wrap in PS single quotes so PS hands the body verbatim.
            $windowsQuoted = $script:__COREUTILS_ARG_RX__.Replace($source, $script:__COREUTILS_ARG_EVAL__)
            $rewrittenArgs += "'" + $windowsQuoted.Replace("'", "''") + "'"
            $i++
        }
        $rewrittenArgs += $line.Substring($argsStart, $argsEnd - $argsStart)

        $line = $line.Substring(0, $start) + $replacement + $rewrittenArgs + $line.Substring($argsEnd)
    }

    return $line
}
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# DO NOT MODIFY -- coreutils -- 60b36fc6-2d59-49df-be51-28dd2f4c3c9a

# Windows Terminal palette: regenerate the Windows-side entries (psmux "# wt:"
# markers, chezmoi configs) when a source changed. The check is a few file
# timestamps; the regeneration runs in a background thread.
if ($env:WT_SESSION) {
    $__wtPalette = Join-Path $HOME '.config\wt-palette\wt-palette.ps1'
    if (Test-Path -LiteralPath $__wtPalette) {
        $null = Start-ThreadJob -ScriptBlock { & $using:__wtPalette -Windows -IfChanged *> $null }
    }
    Remove-Variable __wtPalette
}
