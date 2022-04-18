function Move-sjPhotosToYearMonthFolder {

    # Count has a problem where it is counting before the filtering of the results
    # line 70 - 90

    # Test for the $OneDrive variable
    # Add Param for Destination root
    # Add help text block

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [Alias("FullName")]
        [string]$Directory = $PWD.Path,

        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string]$Destination = "$env:OneDriveConsumer\Pictures",

        [switch]$Recurse,
        
        [int]$Count
    )
    function RemoveEmptyDirectory {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipelineByPropertyName)]
            [string]
            $FullName,
            $Recurse
        )

        process {
            Write-Verbose "Processing Directory: $FullName"
            if ($Recurse) {
                if (Get-ChildItem -Path $FullName) {
                    foreach ($item in (Get-ChildItem -Path $FullName -Directory)) {
                        RemoveEmptyDirectory $item
                    }
                }
            }
            if (-not (Get-ChildItem -Path $FullName)) {
                Remove-Item -Path $FullName
            }
        }
    } #end function RemoveEmptyDirectory

    function RelocateFile {
        [CmdletBinding()]
        param (
            [string]$Source,
            [string]$Destination
        )

        Move-Item -Path $Source -Destination $Destination -PassThru
        Write-Verbose "Moved $Source"
        Write-Verbose "   To $Destination"
    }

    $CleanedDirectory = Join-Path (Split-Path -Path $Directory -Parent) (Split-Path -Path $Directory -Leaf)
    $CleanedDestination = Join-Path (Split-Path -Path $Destination -Parent) (Split-Path -Path $Destination -Leaf)
    

    # if ($env:OneDriveConsumer) {
    #     $OneDrive = $env:OneDriveConsumer
    # }
    # else {
    #     $OneDrive = $env:OneDrive
    # }

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
            $Path = "$Destination\$($item.Year)\$($item.Month)"
            $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
            $ChildPath = $ChildPath -replace '(\d{4}|Camera Roll)'
            $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
        }
        elseif ($CleanedDirectory -eq $CleanedDestination) {
            $FinalDestination = "$Destination\$($item.Year)\$($item.Month)"
        }
        else {
            $Path = "$Destination\$($item.Year)\$($item.Month)"
            $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
            $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
        }
        if (-not(Test-Path -Path $FinalDestination)) {
            $null = New-Item -Path $FinalDestination -ItemType Directory -Force
        }
        try {
            RelocateFile -Source $item.Path -Destination $FinalDestination -ErrorAction Stop
        }
        catch [System.IO.IOException] {
            $FinalDestination = "$Destination\IOException"
            RelocateFile -Source $item.Path -Destination $FinalDestination -ErrorAction Stop
        }
    }

    #move files with date/time in the name
    foreach ($item in $FilesWithoutDateTaken) {
        $CurrentDir = Split-Path $item.Path
        if ($item.Filename -match '20[0-2][0-9]\d{4}[-_]\d{4}') {
            $Year = $Matches[0].Substring(0, 4)
            $Month = $Matches[0].Substring(4, 2)
            $null = $item | Add-Member -NotePropertyName 'Year' -NotePropertyValue $Year -PassThru | Add-Member -NotePropertyName 'Month' -NotePropertyValue $Month -PassThru
            if ($CurrentDir -match '(^\d{4}|Camera Roll)') {
                $Path = "$Destination\$($item.Year)\$($item.Month)"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $ChildPath = $ChildPath -replace '(^\d{4}|Camera Roll)'
                $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
            }
            elseif ($CleanedDirectory -eq $CleanedDestination) {
                $FinalDestination = "$Destination\$($item.Year)\$($item.Month)"
            }
            else {
                $Path = "$Destination\$($item.Year)\$($item.Month)"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
            }
            if (-not(Test-Path -Path $FinalDestination)) {
                $null = New-Item -Path $FinalDestination -ItemType Directory -Force
            }
            RelocateFile -Source $item.Path -Destination $FinalDestination -ErrorAction Stop
        }
        else {
            if ($CurrentDir -match '(^\d{4}|Camera Roll)') {
                $Path = "$Destination\Unknown Date"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $ChildPath = $ChildPath -replace '(^\d{4}|Camera Roll)'
                $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
            }
            elseif ($CleanedDirectory -eq $CleanedDestination) {
                $FinalDestination = "$Destination\Unknown Date"
            }
            else {
                $Path = "$Destination\Unknown Date"
                $ChildPath = $CurrentDir -replace [regex]::Escape($RootDirectory)
                $FinalDestination = Join-Path -Path $Path -ChildPath $ChildPath
            }
            if (-not(Test-Path -Path $FinalDestination)) {
                $null = New-Item -Path $FinalDestination -ItemType Directory -Force
            }
            RelocateFile -Source $item.Path -Destination $FinalDestination -ErrorAction Stop
        }
    }

    RemoveEmptyDirectory -FullName $Directory -Recurse:$Recurse

} # end function Move-PhotosToYearMonthFolder

# test cases
# Move-sjPhotosToYearMonthFolder -Directory "C:\Users\steve\OneDrive\Pictures\Camera Roll" -Recurse -Verbose -Count 100
# Move-sjPhotosToYearMonthFolder -Directory "C:\Users\steve\OneDrive\Pictures\Camera Roll" -Verbose
# Move-sjPhotosToYearMonthFolder -Directory "C:\Users\steve\OneDrive\Pictures\Devon new bldg" -Recurse -Verbose