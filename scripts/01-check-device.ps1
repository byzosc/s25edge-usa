[CmdletBinding()]
param([int]$TimeoutSeconds = 120)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\S25Edge.Common.ps1')

try {
    [void](Wait-S25Device -TimeoutSeconds $TimeoutSeconds)
    $info = Get-SafeDeviceSnapshot
    $info | Format-List

    if ($info.model -notmatch '^SM-S937') {
        Write-Warning "Expected Galaxy S25 Edge model SM-S937*, but connected model is '$($info.model)'."
    }

    $saved = Save-SafeDeviceSnapshot -Label 'device-check'
    Write-Host "Saved privacy-safe snapshot: $saved" -ForegroundColor Green
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
