function Send-sjVolumeKey {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('VolumeUp', 'VolumeDown', 'Mute')]
    [string]$Action
  )

  # Create a new COM object for WScript.Shell
  $shell = New-Object -ComObject wscript.shell

  switch ($action) {
    'VolumeUp' {
      $shell.SendKeys([char]175)
    }
    'VolumeDown' {
      $shell.SendKeys([char]174)
    }
    'Mute' {
      $shell.SendKeys([char]173)
    }
    default {
      Write-Output 'Invalid action. Use VolumeUp, VolumeDown, or Mute.'
    }
  }
}

# Test cases
# Send-sjVolumeKey -Action 'VolumeUp'
# Send-sjVolumeKey -Action VolumeDown
Send-sjVolumeKey -Action Mute