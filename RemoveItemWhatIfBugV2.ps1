$Directory = @(
    Join-Path $env:TEMP DoNotDeleteDir
    Join-Path "$HOME\OneDrive\Pictures\Camera Roll\2019" DoNotDeleteDir
    Join-Path "$HOME\OneDrive" DoNotDeleteDir
)
# $File = @(
#     Join-Path $env:TEMP DoNotDeleteFile
#     Join-Path "$HOME\OneDrive\Pictures\Camera Roll\2019" DoNotDeleteFile
#     Join-Path "$HOME\OneDrive" DoNotDeleteFile
# )

New-Item $Directory -ItemType Directory
Test-Path $Directory
Remove-Item $Directory -WhatIf
Test-Path $Directory

# New-Item $File -ItemType File
# Test-Path $File
# Remove-Item $File -WhatIf
# Test-Path $File
