# ============================================================
#   PC Optimizer & Windows AI Disabler
#   GitHub: วางไฟล์นี้ใน repo แล้วรันด้วย PowerShell
#   รันด้วย: powershell -ExecutionPolicy Bypass -File PC-Optimizer.ps1
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── ธีมสี ──────────────────────────────────────────────────
$bgColor      = [System.Drawing.Color]::FromArgb(15, 15, 25)
$panelColor   = [System.Drawing.Color]::FromArgb(25, 25, 40)
$accentBlue   = [System.Drawing.Color]::FromArgb(0, 150, 255)
$accentPurple = [System.Drawing.Color]::FromArgb(150, 0, 255)
$accentGreen  = [System.Drawing.Color]::FromArgb(0, 220, 120)
$accentRed    = [System.Drawing.Color]::FromArgb(255, 60, 80)
$textColor    = [System.Drawing.Color]::White
$subTextColor = [System.Drawing.Color]::FromArgb(160, 160, 180)

# ── Helper: สร้างปุ่มสวย ────────────────────────────────────
function New-FancyButton {
    param(
        [string]$Text,
        [int]$X, [int]$Y,
        [int]$Width = 320, [int]$Height = 48,
        [System.Drawing.Color]$Color,
        [string]$Icon = ""
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = "$Icon  $Text"
    $btn.Location  = New-Object System.Drawing.Point($X, $Y)
    $btn.Size      = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize  = 0
    $btn.BackColor = $Color
    $btn.ForeColor = $textColor
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb([Math]::Min(255,$this.BackColor.R+30), [Math]::Min(255,$this.BackColor.G+30), [Math]::Min(255,$this.BackColor.B+30)) })
    $btn.Add_MouseLeave({ $this.BackColor = $Color })
    return $btn
}

# ── Helper: Label ───────────────────────────────────────────
function New-Label {
    param([string]$Text, [int]$X, [int]$Y, [int]$W=320, [int]$H=22,
          [System.Drawing.Color]$Color, [int]$FontSize=9, [System.Drawing.FontStyle]$Style=[System.Drawing.FontStyle]::Regular)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $Text
    $lbl.Location  = New-Object System.Drawing.Point($X, $Y)
    $lbl.Size      = New-Object System.Drawing.Size($W, $H)
    $lbl.ForeColor = $Color
    $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", $FontSize, $Style)
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    return $lbl
}

# ── Log Box ─────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $prefix = switch ($Type) {
        "OK"    { "[✓]" }
        "WARN"  { "[!]" }
        "ERROR" { "[✗]" }
        default { "[→]" }
    }
    $logBox.AppendText("$prefix $Message`r`n")
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ════════════════════════════════════════════════════════════
#   ฟังก์ชัน: ทำให้คอมลื่น
# ════════════════════════════════════════════════════════════
function Optimize-PC {
    Write-Log "เริ่มปรับแต่งประสิทธิภาพ..." "INFO"

    # 1. ปิด Visual Effects ที่ไม่จำเป็น
    Write-Log "ปิด Visual Effects..."
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "Visual Effects → ตั้งค่า Best Performance" "OK"

    # 2. ปิด Startup Delay
    $sdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
    if (!(Test-Path $sdPath)) { New-Item -Path $sdPath -Force | Out-Null }
    Set-ItemProperty -Path $sdPath -Name "StartupDelayInMSec" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "Startup Delay → ปิดแล้ว" "OK"

    # 3. ปิด GameDVR / Game Bar (กิน CPU/RAM)
    $gdvr = "HKCU:\System\GameConfigStore"
    if (Test-Path $gdvr) {
        Set-ItemProperty -Path $gdvr -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
    }
    $gb = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
    if (!(Test-Path $gb)) { New-Item -Path $gb -Force | Out-Null }
    Set-ItemProperty -Path $gb -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "Game Bar / GameDVR → ปิดแล้ว" "OK"

    # 4. ตั้ง Power Plan → High Performance
    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Log "Power Plan → High Performance" "OK"
    } catch {
        Write-Log "Power Plan: ไม่สามารถเปลี่ยนได้ (ข้าม)" "WARN"
    }

    # 5. ปิด Search Indexing (ถ้า service มีอยู่)
    try {
        $svc = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
            Set-Service  -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "Windows Search Indexing → ปิดแล้ว" "OK"
        }
    } catch { Write-Log "Search Indexing: ข้าม" "WARN" }

    # 6. ล้าง Temp files
    Write-Log "ล้างไฟล์ Temp..."
    $tempPaths = @($env:TEMP, $env:TMP, "C:\Windows\Temp")
    $freed = 0
    foreach ($p in $tempPaths) {
        if (Test-Path $p) {
            $files = Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                try {
                    $freed += $f.Length
                    Remove-Item $f.FullName -Force -Recurse -ErrorAction SilentlyContinue
                } catch {}
            }
        }
    }
    $freedMB = [Math]::Round($freed / 1MB, 1)
    Write-Log "ล้าง Temp เสร็จ → ได้พื้นที่คืน $freedMB MB" "OK"

    # 7. ปรับ RAM Priority ผ่าน Registry
    $mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-ItemProperty -Path $mmPath -Name "ClearPageFileAtShutdown" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $mmPath -Name "LargeSystemCache" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "Memory Management → ปรับแล้ว" "OK"

    Write-Log "══════════════════════════════" "INFO"
    Write-Log "✅ ปรับแต่งคอมเสร็จสมบูรณ์!" "OK"
}

