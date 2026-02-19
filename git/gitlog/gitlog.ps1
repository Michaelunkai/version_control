<#
.SYNOPSIS
    gitlog
#>
[System.IO.File]::WriteAllText("$env:USERPROFILE\.git-credentials", "https://Michaelunkai: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@github.com`n"); git config --global credential.helper store; git config --global user.name "Michaelunkai"; git config --global user.email "mishaelunkai@users.noreply.github.com"; gh auth logout --hostname github.com 2>$null; git config --global --unset-all credential.https://github.com.helper 2>$null
