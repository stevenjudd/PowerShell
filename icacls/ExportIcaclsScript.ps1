<#
.SYNOPSIS
    Export icacls for mapped drive X:, files in the root, and directories as requested.

    Behavior:
    - Exports icacls for X:\ (recursive) to a file in the script folder.
    - Exports icacls for every file at X:\ root to separate files.
    - Starts a PowerShell job for each directory at X:\ root (recursive), except `GEOLOGY`.
    - For `GEOLOGY`: exports icacls for files in GEOLOGY (root of GEOLOGY) and
      starts a job for each subdirectory in GEOLOGY that exports that subdirectory recursively.

    Output files are created in the same directory the script is run from, named
    `icaclsExportRoot_<CleanName>.acl` where non-alphanumeric characters are removed from <CleanName>.
#>

function Set-CleanName {
  param([string]$Name)
  return ($Name -replace '[^A-Za-z0-9]', '')
}

$DriveRoot = 'X:\'

if (-not (Test-Path -Path $DriveRoot)) {
  throw "Drive path $DriveRoot not found. Ensure X: is mapped and accessible."
}

# Determine script folder (where output files will be placed)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = Get-Location }

Write-Host "Export directory: $ScriptDir"

# 1) Export icacls for the root of the mapped drive (recursive)
$driveLabel = Set-CleanName($DriveRoot)
$outFile = Join-Path $ScriptDir ("icaclsExportRoot_$driveLabel.acl")
Write-Host "Exporting icacls for '$DriveRoot' to '$outFile'"
icacls $DriveRoot /save $outFile /C

# 2) List all files in the root of X: and export icacls for each file
Get-ChildItem -Path $DriveRoot -File -Force | ForEach-Object {
  $clean = Set-CleanName($_.Name)
  if (-not $clean) { $clean = [System.IO.Path]::GetRandomFileName().Replace('.', '') }
  $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
  Write-Host "Exporting file:`t$($_.FullName) -> $outFile"
  icacls $_.FullName /save $outFile /C
}

# Helper scriptblock for recursive export used by jobs
$jobScript = {
  param($Path, $OutFile)
  icacls $Path /save $OutFile /T /C
}

# 3) For each directory in root, start a job exporting icacls recursively, except GEOLOGY
$rootDirs = Get-ChildItem -Path $DriveRoot -Directory -Force
$geo = $rootDirs | Where-Object { $_.Name -ieq 'GEOLOGY' } | Select-Object -First 1

foreach ($d in $rootDirs) {
  if ($geo -and ($d.FullName -eq $geo.FullName)) { continue }
  $clean = Set-CleanName($d.Name)
  if (-not $clean) { $clean = 'dir' }
  $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
  Write-Host "Starting job for directory:`t$d -> $outFile"
  Start-Job -ScriptBlock $jobScript -ArgumentList $d.FullName, $outFile | Out-Null
  
}

# 4) Handle GEOLOGY specially (if present)
if ($geo) {
  Write-Host "Handling GEOLOGY: $($geo.FullName)"
  
  # Export icacls for files directly in GEOLOGY (non-recursive)
  Get-ChildItem -Path $geo.FullName -File -Force | ForEach-Object {
    $clean = Set-CleanName($_.Name)
    if (-not $clean) { $clean = 'file' }
    $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
    Write-Host "Exporting GEOLOGY file:`t$($_.FullName) -> $outFile"
    icacls $_.FullName /save $outFile /C
  }
  
  # Start a job for each subdirectory inside GEOLOGY (recursive)
  Get-ChildItem -Path $geo.FullName -Directory -Force | ForEach-Object {
    $clean = Set-CleanName($_.Name)
    if (-not $clean) { $clean = 'geodir' }
    $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
    Write-Host "Starting job for GEOLOGY subdir:`t$($_.FullName) -> $outFile"
    Start-Job -ScriptBlock $jobScript -ArgumentList $_.FullName, $outFile | Out-Null
    }
  
}

Write-Host "All tasks started. Use `Get-Job` to view job status and `Receive-Job` to fetch outputs if desired.`n"
