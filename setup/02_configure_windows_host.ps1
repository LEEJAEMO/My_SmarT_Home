[CmdletBinding()]
param(
    [string]$VmName = 'Home Assistant'
)

$ErrorActionPreference = 'Stop'
$smarthomeVBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
if (-not (Test-Path -LiteralPath $smarthomeVBoxManage)) {
    throw "VBoxManage was not found: $smarthomeVBoxManage"
}

& $smarthomeVBoxManage showvminfo $VmName '--machinereadable' *> $null
if ($LASTEXITCODE -ne 0) {
    throw "VirtualBox VM was not found: $VmName"
}

# Preserve battery settings; only disable sleep and hibernation while on AC.
powercfg /change standby-timeout-ac 0
if ($LASTEXITCODE -ne 0) {
    throw 'Disabling sleep on AC failed. Run this in an elevated PowerShell window.'
}
powercfg /change hibernate-timeout-ac 0
if ($LASTEXITCODE -ne 0) {
    throw 'Disabling hibernation on AC failed. Run this in an elevated PowerShell window.'
}

$smarthomeTaskName = 'Home Assistant VM - Auto Start'
$smarthomeAction = New-ScheduledTaskAction -Execute $smarthomeVBoxManage -Argument "startvm `"$VmName`" --type headless"
$smarthomeTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$smarthomeTrigger.Delay = 'PT30S'
$smarthomeSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $smarthomeTaskName -Action $smarthomeAction -Trigger $smarthomeTrigger -Settings $smarthomeSettings -Description 'Starts the Home Assistant VM headless 30 seconds after Galaxy Book logon.' -Force | Out-Null

Write-Host 'Disabled sleep and hibernation on AC. Battery settings were preserved.'
Write-Host "Registered the logon auto-start task: $smarthomeTaskName"
