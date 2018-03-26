Function Get-sjExtendedMetaData
{
    #Requires -Version 2.0 
    <# 
    .Notes 
        Name:  Get-sjExtendedMetaData 
        Script: Get-sjExtendedMetaDataReturnObject.ps1 
        Author: ed wilson, msft 
        Modified by Steven Judd on 20180325 to:
            return MetaData on a single file, folder, or multiple files
            Accept file objects from the pipeline
            ensure that the file objects exist
            added Write-Progress to folders since the function is slow
            added additional attributes to return and confirm they have data
            added a -Recurse switch option to traverse folders
            added Write-Verbose output
        Last edit: 20180325
        Keywords: Metadata, Storage, Files 
        HSG: HSG-2-5-14 
        comments: Uses the Shell.APplication object to get file metadata 
        Gets all the metadata and returns a custom PSObject 
        it is a bit slow right now, because I need to check all 400 fields 
        for each file, and then create a custom object and emit it. 
        If used, use a variable to store the returned objects before attempting 
        to do any sorting, filtering, and formatting of the output. 
        To do a recursive lookup of all metadata on all files, use the -Recurse switch.
        Get-sjExtendedMetaData -FullName (gci e:\music).FullName -Recurse
        
    .Synopsis 
        This function gets file and folder metadata and returns it as a custom PS Object  
    .Description 
        This function gets file and folder metadata using the Shell.Application object and 
        returns a custom PSObject object that can be sorted, filtered or otherwise 
        manipulated. 
    .Example 
        Get-sjExtendedMetaData -FullName "e:\music" 
        Gets file metadata for all files in the e:\music directory 
    .Example 
        Get-sjExtendedMetaData -FullName (gci e:\music).FullName -Recurse
        This example uses the Get-ChildItem cmdlet to do a recursive lookup of  
        all directories in the e:\music folder and then it goes through and gets 
        all of the file metada for all the files in the directories and in the  
        subdirectories.   
    .Example 
        Get-sjExtendedMetaData -FullName "c:\fso","E:\music\Big Boi" 
        Gets file metadata from files in both the c:\fso directory and the 
        e:\music\big boi directory. 
    .Example 
        $meta = Get-sjExtendedMetaData -FullName "E:\music" 
        This example gets file metadata from all files in the root of the 
        e:\music directory and stores the returned custom objects in a $meta  
        variable for later processing and manipulation. 
    .Example 
        Get-ChildItem C:\Users\steve\OneDrive *.jpg | Get-sjExtendedMetaData
        This command will pass all of the JPG files in the OneDrive folder
        to the function, which will return the extended file information for
        each file.
    .Parameter FullName 
        The full path for the files or folders to return extended metadata. 
    .Link 
        https://github.com/stevenjudd/PowerShell
    #>

    Param(
        [parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true)]
        #[Alias('directory', 'folder', 'file')]
        [ValidateScript( {
                if (Test-Path $_)
                {
                    $true
                }
                else
                {
                    throw "Please enter a valid path. Unable to validate $_"
                }
            })]
        [string[]]$FullName = $PWD.path,

        [switch]$Recurse
    )

    begin
    {
        $objShell = New-Object -ComObject Shell.Application
    }

    process
    {
        foreach ($ArrayItem in $FullName)
        { 
            Write-Verbose "Analyzing: $ArrayItem"
            #is the item a folder?
            if ((Get-Item -Path $ArrayItem).PSIsContainer)
            {
                $a = 0
                $objFolder = $objShell.namespace($ArrayItem) 
                $numberOfItems = $objFolder.Items().count
                $currentFileNumber = 1
                foreach ($File in $objFolder.items())
                {
                    Write-Progress -Activity "Scanning folder $ArrayItem" -Status "Processing $currentFileNumber of $numberOfItems :: $([math]::Round($currentFileNumber / $numberOfItems * 100))% Complete " -PercentComplete ($currentFileNumber / $numberOfItems * 100)
                    Write-Verbose -Message "Getting extended file details: $($File.Name)"
                    $FileMetaData = New-Object PSOBJECT
                    $a = 0 
                    for ($a ; $a -le 400; $a++)
                    {
                        if ($objFolder.getDetailsOf($File, $a))
                        {
                            $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a)) = $($objFolder.getDetailsOf($File, $a)) }
                            if ($objFolder.getDetailsOf($objFolder.items, $a))
                            {
                                $FileMetaData | Add-Member $hash
                            }
                            $hash.clear()
                        } #end if 
                    } #end for  
                    $FileMetaData
                    #is the item a folder
                    if ($File.IsFolder)
                    {
                        if ($Recurse)
                        {
                            Get-sjExtendedMetaData -Name $File.Path -Recurse 
                        }
                    }
                    $currentFileNumber ++
                } #end foreach $file 
            } #end if ArrayItem is a container
            else #ArrayItem is not a container
            {
                $ArrayItemParent = Split-Path -Path $ArrayItem
                $objFolder = $objShell.namespace($ArrayItemParent)
                foreach ($File in $objFolder.items())
                {
                    #loop through items until ArrayItem
                    if ($ArrayItem -eq $File.Path)
                    {
                        Write-Verbose -Message "Getting extended file details: $($File.Name)"
                        $FileMetaData = New-Object PSOBJECT
                        $a = 0
                        for ($a ; $a -le 400; $a++)
                        {
                            if ($objFolder.getDetailsOf($File, $a))
                            {
                                $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a)) = $($objFolder.getDetailsOf($File, $a)) }
                                if ($objFolder.getDetailsOf($objFolder.items, $a))
                                {
                                    $FileMetaData | Add-Member $hash
                                }
                                $hash.clear()
                            } #end if 
                        } #end for  
                        $FileMetaData
                    } #end if ArrayItem -eq File
                } #end foreach File in ObjFolder.items
            } #end else (Name is not a container)
        } #end foreach ArrayItem in FullName
    } #end process
    
    end {}

} #end Get-sjExtendedMetaData

#test cases
#Get-sjExtendedMetaData -FullName C:\Users\steve\OneDrive\186.JPG -Verbose #file
#Get-sjExtendedMetaData -FullName C:\Users\steve\OneDrive\2016 -Verbose #folder
#Get-sjExtendedMetaData -FullName C:\Users\steve\OneDrive\2016 -Recurse -Verbose #folder recursive
#Get-sjExtendedMetaData -FullName ThisFileDoesNotExist.nope #file/folder that doesn't exist
#Get-sjExtendedMetaData -FullName C:\Users\steve\OneDrive\186.JPG, C:\Users\steve\OneDrive\187.JPG #multiple files
#Get-sjExtendedMetaData -FullName C:\Users\steve\OneDrive\186.JPG, C:\Users\steve\OneDrive\Vienna #multiple files and folders
#using pipeline
#Get-ChildItem C:\Users\steve\OneDrive *.jpg | Get-sjExtendedMetaData