[CmdletBinding()]
param([int]$TimeoutSeconds = 120)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\S25Edge.Common.ps1')

try {
    [void](Wait-S25Device -TimeoutSeconds $TimeoutSeconds)
    [void](Open-SamsungServiceMain)
    Write-Host 'Samsung Service Mode is open on the phone.' -ForegroundColor Green
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
