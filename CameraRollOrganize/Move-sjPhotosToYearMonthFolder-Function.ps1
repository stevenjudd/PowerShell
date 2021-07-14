function Move-sjPhotosToYearMonthFolder {

    # Count has a problem where it is counting before the filtering of the results
    # line 70 - 90

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [Alias("FullName")]
        [string]$Directory = $PWD.Path,
        [switch]$Recurse,
        [int]$Count
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
    } #end function RemoveEmptyDirectory

    function RelocateFile {
        Move-Item -Path $item.Path -Destination $DestinationPath -PassThru #-WhatIf
        Write-Verbose "Moved $($item.Path)"
        Write-Verbose "   To $DestinationPath"
        Write-Verbose ""
    }

    # Get Verbose
    # get directory
    if ($env:OneDriveConsumer) {
        $OneDrive = $env:OneDriveConsumer
    }
    else {
        $OneDrive = $env:OneDrive
    }

    # replace dot directories with full paths
    if ($Directory -eq ".") {
        $Directory = $PWD.Path
    }
    elseif ($Directory -eq "..") {
        $Directory = Split-Path -Path $PWD.Path
    }
    
    $RootDirectory = Split-Path -Path $Directory
    #get extended metadate for Path and Date taken properties
    try {
        $param = @{
            FullName   = $Directory
            Properties = "Filename", "Path", "Date taken", "Media created"
            Recurse    = $Recurse
            # Verbose    = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        }
        # Wait-Debugger
        # Write-Host "Verbose:" $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        if ($Count -gt 0) {
            $FileResults = Get-sjExtendedMetaData @param | Select-Object -First $Count
        }
        else {
            $FileResults = Get-sjExtendedMetaData @param
        }
        
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
        try {
            Move-Item -Path $item.Path -Destination $DestinationPath -PassThru -ErrorAction Stop #-WhatIf
            Write-Verbose "Moved $($item.Path)"
            Write-Verbose "   To $DestinationPath"
            Write-Verbose ""
        }
        catch [System.IO.IOException] {
            $DestinationPath = "$OneDrive\Pictures\IOException"
            Move-Item -Path $item.Path -Destination $DestinationPath -PassThru #-WhatIf
            Write-Verbose "Moved $($item.Path)"
            Write-Verbose "   To $DestinationPath"
            Write-Verbose ""
        }
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
            Write-Verbose "Moved $($item.Path)"
            Write-Verbose "   To $DestinationPath"
            Write-Verbose ""
        }
        else {
            $DestinationPath = "$OneDrive\Pictures\Unknown Date"
            Move-Item -Path $item.Path -Destination $DestinationPath -PassThru #-WhatIf
            Write-Verbose "Moved $($item.Path)"
            Write-Verbose "   To $DestinationPath"
            Write-Verbose ""
        }
    }

    RemoveEmptyDirectory -FullName $Directory

} # end function Move-PhotosToYearMonthFolder

# test cases
Move-sjPhotosToYearMonthFolder -Directory "C:\Users\steve\OneDrive\Pictures\Camera Roll" -Recurse -Verbose -Count 10