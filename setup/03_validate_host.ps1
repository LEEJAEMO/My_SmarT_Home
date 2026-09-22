[CmdletBinding()]
param(
    [string]$VmName = 'Home Assistant'
)

$ErrorActionPreference = 'Continue'
$smarthomeVBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$smarthomeResults = [ordered]@{
    CheckedAt = (Get-Date).ToString('s')
    VirtualBoxInstalled = Test-Path -LiteralPath $smarthomeVBoxManage
    VirtualBoxVersion = $null
    VmExists = $false
    VmState = $null
    MemoryMb = $null
    CpuCount = $null
    Firmware = $null
    NetworkMode = $null
    BridgeAdapter = $null
    AutoStartTask = $false
    HomeAssistantLocalPort = $false
}

if ($smarthomeResults.VirtualBoxInstalled) {
    $smarthomeResults.VirtualBoxVersion = (& $smarthomeVBoxManage '--version') | Select-Object -First 1
    $smarthomeInfo = & $smarthomeVBoxManage showvminfo $VmName '--machinereadable' 2>$null
    if ($LASTEXITCODE -eq 0) {
        $smarthomeResults.VmExists = $true
        foreach ($smarthomeLine in $smarthomeInfo) {
            if ($smarthomeLine -match '^VMState="(.+)"$') { $smarthomeResults.VmState = $Matches[1] }
            if ($smarthomeLine -match '^memory=(.+)$') { $smarthomeResults.MemoryMb = $Matches[1] }
            if ($smarthomeLine -match '^cpus=(.+)$') { $smarthomeResults.CpuCount = $Matches[1] }
            if ($smarthomeLine -match '^firmware="?(.+?)"?$') { $smarthomeResults.Firmware = $Matches[1] }
            if ($smarthomeLine -match '^nic1="?(.+?)"?$') { $smarthomeResults.NetworkMode = $Matches[1] }
            if ($smarthomeLine -match '^bridgeadapter1="?(.+?)"?$') { $smarthomeResults.BridgeAdapter = $Matches[1] }
        }
    }
}

$smarthomeResults.AutoStartTask = $null -ne (Get-ScheduledTask -TaskName 'Home Assistant VM - Auto Start' -ErrorAction SilentlyContinue)
$smarthomeResults.HomeAssistantLocalPort = Test-NetConnection -ComputerName 'homeassistant.local' -Port 8123 -InformationLevel Quiet -WarningAction SilentlyContinue

[pscustomobject]$smarthomeResults | Format-List

if (-not $smarthomeResults.VirtualBoxInstalled -or -not $smarthomeResults.VmExists) {
    exit 1
}
if ($smarthomeResults.VmState -ne 'running' -or -not $smarthomeResults.HomeAssistantLocalPort) {
    exit 2
}
exit 0

