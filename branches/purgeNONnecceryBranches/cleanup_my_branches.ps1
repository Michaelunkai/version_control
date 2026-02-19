# ============================================
# CLEANUP MY BRANCHES - TovPlay Repos
# ============================================
# This script deletes ALL branches created by Michael or Claude
# in both tovplay-backend and tovplay-frontend repos
# KEEPS: main, develop, and branches by other team members
# ============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BRANCH CLEANUP SCRIPT - TovPlay" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# My identifiers (Michael's branches)
$myAuthors = @("Michael", "Claude", "Claude Code")

# Repos to clean
$repos = @(
    @{ Name = "tovplay-backend"; Path = "F:\tovplay\tovplay-backend" },
    @{ Name = "tovplay-frontend"; Path = "F:\tovplay\tovplay-frontend" }
)

$totalDeleted = 0
$allDeletedBranches = @()

foreach ($repo in $repos) {
    Write-Host "`n[$($repo.Name)]" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Yellow

    Push-Location $repo.Path

    # Fetch latest
    Write-Host "Fetching latest..." -ForegroundColor Gray
    git fetch --all --prune 2>$null

    # Get all remote branches with their authors
    $branches = git branch -r --format="%(refname:short)|%(authorname)" 2>$null

    $deletedInRepo = 0

    foreach ($line in $branches) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $parts = $line -split '\|'
        $branchFull = $parts[0].Trim()
        $author = if ($parts.Length -gt 1) { $parts[1].Trim() } else { "" }

        # Extract branch name (remove origin/)
        $branch = $branchFull -replace '^origin/', ''

        # Skip protected branches
        if ($branch -eq "main" -or $branch -eq "develop" -or $branch -eq "HEAD") {
            continue
        }

        # Skip if not mine
        $isMine = $false
        foreach ($myAuthor in $myAuthors) {
            if ($author -like "*$myAuthor*") {
                $isMine = $true
                break
            }
        }

        # Also check if branch name starts with claude/
        if ($branch -like "claude/*") {
            $isMine = $true
        }

        if (-not $isMine) {
            continue
        }

        # Delete the branch
        Write-Host "  Deleting: " -NoNewline -ForegroundColor Red
        Write-Host "$branch" -NoNewline -ForegroundColor White
        Write-Host " (by $author)" -ForegroundColor DarkGray

        git push origin --delete $branch 2>$null

        if ($LASTEXITCODE -eq 0) {
            $deletedInRepo++
            $allDeletedBranches += [PSCustomObject]@{
                Repo = $repo.Name
                Branch = $branch
                Author = $author
            }
        } else {
            Write-Host "    [FAILED]" -ForegroundColor DarkRed
        }
    }

    Write-Host "`n  Deleted $deletedInRepo branches from $($repo.Name)" -ForegroundColor Green
    $totalDeleted += $deletedInRepo

    Pop-Location
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CLEANUP COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nTotal branches deleted: $totalDeleted" -ForegroundColor Green

if ($allDeletedBranches.Count -gt 0) {
    Write-Host "`nDeleted branches:" -ForegroundColor Yellow
    $allDeletedBranches | Format-Table -AutoSize
}

Write-Host "`nProtected branches (NOT deleted):" -ForegroundColor Cyan
Write-Host "  - main" -ForegroundColor White
Write-Host "  - develop" -ForegroundColor White
Write-Host "  - All branches by other team members" -ForegroundColor White

# Beep when done
1..3 | ForEach-Object { [console]::Beep(800,300); Start-Sleep -Milliseconds 100 }
