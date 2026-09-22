[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Test-SmarthomeAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-SmarthomeAdministrator)) {
    $smarthomeArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    try {
        $smarthomeElevated = Start-Process -FilePath 'powershell.exe' -ArgumentList $smarthomeArguments -Verb RunAs -Wait -PassThru
        exit $smarthomeElevated.ExitCode
    }
    catch {
        Write-Error 'Administrator approval was not granted. No VM changes were made.'
        exit 1
    }
}

try {
    & (Join-Path $PSScriptRoot '01_install_virtualbox_haos.ps1')
    & (Join-Path $PSScriptRoot '02_configure_windows_host.ps1')
    Write-Host ''
    Write-Host 'Host setup completed successfully.' -ForegroundColor Green
    Write-Host 'Open http://homeassistant.local after the first boot is ready. Use :8123 only if port 80 is unavailable.'
    [void](Read-Host 'Press Enter to close this window')
}
catch {
    Write-Error $_
    [void](Read-Host 'Press Enter to close this window')
    exit 1
}
