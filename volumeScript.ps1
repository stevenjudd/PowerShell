param(
  [string]$action
)

# Create a new COM object for WScript.Shell
$shell = New-Object -ComObject wscript.shell

switch ($action) {
  'volumeup' {
    $shell.SendKeys([char]175)
  }
  'volumedown' {
    $shell.SendKeys([char]174)
  }
  'mute' {
    $shell.SendKeys([char]173)
  }
  default {
    Write-Output 'Invalid action. Use volumeup, volumedown, or mute.'
  }
}
