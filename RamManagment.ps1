$maxRamMB = 4000


$allProcesses = Get-Process | Where-Object { $_.SessionId -ne 0 }  


$groupedBySession = $allProcesses | Group-Object -Property SessionId

foreach ($group in $groupedBySession) {
    $sessionId = $group.Name
    $userProcesses = $group.Group

    
    $totalRAM = ($userProcesses | Measure-Object -Property WorkingSet -Sum).Sum / 1MB
    Write-Host "Session $sessionId is using $([math]::Round($totalRAM,2)) MB RAM"

    
    if ($totalRAM -gt $maxRamMB) {
        Write-Host "Session $sessionId exceeded $maxRamMB MB. Limiting memory usage..."

        
        $processesToKill = $userProcesses | Sort-Object -Property WorkingSet -Descending

        
        foreach ($proc in $processesToKill) {
            Write-Host "Stopping process $($proc.Name) (PID $($proc.Id), $([math]::Round($proc.WorkingSet/1MB,2)) MB)"
            Stop-Process -Id $proc.Id -Force

            
            $userProcesses = Get-Process | Where-Object { $_.SessionId -eq $sessionId }
            $totalRAM = ($userProcesses | Measure-Object -Property WorkingSet -Sum).Sum / 1MB

            if ($totalRAM -le $maxRamMB) {
                Write-Host "Session $sessionId RAM is now under limit: $([math]::Round($totalRAM,2)) MB"
                break
            }
        }
    } else {
        Write-Host "Session $sessionId is within RAM limit."
    }
}

Write-Host "`n===== RAM check complete =====`n"
