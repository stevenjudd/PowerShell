# remove empty directories
# build list of empty directories
$Directory = 'C:\Users\steve\OneDrive\Pictures\Camera Roll\2018', 'C:\Users\steve\OneDrive\Pictures\Camera Roll\2019'
foreach ($dir in $Directory) {
    $DirList = Get-ChildItem $dir -Directory -Recurse
    foreach ($item in $DirList) {
        if ((Get-ChildItem $item).count -eq 0) {
            # Using Write-Host because in VSCode the WhatIf is not working on empty directories
            Write-Host "removing: $item"
            # Remove-Item $item #-WhatIf
        }
    }
}
