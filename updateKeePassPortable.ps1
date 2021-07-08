try {
    #bad practice for a huge try block, but...
    #get the version of Keepass
    #scrape the website for the version
    Write-Host "Get version from keepass.info/download.html page" -ForegroundColor Green
    $websiteContent = Invoke-WebRequest -Uri https://keepass.info/download.html -UseBasicParsing
    $PortableVersionLine = ($websiteContent.rawContent -split "\n" | Select-String "portable \(2\..*?\)").matches.value
    $kpVersion = ($PortableVersionLine -replace "Portable \(") -replace "\)"

    #download the file to downloads dir
    Write-Host "Downloading from sourceforge.net" -ForegroundColor Yellow
    $kpDownloadUrl = "https://sourceforge.net/projects/keepass/files/KeePass%202.x/$kpVersion/KeePass-$kpVersion.zip/download" 
    $zipFilePath = Join-Path -Path $HOME -ChildPath "Downloads\KeePass-$kpVersion.zip"
    (new-object System.Net.WebClient).DownloadFile($kpDownloadUrl, $zipFilePath)
    Write-Host "New version downloaded: $zipFilePath" -ForegroundColor Green

    #unzip file to temp location
    $tempLocation = "$env:TEMP\KeePass"
    if (Test-Path -Path $tempLocation) {
        Remove-Item -Path $tempLocation -Recurse -Force
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $tempLocation)
    Write-Host "Unzipped to temp location: $tempLocation" -ForegroundColor Green

    #copy to destination
    $KeePassDestination = Join-Path -Path $env:OneDrive -ChildPath "Utilities"
    Copy-Item $tempLocation -Destination $KeePassDestination -Recurse -Force
    Write-Host "Copied to destination: $KeePassDestination" -ForegroundColor Green

    #clean up
    Remove-Item -Path $tempLocation -Recurse -Force
    Write-Host "Cleaned up upzipped content" -ForegroundColor Green
}
catch {
    throw $_
}
# In case the downloads don't work as expected, try the following URL format:
# https://downloads.sourceforge.net/project/keepass/KeePass%202.x/2.46/KeePass-2.46.zip