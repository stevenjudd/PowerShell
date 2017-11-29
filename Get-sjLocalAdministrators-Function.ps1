Function Get-sjLocalAdministrators
{

    #################################
    <#
    .NOTES
        Steve Schofield  
        http://weblogs.asp.net/steveschofield/archive/2009/01/08/list-local-administrators-on-a-machine-using-powershell-adsi.aspx  
        Modified by Steven Judd to be a function, add a parameter for computername, and output result as an object
        Updated by Steven Judd on 8/13/2014 to be a function
        Version 20140813.1 (please use yyyymmdd.x notation)
    .SYNOPSIS
        Function to list the local admins of a computer
    .DESCRIPTION
        This function will connect to a computer or a list of computers and return
        a list of users or groups that are part of the local "administrators" group.
    .LINK
        https://github.com/stevenjudd/PowerShell
    .PARAMETER Name
        This is either a single computername or an array of computer names. It can
        take a value from the pipeline. It also supports the alias of computername
        and host. By default it will use the value of $env:computername.
    .EXAMPLE
        Get-sjLocalAdministrators
        This command runs the script and will prompt for the names of the computers 
        the return the local administrators.
    .EXAMPLE
        Get-sjLocalAdministrators -Name server1,server2
        This command runs the script and will return the local administrators of
        the "server1" and "server2" computers.
    .EXAMPLE
        Get-sjLocalAdministrators -Name (Get-Content .\serverlist.txt)
        This command runs the script and will return the local administrators of
        the computer names found in the file serverlist.txt.
    .EXAMPLE
        Get-ADComputer | Get-sjLocalAdministrators
        This command uses the ActiveDirectory cmdlet Get-ADComputer to connect to
        Active Directory and return all of the computernames. It pipes the Name
        field to Get-sjLocalAdministrators, returning all the local administrator 
        accounts for all computers in the domain.
    #>
    #################################

    Param(
        [parameter(
            Mandatory=$false, 
            ValueFromPipeline=$true, 
            ValueFromPipelineByPropertyName=$true)]
        [Alias('host','computername')]
        [String[]]$Name	= $env:COMPUTERNAME #Specify the Computernames to check RDP sessions
    )
    
    Begin{}

    Process
    {
        Foreach ($pc in $Name)
        {
            $computerObj = [ADSI]("WinNT://" + $pc + ",computer")
            $Group = $computerObj.psbase.children.find("Administrators")
            $members= $Group.psbase.invoke("Members") | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
            
            foreach($user in $members)
            {
                $Results=[ordered]@{
                        'ComputerName'=$pc;
                        'LocalAdmin'=$user
                        }
                $Obj=New-Object -TypeName PSObject -Property $Results 
                Write-Output $Obj

            } #end foreach $user in $members

        } #end foreach $pc in $name
    } #end process

    End{}

} #end Get-sjLocalAdministrators Function