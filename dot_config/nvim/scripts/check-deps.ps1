# Check external dependencies for this Neovim config (Windows / PowerShell).
# Usage: pwsh ./scripts/check-deps.ps1   (or .\scripts\check-deps.ps1)
# Exit code: number of missing REQUIRED deps (0 = all good).

$script:MissingRequired    = 0
$script:MissingRecommended = 0
$script:MissingOptional    = 0

$useColor = $Host.UI.SupportsVirtualTerminal -or $env:WT_SESSION -or $env:TERM_PROGRAM
function Write-Status {
    param([string]$Color, [string]$Label, [string]$Name, [string]$Tail = '')
    if ($useColor) {
        $codes = @{ green=32; red=31; yellow=33; gray=90; bold=1 }
        $c = $codes[$Color]
        Write-Host ("  `e[${c}m{0}`e[0m {1,-22} {2}" -f $Label, $Name, $Tail)
    } else {
        Write-Host ("  {0,-7} {1,-22} {2}" -f $Label, $Name, $Tail)
    }
}

function Test-Tool { param([string]$Name) [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Check-Dep {
    param(
        [ValidateSet('required','recommended','optional')] [string]$Tier,
        [string]$Name, [string]$Hint, [string]$Note = ''
    )
    if (Test-Tool $Name) {
        Write-Status 'green' 'OK' $Name
        return
    }
    switch ($Tier) {
        'required' {
            Write-Status 'red' 'MISSING' $Name "-> $Hint"
            $script:MissingRequired++
        }
        'recommended' {
            Write-Status 'yellow' 'MISSING' $Name "-> $Hint"
            $script:MissingRecommended++
        }
        'optional' {
            $tail = if ($Note) { "-> $Hint  ($Note)" } else { "-> $Hint" }
            Write-Status 'gray' 'MISSING' $Name $tail
            $script:MissingOptional++
        }
    }
}

function Check-CCompiler {
    foreach ($c in 'cc','gcc','clang','cl') {
        if (Test-Tool $c) {
            Write-Status 'green' 'OK' 'C compiler' "($c)"
            return
        }
    }
    Write-Status 'red' 'MISSING' 'C compiler' '-> winget install LLVM.LLVM  /  Visual Studio Build Tools'
    $script:MissingRequired++
}

Write-Host 'Neovim config - external dependency check'
Write-Host ''

Write-Host 'Required'
Check-Dep required git    'winget install Git.Git'
Check-Dep required rg     'winget install BurntSushi.ripgrep.MSVC                  (telescope find/grep)'
Check-Dep required make   'winget install GnuWin32.Make / scoop install make       (plugin build steps)'
Check-CCompiler
Check-Dep required node   'winget install OpenJS.NodeJS / use volta or fnm         (Mason JS tooling)'
# tmux: WSL-only on Windows; flag as missing with hint, but still required for claudecode + tmux nav
Check-Dep required tmux   'WSL only - run Neovim from WSL                          (claudecode + tmux nav)'

Write-Host ''
Write-Host 'Recommended'
# fd: scoop ships as `fd`; cargo also installs `fd`. No fdfind on Windows.
Check-Dep recommended fd      'winget install sharkdp.fd / scoop install fd        (telescope auto-detects)'
Check-Dep recommended fzf     'winget install junegunn.fzf                         (future picker swap)'
Check-Dep recommended lazygit 'winget install JesseDuffield.lazygit'

Write-Host ''
Write-Host 'Optional (config has fallbacks)'
Check-Dep optional tsgo             'pnpm add -g @typescript/native-preview' 'falls back to ts_ls'
Check-Dep optional tmux-sessionizer 'custom user script'                     '<C-f> keybind'

Write-Host ''
Write-Host 'Mason auto-installs (no manual action needed)'
Write-Host '  LSPs:  astro, bashls, cssls, gh_actions_ls, jsonls, lua_ls, pylsp,'
Write-Host '         pyright, rust_analyzer, tailwindcss, ts_ls, yamlls'
Write-Host '  Tools: prettier, prettierd, stylua, isort, black, pylint, eslint_d'
Write-Host '  Run :Mason inside Neovim to inspect installation status.'

Write-Host ''
Write-Host 'Summary'
Write-Host ("  required missing:    {0}" -f $script:MissingRequired)
Write-Host ("  recommended missing: {0}" -f $script:MissingRecommended)
Write-Host ("  optional missing:    {0}" -f $script:MissingOptional)

exit $script:MissingRequired
