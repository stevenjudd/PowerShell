$OneDrivePath = (Join-Path -Path $HOME -ChildPath OneDrive) #| Join-Path -ChildPath "test"
$SourceFileList = "E:\OneDriveDeltas\OneDriveFileList.csv"
$OneDriveList = Get-ChildItem -Path $OneDrivePath -Recurse | Select-Object FullName, Length, LastWriteTime, CreationTime | Sort-Object -Property FullName | ConvertTo-Csv -NoTypeInformation
$OneDriveList | Out-File -FilePath $SourceFileList