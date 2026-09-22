[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function ConvertFrom-SmarthomeSecureString {
    param([Security.SecureString]$Value)
    $smarthomePointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($smarthomePointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($smarthomePointer)
    }
}

$smarthomeToken = ConvertFrom-SmarthomeSecureString (Read-Host 'SwitchBot OpenAPI Token (input hidden)' -AsSecureString)
$smarthomeSecret = ConvertFrom-SmarthomeSecureString (Read-Host 'SwitchBot OpenAPI Secret (input hidden)' -AsSecureString)

$smarthomeTimestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString()
$smarthomeNonce = [Guid]::NewGuid().ToString()
$smarthomeStringToSign = "$smarthomeToken$smarthomeTimestamp$smarthomeNonce"
$smarthomeHmac = [Security.Cryptography.HMACSHA256]::new([Text.Encoding]::UTF8.GetBytes($smarthomeSecret))
try {
    $smarthomeSignature = [Convert]::ToBase64String($smarthomeHmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($smarthomeStringToSign)))
}
finally {
    $smarthomeHmac.Dispose()
}

$smarthomeHeaders = @{
    Authorization = $smarthomeToken
    sign = $smarthomeSignature
    nonce = $smarthomeNonce
    t = $smarthomeTimestamp
}
$smarthomeResponse = Invoke-RestMethod -Method Get -Uri 'https://api.switch-bot.com/v1.1/devices' -Headers $smarthomeHeaders
if ($smarthomeResponse.statusCode -ne 100) {
    throw "SwitchBot API error $($smarthomeResponse.statusCode): $($smarthomeResponse.message)"
}

Write-Host ''
Write-Host 'Physical devices'
$smarthomeResponse.body.deviceList | Select-Object deviceName, deviceType, deviceId, hubDeviceId | Format-Table -AutoSize
Write-Host 'Infrared virtual remotes'
$smarthomeResponse.body.infraredRemoteList | Select-Object deviceName, remoteType, deviceId, hubDeviceId | Format-Table -AutoSize

$smarthomeToken = $null
$smarthomeSecret = $null
