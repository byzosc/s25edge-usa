$ErrorActionPreference = 'Stop'

$script:ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:AdbPath = Join-Path $script:ProjectRoot 'tools\platform-tools\adb.exe'
$script:DeviceSerial = $null
$script:ActionLogPath = $null

function Start-ActionLog {
    param([string]$Label = 'actions')
    $logDir = Join-Path $script:ProjectRoot 'logs'
    if (-not (Test-Path -LiteralPath $logDir)) {
        [void](New-Item -ItemType Directory -Force -Path $logDir)
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:ActionLogPath = Join-Path $logDir "$stamp-$Label.log"
    "# S25 Edge action log`r`n# Started: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz'))" |
        Set-Content -LiteralPath $script:ActionLogPath -Encoding UTF8
    return $script:ActionLogPath
}

function Write-ActionLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    if ($script:ActionLogPath) {
        $line = "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Message"
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                Add-Content -LiteralPath $script:ActionLogPath -Value $line -Encoding UTF8 -ErrorAction Stop
                return
            } catch {
                if ($attempt -lt 3) { Start-Sleep -Milliseconds 200 }
            }
        }
        # A transient log-file lock must never interrupt a modem setting run.
        Write-Warning "Could not append to action log; continuing recovery: $script:ActionLogPath"
    }
}

function Assert-AdbAvailable {
    if (-not (Test-Path -LiteralPath $script:AdbPath)) {
        throw "Portable ADB was not found: $script:AdbPath"
    }
}

function Invoke-AdbRaw {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    Assert-AdbAvailable
    $savedPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $script:AdbPath @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedPreference
    }
    if (($code -ne 0) -and (-not $AllowFailure)) {
        throw "ADB failed (exit $code): adb $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return [pscustomobject]@{
        ExitCode = $code
        Output = ($output -join "`n")
    }
}

function Invoke-DeviceAdb {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )
    if (-not $script:DeviceSerial) {
        throw 'No ADB device has been selected.'
    }
    return Invoke-AdbRaw -Arguments (@('-s', $script:DeviceSerial) + $Arguments) -AllowFailure:$AllowFailure
}

function Wait-S25Device {
    param([int]$TimeoutSeconds = 120)

    Assert-AdbAvailable
    $env:ADB_USB_LEGACY = '1'
    [void](Invoke-AdbRaw -Arguments @('start-server') -AllowFailure)

    Write-Host 'Waiting for an authorized USB-debugging device...'
    Write-Host 'Keep the phone unlocked and accept the Allow USB debugging prompt.'

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $result = Invoke-AdbRaw -Arguments @('devices', '-l') -AllowFailure
        $deviceLines = @($result.Output -split "`r?`n" | Where-Object { $_ -match '^\S+\s+(device|unauthorized|offline)(\s|$)' })
        $authorized = @($deviceLines | Where-Object { $_ -match '^\S+\s+device(\s|$)' })
        $unauthorized = @($deviceLines | Where-Object { $_ -match '^\S+\s+unauthorized(\s|$)' })

        if ($unauthorized.Count -gt 0) {
            Write-Host 'Phone detected but not authorized. Check the phone screen.' -ForegroundColor Yellow
        }
        if ($authorized.Count -eq 1) {
            $script:DeviceSerial = ($authorized[0] -split '\s+')[0].Trim()
            Write-Host "Connected: $script:DeviceSerial" -ForegroundColor Green
            return $script:DeviceSerial
        }
        if ($authorized.Count -gt 1) {
            throw 'More than one authorized ADB device is connected. Disconnect the other device and retry.'
        }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $samsungAdb = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.Class -eq 'AndroidUsbDeviceClass' -and $_.InstanceId -match '^USB\\VID_04E8'
    } | Select-Object -First 1
    if ($samsungAdb) {
        throw @'
Windows can see the Samsung ADB interface, but ADB cannot communicate with it.
Unplug and reconnect the USB cable, keep the phone unlocked, choose File transfer
for USB use, toggle USB debugging off/on once, and accept the RSA authorization.
Then run this command again. A different data-capable USB cable/port may be needed.
'@
    }
    throw 'No Samsung ADB interface was found. Connect a data-capable USB cable and enable USB debugging.'
}

function Get-DeviceProperty {
    param([Parameter(Mandatory = $true)][string]$Name)
    return (Invoke-DeviceAdb -Arguments @('shell', 'getprop', $Name)).Output.Trim()
}

