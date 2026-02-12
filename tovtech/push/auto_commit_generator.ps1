# auto_commit_generator.ps1
# Automatic commit script generator with intelligent change detection and documentation
# Created by: Michael Fedorovsky
# Date: 2025-12-17
#
# Usage:
#   .\auto_commit_generator.ps1                    - Generate commit script for today
#   .\auto_commit_generator.ps1 -Date "2025-12-20" - Generate for specific date
#   .\auto_commit_generator.ps1 -Description "Feature XYZ" - Add custom description

param(
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [string]$Description = ""
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$scriptDir = "F:\study\Version_Control\tovtech\push"
$backendPath = "F:\tovplay\tovplay-backend"
$frontendPath = "F:\tovplay\tovplay-frontend"

$dateFormatted = Get-Date -Format "MMM dd, yyyy"
$dateFilename = Get-Date -Format "MMdd_yyyy"
$outputScript = "$scriptDir\commit_${dateFilename}.ps1"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Auto Commit Script Generator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Analyzing repositories..." -ForegroundColor Yellow
Write-Host "  Backend:  $backendPath" -ForegroundColor Gray
Write-Host "  Frontend: $frontendPath" -ForegroundColor Gray
Write-Host "  Output:   $outputScript`n" -ForegroundColor Gray

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-GitStatus {
    param([string]$RepoPath)

    $currentDir = Get-Location
    Set-Location $RepoPath

    $status = @{
        Modified = @()
        Added = @()
        Deleted = @()
        Renamed = @()
        TotalFiles = 0
        LinesAdded = 0
        LinesDeleted = 0
    }

    # Get status output (suppress warnings)
    $ErrorActionPreference = 'SilentlyContinue'
    $statusOutput = git status --short 2>$null
    $ErrorActionPreference = 'Stop'

    if ($statusOutput) {
        foreach ($line in $statusOutput) {
            if ($line -match '^\s*([MAD\?R]+)\s+(.+)$') {
                $statusCode = $Matches[1].Trim()
                $file = $Matches[2].Trim()

                switch -Regex ($statusCode) {
                    '^M' { $status.Modified += $file }
                    '^A' { $status.Added += $file }
                    '^D' { $status.Deleted += $file }
                    '^R' { $status.Renamed += $file }
                    '^\?' { $status.Added += $file }
                }
                $status.TotalFiles++
            }
        }
    }

    # Get diff stats (capture only stdout)
    $ErrorActionPreference = 'SilentlyContinue'
    $diffStats = git diff --stat 2>$null | Out-String
    $ErrorActionPreference = 'Stop'

    if ($diffStats -and $diffStats.Trim()) {
        $lines = $diffStats -split "`n" | Where-Object { $_.Trim() }
        $summaryLine = $lines | Select-Object -Last 1
        if ($summaryLine -match '(\d+) insertion.*?(\d+) deletion') {
            $status.LinesAdded = [int]$Matches[1]
            $status.LinesDeleted = [int]$Matches[2]
        }
        elseif ($summaryLine -match '(\d+) insertion') {
            $status.LinesAdded = [int]$Matches[1]
        }
        elseif ($summaryLine -match '(\d+) deletion') {
            $status.LinesDeleted = [int]$Matches[1]
        }
    }

    Set-Location $currentDir
    return $status
}

function Get-FileCategories {
    param([array]$Files)

    $categories = @{
        Config = @()
        Components = @()
        Pages = @()
        API = @()
        Utils = @()
        Hooks = @()
        Context = @()
        Stores = @()
        Tests = @()
        Docs = @()
        Routes = @()
        Models = @()
        Migrations = @()
        Other = @()
    }

    foreach ($file in $Files) {
        switch -Regex ($file) {
            '\.(json|yml|yaml|ini|env|config|toml)$' { $categories.Config += $file }
            'component|ui/' { $categories.Components += $file }
            'pages?/' { $categories.Pages += $file }
            'api/' { $categories.API += $file }
            'utils?/' { $categories.Utils += $file }
            'hooks?/' { $categories.Hooks += $file }
            'context/' { $categories.Context += $file }
            'store|slice' { $categories.Stores += $file }
            'test|spec|__tests__' { $categories.Tests += $file }
            '\.(md|txt|rst)$|docs?/' { $categories.Docs += $file }
            'routes?/' { $categories.Routes += $file }
            'models?/' { $categories.Models += $file }
            'migration' { $categories.Migrations += $file }
            default { $categories.Other += $file }
        }
    }

    return $categories
}

function Format-ChangeList {
    param(
        [hashtable]$Status,
        [string]$RepoName
    )

    $output = ""

    if ($Status.TotalFiles -eq 0) {
        return "No changes detected in $RepoName"
    }

    $categories = Get-FileCategories -Files ($Status.Modified + $Status.Added + $Status.Deleted + $Status.Renamed)

    # Modified Files
    if ($Status.Modified.Count -gt 0) {
        $modCategories = Get-FileCategories -Files $Status.Modified
        $output += "`n### Modified Files ($($Status.Modified.Count))`n`n"

        foreach ($category in $modCategories.Keys | Where-Object { $modCategories[$_].Count -gt 0 } | Sort-Object) {
            $files = $modCategories[$category]
            if ($files.Count -gt 0) {
                $output += "**$category ($($files.Count) files)**:`n"
                foreach ($file in $files | Sort-Object) {
                    $output += "- $file`n"
                }
                $output += "`n"
            }
        }
    }

    # Added Files
    if ($Status.Added.Count -gt 0) {
        $addCategories = Get-FileCategories -Files $Status.Added
        $output += "`n### Added Files ($($Status.Added.Count))`n`n"

        foreach ($category in $addCategories.Keys | Where-Object { $addCategories[$_].Count -gt 0 } | Sort-Object) {
            $files = $addCategories[$category]
            if ($files.Count -gt 0) {
                $output += "**$category ($($files.Count) files)**:`n"
                foreach ($file in $files | Sort-Object) {
                    $output += "- $file`n"
                }
                $output += "`n"
            }
        }
    }

    # Deleted Files
    if ($Status.Deleted.Count -gt 0) {
        $delCategories = Get-FileCategories -Files $Status.Deleted
        $output += "`n### Deleted Files ($($Status.Deleted.Count))`n`n"

        foreach ($category in $delCategories.Keys | Where-Object { $delCategories[$_].Count -gt 0 } | Sort-Object) {
            $files = $delCategories[$category]
            if ($files.Count -gt 0) {
                $output += "**$category ($($files.Count) files)**:`n"
                foreach ($file in $files | Sort-Object) {
                    $output += "- $file`n"
                }
                $output += "`n"
            }
        }
    }

    # Renamed Files
    if ($Status.Renamed.Count -gt 0) {
        $output += "`n### Renamed Files ($($Status.Renamed.Count))`n`n"
        foreach ($file in $Status.Renamed | Sort-Object) {
            $output += "- $file`n"
        }
        $output += "`n"
    }

    return $output
}

function Generate-CommitMessage {
    param(
        [hashtable]$Status,
        [string]$RepoName,
        [string]$CustomDescription
    )

    if ($Status.TotalFiles -eq 0) {
        return $null
    }

    # Determine commit type
    $commitType = "chore"
    if ($Status.Added.Count -gt $Status.Modified.Count -and $Status.Added.Count -gt $Status.Deleted.Count) {
        $commitType = "feat"
    }
    elseif ($Status.Deleted.Count -gt 10) {
        $commitType = "refactor"
    }
    elseif ($Status.Modified.Count -gt 0 -and $Status.Added.Count -eq 0 -and $Status.Deleted.Count -eq 0) {
        $commitType = "fix"
    }

    # Calculate net change
    $netChange = $Status.LinesAdded - $Status.LinesDeleted
    $netChangeStr = if ($netChange -gt 0) { "+$netChange" } else { "$netChange" }

    # Build commit message
    $title = if ($CustomDescription) {
        "$commitType`: $CustomDescription ($dateFormatted)"
    }
    else {
        "$commitType`: Update $RepoName ($dateFormatted)"
    }

    $changeList = Format-ChangeList -Status $Status -RepoName $RepoName

    $message = @"
$title

## Change Summary

**Files Changed**: $($Status.TotalFiles) files
**Lines Added**: +$($Status.LinesAdded) lines
**Lines Deleted**: -$($Status.LinesDeleted) lines
**Net Change**: $netChangeStr lines

$changeList

## Impact Analysis

"@

    # Add impact based on changes
    if ($Status.Config.Count -gt 0 -or ($Status.Modified + $Status.Added + $Status.Deleted) -match 'package\.json|requirements\.txt|\.env') {
        $message += "[WARNING] **Configuration Changes**: May require dependency reinstall or environment updates`n"
    }

    if (($Status.Modified + $Status.Added + $Status.Deleted) -match 'migration') {
        $message += "[WARNING] **Database Changes**: May require migration execution`n"
    }

    if (($Status.Modified + $Status.Added) -match 'test') {
        $message += "[INFO] **Test Changes**: Verify all tests pass before deployment`n"
    }

    if ($Status.Deleted.Count -gt 5) {
        $message += "[INFO] **File Cleanup**: $($Status.Deleted.Count) files removed - verify no breaking changes`n"
    }

    $message += @"

## Validation Checklist

- [ ] Application starts successfully
- [ ] All tests passing
- [ ] No console errors
- [ ] Key features functional
- [ ] Dependencies up to date

## Additional Notes

Generated automatically on $dateFormatted
Repository: $RepoName

---
Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
"@

    return $message
}

# ============================================================================
# ANALYZE REPOSITORIES
# ============================================================================

Write-Host "Analyzing backend repository..." -ForegroundColor Yellow
$backendStatus = Get-GitStatus -RepoPath $backendPath
Write-Host "  Files: $($backendStatus.TotalFiles) | +$($backendStatus.LinesAdded) -$($backendStatus.LinesDeleted)" -ForegroundColor Gray

Write-Host "Analyzing frontend repository..." -ForegroundColor Yellow
$frontendStatus = Get-GitStatus -RepoPath $frontendPath
Write-Host "  Files: $($frontendStatus.TotalFiles) | +$($frontendStatus.LinesAdded) -$($frontendStatus.LinesDeleted)`n" -ForegroundColor Gray

# Check if there are any changes
if ($backendStatus.TotalFiles -eq 0 -and $frontendStatus.TotalFiles -eq 0) {
    Write-Host "[NO CHANGES] No changes detected in either repository!" -ForegroundColor Red
    Write-Host "   Nothing to commit.`n" -ForegroundColor Gray
    exit 0
}

# ============================================================================
# GENERATE COMMIT MESSAGES
# ============================================================================

Write-Host "Generating commit messages..." -ForegroundColor Yellow

$backendCommit = Generate-CommitMessage -Status $backendStatus -RepoName "backend" -CustomDescription $Description
$frontendCommit = Generate-CommitMessage -Status $frontendStatus -RepoName "frontend" -CustomDescription $Description

# ============================================================================
# BUILD COMMIT SCRIPT
# ============================================================================

Write-Host "Building commit script..." -ForegroundColor Yellow

$scriptContent = @"
# commit_${dateFilename}.ps1
# Auto-generated commit script
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Backend Changes: $($backendStatus.TotalFiles) files
# Frontend Changes: $($frontendStatus.TotalFiles) files

`$ErrorActionPreference = "SilentlyContinue"

# Configure Git identity
git config --global user.email "michael@tovtech.org"
git config --global user.name "Michael"

Write-Host "``n========================================" -ForegroundColor Cyan
Write-Host "TovPlay Deployment - $dateFormatted" -ForegroundColor Cyan
Write-Host "========================================``n" -ForegroundColor Cyan

"@

# Add backend section if there are changes
if ($backendStatus.TotalFiles -gt 0) {
    $backendCommitEscaped = $backendCommit -replace '"', '`"' -replace '\$', '`$'

    $scriptContent += @"

# ============================================================================
# BACKEND REPOSITORY
# ============================================================================

Write-Host "Processing Backend Repository..." -ForegroundColor Yellow
Set-Location $backendPath

git checkout main 2>`$null

`$backendCommit = @"
$backendCommitEscaped
"@

git add -A
git commit -m `$backendCommit

git push origin main

Write-Host "✓ Backend committed and pushed" -ForegroundColor Green

"@
}

# Add frontend section if there are changes
if ($frontendStatus.TotalFiles -gt 0) {
    $frontendCommitEscaped = $frontendCommit -replace '"', '`"' -replace '\$', '`$'

    $scriptContent += @"

# ============================================================================
# FRONTEND REPOSITORY
# ============================================================================

Write-Host "``nProcessing Frontend Repository..." -ForegroundColor Yellow
Set-Location $frontendPath

Remove-Item -Path "nul","null" -Force -ErrorAction SilentlyContinue

git checkout main 2>`$null

`$frontendCommit = @"
$frontendCommitEscaped
"@

git add -A
git commit -m `$frontendCommit

git push origin main

Write-Host "✓ Frontend committed and pushed" -ForegroundColor Green

"@
}

# Add completion summary
$totalFiles = $backendStatus.TotalFiles + $frontendStatus.TotalFiles
$totalAdded = $backendStatus.LinesAdded + $frontendStatus.LinesAdded
$totalDeleted = $backendStatus.LinesDeleted + $frontendStatus.LinesDeleted
$netTotal = $totalAdded - $totalDeleted
$netTotalStr = if ($netTotal -gt 0) { "+$netTotal" } else { "$netTotal" }

$scriptContent += @"

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-Host "``n========================================" -ForegroundColor Cyan
Write-Host "         DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "``nSummary:" -ForegroundColor Yellow
Write-Host "  Total Files:     $totalFiles files" -ForegroundColor White
Write-Host "  Lines Added:     +$totalAdded" -ForegroundColor Green
Write-Host "  Lines Deleted:   -$totalDeleted" -ForegroundColor Red
Write-Host "  Net Change:      $netTotalStr" -ForegroundColor $(if ($netTotal -gt 0) { 'Green' } else { 'Red' })

"@

if ($backendStatus.TotalFiles -gt 0) {
    $scriptContent += @"
Write-Host "``n  Backend:  $($backendStatus.TotalFiles) files (+$($backendStatus.LinesAdded) -$($backendStatus.LinesDeleted))" -ForegroundColor White
"@
}

if ($frontendStatus.TotalFiles -gt 0) {
    $scriptContent += @"
Write-Host "  Frontend: $($frontendStatus.TotalFiles) files (+$($frontendStatus.LinesAdded) -$($frontendStatus.LinesDeleted))" -ForegroundColor White
"@
}

$scriptContent += @"

Write-Host "``nRepository Links:" -ForegroundColor Yellow
Write-Host "  Backend:  https://github.com/TovTechOrg/tovplay-backend" -ForegroundColor Cyan
Write-Host "  Frontend: https://github.com/TovTechOrg/tovplay-frontend" -ForegroundColor Cyan

Write-Host "``n[SUCCESS] Script completed successfully!``n" -ForegroundColor Green

Set-Location F:/tovplay
"@

# ============================================================================
# SAVE SCRIPT
# ============================================================================

try {
    $scriptContent | Out-File -FilePath $outputScript -Encoding UTF8 -Force
    Write-Host "[SUCCESS] Script generated successfully!" -ForegroundColor Green
    Write-Host "`nOutput: $outputScript`n" -ForegroundColor Cyan

    # Display summary
    Write-Host "Generation Summary:" -ForegroundColor Yellow
    Write-Host "  Date: $dateFormatted" -ForegroundColor Gray
    if ($backendStatus.TotalFiles -gt 0) {
        Write-Host "  Backend: $($backendStatus.TotalFiles) files (+$($backendStatus.LinesAdded) -$($backendStatus.LinesDeleted))" -ForegroundColor Gray
    }
    if ($frontendStatus.TotalFiles -gt 0) {
        Write-Host "  Frontend: $($frontendStatus.TotalFiles) files (+$($frontendStatus.LinesAdded) -$($frontendStatus.LinesDeleted))" -ForegroundColor Gray
    }

    Write-Host "`nTo execute the generated script, run:" -ForegroundColor Yellow
    Write-Host "   .\commit_${dateFilename}.ps1`n" -ForegroundColor Cyan
}
catch {
    Write-Host "[ERROR] Error generating script: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# ARCHIVE OLD SCRIPTS (Optional)
# ============================================================================

$archiveDir = "$scriptDir\archive"
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

# Archive scripts older than 30 days
Get-ChildItem "$scriptDir\commit_*.ps1" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    ForEach-Object {
        Move-Item $_.FullName -Destination $archiveDir -Force
        Write-Host "Archived old script: $($_.Name)" -ForegroundColor DarkGray
    }

Write-Host "`n[DONE] Script generation complete!`n" -ForegroundColor Green
