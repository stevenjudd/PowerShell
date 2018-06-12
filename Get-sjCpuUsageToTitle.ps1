function Get-sjCpuUsageToTitle {

    Start-Job -Name CpuMonitor -ScriptBlock {
        while($true)
        {
            $cpuValue = (Get-WmiObject win32_processor).LoadPercentage
            $Host.UI.RawUI.WindowTitle = "$env:username | PSVer: $($PSVersionTable.PsVersion.ToString()) | PID: $PID | CPU%: $cpuValue"
            Start-Sleep -Seconds 15
        }
    } | Out-Null

    if(-not($timer))
    {
        $timer = New-Object System.Timers.Timer
        $action = {Receive-Job -Name CpuMonitor -Keep}
        $timer.Interval = 15000
        $timer.Enabled = $true
        Register-ObjectEvent -InputObject $timer -EventName elapsed -SourceIdentifier CpuTimer -Action $action | Out-Null
        $timer.Start()
    }

} #end Get-sjCpuUsageToTitle function 
