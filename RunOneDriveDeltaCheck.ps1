#get the changes to OneDrive files and log the results
$LogPath = Join-Path -Path $PSScriptRoot -ChildPath "logs"
if (-not(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force
}
$LogFile = Join-Path -Path $LogPath -ChildPath "OneDriveModifyNewRemoveLog-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$XmlFile = Join-Path -Path $LogPath -ChildPath "OneDriveModifyNewRemoveXml-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
try {
    $OneDriveDeltas = & (Join-Path -Path $PSScriptRoot -ChildPath "Get-sjOneDriveDeltas.ps1")
    if ($OneDriveDeltas) {
        $OneDriveDeltas | Export-Clixml -Path $XmlFile -Force -ErrorAction Stop
        $OneDriveDeltas | ConvertTo-Csv -NoTypeInformation -ErrorAction Stop | Out-File -FilePath $LogFile -Force -ErrorAction Stop
    }
}
catch {
    throw $_
}

#email the results
if ($OneDriveDeltas) {
    # $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'stevenkjudd@hotmail.com', $('XXXXX' | ConvertTo-SecureString -AsPlainText -Force)
    $Credential = Get-Credential
    $Body = @"
Report save location: $LogFile
Object save location: $XmlFile

$(Get-Content -Path $LogFile | Out-String)
"@
    $Params = @{
        Body        = $Body #"Report save location: $XmlFile `n`n$(Import-Clixml -Path $XmlFile | Format-Table -AutoSize | Out-String)"
        To          = 'stevenjudd@outlook.com'
        From        = 'stevenkjudd@hotmail.com'
        Subject     = "OneDrive Automation Report on $(Get-Date -Format 'yyyyMMdd-HHmmss')"
        SmtpServer  = 'smtp.live.com'
        Port        = "587"
        Credential  = $Credential
        UseSsl      = $true
        ErrorAction = "Stop"
    }
    try {
        Send-MailMessage @Params
        & (Join-Path -Path $PSScriptRoot -ChildPath "Update-sjOneDriveDeltas.ps1")
    }
    catch {
        throw $_
    }
}
