function Get-sjCpuUsageToTitle {

    <#
    .Notes
        Based on a script from Daniel S Potter:
        https://twitter.com/DanielSPotter1/status/1005133432622592001
        Modified by Steven Judd to be a function, add a parameter for computername, and output result as an object
        Updated by [name] on [yyyy/mm/dd] to ...
        Version 20180612.1 (please use yyyymmdd.x notation)

        Features to add:
            Add a parameter to specify the interval to update the title
    .SYNOPSIS
        Function to update the window title with username, version, processId, CPU percent
    .DESCRIPTION
        This function will create a job and a system timer that will get the current
        CPU percent and update the window title with the username, the PowerShell
        version, the shell process ID, and the current CPU percent.
    .LINK
        https://github.com/stevenjudd/PowerShell/blob/master/Get-sjCpuUsageToTitle.ps1https://github.com/stevenjudd/PowerShell
    .EXAMPLE
        Get-sjCpuUsageToTitle
        This command runs the function to start two background jobs that will update
        the title of the window with the username, the PowerShell version, the shell
        process ID, and the current CPU percent.
    #>
    
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
