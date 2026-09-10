[CmdletBinding()]
param(
    [ValidateSet(1, 2)][int]$SimSlot = 1,
    [int]$TimeoutSeconds = 120,
    [switch]$NoReboot,
    [switch]$ForceModel,
    [switch]$AssumeYes
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\S25Edge.Common.ps1')
$actionLog = $null
$settingsCompleted = $false

function Apply-Core5GSettings {
    if ($SimSlot -eq 2) {
        Invoke-ServiceModeSetting -Name 'Use NR5G stack 2 for SIM 2' `
            -ParentPath @('UE SETTING & INFO', 'SETTING', 'PROTOCOL', 'NR5G', 'STACK SELECTION') `
            -ActionLabel 'SELECT STACK 2'
    }

    Invoke-ServiceModeSetting -Name 'Restore default LTE band configuration' `
        -ParentPath @('UE SETTING & INFO', 'SETTING', 'SYSTEM', 'NEXT PAGE', 'NEXT PAGE', 'NEXT PAGE', 'NEXT PAGE', 'SET LTE BAND CONFIG') `
        -ActionLabel 'SET DEFAULT LTE BAND'

    Invoke-ServiceModeSetting -Name 'Remove NR5G prune' `
        -ParentPath @('UE SETTING & INFO', 'SETTING', 'PROTOCOL', 'NR5G', 'PRUNE STATUS') `
        -ActionLabel 'REMOVE NR5G PRUNE' `
        -AlreadyAppliedLabel 'RESTORE NR5G PRUNE'

    Invoke-ServiceModeSetting -Name 'Remove NR whitelist' `
        -ParentPath @('UE SETTING & INFO', 'SETTING', 'PROTOCOL', 'GCF') `
        -ActionLabel 'REMOVE ONLY NR WHITELIST'

    Invoke-ServiceModeSetting -Name 'Enable SA and NSA' `
        -ParentPath @('UE SETTING & INFO', 'SETTING', 'PROTOCOL', 'NR5G', 'SA/NSA MODE CONTROL') `
        -ActionLabel 'SA/NSA ENABLE'

    Invoke-ServiceModeSetting -Name 'Remove SA permit list' `
        -ParentPath @('UE SETTING & INFO', 'SETTING', 'PROTOCOL', 'NR5G', 'SA/NSA MODE CONTROL') `
        -ActionLabel 'REMOVE SA PERMIT LIST'
}

try {
    Write-Host 'S25 Edge USA - post-update China Mobile 5G recovery' -ForegroundColor Cyan
    Write-Host 'This uses ADB to drive Samsung Service Mode. It does not root, flash, change CSC, or unlock the bootloader.'
    Write-Host 'The phone must stay unlocked while menu automation is running.'

    [void](Wait-S25Device -TimeoutSeconds $TimeoutSeconds)
    $before = Get-SafeDeviceSnapshot
    $before | Format-List

    if ((-not $ForceModel) -and ($before.model -notmatch '^SM-S937(U|U1)?$')) {
        throw "Refusing to change '$($before.model)'. Expected a US Galaxy S25 Edge (SM-S937U/U1). Use -ForceModel only after checking the model."
    }

    if (-not $AssumeYes) {
        $answer = Read-Host 'Type YES to apply the core settings (plus stack selection for SIM 2) and then reboot'
        if ($answer -cne 'YES') {
            throw 'Cancelled; no Service Mode setting was changed by this run.'
        }
    }

    $actionLog = Start-ActionLog -Label '5g-recovery-actions'
    Write-ActionLog "Device: model=$($before.model); build=$($before.build_incremental); CSC=$($before.sales_code); SIM slot=$SimSlot"
    Write-ActionLog "Before network type: $($before.network_type); operator=$($before.operator_name)"
    $beforePath = Save-SafeDeviceSnapshot -Label 'before-recovery'
    Write-ActionLog "Before snapshot: logs\$(Split-Path $beforePath -Leaf)"
    Apply-Core5GSettings
    $settingsCompleted = $true
    Write-ActionLog 'All requested core Service Mode settings completed'
    Write-Host "Core settings completed. Before-state: $beforePath" -ForegroundColor Green

    if (-not $NoReboot) {
        Write-Host 'Rebooting the phone...'
        Write-ActionLog 'ADB reboot requested'
        [void](Invoke-DeviceAdb -Arguments @('reboot'))
        $script:DeviceSerial = $null
        Start-Sleep -Seconds 8
        [void](Wait-S25Device -TimeoutSeconds 180)
    }

    $afterPath = Save-SafeDeviceSnapshot -Label 'after-recovery'
    $radio = Get-RadioSummary
    Write-ActionLog "After network type: $($radio.network_type_property); operator=$($radio.operator_name)"
    Write-ActionLog "After snapshot: logs\$(Split-Path $afterPath -Leaf)"
    $radio | Format-List
    Write-Host "After-state: $afterPath" -ForegroundColor Green
    Write-Host "Action log: $actionLog" -ForegroundColor Green
    Write-Host 'Recovery run finished. A 5G icon still depends on local coverage, SIM provisioning, and supported hardware bands.' -ForegroundColor Green
} catch {
    if ($actionLog) { Write-ActionLog "FAILED: $($_.Exception.Message)" }
    Write-Host ''
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($settingsCompleted) {
        Write-Host 'All core settings were applied, but the post-reboot connection or verification did not finish.' -ForegroundColor Yellow
        Write-Host 'Reconnect and unlock the phone, then run verify-5g.cmd; do not repeat the menu steps just for this message.' -ForegroundColor Yellow
    } else {
        Write-Host 'The script stopped before all menu settings were verified. No factory reset, CSC change, or flashing command is used.' -ForegroundColor Yellow
        Write-Host 'Use docs\manual-menu-paths.md only if the same menu error repeats.' -ForegroundColor Yellow
    }
    exit 1
}
