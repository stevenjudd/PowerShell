function Move-PhotosToYearMonthFolder {

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [Alias("FullName")]
        [string]$Directory, #= 'C:\Users\steve\OneDrive\Pictures\1999'
        [switch]$Recurse
    )
    function RemoveEmptyDirectory {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipelineByPropertyName)]
            [string]
            $FullName
        )

        process {
            Write-Verbose "Processing Directory: $FullName"
            if (Get-ChildItem -Path $FullName) {
                foreach ($item in (Get-ChildItem -Path $FullName -Directory)) {
                    RemoveEmptyDirectory $item
                }
            }
            if (-not (Get-ChildItem -Path $FullName)) {
                Remove-Item -Path $FullName
            }
        }
    }

    #get directory
    if ($env:OneDriveConsumer) {
        $OneDrive = $env:OneDriveConsumer
    }
    else {
        $OneDrive = $env:OneDrive
    }
    $RootDirectory = Split-Path -Path $Directory
    #get extended metadate for Path and Date taken properties
    try {
        $param = @{
            FullName   = $Directory
            Properties = "Filename", "Path", "Date taken", "Media created"
            Recurse    = $Recurse
            Verbose    = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        }
        $FileResults = Get-sjExtendedMetaData @param
        #remove all files with yyyy\mm in the path
        $FileResults = $FileResults | Where-Object Path -notmatch '\d{4}\\\d{2}\\'
        $FilesWithoutDateTaken = $FileResults | Where-Object { -not ($_.'Date taken' -or $_.'Media created') }
        $FilesWithDateTaken = $FileResults |
        #if date taken remove unicode and use get-date to get year and month
        Where-Object { $_.'Date taken' } |
        #add Year and Month properties from Date taken property
        Foreach-Object {
            $Year = (Get-Date ($_.'Date taken' -replace '[^\x00-\x7F]', '')).Year
            $Month = "{0:00}" -f (Get-Date ($_.'Date taken' -replace '[^\x00-\x7F]', '')).Month
            $_ | Add-Member -NotePropertyName 'Year' -NotePropertyValue $Year -PassThru | Add-Member -NotePropertyName 'Month' -NotePropertyValue $Month -PassThru
        }
        $FilesWithMediaCreated = $FileResults |
        #if date taken remove unicode and use get-date to get year and month
        Where-Object { $_.'Media created' } |
        #add Year and Month properties from Date taken property
        Foreach-Object {
            $Year = (Get-Date ($_.'Media created' -replace '[^\x00-\x7F]', '')).Year
            $Month = "{0:00}" -f (Get-Date ($_.'Media created' -replace '[^\x00-\x7F]', '')).Month
            $_ | Add-Member -NotePropertyName 'Year' -NotePropertyValue $Year -PassThru | Add-Member -NotePropertyName 'Month' -NotePropertyValue $Month -PassThru
        }
    }
    catch {
        throw $_
    }
    #move file to a year\month folder
    foreach ($item in $FilesWithDateTaken + $FilesWithMediaCreated) {
        #check parent folder and keep if not "Camera Roll" or a year
        $CurrentDir = Split-Path -Path $item.Path
        if ($CurrentDir -match '(\d{4}|Camera Roll)') {
            $Path = "$OneDrive\Pictures\$($item.Year)\$($item.Month)"
            $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
            $ChildPath = $ChildPath -replace '(\d{4}|Camera Roll)'
            $DestinationPath = Join-Path -Path $Path -ChildPath $ChildPath
        }
        else {
            $Path = "$OneDrive\Pictures\$($item.Year)\$($item.Month)"
            $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
            $DestinationPath = Join-Path -Path $Path -ChildPath $ChildPath
        }
        if (-not(Test-Path -Path $DestinationPath)) {
            $null = New-Item -Path $DestinationPath -ItemType Directory -Force
        }
        Move-Item -Path $item.Path -Destination $DestinationPath -PassThru #-WhatIf
    }

    #move files with date/time in the name
    foreach ($item in $FilesWithoutDateTaken) {
        if ($item.Filename -match '20[0-2]\d{5}[-_]\d{4}') {
            $Year = $Matches[0].Substring(0, 4)
            $Month = $Matches[0].Substring(4, 2)
            $null = $item | Add-Member -NotePropertyName 'Year' -NotePropertyValue $Year -PassThru | Add-Member -NotePropertyName 'Month' -NotePropertyValue $Month -PassThru
            $CurrentDir = Split-Path $item.Path
            if ($CurrentDir -match '(^\d{4}|Camera Roll)') {
                $Path = "$OneDrive\Pictures\$($item.Year)\$($item.Month)"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $ChildPath = $ChildPath -replace '(^\d{4}|Camera Roll)'
                $DestinationPath = Join-Path -Path $Path -ChildPath $ChildPath
            }
            else {
                $Path = "$OneDrive\Pictures\$($item.Year)\$($item.Month)"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $DestinationPath = Join-Path -Path $Path -ChildPath $ChildPath
            }
            if (-not(Test-Path -Path $DestinationPath)) {
                $null = New-Item -Path $DestinationPath -ItemType Directory -Force
            }
            Move-Item -Path $item.Path -Destination $DestinationPath -PassThru #-WhatIf
        }
    }

    RemoveEmptyDirectory -FullName $Directory -Verbose

} # end function Move-PhotosToYearMonthFolder

Move-PhotosToYearMonthFolder -Directory "C:\Users\steve\OneDrive\Pictures\2001" -Recurse -Verbose