<#
.SYNOPSIS
    rmfe
#>
$f=@("NetFx3","NetFx4-AdvSrvs","Containers","Microsoft-Hyper-V-All","IIS-WebServerRole","IIS-WebServer","IIS-CommonHttpFeatures","IIS-HttpErrors","IIS-HttpRedirect","IIS-ApplicationDevelopment","IIS-NetFxExtensibility","IIS-NetFxExtensibility45","IIS-HealthAndDiagnostics","IIS-HttpLogging","IIS-LoggingLibraries","IIS-RequestMonitor","IIS-HttpTracing","IIS-Security","IIS-URLAuthorization","IIS-RequestFiltering","IIS-IPSecurity","IIS-Performance","IIS-HttpCompressionDynamic","IIS-WebServerManagementTools","IIS-ManagementScriptingTools","IIS-IIS6ManagementCompatibility","IIS-Metabase","IIS-HostableWebCore","IIS-StaticContent","IIS-DefaultDocument","IIS-DirectoryBrowsing","IIS-WebDAV","IIS-WebSockets","IIS-ApplicationInit","IIS-ASPNET","IIS-ASPNET45","IIS-ASP","IIS-CGI","IIS-ISAPIExtensions","IIS-ISAPIFilter","IIS-ServerSideIncludes","IIS-CustomLogging","IIS-BasicAuthentication","IIS-HttpCompressionStatic","IIS-ManagementConsole","IIS-ManagementService","IIS-WMICompatibility","IIS-LegacyScripts","IIS-LegacySnapIn","IIS-FTPServer","IIS-FTPSvc","IIS-FTPExtensibility","LegacyComponents","DirectPlay","MediaPlayback","WindowsMediaPlayer","Printing-PrintToPDFServices-Features","Printing-XPSServices-Features","MSRDC-Infrastructure","ServicesForNFS-ClientOnly","TelnetClient","TFTP","TIFFIFilter","VirtualMachinePlatform","HypervisorPlatform","Microsoft-Windows-Subsystem-Linux")
    
    Write-Host "=== RMFE: Disable Windows Features ===" -ForegroundColor Magenta
    $total = $f.Count
    $i = 0
    $startTime = Get-Date
    $maxWaitSec = 30
    
    foreach($feat in $f) {
        $i++
        $pct = [math]::Round(($i / $total) * 100, 2)
        Write-Host "[$pct%] [$i/$total] $feat " -NoNewline -ForegroundColor Cyan
        
        $proc = Start-Process -FilePath "dism.exe" -ArgumentList "/online /disable-feature /featurename:$feat /remove /norestart /quiet" -PassThru -WindowStyle Hidden
        $waited = 0
        $exited = $false
        while ($waited -lt $maxWaitSec) {
            $exited = $proc.WaitForExit(500)
            if ($exited) { break }
            $waited += 0.5
            Write-Host "." -NoNewline -ForegroundColor DarkGray
        }
        
        if (-not $exited) {
            try { $proc.Kill() } catch {}
            Start-Sleep -Milliseconds 200
            Get-Process -Name "dism","dismhost","TiWorker" -EA 0 | Stop-Process -Force -EA 0
            Write-Host " TIMEOUT" -ForegroundColor DarkYellow
        } elseif ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Host " OK" -ForegroundColor Green
        } elseif ($proc.ExitCode -eq 50 -or $proc.ExitCode -eq 87) {
            Write-Host " SKIP" -ForegroundColor Yellow
        } else {
            Write-Host " ERR$($proc.ExitCode)" -ForegroundColor Red
        }
    }
    
    $totalTime = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    Write-Host "`n=== RMFE COMPLETE === ($totalTime sec)" -ForegroundColor Magenta
