Set-Alias v nvim

$env:POSH_GIT_ENABLED = $true
Import-Module -Name Terminal-Icons
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
if ($env:TERM_PROGRAM -eq "vscode")
{ . "$(code --locate-shell-integration-path pwsh)" 
}

Invoke-Expression (&starship init powershell)


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# nvim
$env:XDG_CONFIG_HOME = "$HOME/.config"
