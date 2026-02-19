<#
.SYNOPSIS
    rmthis
#>
# Simple list of operations: directory and command pairs - easy to modify
    $operations = @(
        @("C:\Users\micha\AppData\Local", "ws 'rmf uv'"),
        @("C:\Users\micha\AppData\Local", "ws 'rmf temp'"),
        @("C:\Users\micha\AppData\Roaming", "ws 'rmf uv'"),
        @("C:\Users\micha\AppData\Local", "ws 'rmf temp'"),
        @("C:\Windows", "ws 'rmf Temp'"),
        @("$env:USERPROFILE\AppData\Local", "ws 'rmf Temp'"),
        @("C:\Windows", 'ws "rmf Downloaded Program Files"'),
        @("C:\ProgramData\Microsoft\Windows\WER", "ws 'rmf ReportArchive'"),
        @("C:\Windows", "ws 'rmf Prefetch'"),
        @("$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default", "ws 'rmf Cache'"),
        @("$env:USERPROFILE\AppData\Local\Microsoft\Windows", "ws 'rmf INetCache'"),
        @("$env:USERPROFILE\AppData\Roaming\Microsoft\Windows", "ws 'rmf Recent'"),
        @("C:\Windows\SoftwareDistribution", "ws 'rmf Download'"),
        @("$env:USERPROFILE\AppData\Local\Microsoft\Windows", 'ws "rmf Temporary Internet Files"'),
        @("C:\Program Files (x86)", 'ws "rmf IOBIT"')
    )

    foreach ($op in $operations) {
        $path = $op[0]
        $command = $op[1]
        if (Test-Path $path) {
            Write-Host "Changing to directory: $path and executing: $command"
            cd $path
            try {
                Invoke-Expression $command
            }
            catch {
                Write-Host "Error executing command in $path : $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "Directory does not exist: $path"
        }
    }
