function Get-sjNtfsPermissions {
  <#
  .SYNOPSIS
    Function to retrieve the unique NTFS permissions on a file or folder.
  .DESCRIPTION
    This function will take a filename or foldername and return the NTFS
    permissions for that item. It will also do a recursive search for 
    unique NTFS permissions starting at a specified folder. This function
    will accept values through the pipeline for the FullName parameter.
  .PARAMETER FullName
    This parameter is the filename or foldername to retrieve the NTFS
    permissions for. More than one filename or folder may be specified.
    This parameter will accept values through the pipeline by parameter name.

    The default value is the current directory ($PWD).
  .PARAMETER Recurse
    This switch parameter specifies whether to look for unique NTFS 
    permissions recursively starting at the specified folder. You must specify
    a folder as the FullName for this parameter.
  .EXAMPLE
    Get-sjNtfsPermissions
    This command will retrieve the NTFS permissions for the current directory.
  .EXAMPLE
    Get-sjNtfsPermissions -Recurse
    This command will retrieve the NTFS permissions for the current directory
    and the unique NTFS permissions for all items contained within the 
    current directory.
  .EXAMPLE
    Get-sjNtfsPermissions -Path ".","..\PowerShell_Versioning"
    This command will retrieve the NTFS permissions for the current directory
    and the PowerShell_Versioning directory.
  .EXAMPLE
    Get-ChildItem .. -Directory | Get-sjNtfsPermissions -Recurse -Verbose
    This command will list all of the files in the parent directory of the
    current directory and pass this result to the Get-sjNtfsPermissions function.
    Each item passed will output the NTFS permissions and be recursively
    scanned for items with unique NTFS permissions.
  .EXAMPLE
    Invoke-Command (Get-ADComputer -Filter {Name -like "*wbii*p"}).Name -ScriptBlock {. '\\odcnafsvs001p\judds$\documents\scripts\PowerShell\Functions\wip\Get-sjNtfsPermissions-Function.ps1';Get-sjNtfsPermissions c:\inetpub} | Export-Csv $env:TEMP\PermissionsAudit.csv -NoTypeInformation;& $env:TEMP\PermissionsAudit.csv
    This command uses Invoke-Command to load and execute the Get-sjNtfsPermissions
    function on the path C:\inetpub to all the servers containing "wbii" in the
    name, then it passes the results to Export-Csv to a file named
    PermissionsAudit.csv in the $env:TEMP location, and finally it loads the
    $env:TEMP\PermissionsAudit.csv file for viewing.
  .NOTES
    PowerShell function written to retrieve the NTFS permissions on a file,
      folder, or list of files and/or folders. This function will take
      parameters through the pipeline.
    Based upon a script by JFRMilner: https://jfrmilner.wordpress.com/2011/05/01/audit-ntfs-permissions-powershell-script/
    Written by Steven Judd on 2016/03/16
    Updated by Steven Judd on 2017/07/05 to modify the output property order to make the standard output more quickly readable
    Update comments going forward will be in the git commit messages.
    See https://github.com/stevenjudd/PowerShell for the latest version.
    
    Feature requests:
      Please put feature requests and issues at https://github.com/stevenjudd/PowerShell
  #>
  [CmdletBinding()]

  param (
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateScript({
        if (Test-Path -LiteralPath $_) {
          return $true
        } else {
          throw "Source '$_' is invalid."
        }
      })]
    [String[]]$FullName = $PWD,
    [Switch]$Recurse
  )

  begin {
    $outputProperties = @(
      'Path',
      'IdentityReference',
      'FileSystemRights',
      'AccessControlType',
      'IsInherited',
      'InheritanceFlags',
      'PropagationFlags'
    )
  }

  process {
    foreach ($item in $FullName) {
      Write-Verbose "Checking $item"
      #$root = Get-Item $item
      (Get-Acl -Path $item).Access |
        Add-Member -MemberType NoteProperty -Name 'Path' -Value $item -PassThru |
        Select-Object $outputProperties
      if ($Recurse -and (Get-Item -Path $item).PSIsContainer) {
        Write-Information "Building recursive file list for $item" -InformationAction Continue
        $childItem = Get-ChildItem -Path $item -Recurse
        if ($null -ne $childItem) {
          # add a write-progress command to show progress on large folder structures
          $fileCount = 1
          $fileTotal = $childItem.Count
          foreach ($subItem in $childItem) {
            Write-Progress -Activity "Processing items in $item" -Status "Processing $fileCount of $fileTotal" -PercentComplete (($fileCount / $fileTotal) * 100)
            Write-Verbose "Checking $($subItem.FullName)"
            (Get-Acl -Path $subItem.FullName).Access |
              Where-Object { $_.IsInherited -eq $false } |
              Add-Member -MemberType NoteProperty -Name 'Path' -Value $($subItem.fullname).ToString() -PassThru |
              Select-Object $outputProperties
            $fileCount++
          }
        } #end if $subItems -ne $null
      } #end if Recurse switch is set and item is a container
    } #end foreach item
  } #end process

  end {}

} #end function

# test cases
# Get-sjNtfsPermissions
# Get-sjNtfsPermissions -Verbose
# Get-sjNtfsPermissions -Recurse -Verbose
# Get-sjNtfsPermissions -FullName "$env:TEMP\TestFolder"
# Get-sjNtfsPermissions -FullName "$env:TEMP\TestFolder" -Recurse -Verbose
# Get-ChildItem C:\Temp | Get-sjNtfsPermissions -Recurse