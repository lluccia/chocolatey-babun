function RunBabunInstall($unzipPath)
{
    $babunpath = Join-Path $env:USERPROFILE ".babun"
    $updateBat = Join-Path $babunpath "update.bat"
    if (Test-Path $updateBat)
    {
        start-process $updateBat -Wait
    }
    else
    {
        $setupBat = Join-Path $unzipPath "babun-1.2.0"
        $setupBat = Join-Path $setupBat "install.bat"
        start-process $setupBat #-Wait
    }
}

$unzipPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$packageArgs = @{
  packageName = 'babun'
  url = 'http://projects.reficio.org/babun/download/babun-1.2.0-dist.zip';
  checksumType = 'sha256'
  checksum = '89C0A51EA1D995BE5B04B24CD795BA3EBA713B293B43991F0C87E29300429B14'
  unzipLocation = $unzipPath
}

Install-ChocolateyZipPackage @packageArgs
RunBabunInstall $unzipPath
