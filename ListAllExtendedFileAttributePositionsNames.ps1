# Based on code from https://www.powershellmagazine.com/2015/04/13/pstip-use-shell-application-to-display-extended-file-attributes/
param(
    [string]$FullName = $PSScriptRoot
)
if (-not (Test-Path -Path $FullName -PathType Container)) {
    $FullName = Split-Path -Path $FullName -Parent
}
Write-Host "Extended File Attributes for $FullName"
$com = (New-Object -ComObject Shell.Application).NameSpace($FullName)
for ($index = 0; $index -ne 400; $index++) {
    New-Object -TypeName PSCustomObject -Property @{
        IndexNumber = $Index
        Attribute   = $com.GetDetailsOf($com, $index)
    } | Where-Object { $_.Attribute }
} 