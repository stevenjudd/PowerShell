function Get-sjPassword {
    <#
    .NOTES
        PowerShell function written to retrieve a user's password from the registry 
        for use with scripts that need credentials.
        Written by Steven Judd, 2014/06/12
        Updated by Steven Judd on 2014/06/13
        Updated by Steven Judd on 2015/08/18 to add the option to retreive the 
            password from a file as well as the registry
        Updated by Steven Judd on 2019/10/27 to remove the File parameter, tighten up
            the code, make the Filename mandatory

        Version 20191027.1
        
        Feature requests:
            -
    .SYNOPSIS
        Script prompts for username and retrieves the plain text password from
        either the registry or a text file and returns a credential object.
    .DESCRIPTION
        This function either reads a specified text file or a Registry Key
        location based on the specified username. From either the file or the 
        Registry the encrypted password is loaded. It then returns the username
        and password as an object.

        The password must have been created by the current user on the current
        machine to be able to decrypt it.
    .PARAMETER UserName
        This parameter will specify the username to return the credentials. If
        no username is specified, the script will use the current user. 
    .PARAMETER FileName
        This parameter will specify the filename from which to get the encrypted
        credentials. This value is mandatory if the parameter is specified.
    .EXAMPLE
        Get-sjPassword
        This command will retrieve the password for the current user from the key
        HKCU:\Software\PasswordCache\[domain]\[username] in the registry.
    .EXAMPLE
        Get-sjPassword -UserName domain01\user01
        This command will retrieve the password for the user "user01" in the domain
        "domain01" from the key HKCU:\Software\PasswordCache\domain01\user01.
    .EXAMPLE
        Get-sjPassword -UserName test -Filename testPwd.txt
        This command will retrieve the password for the user "test" from the file
        "testPwd.txt" in the current directory.
    .OUTPUTS
        System.Management.Automation.PSCredential
    #>

    [CmdletBinding(DefaultParameterSetName = "Registry")]
    param (  
        [Parameter(Mandatory = $false,
            Position = 0,
            ParameterSetName = "Registry")]
        [Parameter(Mandatory = $false,
            Position = 0,
            ParameterSetName = "File")]
        [string]$UserName = "$env:userdomain\$env:username",	#current user with domain
        
        # [Parameter(Mandatory=$false,
        #            Position=1,
        #            ParameterSetName="File")]
        #     [switch]$File,

        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = "File",
            HelpMessage = "Enter a valid path and filename for the password file")]
        [ValidateScript( {
                if (Test-Path $_ -PathType Leaf) {
                    return $true
                }
                else {
                    #Test-Path check failed
                    throw "Destination $_ is invalid. Please enter the correct filename or run Set-sjPassword."
                }
            })]
        [string]$Filename #= "$env:TEMP\PasswordCache\$Username.txt"
    ) 

    if ($Filename) {
        Write-Verbose "FilePath -- $Filename"
    }
    else {
        $RegPath = "HKCU:\Software\sjPasswordCache\$UserName"
        Write-Verbose "Registry location for password: $RegPath"
    }

    if ($Filename) {
        #Get the password from the file specified
        try {
            Write-Verbose "Get password from File: $Filename"
            $Password = Get-Content -Path $Filename | ConvertTo-SecureString
            $Credential = New-Object System.Management.Automation.PsCredential($UserName, $Password)
            Return $Credential
        }
        catch {
            Write-Error $_
        }
    } #end if ($Filename)
    else {
        #Get the password from the default registry location
        if (Test-Path -Path $RegPath) {
            try {
                Write-Verbose "Get password from registry: $RegPath"
                [datetime]$PwdDateTime = (Get-ItemProperty -Path $RegPath).PSPasswordDate
                $PwdAge = (Get-Date) - $PwdDateTime
                Write-Verbose "The password is $($PwdAge.Days) old"
            
                $Password = (Get-ItemProperty -Path $RegPath).PSPasswordString | ConvertTo-SecureString
                $Credential = New-Object System.Management.Automation.PsCredential($UserName, $Password)
                Return $Credential
            }
            catch {
                Write-Error $_
            }
        } #end if (Test-Path -Path $RegPath)
        else {
            Write-Error "Unable to find password entry for $UserName. Please confirm the username and/or run Set-sjPassword."
        }
    }

} #end function Get-sjPassword

#Test commands
# Get-sjPassword
# Get-sjPassword -UserName test -Verbose
# Get-sjPassword -UserName test -Filename testPwd.txt -Verbose
# Get-sjPassword -Filename -Verbose
