[CmdletBinding()]
param(
    [string]$VmName = 'Home Assistant',
    [int]$CpuCount = 2,
    [int]$MemoryMb = 4096,
    [int]$DiskSizeMb = 32768,
    [string]$BridgeAdapter = ''
)

$ErrorActionPreference = 'Stop'

function Test-SmarthomeAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$smarthomeVBoxManage = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
if (-not (Test-Path -LiteralPath $smarthomeVBoxManage)) {
    if (-not (Test-SmarthomeAdministrator)) {
        throw 'VirtualBox installation requires an elevated PowerShell window.'
    }

    Write-Host 'Installing Oracle VirtualBox. The network can disconnect briefly.'
    winget install --id Oracle.VirtualBox --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "VirtualBox installation failed. winget exit code: $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $smarthomeVBoxManage)) {
    throw "VBoxManage was not found: $smarthomeVBoxManage"
}


$smarthomeRoot = Join-Path $env:LOCALAPPDATA 'HomeAssistantVM'
$smarthomeDownloads = Join-Path $smarthomeRoot 'downloads'
$smarthomeVmFolder = Join-Path $smarthomeRoot 'vm'
New-Item -ItemType Directory -Path $smarthomeDownloads -Force | Out-Null
New-Item -ItemType Directory -Path $smarthomeVmFolder -Force | Out-Null

$smarthomeStable = Invoke-RestMethod -Uri 'https://version.home-assistant.io/stable.json'
$smarthomeHaosVersion = [string]$smarthomeStable.hassos.ova
if ([string]::IsNullOrWhiteSpace($smarthomeHaosVersion)) {
    throw 'The HAOS OVA version was not found in Home Assistant stable.json.'
}

$smarthomeAssetName = "haos_ova-$smarthomeHaosVersion.vdi.zip"
$smarthomeZip = Join-Path $smarthomeDownloads $smarthomeAssetName
$smarthomeVdi = Join-Path $smarthomeVmFolder "haos_ova-$smarthomeHaosVersion.vdi"
$smarthomeReleaseUri = "https://api.github.com/repos/home-assistant/operating-system/releases/tags/$smarthomeHaosVersion"
$smarthomeRelease = Invoke-RestMethod -Uri $smarthomeReleaseUri
$smarthomeAsset = $smarthomeRelease.assets | Where-Object { $_.name -eq $smarthomeAssetName } | Select-Object -First 1
if ($null -eq $smarthomeAsset) {
    throw "The HAOS release asset was not found: $smarthomeAssetName"
}

if (-not (Test-Path -LiteralPath $smarthomeVdi)) {
    $smarthomeDownloadNeeded = $true
    if (Test-Path -LiteralPath $smarthomeZip) {
        $smarthomeExistingLength = (Get-Item -LiteralPath $smarthomeZip).Length
        $smarthomeDownloadNeeded = $smarthomeExistingLength -ne [int64]$smarthomeAsset.size
    }

    if ($smarthomeDownloadNeeded) {
        Write-Host "Downloading the HAOS $smarthomeHaosVersion VDI."
        Invoke-WebRequest -Uri $smarthomeAsset.browser_download_url -OutFile $smarthomeZip
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$smarthomeAsset.digest)) {
        $smarthomeExpectedHash = ([string]$smarthomeAsset.digest).Split(':')[-1].ToUpperInvariant()
        $smarthomeActualHash = (Get-FileHash -LiteralPath $smarthomeZip -Algorithm SHA256).Hash
        if ($smarthomeActualHash -ne $smarthomeExpectedHash) {
            throw 'The HAOS download failed SHA-256 verification and will not be used.'
        }
    }

    Write-Host 'Extracting the HAOS virtual disk.'
    Expand-Archive -LiteralPath $smarthomeZip -DestinationPath $smarthomeVmFolder
}

if (-not (Test-Path -LiteralPath $smarthomeVdi)) {
    throw "The extracted VDI was not found: $smarthomeVdi"
}

# Check whether the VM already exists without intentionally invoking VBoxManage
# against a missing VM. `showvminfo` on a nonexistent VM writes an error that can
# terminate the script under some PowerShell configurations when ErrorActionPreference
# is set to Stop.
$smarthomeRegisteredVms = & $smarthomeVBoxManage list vms
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to query the VirtualBox VM list.'
}

$smarthomeVmExists = $false
foreach ($smarthomeVmLine in $smarthomeRegisteredVms) {
    if ($smarthomeVmLine -match '^"(.+)"\s+\{[0-9A-Fa-f-]+\}$' -and $Matches[1] -eq $VmName) {
        $smarthomeVmExists = $true
        break
    }
}

if ($smarthomeVmExists) {
    Write-Host "Existing VM '$VmName' was preserved. No disk was overwritten."
    return
}

if ([string]::IsNullOrWhiteSpace($BridgeAdapter)) {
    $smarthomeWifi = Get-NetAdapter | Where-Object {
        $_.Status -eq 'Up' -and ($_.Name -match 'Wi-?Fi' -or $_.InterfaceDescription -match 'Wi-?Fi|Wireless')
    } | Select-Object -First 1
    if ($null -eq $smarthomeWifi) {
        throw 'No active Wi-Fi adapter was found. Pass a VBoxManage bridgedifs Name with -BridgeAdapter.'
    }
    $BridgeAdapter = [string]$smarthomeWifi.InterfaceDescription
}

Write-Host "Creating VirtualBox VM '$VmName'. Bridge: $BridgeAdapter"
& $smarthomeVBoxManage createvm '--name' $VmName '--ostype' 'Oracle_64' '--basefolder' $smarthomeVmFolder '--register'
if ($LASTEXITCODE -ne 0) { throw 'VirtualBox VM creation failed.' }

& $smarthomeVBoxManage modifyvm $VmName '--memory' $MemoryMb '--cpus' $CpuCount '--firmware' 'efi' '--ioapic' 'on' '--boot1' 'disk' '--boot2' 'none' '--graphicscontroller' 'vmsvga' '--vram' '16' '--nic1' 'bridged' '--bridgeadapter1' $BridgeAdapter '--cableconnected1' 'on'
if ($LASTEXITCODE -ne 0) { throw 'VirtualBox VM hardware configuration failed.' }

& $smarthomeVBoxManage modifymedium 'disk' $smarthomeVdi '--resize' $DiskSizeMb
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'VDI resize was unnecessary or unsupported. Continuing with the existing size.'
}

& $smarthomeVBoxManage storagectl $VmName '--name' 'SATA Controller' '--add' 'sata' '--controller' 'IntelAhci'
if ($LASTEXITCODE -ne 0) { throw 'VirtualBox SATA controller creation failed.' }

& $smarthomeVBoxManage storageattach $VmName '--storagectl' 'SATA Controller' '--port' '0' '--device' '0' '--type' 'hdd' '--medium' $smarthomeVdi '--nonrotational' 'on'
if ($LASTEXITCODE -ne 0) { throw 'Attaching the HAOS VDI failed.' }

& $smarthomeVBoxManage startvm $VmName '--type' 'headless'
if ($LASTEXITCODE -ne 0) { throw 'Starting the Home Assistant VM failed.' }

Write-Host ''
Write-Host 'VM started. First-time setup can take 5 to 20 minutes.'
Write-Host 'Open http://homeassistant.local when it is ready. Use :8123 only if port 80 is unavailable.'
