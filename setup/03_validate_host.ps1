[CmdletBinding()]
param(
    [string]$VmName = 'Home Assistant',
    [string]$HomeAssistantHost = 'homeassistant.local'
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
    HomeAssistantPort80 = $false
    HomeAssistantPort8123 = $false
    HomeAssistantLocalPort = $false
    HomeAssistantUrl = $null
    ObserverPort4357 = $false
}

function Test-SmartHomeTcpPort {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [int]$Port,

        [int]$TimeoutMilliseconds = 1500
    )

    try {
        $smarthomeParsedAddress = $null
        if ([System.Net.IPAddress]::TryParse($ComputerName, [ref]$smarthomeParsedAddress)) {
            $smarthomeAddresses = @($smarthomeParsedAddress)
        }
        else {
            $smarthomeAddresses = @([System.Net.Dns]::GetHostAddresses($ComputerName))
        }
    }
    catch {
        return $false
    }

    $smarthomeAddresses = @($smarthomeAddresses | Sort-Object @{ Expression = {
        if ($_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) { 0 } else { 1 }
    } })

    foreach ($smarthomeAddress in $smarthomeAddresses) {
        $smarthomeClient = [System.Net.Sockets.TcpClient]::new($smarthomeAddress.AddressFamily)
        try {
            $smarthomeConnect = $smarthomeClient.BeginConnect($smarthomeAddress, $Port, $null, $null)
            if ($smarthomeConnect.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
                $smarthomeClient.EndConnect($smarthomeConnect)
                if ($smarthomeClient.Connected) { return $true }
            }
        }
        catch {
            continue
        }
        finally {
            $smarthomeClient.Dispose()
        }
    }
    return $false
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
$smarthomeResults.HomeAssistantPort80 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 80
$smarthomeResults.HomeAssistantPort8123 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 8123
$smarthomeResults.ObserverPort4357 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 4357
$smarthomeResults.HomeAssistantLocalPort = $smarthomeResults.HomeAssistantPort80 -or $smarthomeResults.HomeAssistantPort8123
if ($smarthomeResults.HomeAssistantPort80) {
    $smarthomeResults.HomeAssistantUrl = "http://$HomeAssistantHost"
}
elseif ($smarthomeResults.HomeAssistantPort8123) {
    $smarthomeResults.HomeAssistantUrl = "http://${HomeAssistantHost}:8123"
}

[pscustomobject]$smarthomeResults | Format-List

if (-not $smarthomeResults.VirtualBoxInstalled -or -not $smarthomeResults.VmExists) {
    exit 1
}
if ($smarthomeResults.VmState -ne 'running' -or -not $smarthomeResults.HomeAssistantLocalPort) {
    exit 2
}
exit 0