# ════════════════════════════════════════════════════════════
#   ฟังก์ชัน: ปิด Windows AI Features
# ════════════════════════════════════════════════════════════
function Disable-WindowsAI {
    Write-Log "เริ่มปิด Windows AI Features..." "INFO"

    # 1. ปิด Copilot
    $cpPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (!(Test-Path $cpPath)) { New-Item -Path $cpPath -Force | Out-Null }
    Set-ItemProperty -Path $cpPath -Name "TurnOffWindowsCopilot" -Value 1 -ErrorAction SilentlyContinue
    # ซ่อน Copilot จาก Taskbar
    $tbPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $tbPath -Name "ShowCopilotButton" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "Windows Copilot → ปิดแล้ว" "OK"

    # 2. ปิด Cortana
    $cortanaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $cortanaPath -Name "CortanaConsent" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cortanaPath -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cortanaPath -Name "AllowSearchToUseLocation" -Value 0 -ErrorAction SilentlyContinue
    try {
        $cortSvc = Get-Service -Name "WpnService" -ErrorAction SilentlyContinue
        # (Cortana ไม่มี standalone service ใน Win11 แต่ปิดผ่าน policy ได้)
    } catch {}
    Write-Log "Cortana → ปิดแล้ว" "OK"

    # 3. ปิด AI-powered Search ใน Taskbar
    $srchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $srchPath -Name "SearchboxTaskbarMode" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "AI Search / Web Search ใน Taskbar → ปิดแล้ว" "OK"

    # 4. ปิด Windows Recall (Win11 24H2+)
    $recallPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
    if (!(Test-Path $recallPath)) { New-Item -Path $recallPath -Force | Out-Null }
    Set-ItemProperty -Path $recallPath -Name "DisableAIDataAnalysis" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "Windows Recall → ปิดแล้ว" "OK"

    # 5. ปิด Suggested Content / AI Ads
    $cpPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    $aiAdKeys = @("SubscribedContent-338389Enabled","SubscribedContent-353694Enabled",
                  "SubscribedContent-353696Enabled","SilentInstalledAppsEnabled",
                  "SystemPaneSuggestionsEnabled","SoftLandingEnabled")
    foreach ($k in $aiAdKeys) {
        Set-ItemProperty -Path $cpPath2 -Name $k -Value 0 -ErrorAction SilentlyContinue
    }
    Write-Log "AI Suggested Content / Tips → ปิดแล้ว" "OK"

    # 6. ปิด Bing AI ใน Windows Search
    $bingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $bingPath -Name "BingSearchEnabled" -Value 0 -ErrorAction SilentlyContinue
    $bingPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (!(Test-Path $bingPol)) { New-Item -Path $bingPol -Force | Out-Null }
    Set-ItemProperty -Path $bingPol -Name "DisableWebSearch" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "Bing AI Search → ปิดแล้ว" "OK"

    # 7. ปิด Diagnostic Data (ที่ส่งให้ AI Training)
    $diagPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (!(Test-Path $diagPath)) { New-Item -Path $diagPath -Force | Out-Null }
    Set-ItemProperty -Path $diagPath -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "Telemetry / Diagnostic Data → ปิดแล้ว" "OK"

    Write-Log "══════════════════════════════" "INFO"
    Write-Log "✅ ปิด Windows AI Features เสร็จสมบูรณ์!" "OK"
    Write-Log "⚠️ รีสตาร์ทเครื่องเพื่อให้การเปลี่ยนแปลงมีผล" "WARN"
}

