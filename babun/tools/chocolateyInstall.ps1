$babunpath = Join-Path $env:USERPROFILE ".babun"
$unzipPath = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

function ConfigureBabunToUseInternalHomeDir {
    Write-Host "Configuring Babun to use internal home directory..."

    $etcPath = Join-Path $babunpath "cygwin/etc"

    $etcProfile = Join-Path $etcPath "profile"
    $etcProfileReplaced = Join-Path $etcPath "profile_rep"

    (Get-Content $etcProfile -Raw).Replace('USER="$(/usr/bin/id -un)"', "USER=`"`$(/usr/bin/id -un)`"`n  HOME=`$(eval echo `"~`$USER`")") |
        Set-Content $etcProfileReplaced

     Move-Item -Force $etcProfileReplaced $etcProfile

     $etcZProfile = Join-Path $etcPath "zprofile"
     $etcZProfileReplaced = Join-Path $etcPath "zprofile_rep"

     (Get-Content $etcZProfile -Raw).Replace('USER="$(/usr/bin/id -un)"', "USER=`"`$(/usr/bin/id -un)`"`n  HOME=`$(eval echo `"~`$USER`")") |
         Set-Content $etcZProfileReplaced

      Move-Item -Force $etcZProfileReplaced $etcZProfile

      $zshrc = Join-Path $env:USERPROFILE ".zshrc"
      New-Item $zshrc -type file
}

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

    if ($env:HOME) {
        # temporary disable HOME variable during installation because it is not supported by babun
        $homeEnvVar = $env:HOME
        $env:HOME = ""
    }

    Write-Host "Executing installation script..."
    start-process $setupBatUnattended -Wait -WindowStyle Minimized

    if ($homeEnvVar) {
        $env:HOME = $homeEnvVar
        ConfigureBabunToUseInternalHomeDir
    }
}

function FixFilePermissions {
    $Acl = Get-Acl $env:APPDATA
    $babunFilesAndFolders = Get-ChildItem -Recurse $babunpath

    Set-Acl -Path $babunpath -AclObject $Acl
    foreach ($fileOrFolder in $babunFilesAndFolders) {
        try {
            Set-Acl -Path $fileOrFolder.FullName -AclObject $Acl
        } catch [System.Management.Automation.WildcardPatternException] {
            #ignore error on invalid filenames: [.exe and [.1.gz
            Write-Host "Skipped invalid file $fileOrFolder"
        }
    }
}

function BabunIsInstalled {
    return Test-Path $babunpath
}

if (BabunIsInstalled) {
    Write-Host "Babun is already installed! Skipping..."
} else {
    InstallBabun

    Write-Host "Fixing file permissions..."
    FixFilePermissions
}
