param(
    [parameter(Mandatory)]
    [ValidateScript({
            if (Test-Path -Path $_ -PathType Container) {
                Return $true
            }
            else {
                Throw "ERROR: Not a valid Directory: $_"
            }
        })]
    [string]$Path,

    [switch]$WhatIf
)

$tempdir = Join-Path -Path $env:TEMP -ChildPath 'WhatIf'
Get-ChildItem -Path $Path -Filter '*.csv' | Copy-Item -Destination $tempdir -WhatIf:$WhatIf