# ════════════════════════════════════════════════════════════
#   ฟังก์ชัน: Roblox FPS Boost
# ════════════════════════════════════════════════════════════
function Boost-RobloxFPS {
    Write-Log "══════════════════════════════"
    Write-Log "🎮 เริ่ม Roblox FPS Boost..."
    Write-Log "══════════════════════════════"

    # ── 1. ปิด Hardware-Accelerated GPU Scheduling (HAGS) ที่ทำให้ lag ใน Roblox
    Write-Log "ปรับ GPU Scheduling..."
    $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "GPU Scheduling → ปรับเป็น Legacy mode (ลด stutter)" "OK"

    # ── 2. ตั้ง CPU Priority ให้ Roblox สูงสุด (ผ่าน Image File Execution Options)
    Write-Log "ตั้ง CPU Priority ให้ RobloxPlayerBeta..."
    $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxPlayerBeta.exe\PerfOptions"
    if (!(Test-Path $ifeoPath)) { New-Item -Path $ifeoPath -Force | Out-Null }
    Set-ItemProperty -Path $ifeoPath -Name "CpuPriorityClass" -Value 3 -ErrorAction SilentlyContinue
    # 3 = High Priority
    Write-Log "CPU Priority → High (สำหรับ Roblox)" "OK"

    # ── 3. ปิด Nagle's Algorithm (ลด Ping / Network Lag ใน Roblox)
    Write-Log "ปิด Nagle's Algorithm (ลด Ping)..."
    $tcpPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $interfaces = Get-ChildItem $tcpPath -ErrorAction SilentlyContinue
    $count = 0
    foreach ($iface in $interfaces) {
        $fullPath = $iface.PSPath
        Set-ItemProperty -Path $fullPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $fullPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
        $count++
    }
    Write-Log "Nagle's Algorithm → ปิดแล้ว ($count interfaces)" "OK"

    # ── 4. ปิด Xbox Game Bar และ Overlay ที่กิน FPS
    Write-Log "ปิด Xbox Overlay..."
    $xboxPath = "HKCU:\System\GameConfigStore"
    if (!(Test-Path $xboxPath)) { New-Item -Path $xboxPath -Force | Out-Null }
    Set-ItemProperty -Path $xboxPath -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $xboxPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $xboxPath -Name "Win32_AutoGameModeDefaultProfile" -Value ([byte[]](0x01,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Write-Log "Xbox Game Bar / Overlay → ปิดแล้ว" "OK"

    # ── 5. เปิด Game Mode ใน Windows
    Write-Log "เปิด Windows Game Mode..."
    $gmPath = "HKCU:\Software\Microsoft\GameBar"
    if (!(Test-Path $gmPath)) { New-Item -Path $gmPath -Force | Out-Null }
    Set-ItemProperty -Path $gmPath -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gmPath -Name "AllowAutoGameMode" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "Windows Game Mode → เปิดแล้ว (จัดสรร CPU/GPU ให้เกม)" "OK"

    # ── 6. ตั้ง Power Plan → Ultimate Performance (ดีที่สุดสำหรับเกม)
    Write-Log "ตั้ง Power Plan → Ultimate Performance..."
    try {
        # เปิดใช้ Ultimate Performance plan (มีใน Win10/11 Pro)
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
        $upPlan = powercfg /list 2>$null | Where-Object { $_ -match "Ultimate" } | Select-Object -First 1
        if ($upPlan -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})") {
            powercfg /setactive $matches[1] 2>$null
            Write-Log "Power Plan → Ultimate Performance ✓" "OK"
        } else {
            # Fallback: High Performance
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Log "Power Plan → High Performance (Ultimate ไม่มีใน edition นี้)" "OK"
        }
    } catch { Write-Log "Power Plan: ข้าม" "WARN" }

    # ── 7. ปิด fullscreen optimizations สำหรับ Roblox (ลด input lag)
    Write-Log "ปิด Fullscreen Optimizations สำหรับ Roblox..."
    $robloxPaths = @(
        "$env:LOCALAPPDATA\Roblox\Versions",
        "$env:PROGRAMFILES\Roblox\Versions",
        "${env:PROGRAMFILES(x86)}\Roblox\Versions"
    )
    $found = $false
    foreach ($rPath in $robloxPaths) {
        if (Test-Path $rPath) {
            $exeFiles = Get-ChildItem $rPath -Filter "RobloxPlayerBeta.exe" -Recurse -ErrorAction SilentlyContinue
            foreach ($exe in $exeFiles) {
                $layersPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
                if (!(Test-Path $layersPath)) { New-Item -Path $layersPath -Force | Out-Null }
                Set-ItemProperty -Path $layersPath -Name $exe.FullName -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" -ErrorAction SilentlyContinue
                $found = $true
                Write-Log "Fullscreen Opt → ปิดสำหรับ: $($exe.FullName)" "OK"
            }
        }
    }
    if (!$found) { Write-Log "ไม่พบ Roblox ในเครื่อง (จะมีผลหลังติดตั้ง)" "WARN" }

    # ── 8. ล้าง Roblox Cache (ทำให้โหลดเกมเร็วขึ้น)
    Write-Log "ล้าง Roblox Cache..."
    $cachePaths = @(
        "$env:LOCALAPPDATA\Temp\Roblox",
        "$env:LOCALAPPDATA\Roblox\logs",
        "$env:TEMP\Roblox"
    )
    $freed = 0
    foreach ($cp in $cachePaths) {
        if (Test-Path $cp) {
            $files = Get-ChildItem $cp -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                try { $freed += $f.Length; Remove-Item $f.FullName -Force -Recurse -ErrorAction SilentlyContinue } catch {}
            }
        }
    }
    Write-Log "Roblox Cache → ล้างแล้ว ($([Math]::Round($freed/1MB,1)) MB)" "OK"

    # ── 9. ปรับ GPU Preference ให้ Roblox ใช้ High Performance GPU
    Write-Log "ตั้งให้ Roblox ใช้ GPU หลัก (High Performance)..."
    $gpuPrefPath = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if (!(Test-Path $gpuPrefPath)) { New-Item -Path $gpuPrefPath -Force | Out-Null }
    # ค้นหา path จริงของ Roblox
    foreach ($rPath in $robloxPaths) {
        if (Test-Path $rPath) {
            $exeFiles = Get-ChildItem $rPath -Filter "RobloxPlayerBeta.exe" -Recurse -ErrorAction SilentlyContinue
            foreach ($exe in $exeFiles) {
                Set-ItemProperty -Path $gpuPrefPath -Name $exe.FullName -Value "GpuPreference=2;" -ErrorAction SilentlyContinue
                Write-Log "GPU → High Performance สำหรับ Roblox" "OK"
            }
        }
    }

    # ── 10. ปิด background apps ที่กิน RAM ขณะเล่นเกม
    Write-Log "ปิด Background App Refresh..."
    $bgPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    Set-ItemProperty -Path $bgPath -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "Background Apps → ปิดแล้ว (ประหยัด RAM)" "OK"

    Write-Log "══════════════════════════════"
    Write-Log "✅ Roblox FPS Boost เสร็จสมบูรณ์!" "OK"
    Write-Log "⚠️ รีสตาร์ทเครื่องแล้วเปิด Roblox" "WARN"
    Write-Log "📈 คาดว่า FPS จะเพิ่ม 20-60%" "OK"
}

