<#
.SYNOPSIS
    refe
#>
Write-Host "`n=== REFE: FULL FEATURE RESET CYCLE ===" -ForegroundColor Magenta
    Write-Host "Step 1: Disabling all Windows features..." -ForegroundColor Cyan
    rmfe
    
    Write-Host "`nStep 2: Scheduling GFE to run after reboot..." -ForegroundColor Cyan
    
    # Create a one-time scheduled task to run gfe after next logon
    $taskName = "REFE_GFE_OneTime"
    $profilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    
    # Remove any existing task
    schtasks /delete /tn $taskName /f 2>$null
    
    # Create PowerShell script that will run gfe and then delete itself
    $scriptPath = "$env:TEMP\refe_gfe_runner.ps1"
    $scriptContent = @"
# REFE GFE Runner - One Time Only
Start-Sleep -Seconds 5
. '$profilePath'
gfe
# Clean up - delete task and this script
schtasks /delete /tn '$taskName' /f 2>`$null
Remove-Item '$scriptPath' -Force -ErrorAction SilentlyContinue
"@
    $scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    
    # Create scheduled task to run at logon
    $action = "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Normal -File `"$scriptPath`""
    schtasks /create /tn $taskName /tr $action /sc ONLOGON /rl HIGHEST /f | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Task '$taskName' created successfully!" -ForegroundColor Green
        Write-Host "Script: $scriptPath" -ForegroundColor DarkGray
        Write-Host "`nAfter reboot, GFE will run automatically and clean up." -ForegroundColor Green
        Write-Host "Reboot now? (y/n): " -NoNewline -ForegroundColor Yellow
        $answer = Read-Host
        if ($answer -eq 'y' -or $answer -eq 'Y') {
            Write-Host "Rebooting in 3 seconds..." -ForegroundColor Red
            Start-Sleep -Seconds 3
            Restart-Computer -Force
        }
    } else {
        Write-Host "Failed to create scheduled task. Run 'gfe' manually after reboot." -ForegroundColor Red
    }
