#script to check for changes in OneDrive
$OneDrivePath = (Join-Path -Path $HOME -ChildPath OneDrive) #| Join-Path -ChildPath "test"
#$OneDriveDeltaPath = "E:\OneDriveDeltas"
$SourceFileList = "E:\OneDriveDeltas\OneDriveFileList.csv"
$OneDriveSourceList = Get-Content -Path $SourceFileList
$OneDriveList = Get-ChildItem -Path $OneDrivePath -Recurse | Select-Object FullName, Length, LastWriteTime, CreationTime | Sort-Object -Property FullName | ConvertTo-Csv -NoTypeInformation
$Deltas = Compare-Object -ReferenceObject $OneDriveList -DifferenceObject $OneDriveSourceList

if ($Deltas) {
    $DeltaList = foreach ($item in $Deltas) {
        switch ($item.SideIndicator) {
            "=>" { $SideInidcator = "SourceList" }
            "<=" { $SideInidcator = "OneDriveList" }
        }
        $InputObject = $item.InputObject | ConvertFrom-Csv -Header "FullName", "Length", "LastWriteTime", "CreationTime"
        [PSCustomObject]@{
            FullName      = $InputObject.FullName
            Length        = $InputObject.Length
            LastWriteTme  = $InputObject.LastWriteTime
            CreationTime  = $InputObject.CreationTime
            SideIndicator = $SideInidcator
        }
    } #end foreach ($item in $Deltas)
    
    $DeltaListGroup = $DeltaList | Group-Object -Property FullName
    
    foreach ($NewModifyRemove in $DeltaListGroup) {
        #consider replacing with switch
        if ($NewModifyRemove.Count -gt 1) {
            $NewModifyRemove.Group | Add-Member -NotePropertyName Status -NotePropertyValue "Modify" -PassThru
        }
        elseif ($NewModifyRemove.Group.SideIndicator -eq "OneDriveList") {
            $NewModifyRemove.Group | Add-Member -NotePropertyName Status -NotePropertyValue "New" -PassThru
        }
        elseif ($NewModifyRemove.Group.SideIndicator -eq "SourceList") {
            $NewModifyRemove.Group | Add-Member -NotePropertyName Status -NotePropertyValue "Remove" -PassThru
        }
        else {
            Write-Error "There is a type error for the data: $NewModifyRemove"
        }
    } #end foreach ($NewModifyRemove in $DeltaListGroup)
}