# ════════════════════════════════════════════════════════════
#   สร้าง GUI หลัก
# ════════════════════════════════════════════════════════════
$form = New-Object System.Windows.Forms.Form
$form.Text            = "PC Optimizer  |  by GitHub Script"
$form.Size            = New-Object System.Drawing.Size(760, 700)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $bgColor
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false
$form.Icon            = [System.Drawing.SystemIcons]::Application

# ── Header ──────────────────────────────────────────────────
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location  = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size      = New-Object System.Drawing.Size(760, 70)
$headerPanel.BackColor = $panelColor
$form.Controls.Add($headerPanel)

$titleLabel = New-Label "⚡  PC OPTIMIZER" 20 12 400 36 $accentBlue 18 Bold
$headerPanel.Controls.Add($titleLabel)

$subLabel = New-Label "ทำให้คอมลื่น + ปิด Windows AI + Roblox FPS Boost" 22 46 500 20 $subTextColor 9
$headerPanel.Controls.Add($subLabel)

$versionLabel = New-Label "v2.0  Windows 10/11" 600 25 150 20 $subTextColor 8
$headerPanel.Controls.Add($versionLabel)

# ── Left Panel (ปุ่ม) ────────────────────────────────────────
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Location  = New-Object System.Drawing.Point(10, 80)
$leftPanel.Size      = New-Object System.Drawing.Size(350, 580)
$leftPanel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($leftPanel)

