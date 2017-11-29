Function Update-sjFileString 
{

    #requires -version 2

    <#
    .NOTES
        Version: 20150323.1

        Update-sjFileString-Function.ps1
        Written by Bill Stewart (bstewart@iname.com)
        Converted to Function by Steven Judd

        Replaces strings in files using a regular expression. Supports
        multi-line searching and replacing.

        Future Enhancements:
            1. (none at this time)

        Updates:
            2015-03-23 updated by Steven Judd to validate Encoding variable with ValidateSet in the param section
            2015-03-23 updated by Steven Judd to output the filename to confirm the completion of the -Overwrite command

    .SYNOPSIS
        Replaces strings in files using a regular expression.

    .DESCRIPTION
        Replaces strings in files using a regular expression. Supports
        multi-line searching and replacing.

    .PARAMETER Pattern
        Specifies the regular expression pattern.

    .PARAMETER Replacement
        Specifies the regular expression replacement pattern.

    .PARAMETER Path
        Specifies the path to one or more files. Wildcards are permitted. Each
        file is read entirely into memory to support multi-line searching and
        replacing, so performance may be slow for large files.

    .PARAMETER LiteralPath
        Specifies the path to one or more files. The value of the this
        parameter is used exactly as it is typed. No characters are interpreted
        as wildcards. Each file is read entirely into memory to support
        multi-line searching and replacing, so performance may be slow for
        large files.

    .PARAMETER CaseSensitive
        Specifies case-sensitive matching. The default is to ignore case.

    .PARAMETER Multiline
        Changes the meaning of ^ and $ so they match at the beginning and end,
        respectively, of any line, and not just the beginning and end of the
        entire file. The default is that ^ and $, respectively, match the
        beginning and end of the entire file.

    .PARAMETER UnixText
        Causes $ to match only linefeed (\n) characters. By default, $ matches
        carriage return+linefeed (\r\n). (Windows-based text files usually use
        \r\n as line terminators, while Unix-based text files usually use only
        \n.)

    .PARAMETER Overwrite
        Overwrites a file by creating a temporary file containing all
        replacements and then replacing the original file with the temporary
        file. The default is to output but not overwrite.

    .PARAMETER Force
        Allows overwriting of read-only files. Note that this parameter cannot
        override security restrictions.

    .PARAMETER Encoding
        Specifies the encoding for the file when -Overwrite is used. Possible
        values are: ASCII, BigEndianUnicode, Unicode, UTF32, UTF7, or UTF8. The
        default value is ASCII.

    .INPUTS
        System.IO.FileInfo.

    .OUTPUTS
        System.String without the -Overwrite parameter, or nothing with the
        -Overwrite parameter.

    .LINK
        about_Regular_Expressions

    .EXAMPLE
        C:\>Update-sjFileString.ps1 '(Ferb) and (Phineas)' '$2 and $1' Story.txt
        This command replaces the string 'Ferb and Phineas' with the string
        'Phineas and Ferb' in the file Story.txt and outputs the file. Note
        that the pattern and replacement strings are enclosed in single quotes
        to prevent variable expansion.

    .EXAMPLE
        C:\>Update-sjFileString.ps1 'Perry' 'Agent P' Ferb.txt -Overwrite
        This command replaces the string 'Perry' with the string 'Agent P' in
        the file Ferb.txt and overwrites the file.

    .EXAMPLE
        C:\>Get-ChildItem *.log | where length -lt 1000 | Update-sjFileString.ps1 -Pattern "LOGGING" -Replacement "Logged" -Overwrite
        This command will list all the .log files that are smaller than 1000 bytes and replace "LOGGING" with "Logged"

    .EXAMPLE
        C:\>Get-ChildItem -Filter "*.config" -r | Select-String "old.?name" | foreach {Update-sjFileString -Path $_.path -Pattern "old.?name" -Replacement "new-name" -Overwrite}
        This command finds all the ".config" files, passes that to Select-String to look for either "oldname" or "old.name" and for each of the files that this is true, 
        replaces the string with the string "new-name" and commits this change (-Overwrite).

    #>

    [CmdletBinding(DefaultParameterSetName="Path",
                SupportsShouldProcess=$TRUE)]
    param(
        [parameter(Mandatory=$TRUE,
                   Position=0)]
        [String] $Pattern,

        [parameter(Mandatory=$TRUE,
                   Position=1)]
        [String] [AllowEmptyString()] $Replacement,

        [parameter(Mandatory=$TRUE,
                   ParameterSetName="Path",
                   Position=2,
                   ValueFromPipeline=$TRUE)]
        [String[]] $Path,

        [parameter(Mandatory=$TRUE,
                ParameterSetName="LiteralPath",
                Position=2)]
        [String[]] $LiteralPath,

        [Switch] $CaseSensitive,

        [Switch] $Multiline,

        [Switch] $UnixText,

        [Switch] $Overwrite,

        [Switch] $Force,

        [ValidateSet("ASCII","BigEndianUnicode","Unicode","UTF32","UTF7","UTF8")]
        [String] $Encoding="ASCII"
    )

    begin
    {
        # Extended test-path function: Check the parameter set name to see whether to use -LiteralPath or not.
        function Test-PathExtended ($Path)
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                "Path" 
                {
                    Test-Path -Path $Path
                }
                "LiteralPath" 
                {
                    Test-Path -LiteralPath $path
                }
            } #end switch on $PSCmdlet.ParameterSetName
        } #end function 

        # Extended get-childitem function: Check the parameter set name to see whether to use -LiteralPath or not.
        function Get-ChildItemExtended ($path) 
        {
            switch ($PSCmdlet.ParameterSetName)
            {
                "Path" 
                {
                    Get-ChildItem -Path $Path -Force
                }
                "LiteralPath" 
                {
                    Get-ChildItem -LiteralPath $Path -Force
                }
            } #end switch on $PSCmdlet.ParameterSetName
        } #end function

        #Function to output the full name of a temporary file in the specified path.
        function Get-TempFileName ($Path)
        {
            #the Do-While loop ensures that the filename genereated by GetRandomFilename does not exist
            do 
            {
                $TempFileName = Join-Path -Path $Path -ChildPath ([IO.Path]::GetRandomFilename())
            }
            while (Test-Path -Path $TempFileName)
            $TempFileName
        }

        # Use '\r$' instead of '$' unless -UnixText specified because
        # '$' alone matches '\n', not '\r\n'. Ignore '\$' (literal '$').
        if (-not $UnixText) 
        {
            $Pattern = $Pattern -replace '(?<!\\)\$', '\r$'
        }

        # Build an array of Regex options and create the Regex object.
        $Opts = @()
        if (-not $CaseSensitive) { $Opts += "IgnoreCase" }
        if ($MultiLine) { $Opts += "Multiline" }
        if ($Opts.Length -eq 0) { $Opts += "None" }
        $RegEx = New-Object -TypeName Text.RegularExpressions.Regex -ArgumentList $Pattern, $Opts

    } #end Begin block

    process
    {
        # The list of items to iterate depends on the parameter set name.
        switch ($PSCmdlet.ParameterSetName)
        {
            "Path" 
            { 
                $List = $Path 
            }
            "LiteralPath" 
            { 
                $List = $LiteralPath 
            }
        }

        # Iterate the items in the list of paths. If an item does not exist, continue to the next item in the list.
        foreach ($Item in $List) 
        {
            if (Test-PathExtended $Item) 
            {
                # Iterate each item in the path. If an item is not a file, skip all remaining items.
                foreach ($File in Get-ChildItemExtended  $Item) 
                {
                    if ($File -is [IO.FileInfo]) 
                    {
                        # Get a temporary file name in the file's directory and create
                        # it as a empty file. If Set-Content fails, continue to the next
                        # file. Better to fail before than after reading the file for
                        # performance reasons.
                        if ($Overwrite) 
                        {
                            $TempFileName = Get-TempFileName -Path $File.DirectoryName
                            Set-Content -Path $TempFileName -Value $NULL -Confirm:$FALSE
                            #check to see if the Set-Content command was successful
                            if (-not $?)
                            {
                                #use the continue command to go to the next item in the "foreach($Item in List)" loop
                                continue 
                            }
                            Write-Verbose -Message "Created file '$TempFileName'"
                        } #end if $Overwrite

                        # Read all the text from the file into a single string in order to be able to search across line breaks.
                        try 
                        {
                            Write-Verbose -Message "Reading '$File'"
                            $FileContents = [IO.File]::ReadAllText($File.FullName)
                            #$FileContents = Get-Content $file.FullName -Raw #-Raw is PowerShell 3.0 and higher
                            Write-Verbose -Message "Finished reading '$File'"
                        }
                        catch [Management.Automation.MethodInvocationException] 
                        {
                            Write-Error -Message $Error[0]
                            #use the continue command to go to the next item in the "foreach($Item in List)" loop
                            continue
                        }

                        # If -Overwrite not specified, output the result of the Replace method and continue to the next file.
                        if (-not $Overwrite) 
                        {
                            Write-Output $RegEx.Replace($FileContents, $Replacement)
                            #use the continue command to go to the next item in the "foreach($Item in List)" loop
                            continue
                        }

                        if ($WhatIfPreference)
                        {
                            #use the continue command to go to the next item in the "foreach($Item in List)" loop
                            continue
                        }

                        try 
                        {
                            Write-Verbose -Message "Writing '$TempFileName'"
                            [IO.File]::WriteAllText("$TempFileName", $RegEx.Replace($FileContents,$Replacement), [Text.Encoding]::$Encoding)
                            Write-Verbose -Message "Finished writing '$TempFileName'"
                            Write-Verbose -Message "Copying '$TempFileName' to '$file'"
                            Copy-Item $TempFileName $File -force:$Force -ErrorAction Continue
                            if ($?) #if the Copy-Item command was successful
                            {
                                Write-Verbose -Message "Finished copying '$TempFileName' to '$File'"
                                #output message that show the file has been updated
                                Write-Output "$File has been successfully updated"
                            }
                            else
                            {
                                Write-Error -Message "Error copying updated content to $File"
                            }
                            Remove-Item -Path $TempFileName -ErrorAction Continue
                            if ($?) #if the Remove-Item command was successful
                            {
                                Write-Verbose -Message "Removed file '$TempFileName'"
                            }
                            else
                            {
                                Write-Error -Message "Error removing temporary file $TempFileName"
                            }
                        }
                        catch [Management.Automation.MethodInvocationException] 
                        {
                            Write-Error -Message $Error[0]
                        }
                    } #end if $File -is [IO.FileInfo]
                    else
                    {
                        Write-Error -Message "'$file' is not in the file system."
                    }
                } #end foreach $file
            } #end if Test-PathExtended $Item
            else
            {
                Write-Error -Message "Unable to find '$Item'"
            }
        } #end foreach $item
    } #end process

    end { }

} #end Update-sjFileString function