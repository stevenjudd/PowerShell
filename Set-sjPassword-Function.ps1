function Set-sjPassword {
    <#
    .NOTES
        PowerShell function written to store a username and password in the registry 
        or in a file for use with scripts that need credentials
        Written by Steven Judd, 2014/06/11
        Updated by Steven Judd on 2014/06/11
        Updated by Steven Judd on 2015/04/13 
        Updated by Steven Judd on 2015/08/17 to add the option to store the password
            in a file instead of the registry
        Updated by Steven Judd on 2019/10/26 to remove the File parameter, tighten up
            the code, make the Filename mandatory
        Updated by Steven Judd on 2019/10/27 to add a Clixml switch parameter to allow
            taking the credentials specified and export a PSCredential object into the
            FileName specified.

        Version 20191027.1
        
        Feature requests:
            -
    .SYNOPSIS
        Gets username and password and stores it in either the registry or a text
        file as secure text
    .DESCRIPTION
        This is a very basic function that prompts for the username and password by
        using the Get-Credential command. It takes the input, converts the password
        to secure string, and either creates a Registry Key location based on the 
        username to store the username, password, and the date and time of when the
        password was created, or it creates a specified file and stores the password
        in that file.

        The purpose for creating a file is that the registry keys for HKCU are not
        available if the user is not logged on. Thus if you want to create an automation
        where the username and password are retrieved without the user being logged on
        you will need to use the Filename parameter to create a file with the password.

        The password that is stored can only be accessed by the person that created
        it on the machine where they created it.
    .LINK
        http://notspecified
    .PARAMETER UserName
        This parameter will specify the username to prompt for the credentials. If
        no username is specified, the script will use the current user.
    .PARAMETER FileName
        This parameter will specify the filename into which to save the encrypted
        credentials. This value is mandatory if the parameter is specified.
    .PARAMETER Clixml
        This switch parameter will export the credentials gathered into the filename 
        specified in the FileName parameter using Export-Clixml. It will store the 
        username and the encrypted password in the file.
    .EXAMPLE
        Set-sjPassword
        This command will prompt for the password for the current user and store the
        resulting information under the key HKCU:\Software\PasswordCache in
        the registry.
    .EXAMPLE
        Set-sjPassword -UserName domain01\user01
        This command will prompt for the password for the user "user01" in the 
        domain "domain01" and store the resulting information under the key 
        HKCU:\Software\PasswordCache\domain01\user01 in the registry.
    .EXAMPLE
        Set-sjPassword -UserName test -Filename testPwd.txt -Verbose
        This command will prompt for the password for the user "test" and put the
        encrypted password into a file named "testPwd.txt" in the current directory.
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

        [Parameter(Mandatory = $true,
            Position = 1,
            ParameterSetName = "File",
            HelpMessage = "Enter a valid path and filename for the password file")]
        [string]$Filename,

        [Parameter(Mandatory = $false,
            Position = 2,
            ParameterSetName = "File")]
        [switch]$Clixml
    )

    Write-Verbose "Get Username and password"
    $Cred = Get-Credential -UserName $UserName -Message "Enter the username and password"

    if (!$Cred) {
        #if Cancel was clicked on the credential prompt
        Write-Warning "Script cancelled"
        Return
    }

    if ($Cred.Password.Length -gt 0) {
        $Password = ConvertFrom-SecureString -SecureString $Cred.Password
    }
    else {
        #password is blank
        Write-Warning "Password is blank. This is insecure and will most likely be an issue."
    }

    $CredUserName = $Cred.UserName
    Write-Verbose "UserName -- $CredUserName"

    [datetime]$currDateTime = Get-Date
    Write-Verbose "DateTime -- $currDateTime"

    if ($Filename) {
        Write-Verbose "FilePath -- $Filename"
    }
    else {
        $RegPath = "HKCU:\Software\sjPasswordCache\$CredUserName"
        Write-Verbose "RegPath  -- $RegPath"
    }

    if ($Filename) {
        Write-Verbose "Password file creation and/or update"
        if (-not(Test-Path -Path $Filename)) {
            try {
                Write-Verbose "Creating password file -- $Filename"
                New-Item -Path $Filename -ItemType File -Force | Write-Verbose
            }
            catch {
                throw $_
            }
        } #end if (-not(Test-Path -Path $Filename))

        try {
            Write-Verbose "Writing password to file -- $Filename"
            if ($Clixml) {
                $Cred | Export-Clixml -Path $Filename -Force
            }
            else {
                Out-File -FilePath $Filename -InputObject $Password -Force
            }
            Write-Verbose "Contents of $Filename -- $(Get-Content $Filename)"
        }
        catch {
            throw $_
        }
    } #end if ($Filename)

    else {
        Write-Verbose "Password registry creation and/or update"
        if (Test-Path -Path $RegPath) {
            try {
                Write-Verbose "Set registry values"
                Set-ItemProperty -Path $RegPath -Name PSUserName -Value $UserName
                Get-ItemProperty -Path $RegPath -Name PSUserName | Write-Verbose
                Set-ItemProperty -Path $RegPath -Name PSPasswordString -Value $Password
                Get-ItemProperty -Path $RegPath -Name PSPasswordString | Write-Verbose
                Set-ItemProperty -Path $RegPath -Name PSPasswordDate -Value $currDateTime
                Get-ItemProperty -Path $RegPath -Name PSPasswordDate | Write-Verbose
            }
            catch {
                throw $_
            }
        } #end if
        else {
            try {
                Write-Verbose "Create registry values"
                New-Item -Path $RegPath -Force | Write-Verbose
                New-ItemProperty -Path $RegPath -Name PSUserName -Value $UserName | Write-Verbose
                New-ItemProperty -Path $RegPath -Name PSPasswordDate -Value $currDateTime | Write-Verbose
                New-ItemProperty -Path $RegPath -Name PSPasswordString -Value $Password | Write-Verbose
            }
            catch {
                throw $_
            }
        }
    }
    #endregion

} #end function

#Test commands
# Set-sjPassword
# Set-sjPassword -UserName test -Verbose
# Set-sjPassword -UserName test -Filename (Join-Path -Path $env:temp -ChildPath "testPwd.txt") -Verbose
# Set-sjPassword -UserName test -Filename (Join-Path -Path $env:temp -ChildPath "testPwd.txt") -Clixml -Verbose
# Set-sjPassword -Filename -Verbose