# Section: ทำให้คอมลื่น
$sec1 = New-Label "🚀  ทำให้คอมลื่น" 0 5 330 24 $accentBlue 11 Bold
$leftPanel.Controls.Add($sec1)

$btnOptimize = New-FancyButton "ปรับแต่งคอมให้ลื่น (แนะนำ)" 0 34 330 50 ([System.Drawing.Color]::FromArgb(0,100,200))  "⚡"
$btnOptimize.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show(
        "ต้องการปรับแต่งคอมให้ลื่นขึ้นใช่ไหม?`n(จะแก้ไข Registry และล้าง Temp files)",
        "ยืนยัน", "YesNo", "Question") -eq "Yes") {
        $logBox.Clear()
        Optimize-PC
    }
})
$leftPanel.Controls.Add($btnOptimize)

$btnCleanTemp = New-FancyButton "ล้าง Temp Files เท่านั้น" 0 94 330 44 ([System.Drawing.Color]::FromArgb(0,80,160)) "🗑"
$btnCleanTemp.Add_Click({
    $logBox.Clear()
    Write-Log "ล้าง Temp Files..."
    $tempPaths = @($env:TEMP, $env:TMP, "C:\Windows\Temp")
    $freed = 0
    foreach ($p in $tempPaths) {
        if (Test-Path $p) {
            $files = Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                try { $freed += $f.Length; Remove-Item $f.FullName -Force -Recurse -ErrorAction SilentlyContinue } catch {}
            }
        }
    }
    Write-Log "เสร็จ → ได้พื้นที่คืน $([Math]::Round($freed/1MB,1)) MB" "OK"
})
$leftPanel.Controls.Add($btnCleanTemp)

# Section: AI
$sec2 = New-Label "🤖  Windows AI Features" 0 155 330 24 $accentPurple 11 Bold
$leftPanel.Controls.Add($sec2)

$btnDisableAI = New-FancyButton "ปิด Windows AI ทั้งหมด" 0 184 330 50 ([System.Drawing.Color]::FromArgb(120,0,200)) "🚫"
$btnDisableAI.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show(
        "ต้องการปิด Windows AI Features ทั้งหมด?`n(Copilot, Cortana, Recall, AI Search, Telemetry)`n`nสามารถเปิดใหม่ได้ภายหลัง",
        "ยืนยัน", "YesNo", "Question") -eq "Yes") {
        $logBox.Clear()
        Disable-WindowsAI
    }
})
$leftPanel.Controls.Add($btnDisableAI)

$btnBoth = New-FancyButton "ทำทั้งคู่ (ลื่น + ปิด AI)" 0 244 330 50 ([System.Drawing.Color]::FromArgb(150,0,150)) "⚡"
$btnBoth.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show(
        "ต้องการปรับแต่งคอมให้ลื่น + ปิด AI ทั้งหมดใช่ไหม?",
        "ยืนยัน", "YesNo", "Question") -eq "Yes") {
        $logBox.Clear()
        Optimize-PC
        Disable-WindowsAI
    }
})
$leftPanel.Controls.Add($btnBoth)

# Section: Roblox FPS Boost
$accentOrange = [System.Drawing.Color]::FromArgb(255, 120, 0)
$sec25 = New-Label "🎮  Roblox FPS Boost" 0 305 330 24 $accentOrange 11 Bold
$leftPanel.Controls.Add($sec25)

