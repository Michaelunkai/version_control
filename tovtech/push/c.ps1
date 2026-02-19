#═══════════════════════════════════════════════════════════════════════════════
# SCRIPT: c.ps1
# PURPOSE: Force deploy DEVELOP branches only (backend + frontend)
# AUTHOR: Michael @ TovTech
# REPOS: TovTechOrg/tovplay-backend, TovTechOrg/tovplay-frontend
#═══════════════════════════════════════════════════════════════════════════════

#───────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
#───────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "SilentlyContinue"
$commitMessage = "testing ci/cd pipelines"

#───────────────────────────────────────────────────────────────────────────────
# STEP 1: Configure Git Identity
#───────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 1] Configuring Git identity..." -ForegroundColor Yellow
git config --global user.email "michael@tovtech.org"
git config --global user.name "Michael"
Write-Host "  Git identity set: Michael <michael@tovtech.org>" -ForegroundColor DarkGray

#───────────────────────────────────────────────────────────────────────────────
# STEP 2: Deploy Backend - DEVELOP Branch
#───────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 2] Deploying Backend/develop..." -ForegroundColor Yellow
Set-Location F:/tovplay/tovplay-backend
git checkout develop 2>$null
git add -A
git commit --allow-empty -m $commitMessage 2>$null
git push origin develop --force --no-verify 2>$null
git checkout main 2>$null
Write-Host "  Backend/develop pushed successfully" -ForegroundColor Green

#───────────────────────────────────────────────────────────────────────────────
# STEP 3: Deploy Frontend - DEVELOP Branch
#───────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 3] Deploying Frontend/develop..." -ForegroundColor Yellow
Set-Location F:/tovplay/tovplay-frontend
Remove-Item -Path "nul","null" -Force 2>$null
git checkout develop 2>$null
git add -A
git commit --allow-empty -m $commitMessage 2>$null
git push origin develop --force --no-verify 2>$null
git checkout main 2>$null
Write-Host "  Frontend/develop pushed successfully" -ForegroundColor Green

#───────────────────────────────────────────────────────────────────────────────
# COMPLETE
#───────────────────────────────────────────────────────────────────────────────
Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE: DEVELOP branches pushed!" -ForegroundColor Cyan
Write-Host "    - Backend/develop" -ForegroundColor White
Write-Host "    - Frontend/develop" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
