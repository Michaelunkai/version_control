<#
.SYNOPSIS
    gitco
#>
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Repository
    )

    git clone $Repository
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git clone failed"
        return
    }

    $cleanRepo = $Repository.TrimEnd('/', '\')
    $segments = @($cleanRepo -split '[\\/]' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if (-not $segments) {
        Write-Warning "Unable to determine directory name from value '$Repository'"
        return
    }

    $targetDir = $segments[-1]
    if ($targetDir.EndsWith('.git')) {
        $targetDir = $targetDir.Substring(0, $targetDir.Length - 4)
    }

    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        Write-Warning "Cloned directory '$targetDir' was not found"
        return
    }

    Set-Location -Path $targetDir
