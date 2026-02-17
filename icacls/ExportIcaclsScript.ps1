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

function Get-CleanName {
  param([string]$Name)
  $clean = $Name -replace '[^A-Za-z0-9]', ''
  if (-not $clean) {
    throw -Message "Cleaned name for '$Name' is empty after removing non-alphanumeric characters." -Category InvalidArgument -ErrorAction Stop
  }
  return $clean
}

# Wait-Debugger
$DriveRoot = 'X:\'

if (-not (Test-Path -Path $DriveRoot)) {
  throw "Drive path $DriveRoot not found. Ensure X: is mapped and accessible."
}

# Determine script folder (where output files will be placed)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = Get-Location }

Write-Host "Export directory: $ScriptDir"

# 1) Export icacls for the root of the mapped drive
$driveLabel = Get-CleanName($DriveRoot)
$outFile = Join-Path $ScriptDir ("icaclsExportRoot_$driveLabel.acl")
Write-Host "Exporting icacls for '$DriveRoot' to '$outFile'"
icacls $DriveRoot /save $outFile /C

# 2) List all files in the root of X: and export icacls for each file
$fileList = Get-ChildItem -Path $DriveRoot -File -Force
foreach ($file in $fileList) {
  $clean = Get-CleanName($file.Name)
  if (-not $clean) { $clean = [System.IO.Path]::GetRandomFileName().Replace('.', '') }
  $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
  Write-Host "Exporting icalcs for '$($file.FullName)' to '$outFile'"
  icacls $file.FullName /save $outFile /C
}

# Helper scriptblock for recursive export used by jobs
$jobScript = {
  param($Path, $OutFile)
  icacls $Path /save $OutFile /T /C
}

# 3) For each directory in root, start a job exporting icacls recursively, except GEOLOGY
$rootDirs = Get-ChildItem -Path $DriveRoot -Directory -Force | Where-Object { $_.Name -ne 'GEOLOGY' }
foreach ($item in $rootDirs) {
  $clean = Get-CleanName($item.Name)
  if (-not $clean) { $clean = [System.IO.Path]::GetRandomFileName().Replace('.', '') }
  $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
  Write-Host "Starting job for directory '$item' to '$outFile'"
  Start-Job -Name "icaclsExport_$clean" -ScriptBlock $jobScript -ArgumentList $item.FullName, $outFile
}

# 4) Handle GEOLOGY specially (if present)
$geo = Get-Item -Path (Join-Path -Path $DriveRoot -ChildPath 'GEOLOGY')
if ($geo) {
  Write-Host "Handling directory: $($geo.FullName)"
  
  # Export icacls for files directly in GEOLOGY (non-recursive)
  $clean = Get-CleanName($geo.Name)
  $outFile = Join-Path $ScriptDir ("icaclsExportRoot_$clean.acl")
  Write-Host "Exporting directory '$($geo.FullName)' to '$outFile'"
  icacls $geo.FullName /save $outFile /C
  
  # Start a job for each subdirectory inside GEOLOGY (recursive)
  $dirList = Get-ChildItem -Path $geo.FullName -Directory -Force
  foreach ($dir in $dirList) {
    $clean = Get-CleanName($dir.Name)
    if (-not $clean) { $clean = [System.IO.Path]::GetRandomFileName().Replace('.', '') }
    $outFile = Join-Path $ScriptDir ("icaclsExportRoot_geo_$clean.acl")
    Write-Host "Starting job for GEOLOGY subdir '$($dir.FullName)' to '$outFile'"
    Start-Job -Name "icaclsExport_geo_$clean" -ScriptBlock $jobScript -ArgumentList $dir.FullName, $outFile
  }
  
}

Write-Host "All tasks started. Use `Get-Job` to view job status and `Receive-Job` to fetch outputs if desired.`n"
