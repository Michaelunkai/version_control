<#
.SYNOPSIS
    bergrs
#>
param([Parameter(Mandatory=$true)][string]$Path)
    $tempDir = Join-Path $env:TEMP "bergrs_$(Get-Random)"
    git clone --filter=blob:none --sparse https://codeberg.org/mishaelovsky5/study.git $tempDir
    Push-Location $tempDir
    git sparse-checkout set $Path
    $commits = git log --oneline --all -- $Path | Select-Object -First 20
    if (-not $commits) { Write-Host "No commits found for $Path" -ForegroundColor Red; Pop-Location; Remove-Item -Recurse -Force $tempDir; return }
    Write-Host "`nSelect a commit:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $commits.Count; $i++) { Write-Host "[$i] $($commits[$i])" }
    $selection = Read-Host "`nEnter number"
    $commitHash = ($commits[$selection] -split ' ')[0]
    git checkout $commitHash -- $Path
    Pop-Location
    $targetDir = Split-Path -Leaf $Path
    if (Test-Path $targetDir) { Remove-Item -Recurse -Force $targetDir }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    $items = Get-ChildItem -Path (Join-Path $tempDir $Path) -Force
    foreach ($item in $items) { Move-Item -Path $item.FullName -Destination $targetDir -Force }
    Remove-Item -Recurse -Force $tempDir
    Write-Host "Done: $targetDir (from $commitHash)" -ForegroundColor Green
