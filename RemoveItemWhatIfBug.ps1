$Random = Get-Random
$Directory = Join-Path "$HOME\OneDrive" "DoNotDeleteDir$Random"
$File = Join-Path "$HOME\OneDrive" "DoNotDeleteFile$Random.txt"

New-Item $Directory -ItemType Directory
Test-Path $Directory
Remove-Item $Directory -WhatIf
Test-Path $Directory

New-Item $File -ItemType File
Test-Path $File
Remove-Item $File -WhatIf
Test-Path $File

#cleanup
Remove-Item $Directory, $File
Test-Path $Directory, $File