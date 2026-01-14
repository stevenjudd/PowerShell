function Send-sjKeystrokes {
  param(
    [parameter(Mandatory)]
    [string]$WindowTitle,

    [byte]$SecondsToWait = 2,

    [parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string[]]$Keystrokes
  )

  begin{
    try {
      $wshell = New-Object -ComObject wscript.shell
      [Void][System.Reflection.Assembly]::Load('System.Windows.Forms')
    }
    catch {
        throw 'Unable to load required assemblies'
    }
  }

  process{
    foreach($item in $Keystrokes){
      if($wshell.AppActivate($WindowTitle)){
        [System.Windows.Forms.SendKeys]::SendWait($item)
        Start-Sleep -Seconds $SecondsToWait
      } else {
        Write-Warning "Unable to focus on Window: $WindowTitle"
      }
    }
  }

  end {}
}


# Test cases
# Send-sjKeystrokes -WindowTitle 'Notepad' -SecondsToWait 1 -Keystrokes 'asdf'

# $SendSjKeys = @{
#   WindowTitle = 'Load Balancer Administration System and 37 more pages'
#   SecondsToWait = 0
# }
# '{tab 12}web1021{tab}','10.200.10.56{tab}','0{tab 4}' | Send-sjKeystrokes @SendSjKeys
