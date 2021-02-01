# Based on code from https://www.powershellmagazine.com/2015/04/13/pstip-use-shell-application-to-display-extended-file-attributes/

#this is slower than the for loop version due to the cost of spinning up the threads
param(
    [string]$FullName = $PSScriptRoot
)
if (-not (Test-Path -Path $FullName -PathType Container)) {
    $FullName = Split-Path -Path $FullName -Parent
}
Write-Host "Extended File Attributes for $FullName"
$com = (New-Object -ComObject Shell.Application).NameSpace($FullName)
0..400 | ForEach-Object -Parallel {
    $insidecom = $using:com
    [PSCustomObject]@{
        IndexNumber = $_
        Attribute   = $insidecom.GetDetailsOf($insidecom, $_)
    } | Where-Object { $_.Attribute }
}
