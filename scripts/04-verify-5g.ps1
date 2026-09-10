[CmdletBinding()]
param([int]$TimeoutSeconds = 120)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\S25Edge.Common.ps1')

try {
    [void](Wait-S25Device -TimeoutSeconds $TimeoutSeconds)
    $device = Get-SafeDeviceSnapshot
    $radio = Get-RadioSummary
    $device | Format-List model, android, security_patch, build_incremental, sales_code, boot_sales_code, boot_carrier_id, sim_config
    $radio | Format-List
    $path = Save-SafeDeviceSnapshot -Label 'verification'
    Write-Host "Saved verification snapshot: $path" -ForegroundColor Green

    $joined = (($radio.data_network_types + $radio.network_type_property + $radio.nr_states) -join ' ')
    if ($joined -match '\bNR\b|NR_(SA|NSA)|CONNECTED') {
        Write-Host 'The current radio state contains an NR/5G indication.' -ForegroundColor Green
    } else {
        Write-Host 'No current NR indication was found. This does not by itself prove the unlock failed; test in known China Mobile 5G coverage with Wi-Fi off.' -ForegroundColor Yellow
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
