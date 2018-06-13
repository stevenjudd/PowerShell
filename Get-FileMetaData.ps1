Function Get-FileMetaData
{
    #Requires -Version 2.0 
    <# 
        .Notes 
            Name:  Get-FileMetaData 
            Script: Get-FileMetaDataReturnObject.ps1 
            Author: ed wilson, msft 
            Last edit: 01/24/2014 14:08:24 
            Keywords: Metadata, Storage, Files 
            HSG: HSG-2-5-14 
            comments: Uses the Shell.APplication object to get file metadata 
            Gets all the metadata and returns a custom PSObject 
            it is a bit slow right now, because I need to check all 266 fields 
            for each file, and then create a custom object and emit it. 
            If used, use a variable to store the returned objects before attempting 
            to do any sorting, filtering, and formatting of the output. 
            To do a recursive lookup of all metadata on all files, use this type 
            of syntax to call the function: 
            Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
            note: this MUST point to a folder, and not to a file. 
        .Synopsis 
            This function gets file metadata and returns it as a custom PS Object  
        .Description 
            This function gets file metadata using the Shell.Application object and 
            returns a custom PSObject object that can be sorted, filtered or otherwise 
            manipulated. 
        .Example 
            Get-FileMetaData -folder "e:\music" 
            Gets file metadata for all files in the e:\music directory 
        .Example 
            Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName 
            This example uses the Get-ChildItem cmdlet to do a recursive lookup of  
            all directories in the e:\music folder and then it goes through and gets 
            all of the file metada for all the files in the directories and in the  
            subdirectories.   
        .Example 
            Get-FileMetaData -folder "c:\fso","E:\music\Big Boi" 
            Gets file metadata from files in both the c:\fso directory and the 
            e:\music\big boi directory. 
        .Example 
            $meta = Get-FileMetaData -folder "E:\music" 
            This example gets file metadata from all files in the root of the 
            e:\music directory and stores the returned custom objects in a $meta  
            variable for later processing and manipulation. 
        .Parameter Folder 
            The folder that is parsed for files  
        .Link 
            https://github.com/stevenjudd/PowerShell
    #>

    Param(
        [parameter(
            Mandatory = $false, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [Alias('directory', 'folder', 'file')]
        [string[]]$Name = $PWD.path
    )

    begin {}

    process
    {
        foreach ($sFolder in $Name)
        { 
            $a = 0
            $objShell = New-Object -ComObject Shell.Application 
            $objFolder = $objShell.namespace($sFolder) 
    
            foreach ($File in $objFolder.items())
            {
                Write-Verbose -Message "Getting extended file details on $($File.Name)"
                $FileMetaData = New-Object PSOBJECT
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
                $a = 0 
                $FileMetaData
            } #end foreach $file 
        } #end foreach $sfolder 
    } #end process
    
    end {}

} #end Get-FileMetaData

#test cases
#Get-FileMetaData -Name C:\Users\steve\OneDrive