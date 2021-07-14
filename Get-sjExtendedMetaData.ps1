Function Get-sjExtendedMetaData {
    <# 
    .Notes 
        Based on script by Ed Wilson, msft 
        Modified by Steven Judd on 20180325 to:
            return MetaData on a single file, folder, or multiple files
            Accept file objects from the pipeline
            ensure that the file objects exist
            added Write-Progress to folders since the function is slow
            added additional attributes to return and confirm they have data
            added a -Recurse switch option to traverse folders
            added Write-Verbose output
        Modified by Steven Judd in Jan 2021 to do a bunch of stuff (see repo)
            took some ideas from Jaap Brasser for the Properties parameter:
                https://www.powershellmagazine.com/2015/04/13/pstip-use-shell-application-to-display-extended-file-attributes/
        Last edit: 20210123
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
        
        TODO:
            Add Filter parameter and filter the files based on the filter values
            Add Count parameter and limit the number of files returned to the count
    .Synopsis 
        This function gets file metadata and returns it as a custom PS Object.
    .Description 
        This function gets file and folder metadata using the Shell.Application object
        and returns a custom PSObject object that can be sorted, filtered or otherwise 
        manipulated. You must pass the full path to the object to evaluate due to how
        the Shell.Application namespace works. You can pass a file or directory or an
        array of files and/or directories. You can specify if you want to recurse
        through the directories. You can also specify which extended properties to
        return. Note, specifying only the properites you need reduces the time to return
        the results.
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
    .Example
        Get-sjExtendedMetaData -FullName (Get-ChildItem $HOME\OneDrive\Pictures *.jpg -Recurse).FullName -Verbose
        This command will use return all of the .jpg files in the OneDrive Pictures
        directory including subfolders and return all of the extended data. It will
        return verbose output for the function.
    .Example
        Get-sjExtendedMetaData -FullName $PWD.path -Properties "Name", "Date taken", "Size"
        This command will return the Name, Date taken, and Size extended properties for
        the current directory.
    .Parameter FullName 
        The full path for the files or folders to return extended metadata. 
    .Parameter Properties 
        Specify which properties for which to return extended metadata. Specifying only
        the properties required will reduce the time to return the results.
    .Parameter Recurse 
        Specify whether to return metadata on the objects recursively through
        the subfolders of any folders specified in the Fullname parameter.
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
                if (Test-Path $_) {
                    $true
                }
                else {
                    throw "Please enter a valid path. Unable to validate $_"
                }
            })]
        [string[]]$FullName = $PWD.path,

        [string[]]$Properties,

        [switch]$Recurse

        # [int]$Count
    )

    begin {
        $objShell = New-Object -ComObject Shell.Application

        function Get-FileExtProperties {
            param (
                [System.__ComObject]$FileObject
            )

            Write-Verbose -Message "Getting extended file details: $($FileObject.Path)"
            $FileMetaData = @{}
            foreach ($item in $FileExtProperties) {
                if ($objFolder.getDetailsOf($FileObject, $item.IndexNumber)) {
                    $FileMetaData.add($objFolder.getDetailsOf($objFolder.items, $item.IndexNumber), $objFolder.getDetailsOf($FileObject, $item.IndexNumber))
                } #end if 
            } #end foreach $item in $FileExtProperties
            [PSCustomObject]$FileMetaData
        }


        Write-Verbose "Building Extended File Attributes for current filesystem using $env:SystemRoot"
        $com = (New-Object -ComObject Shell.Application).NameSpace($env:SystemRoot)
        $FileExtProperties = for ($index = 0; $index -ne 400; $index++) {
            if ($Properties) {
                [PSCustomObject]@{
                    IndexNumber = $Index
                    Attribute   = $com.GetDetailsOf($com, $index)
                } | Where-Object { $_.Attribute -in $Properties }
            }
            else {
                [PSCustomObject]@{
                    IndexNumber = $Index
                    Attribute   = $com.GetDetailsOf($com, $index)
                } | Where-Object { $_.Attribute }
            }
        }

        # $ItemCount = 0
    } #end begin block

    process {
        foreach ($ArrayItem in $FullName) {
            Write-Verbose "Analyzing: $ArrayItem"
            #is the item a folder?
            if ((Get-Item -Path $ArrayItem).PSIsContainer) {
                $objFolder = $objShell.namespace($ArrayItem) 
                foreach ($File in $objFolder.items()) {
                    # if($Count -gt 0 -and $ItemCount -eq $Count){
                    #     return
                    # }
                    Write-Verbose -Message "Evaluating: $($File.Path)"
                    #is the item a folder
                    if ($File.IsFolder) {
                        if ($Recurse) {
                            if ($Properties) {
                                Get-sjExtendedMetaData -FullName $File.Path -Properties $Properties -Recurse
                            }
                            else {
                                Get-sjExtendedMetaData -FullName $File.Path -Recurse
                            }
                        }
                    } #end if $File.IsFolder
                    else {
                        Get-FileExtProperties -FileObject $File
                    }
                } #end foreach $file 
            } #end if ArrayItem is a container
            else {
                #ArrayItem is not a container
                $ArrayItemParent = Split-Path -Path $ArrayItem
                $objFolder = $objShell.namespace($ArrayItemParent)
                foreach ($File in $objFolder.items()) {
                    #loop through items until ArrayItem
                    if ($ArrayItem -eq $File.Path) {
                        Write-Verbose -Message "Getting extended file details: $($File.Name)"
                        Get-FileExtProperties -FileObject $File
                        #break out of foreach loop
                        break
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
# Get-sjExtendedMetaData -FullName (gi $HOME\OneDrive\Pictures\2019\gtfo2.png).FullName -Verbose
# Get-sjExtendedMetaData -FullName $PWD.path -Properties "Name", "Date taken", "Size"