function Get-SafeDeviceSnapshot {
    $props = [ordered]@{
        captured_at       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
        model             = Get-DeviceProperty 'ro.product.model'
        product_name      = Get-DeviceProperty 'ro.product.name'
        device            = Get-DeviceProperty 'ro.product.device'
        android           = Get-DeviceProperty 'ro.build.version.release'
        sdk               = Get-DeviceProperty 'ro.build.version.sdk'
        security_patch    = Get-DeviceProperty 'ro.build.version.security_patch'
        build_incremental = Get-DeviceProperty 'ro.build.version.incremental'
        build_fingerprint = Get-DeviceProperty 'ro.build.fingerprint'
        sales_code        = Get-DeviceProperty 'ro.csc.sales_code'
        boot_sales_code   = Get-DeviceProperty 'ro.boot.sales_code'
        boot_carrier_id   = Get-DeviceProperty 'ro.boot.carrierid'
        sim_config        = Get-DeviceProperty 'persist.radio.multisim.config'
        network_type      = Get-DeviceProperty 'gsm.network.type'
        operator_name     = Get-DeviceProperty 'gsm.operator.alpha'
    }
    return [pscustomobject]$props
}

function Save-SafeDeviceSnapshot {
    param([string]$Label = 'snapshot')
    $logDir = Join-Path $script:ProjectRoot 'logs'
    if (-not (Test-Path -LiteralPath $logDir)) {
        [void](New-Item -ItemType Directory -Force -Path $logDir)
    }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $logDir "$stamp-$Label.json"
    Get-SafeDeviceSnapshot | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Get-ForegroundActivity {
    $result = Invoke-DeviceAdb -Arguments @('shell', 'dumpsys', 'window') -AllowFailure
    # Multi-user/multi-display builds can report a null focus entry before the
    # real foreground window. Keep all focus lines so package matching sees it.
    $lines = @($result.Output -split "`r?`n" | Where-Object { $_ -match 'mCurrentFocus|mFocusedApp' })
    return ($lines -join "`n")
}

function Test-ServiceModeForeground {
    return ((Get-ForegroundActivity) -match 'RilServiceModeApp|servicemodeapp')
}

function Test-ServiceModeMain {
    if (-not (Test-ServiceModeForeground)) { return $false }
    try {
        return (Test-UiLabel -Label 'UE SETTING & INFO')
    } catch {
        return $false
    }
}

function Wait-ServiceModeMain {
    param([int]$TimeoutMilliseconds = 5000)

    $deadline = (Get-Date).AddMilliseconds($TimeoutMilliseconds)
    do {
        if (Test-ServiceModeMain) { return $true }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    return $false
}

function Send-DialCode {
    param([Parameter(Mandatory = $true)][string]$Digits)

    [void](Invoke-DeviceAdb -Arguments @('shell', 'am', 'start', '-W', '-a', 'android.intent.action.DIAL') -AllowFailure)
    Start-Sleep -Milliseconds 700
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_STAR') -AllowFailure)
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_POUND') -AllowFailure)
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'text', $Digits) -AllowFailure)
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_POUND') -AllowFailure)
    Start-Sleep -Seconds 2
}

function Open-SamsungServiceMain {
    Write-Host 'Opening Samsung Service Mode through ADB...'
    Write-ActionLog 'Open Service Mode: begin'
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP') -AllowFailure)

    # A prior setting may leave Service Mode on a deep result page. Restart only
    # this diagnostic app so every action begins from a known main-menu state.
    if (Test-ServiceModeForeground) {
        [void](Invoke-DeviceAdb -Arguments @('shell', 'am', 'force-stop', 'com.sec.android.RilServiceModeApp') -AllowFailure)
        Write-ActionLog 'Force-stopped stale Service Mode page so navigation restarts at main menu'
        Start-Sleep -Milliseconds 500
    }

    $components = @(
        'com.sec.android.RilServiceModeApp/.ServiceModeApp',
        'com.sec.android.RilServiceModeApp/com.sec.android.RilServiceModeApp.ServiceModeApp'
    )
    foreach ($component in $components) {
        [void](Invoke-DeviceAdb -Arguments @('shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN', '-n', $component, '--es', 'keyString', '27663368378') -AllowFailure)
        if (Wait-ServiceModeMain -TimeoutMilliseconds 3000) {
            Write-ActionLog "Opened Service Mode through direct activity: $component"
            return $true
        }
    }

    $actions = @('com.samsung.android.action.SECRET_CODE', 'android.provider.Telephony.SECRET_CODE')
    foreach ($action in $actions) {
        [void](Invoke-DeviceAdb -Arguments @('shell', 'am', 'broadcast', '-a', $action, '-d', 'android_secret_code://27663368378') -AllowFailure)
        if (Wait-ServiceModeMain -TimeoutMilliseconds 3000) {
            Write-ActionLog "Opened Service Mode through secret-code broadcast: $action"
            return $true
        }
    }

    Send-DialCode -Digits '27663368378'
    if (Wait-ServiceModeMain -TimeoutMilliseconds 8000) {
        Write-ActionLog 'Opened Service Mode by controlling Samsung Dialer and entering 27663368378'
        return $true
    }

    throw @'
ADB could not open Service Mode. Keep the phone unlocked and retry.
If this US firmware blocks Samsung secret codes, enable secret codes once with
the SamFW MTP function mentioned in the saved screenshot, then rerun this script.
'@
}

