$babunpath = Join-Path $env:USERPROFILE ".babun"
$unzipPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

function InstallBabun {
    $packageArgs = @{
        packageName = 'babun'
        url = 'http://projects.reficio.org/babun/download/babun-1.2.0-dist.zip';
        checksumType = 'sha256'
        checksum = '89C0A51EA1D995BE5B04B24CD795BA3EBA713B293B43991F0C87E29300429B14'
        unzipLocation = $unzipPath
    }

    Install-ChocolateyZipPackage @packageArgs

    $babunUnzippedPath = Join-Path $unzipPath "babun-1.2.0"
    $setupBat = Join-Path $babunUnzippedPath "install.bat"
    $setupBatUnattended = Join-Path $babunUnzippedPath "install-unattended.bat"

    Get-Content $setupBat |
        foreach-object {$_ -replace '"%BABUN_HOME%"\\babun.bat', 'rem -- should not run babun --' } |
        foreach-object {$_ -replace 'pause', 'rem -- should not pause --' } |
        Set-Content $setupBatUnattended

    start-process $setupBatUnattended -Wait
}

function BabunIsInstalled {
    return Test-Path $babunpath
}

if (BabunIsInstalled) {
    Write-Host "Babun is already installed! Skipping..."
} else {
    Write-Host "Executing installation script..."
    InstallBabun
}
