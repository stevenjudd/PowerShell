#get directory
$Directory = 'C:\Users\steve\OneDrive\Pictures\Camera Roll\2018', 'C:\Users\steve\OneDrive\Pictures\Camera Roll\2019'
#get extended metadate for Path and Date taken properties
try {
    $param = @{
        FullName   = $Directory
        Properties = "Path", "Date taken"
        Recurse    = $true
        Verbose    = $true
    }
    $FileResults = Get-sjExtendedMetaData @param |
    #if date taken remove unicode and use get-date to get year and month
    Where-Object { $_.'Date taken' } |
    #add Year and Month properties from Date taken property
    Foreach-Object {
        $Year = (Get-Date ($_.'Date taken' -replace '[^\x00-\x7F]', '')).Year
        $Month = "{0:00}" -f (Get-Date ($_.'Date taken' -replace '[^\x00-\x7F]', '')).Month
        $_ | Add-Member -NotePropertyName 'Year' -NotePropertyValue $Year -PassThru | Add-Member -NotePropertyName 'Month' -NotePropertyValue $Month -PassThru
    }
}
catch {
    throw $_
}
#move file to a year\month folder
foreach ($item in $FileResults) {
    $DestinationPath = "C:\Users\steve\OneDrive\Pictures\$($item.Year)\$($item.Month)"
    if (-not(Test-Path -Path $DestinationPath)) {
        $null = New-Item -Path $DestinationPath -ItemType Directory -Force
    }
    Move-Item -Path $item.Path -Destination "C:\Users\steve\OneDrive\Pictures\$($item.Year)\$($item.Month)" #-WhatIf
}