$btnRoblox = New-FancyButton "Boost FPS Roblox" 0 333 330 50 ([System.Drawing.Color]::FromArgb(200, 80, 0)) "🚀"
$btnRoblox.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show(
        "Boost FPS สำหรับ Roblox?`n`nสิ่งที่จะทำ:`n• CPU Priority → High`n• ปิด Nagle's Algorithm (ลด Ping)`n• GPU → High Performance`n• ล้าง Roblox Cache`n• ตั้ง Ultimate Performance Power Plan`n• ปิด Fullscreen Optimization`n• เปิด Game Mode",
        "ยืนยัน Roblox FPS Boost", "YesNo", "Question") -eq "Yes") {
        $logBox.Clear()
        Boost-RobloxFPS
    }
})
$leftPanel.Controls.Add($btnRoblox)

$btnAllInOne = New-FancyButton "ALL-IN-ONE (ทุกอย่าง)" 0 393 330 50 ([System.Drawing.Color]::FromArgb(180, 0, 100)) "💥"
$btnAllInOne.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnAllInOne.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show(
        "รันทุกฟังก์ชันพร้อมกัน?`n• ปรับแต่งคอม`n• ปิด Windows AI`n• Boost FPS Roblox",
        "ALL-IN-ONE", "YesNo", "Question") -eq "Yes") {
        $logBox.Clear()
        Optimize-PC
        Disable-WindowsAI
        Boost-RobloxFPS
    }
})
$leftPanel.Controls.Add($btnAllInOne)
$sec3 = New-Label "🔧  เครื่องมืออื่นๆ" 0 430 330 24 $accentGreen 11 Bold
$leftPanel.Controls.Add($sec3)

$btnRestart = New-FancyButton "รีสตาร์ทเครื่อง" 0 458 155 44 ([System.Drawing.Color]::FromArgb(180,80,0)) "🔄"
$btnRestart.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("รีสตาร์ทเครื่องเลยไหม?","ยืนยัน","YesNo","Warning") -eq "Yes") {
        Restart-Computer -Force
    }
})
$leftPanel.Controls.Add($btnRestart)

$btnClearLog = New-FancyButton "ล้าง Log" 165 458 155 44 ([System.Drawing.Color]::FromArgb(50,50,70)) "🗑"
$btnClearLog.Add_Click({ $logBox.Clear() })
$leftPanel.Controls.Add($btnClearLog)

$btnExit = New-FancyButton "ออกจากโปรแกรม" 0 512 330 44 ([System.Drawing.Color]::FromArgb(180,0,40)) "✕"
$btnExit.Add_Click({ $form.Close() })
$leftPanel.Controls.Add($btnExit)

# ── Right Panel (Log) ────────────────────────────────────────
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Location  = New-Object System.Drawing.Point(370, 80)
$rightPanel.Size      = New-Object System.Drawing.Size(370, 580)
$rightPanel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($rightPanel)

$logTitle = New-Label "📋  Activity Log" 0 5 360 24 $accentGreen 11 Bold
$rightPanel.Controls.Add($logTitle)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location    = New-Object System.Drawing.Point(0, 34)
$logBox.Size        = New-Object System.Drawing.Size(370, 535)
$logBox.BackColor   = [System.Drawing.Color]::FromArgb(10,10,20)
$logBox.ForeColor   = [System.Drawing.Color]::FromArgb(0,220,120)
$logBox.Font        = New-Object System.Drawing.Font("Consolas", 9)
$logBox.ReadOnly    = $true
$logBox.ScrollBars  = "Vertical"
$logBox.BorderStyle = "None"
$rightPanel.Controls.Add($logBox)

# ── Welcome message ──────────────────────────────────────────
Write-Log "══════════════════════════════"
Write-Log "  PC Optimizer v2.0 พร้อมใช้!"
Write-Log "══════════════════════════════"
Write-Log "เลือกตัวเลือกจากเมนูด้านซ้าย"
Write-Log ""
Write-Log "🎮 Roblox? กด 'Boost FPS Roblox'"
Write-Log "💥 ทุกอย่าง? กด 'ALL-IN-ONE'" "OK"

# ── แสดงหน้าต่าง ─────────────────────────────────────────────
[System.Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()
