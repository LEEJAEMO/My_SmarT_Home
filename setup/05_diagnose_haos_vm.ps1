[CmdletBinding()]
param(
    [string]$VmName = 'Home Assistant',
    [string]$HomeAssistantHost = 'homeassistant.local',
    [string]$EvidencePath
)

$ErrorActionPreference = 'Continue'
$smarthomeVBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'

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

$smarthomeResult = [ordered]@{
    CheckedAt = (Get-Date).ToString('o')
    VirtualBoxInstalled = Test-Path -LiteralPath $smarthomeVBoxManage
    VirtualBoxVersion = $null
    VmExists = $false
    VmState = $null
    VmConfigFile = $null
    VmLogFile = $null
    DiskFile = $null
    NetworkMode = $null
    BridgeAdapter = $null
    BridgeFilterEnabled = $null
    CoreIsolationMemoryIntegrity = $null
    VirtualizationBasedSecurityStatus = $null
    WindowsHypervisorDetected = $false
    VirtualBoxSnailExecutionMode = $false
    ResolvedAddresses = @()
    HomeAssistantPort80 = $false
    HomeAssistantPort8123 = $false
    ObserverPort4357 = $false
    HomeAssistantUrl = $null
    Diagnosis = @()
}

if ($smarthomeResult.VirtualBoxInstalled) {
    $smarthomeResult.VirtualBoxVersion = (& $smarthomeVBoxManage '--version') | Select-Object -First 1
    $smarthomeInfo = & $smarthomeVBoxManage showvminfo $VmName '--machinereadable' 2>$null
    if ($LASTEXITCODE -eq 0) {
        $smarthomeResult.VmExists = $true
        foreach ($smarthomeLine in $smarthomeInfo) {
            if ($smarthomeLine -match '^VMState="(.+)"$') { $smarthomeResult.VmState = $Matches[1] }
            if ($smarthomeLine -match '^CfgFile="(.+)"$') { $smarthomeResult.VmConfigFile = $Matches[1] }
            if ($smarthomeLine -match '^LogFldr="(.+)"$') { $smarthomeLogFolder = $Matches[1] }
            if ($smarthomeLine -match '^nic1="?(.+?)"?$') { $smarthomeResult.NetworkMode = $Matches[1] }
            if ($smarthomeLine -match '^bridgeadapter1="(.+)"$') { $smarthomeResult.BridgeAdapter = $Matches[1] }
            if ($smarthomeLine -match '^".+-0-0"="(.+\.vdi)"$') { $smarthomeResult.DiskFile = $Matches[1] }
        }

        if ($smarthomeLogFolder) {
            $smarthomeResult.VmLogFile = Join-Path $smarthomeLogFolder 'VBox.log'
            if (Test-Path -LiteralPath $smarthomeResult.VmLogFile) {
                $smarthomeResult.VirtualBoxSnailExecutionMode = [bool](
                    Select-String -LiteralPath $smarthomeResult.VmLogFile -Pattern 'Snail execution mode is active' -Quiet
                )
            }
        }
    }
}

if ($smarthomeResult.BridgeAdapter) {
    $smarthomeAdapter = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceDescription -eq $smarthomeResult.BridgeAdapter } |
        Select-Object -First 1
    if ($smarthomeAdapter) {
        $smarthomeBinding = Get-NetAdapterBinding -Name $smarthomeAdapter.Name -ComponentID 'oracle_VBoxNetLwf' -ErrorAction SilentlyContinue
        if ($smarthomeBinding) {
            $smarthomeResult.BridgeFilterEnabled = [bool]$smarthomeBinding.Enabled
        }
    }
}

$smarthomeMemoryIntegrity = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -ErrorAction SilentlyContinue
if ($null -ne $smarthomeMemoryIntegrity.Enabled) {
    $smarthomeResult.CoreIsolationMemoryIntegrity = [bool]$smarthomeMemoryIntegrity.Enabled
}

$smarthomeDeviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace 'root\Microsoft\Windows\DeviceGuard' -ErrorAction SilentlyContinue
if ($smarthomeDeviceGuard) {
    $smarthomeResult.VirtualizationBasedSecurityStatus = $smarthomeDeviceGuard.VirtualizationBasedSecurityStatus
}

$smarthomeComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if ($null -ne $smarthomeComputerSystem -and $null -ne $smarthomeComputerSystem.HypervisorPresent) {
    $smarthomeResult.WindowsHypervisorDetected = [bool]$smarthomeComputerSystem.HypervisorPresent
}

try {
    $smarthomeResult.ResolvedAddresses = @(
        Resolve-DnsName -Name $HomeAssistantHost -ErrorAction Stop |
            Where-Object { $_.IPAddress } |
            Select-Object -ExpandProperty IPAddress -Unique
    )
}
catch {
    $smarthomeResult.ResolvedAddresses = @()
}

$smarthomeResult.HomeAssistantPort80 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 80
$smarthomeResult.HomeAssistantPort8123 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 8123
$smarthomeResult.ObserverPort4357 = Test-SmartHomeTcpPort -ComputerName $HomeAssistantHost -Port 4357

if ($smarthomeResult.HomeAssistantPort80) {
    $smarthomeResult.HomeAssistantUrl = "http://$HomeAssistantHost"
}
elseif ($smarthomeResult.HomeAssistantPort8123) {
    $smarthomeResult.HomeAssistantUrl = "http://${HomeAssistantHost}:8123"
}

if (-not $smarthomeResult.VmExists) {
    $smarthomeResult.Diagnosis += 'VirtualBox VM을 찾지 못했습니다.'
}
elseif ($smarthomeResult.VmState -ne 'running') {
    $smarthomeResult.Diagnosis += 'VM이 실행 중이 아닙니다.'
}
elseif ($smarthomeResult.HomeAssistantPort80) {
    $smarthomeResult.Diagnosis += 'Home Assistant 2026.8 이후 HAOS 기본 포트 80에서 UI가 응답합니다.'
}
elseif ($smarthomeResult.HomeAssistantPort8123) {
    $smarthomeResult.Diagnosis += '레거시/대체 포트 8123에서 UI가 응답합니다.'
}
elseif ($smarthomeResult.ObserverPort4357) {
    $smarthomeResult.Diagnosis += 'HAOS와 Supervisor는 응답하지만 Home Assistant Core UI가 응답하지 않습니다. 콘솔에서 ha core info와 ha core logs를 확인하세요.'
}
else {
    $smarthomeResult.Diagnosis += '게스트 네트워크 또는 HAOS 부팅 상태를 먼저 확인하세요.'
}

if ($smarthomeResult.VirtualBoxSnailExecutionMode) {
    $smarthomeResult.Diagnosis += 'VirtualBox가 Windows Hypervisor Platform 경유 NEM snail mode를 사용합니다. 부팅 지연 가능성은 있지만 UI 불통의 단독 증거는 아닙니다.'
}

$smarthomeObject = [pscustomobject]$smarthomeResult
$smarthomeObject | Format-List

if ($EvidencePath) {
    $smarthomeEvidenceDirectory = Split-Path -Parent $EvidencePath
    if ($smarthomeEvidenceDirectory -and -not (Test-Path -LiteralPath $smarthomeEvidenceDirectory)) {
        New-Item -ItemType Directory -Path $smarthomeEvidenceDirectory -Force | Out-Null
    }
    $smarthomeObject | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $EvidencePath -Encoding utf8
}

if (-not $smarthomeResult.VirtualBoxInstalled -or -not $smarthomeResult.VmExists) {
    exit 1
}
if ($smarthomeResult.VmState -ne 'running') {
    exit 2
}
if (-not $smarthomeResult.HomeAssistantPort80 -and -not $smarthomeResult.HomeAssistantPort8123) {
    exit 3
}
exit 0
