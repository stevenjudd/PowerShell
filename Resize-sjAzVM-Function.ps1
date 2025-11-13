function Resize-sjAzVM {

  #Requires -Modules Az.Compute
    
  <#
    .NOTES
        Function written to update the size of a VM
        Written by Steven Judd on 2018/06/12
        Version 20180613
        Updated by Steven Judd on 2018/06/13 to:
            enabled the WhatIf switch
            added VM status check and if running require a Force parameter
        Updated by Steven Judd on 2020/06/18 to:
            Use the Az module instead of AzureRM module
            Changed the if statement to go to the code execution section if WhatIf is enabled
            Moved code inside the WhatIf to speed up execution using WhatIf switch
    
        Add Features:
            Replace the (commented out) ValidateScript code on the parameters with dynamic parameter code
            Add check if new size is same as current size
    
    .SYNOPSIS
        Function written to update the size of a VM
    .DESCRIPTION
        This function will update the VM size of a specified VM. It can take VM objects
        passed through the pipeline and update multiple VMs to the same size. If the 
        VM is running you can update it through the use of the Force parameter.
        This function will not traverse subscriptions. You must be in the Azure
        subscription context where the VM is located.
    .LINK
        https://github.com/stevenjudd/powershell
    .PARAMETER ResourceGroupName
        The Resource Group where the VM is located. The underlying command that updates
        the VM size requires the Resource Group where the VM is located be specified.
    .PARAMETER VMName
        The name of the VM to resize.
    .PARAMETER VMSize
        The Azure name for the size of the VM. Be sure and specify a size that is 
        available in the region for the VM.
    .PARAMETER Force
        Setting the Force parameter will have the function resize a running VM. There
        is no confirm prompt so be sure the restarting of the server will not cause
        an unplanned outage (CLM/RGE).
    .EXAMPLE
        Resize-sjAzVM -ResourceGroupName "RG_DataFactoryGateway" -VMName "azumsmggw001p" -VMSize "Standard_D2s_v3"
    
        This command will resize the VM 'azumsmggw001p' in the RG_DataFactoryGateway 
        resource group to the 'Standard_D2s_v3' VM size. If the VM is running the 
        command will generate a warning message and not resize the VM.
    .EXAMPLE
        Resize-sjAzVM -ResourceGroupName "RG_DataFactoryGateway" -VMName "azumsmggw001p" -VMSize "Standard_D2s_v3" -Force -Verbose
    
        This command will resize the VM 'azumsmggw001p' in the RG_DataFactoryGateway 
        resource group to the 'Standard_D2s_v3' VM size. It will update the VM even if
        it is in a running state due to the Force parameter being set. The output will 
        include verbose messages.
    .EXAMPLE
        Get-AzVM | where {$_.HardwareProfile.VmSize -match 'd2s'} | Resize-sjAzVM -VMSize "Standard_D2s_v3"
        
        This command uses the output of the Get-AzVM command where the VM size has
        'd2s' in the name of the size and passes this down the pipeline to the 
        Resize-sjAzVM function. This is an example of how to use the pipeline to 
        pass VMs to be resized. For example, if the goal was to change all of the 
        Standard_D2_v2 servers to the Standard_D2_v3 size.
        NOTE: This is a dangerous command example so use with caution.
    #>
    
  [CmdletBinding(SupportsShouldProcess = $True)]
  param(
    [Parameter(Mandatory, Position, ValueFromPipelineByPropertyName)]
    <#
            [ValidateScript({
                If (Get-AzResourceGroup -Name $_)
                {
                    $True
                }
                Else
                {
                    Throw "Unable to locate the specified Resource Group: '$_'"
                }
            })]
            #>
    [string]$ResourceGroupName, #resource group where the VM is located
    
    [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
    <#
            [ValidateScript({
                If (Get-AzVM -ResourceGroupName $ResourceGroup -Name $_)
                {
                    $True
                }
                Else
                {
                    Throw "Unable to locate the specified VM: '$_'"
                }
            })]
            #>
    [alias('Name', 'ComputerName')]
    [string]$VMName, #name of the VM to resize
    
    [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
    <#
            [ValidateScript({
                $availSizes = (Get-AzVMSize -ResourceGroupName $ResourceGroup -Name $VMName).Name
                If ($availSizes -contains $_)
                {
                    $True
                }
                Else
                {
                    Throw "Specified VM size is not available: '$_'"
                }
            })]
            #>
    [string]$VMSize, #size of the VM to resize to
        
    [Parameter(Position = 3)]
    [switch]$Force
  )
    
  begin {}
    
  process {
    Write-Verbose 'Checking VM running status and Force parameter setting'
    $GetAzVMParams = @{
      ResourceGroupName = $ResourceGroupName
      VMName            = $VMName
      Status            = $true
    }
    if (
      ((Get-AzVM @GetAzVMParams).Statuses.DisplayStatus -contains 'VM running') -and 
      (-not($Force)) -and # checking to make sure Force parameter is not set
      (-not($WhatIfPreference.IsPresent)) 
    ) {
      $WarningMessage = @(
        "The VM '$VMName' is running. Either stop the VM or use the -Force parameter to update the"
        "VM size and force a restart."
      ) -join ' '
      Write-Warning $WarningMessage
    } else {
      try {
        if ($PSCmdlet.ShouldProcess("$VMName -- Resize to: $VMSize")) {
          Write-Verbose "Getting VM: $VMName"
          $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -VMName $VMName -ErrorAction Stop
          Write-Verbose "Setting VM size: $VMSize"
          $vm.HardwareProfile.VmSize = $VMSize
          Write-Verbose 'Updating VM. This will restart the VM.'
          Update-AzVM -VM $vm -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        }
      } catch {
        $_
      }
    } #end else VM is not running or Force parameter is set
  } #end process block
    
  end {}
    
} #end Resize-sjAzVM function
    
#test runs
#Resize-sjAzVM -ResourceGroupName "RG_DataFactoryGateway" -VMName "azumsmggw001p" -VMSize "Standard_D2s_v3"
#Resize-sjAzVM -ResourceGroupName "RG_DataFactoryGateway" -VMName "azumsmggw001p" -VMSize "Standard_D16s_v3"
#Resize-sjAzVM -ResourceGroupName "RG_DataFactoryGateway" -VMName "azumsmggw001p" -VMSize "Standard_D32s_v3"
    
#Get-AzVM -ResourceGroupName "RG_DataFactoryGateway" -Name "azumsmggw001p" | Resize-sjAzVM -VMSize "Standard_D2s_v3" 