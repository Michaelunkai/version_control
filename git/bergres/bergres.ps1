<#
.SYNOPSIS
    bergres
#>
param([Parameter(Mandatory=$true)][string]$Path)
    $targetDir = Split-Path -Leaf $Path
    if (Test-Path $targetDir) { Remove-Item -Recurse -Force $targetDir }
    git clone --filter=blob:none --sparse https://codeberg.org/mishaelovsky5/study.git $targetDir
    Push-Location $targetDir
    git sparse-checkout set $Path
    $items = Get-ChildItem -Path $Path -Force
    foreach ($item in $items) { Move-Item -Path $item.FullName -Destination . -Force }
    Remove-Item -Recurse -Force $Path.Split('/')[0]
    Remove-Item -Recurse -Force .git
    Pop-Location
    Write-Host "Done: $targetDir" -ForegroundColor Green