function Get-UiHierarchy {
    $remote = '/sdcard/s25edge-usa-ui.xml'
    [void](Invoke-DeviceAdb -Arguments @('shell', 'uiautomator', 'dump', $remote) -AllowFailure)
    $xmlText = (Invoke-DeviceAdb -Arguments @('exec-out', 'cat', $remote)).Output
    try {
        return [xml]$xmlText
    } catch {
        throw "Could not parse the current Android UI hierarchy. Service Mode may not expose accessible text.`n$xmlText"
    }
}

function Get-NormalizedMenuLabel {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $value = $Text -replace '^\s*\[\d+\]\s*', ''
    $value = $value -replace '\s+', ' '
    return $value.Trim().ToUpperInvariant()
}

function Find-UiNodeByLabel {
    param([Parameter(Mandatory = $true)][string]$Label)

    $xml = Get-UiHierarchy
    $wanted = Get-NormalizedMenuLabel $Label
    $all = @($xml.SelectNodes('//node'))
    $exact = @()
    $partial = @()
    foreach ($node in $all) {
        $candidates = @([string]$node.text, [string]$node.'content-desc')
        foreach ($candidate in $candidates) {
            $normalized = Get-NormalizedMenuLabel $candidate
            if (-not $normalized) { continue }
            if ($normalized -eq $wanted) { $exact += $node; break }
            if ($normalized.Contains($wanted)) { $partial += $node; break }
        }
    }
    if ($exact.Count -gt 0) { return $exact[0] }
    if ($partial.Count -gt 0) { return $partial | Sort-Object { ([string]$_.text).Length } | Select-Object -First 1 }
    return $null
}

function Test-UiLabel {
    param([Parameter(Mandatory = $true)][string]$Label)
    return ($null -ne (Find-UiNodeByLabel -Label $Label))
}

function Tap-UiLabel {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [int]$WaitMilliseconds = 900
    )

    $node = Find-UiNodeByLabel -Label $Label
    if ($null -eq $node) {
        throw "Menu text not found on the current screen: $Label"
    }
    $bounds = [string]$node.bounds
    if ($bounds -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
        throw "Invalid UI bounds for '$Label': $bounds"
    }
    $x = [math]::Floor(([int]$Matches[1] + [int]$Matches[3]) / 2)
    $y = [math]::Floor(([int]$Matches[2] + [int]$Matches[4]) / 2)
    Write-Host "  Tap: $Label"
    Write-ActionLog "UI tap: $Label"
    [void](Invoke-DeviceAdb -Arguments @('shell', 'input', 'tap', [string]$x, [string]$y))
    Start-Sleep -Milliseconds $WaitMilliseconds
}

function Open-And-FollowMenuPath {
    param([Parameter(Mandatory = $true)][string[]]$Labels)
    [void](Open-SamsungServiceMain)
    Start-Sleep -Seconds 1
    foreach ($label in $Labels) {
        Tap-UiLabel -Label $label
    }
}

function Invoke-ServiceModeSetting {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$ParentPath,
        [Parameter(Mandatory = $true)][string]$ActionLabel,
        [string]$AlreadyAppliedLabel
    )

    Write-Host "Applying: $Name" -ForegroundColor Cyan
    Write-ActionLog "Setting begin: $Name"
    Open-And-FollowMenuPath -Labels $ParentPath
    if ($AlreadyAppliedLabel -and (Test-UiLabel -Label $AlreadyAppliedLabel)) {
        Write-Host "  Already applied: $AlreadyAppliedLabel" -ForegroundColor Green
        Write-ActionLog "Setting already applied: $Name ($AlreadyAppliedLabel visible)"
        return
    }
    Tap-UiLabel -Label $ActionLabel
    Write-ActionLog "Setting action selected: $Name -> $ActionLabel"
}

function Get-RadioSummary {
    $registry = (Invoke-DeviceAdb -Arguments @('shell', 'dumpsys', 'telephony.registry') -AllowFailure).Output
    $summary = [ordered]@{
        captured_at           = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
        network_type_property = Get-DeviceProperty 'gsm.network.type'
        operator_name         = Get-DeviceProperty 'gsm.operator.alpha'
        data_network_types    = @([regex]::Matches($registry, 'mDataNetworkType=([^\s,}]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        voice_network_types   = @([regex]::Matches($registry, 'mVoiceNetworkType=([^\s,}]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        nr_states             = @([regex]::Matches($registry, '(?:nrState|mNrState)=([^\s,}]+)', 'IgnoreCase') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    }
    return [pscustomobject]$summary
}
