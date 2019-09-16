$test1 = "$env:temp\test1"
$test2 = "$env:temp\test2"

$test1 = (Join-Path -Path $HOME -ChildPath OneDrive) | Join-Path -ChildPath "test"
try {
    New-Item $test1 -ItemType Directory -ErrorAction Stop
    New-Item $test2 -ItemType Directory -ErrorAction Stop
}
catch {
    throw $_
}

1..5 | ForEach-Object { New-Item -Path (Join-Path -Path $test1 -ChildPath "File$_.txt") -ItemType File -Force }
2..5 | ForEach-Object { Copy-Item -Path (Join-Path -Path $test1 -ChildPath "File$_.txt") -Destination $test2 -Force }
6 | ForEach-Object { New-Item -Path (Join-Path -Path $test2 -ChildPath "File$_.txt") -ItemType File -Force }

Add-Content -Value "New Content in source" -Path (Join-Path -Path $test1 -ChildPath "File3.txt") -PassThru
Add-Content -Value "New Content in destination" -Path (Join-Path -Path $test2 -ChildPath "File4.txt") -PassThru
