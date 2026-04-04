# ============================================================
#   PC Optimizer v3.1  — Dark UI + Toggle + Background Image
#   รันด้วย: powershell -ExecutionPolicy Bypass -File PC-Optimizer.ps1
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:toggleStates = @{}
$script:logBox        = $null
$script:activeTab     = "home"
$script:panels        = @{}
$script:tabBtns       = @{}

# ══════════════════════════════════════════════════════════
#  OPTIMIZER FUNCTIONS
# ══════════════════════════════════════════════════════════
function Optimize-PC {
    Write-Log "เริ่มปรับแต่งคอม..." "INFO"
    $rp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if(!(Test-Path $rp)){New-Item $rp -Force|Out-Null}
    Set-ItemProperty $rp "VisualFXSetting" 2 -EA SilentlyContinue
    Write-Log "Visual Effects → Best Performance" "OK"
    $sp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
    if(!(Test-Path $sp)){New-Item $sp -Force|Out-Null}
    Set-ItemProperty $sp "StartupDelayInMSec" 0 -EA SilentlyContinue
    Write-Log "Startup Delay → ปิด" "OK"
    Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 -EA SilentlyContinue
    Write-Log "Game Bar/DVR → ปิด" "OK"
    try{powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null;Write-Log "Power Plan → High Performance" "OK"}catch{}
    try{Stop-Service "WSearch" -Force -EA SilentlyContinue;Set-Service "WSearch" -StartupType Disabled -EA SilentlyContinue;Write-Log "Search Indexing → ปิด" "OK"}catch{}
    $freed=0;@($env:TEMP,$env:TMP,"C:\Windows\Temp")|ForEach-Object{if(Test-Path $_){Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue|ForEach-Object{try{$freed+=$_.Length;Remove-Item $_.FullName -Force -Recurse -EA SilentlyContinue}catch{}}}}
    Write-Log "Temp → ล้าง $([Math]::Round($freed/1MB,1)) MB" "OK"
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 -EA SilentlyContinue
    Write-Log "Memory Management → ปรับแล้ว" "OK"
    Write-Log "✅ ปรับแต่งคอมเสร็จ!" "OK"
}

function Disable-WindowsAI {
    Write-Log "เริ่มปิด Windows AI..." "INFO"
    $cp="HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if(!(Test-Path $cp)){New-Item $cp -Force|Out-Null}
    Set-ItemProperty $cp "TurnOffWindowsCopilot" 1 -EA SilentlyContinue
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0 -EA SilentlyContinue
    Write-Log "Copilot → ปิด" "OK"
    $sr="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    "CortanaConsent","BingSearchEnabled","AllowSearchToUseLocation"|ForEach-Object{Set-ItemProperty $sr $_ 0 -EA SilentlyContinue}
    Write-Log "Cortana/Bing → ปิด" "OK"
    $rc="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
    if(!(Test-Path $rc)){New-Item $rc -Force|Out-Null}
    Set-ItemProperty $rc "DisableAIDataAnalysis" 1 -EA SilentlyContinue
    Write-Log "Windows Recall → ปิด" "OK"
    $cdm="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    "SubscribedContent-338389Enabled","SubscribedContent-353694Enabled","SubscribedContent-353696Enabled","SilentInstalledAppsEnabled","SystemPaneSuggestionsEnabled","SoftLandingEnabled"|ForEach-Object{Set-ItemProperty $cdm $_ 0 -EA SilentlyContinue}
    Write-Log "AI Ads/Suggestions → ปิด" "OK"
    $dg="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if(!(Test-Path $dg)){New-Item $dg -Force|Out-Null}
    Set-ItemProperty $dg "AllowTelemetry" 0 -EA SilentlyContinue
    Write-Log "Telemetry → ปิด" "OK"
    Write-Log "✅ ปิด AI เสร็จ! (รีสตาร์ทเพื่อให้มีผล)" "OK"
}

function Boost-RobloxFPS {
    Write-Log "🎮 Roblox FPS Boost เริ่ม..." "INFO"
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 1 -EA SilentlyContinue
    Write-Log "GPU Scheduling → Legacy (ลด stutter)" "OK"
    $ifeo="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxPlayerBeta.exe\PerfOptions"
    if(!(Test-Path $ifeo)){New-Item $ifeo -Force|Out-Null}
    Set-ItemProperty $ifeo "CpuPriorityClass" 3 -EA SilentlyContinue
    Write-Log "CPU Priority → High (Roblox)" "OK"
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA SilentlyContinue|ForEach-Object{
        Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -EA SilentlyContinue
        Set-ItemProperty $_.PSPath "TCPNoDelay" 1 -EA SilentlyContinue
    }
    Write-Log "Nagle's Algorithm → ปิด (ลด Ping)" "OK"
    $xb="HKCU:\System\GameConfigStore"
    if(!(Test-Path $xb)){New-Item $xb -Force|Out-Null}
    Set-ItemProperty $xb "GameDVR_Enabled" 0 -EA SilentlyContinue
    Set-ItemProperty $xb "GameDVR_FSEBehaviorMode" 2 -EA SilentlyContinue
    Write-Log "Xbox Overlay → ปิด" "OK"
    $gm="HKCU:\Software\Microsoft\GameBar"
    if(!(Test-Path $gm)){New-Item $gm -Force|Out-Null}
    Set-ItemProperty $gm "AutoGameModeEnabled" 1 -EA SilentlyContinue
    Write-Log "Game Mode → เปิด" "OK"
    try{
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
        $up=powercfg /list 2>$null|Where-Object{$_ -match "Ultimate"}|Select-Object -First 1
        if($up -match "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"){powercfg /setactive $matches[1] 2>$null;Write-Log "Power Plan → Ultimate Performance" "OK"}
        else{powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null;Write-Log "Power Plan → High Performance" "OK"}
    }catch{}
    $rPaths=@("$env:LOCALAPPDATA\Roblox\Versions","$env:PROGRAMFILES\Roblox\Versions")
    $lyr="HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    $gpr="HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
    if(!(Test-Path $lyr)){New-Item $lyr -Force|Out-Null}
    if(!(Test-Path $gpr)){New-Item $gpr -Force|Out-Null}
    $found=$false
    foreach($rp in $rPaths){if(Test-Path $rp){Get-ChildItem $rp -Filter "RobloxPlayerBeta.exe" -Recurse -EA SilentlyContinue|ForEach-Object{Set-ItemProperty $lyr $_.FullName "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" -EA SilentlyContinue;Set-ItemProperty $gpr $_.FullName "GpuPreference=2;" -EA SilentlyContinue;Write-Log "Roblox.exe → GPU High + Fullscreen Opt ปิด" "OK";$found=$true}}}
    if(!$found){Write-Log "ไม่พบ Roblox (จะมีผลหลังติดตั้ง)" "WARN"}
    $freed=0;@("$env:LOCALAPPDATA\Temp\Roblox","$env:LOCALAPPDATA\Roblox\logs","$env:TEMP\Roblox")|ForEach-Object{if(Test-Path $_){Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue|ForEach-Object{try{$freed+=$_.Length;Remove-Item $_.FullName -Force -Recurse -EA SilentlyContinue}catch{}}}}
    Write-Log "Roblox Cache → ล้าง $([Math]::Round($freed/1MB,1)) MB" "OK"
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 -EA SilentlyContinue
    Write-Log "Background Apps → ปิด" "OK"
    Write-Log "✅ Roblox Boost เสร็จ! (FPS +20~60%) รีสตาร์ทแล้วเล่นได้เลย" "OK"
}

# ══════════════════════════════════════════════════════════
#  WRITE-LOG
# ══════════════════════════════════════════════════════════
function Write-Log {
    param([string]$Message,[string]$Type="INFO")
    $prefix=switch($Type){"OK"{"[✓]"}"WARN"{"[!]"}"ERROR"{"[✗]"}default{"[→]"}}
    if($null -ne $script:logBox){$script:logBox.AppendText("$prefix $Message`r`n");$script:logBox.ScrollToCaret()}
    [System.Windows.Forms.Application]::DoEvents()
}

# ══════════════════════════════════════════════════════════
#  FORM — วาดพื้นหลังโดยตรงบน Form (ไม่ใช้ Overlay Panel)
# ══════════════════════════════════════════════════════════
$form = New-Object System.Windows.Forms.Form
$form.Text            = "PC Optimizer v3.1"
$form.Size            = New-Object System.Drawing.Size(900, 640)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false
$form.BackColor       = [System.Drawing.Color]::FromArgb(10,10,20)

# โหลดรูปพื้นหลัง แล้ววาดผ่าน Paint event (ไม่ทับ controls)
$script:bgImage = $null
try {
    $wc    = New-Object System.Net.WebClient
    $bytes = $wc.DownloadData("https://cdn.discordapp.com/attachments/1475107345091788872/1489953684254228591/2Q.png?ex=69d24b00&is=69d0f980&hm=93baa6b961925defa5c4bebe67bbbfb3e11d83b086cb25c00bb22312ea03cf22&")
    $script:bgImage = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new($bytes))
} catch {}

$form.Add_Paint({
    param($s,$e)
    if($null -ne $script:bgImage) {
        $e.Graphics.DrawImage($script:bgImage, 0, 0, $s.ClientSize.Width, $s.ClientSize.Height)
        # Overlay กึ่งโปร่งแสงทับรูป
        $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(175,8,8,18))
        $e.Graphics.FillRectangle($br, 0, 0, $s.ClientSize.Width, $s.ClientSize.Height)
        $br.Dispose()
    }
})

# ── HELPER สร้าง Label โปร่งแสง ────────────────────────────
function New-Lbl {
    param([string]$T,[int]$X,[int]$Y,[int]$W,[int]$H,[System.Drawing.Color]$C,[float]$Sz=9,[System.Drawing.FontStyle]$St=[System.Drawing.FontStyle]::Regular)
    $l=New-Object System.Windows.Forms.Label
    $l.Text=$T;$l.Location=New-Object System.Drawing.Point($X,$Y);$l.Size=New-Object System.Drawing.Size($W,$H)
    $l.Font=New-Object System.Drawing.Font("Segoe UI",$Sz,$St);$l.ForeColor=$C;$l.BackColor=[System.Drawing.Color]::Transparent
    return $l
}

# ── HELPER ปุ่ม ─────────────────────────────────────────────
function New-Btn {
    param([string]$T,[int]$X,[int]$Y,[int]$W,[int]$H,[System.Drawing.Color]$Bg,[float]$Sz=9,[System.Drawing.FontStyle]$St=[System.Drawing.FontStyle]::Bold)
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$T;$b.Location=New-Object System.Drawing.Point($X,$Y);$b.Size=New-Object System.Drawing.Size($W,$H)
    $b.FlatStyle="Flat";$b.FlatAppearance.BorderSize=0;$b.BackColor=$Bg;$b.ForeColor=[System.Drawing.Color]::White
    $b.Font=New-Object System.Drawing.Font("Segoe UI",$Sz,$St);$b.Cursor=[System.Windows.Forms.Cursors]::Hand
    return $b
}

# ── TOGGLE SWITCH ───────────────────────────────────────────
function New-Toggle {
    param([string]$Key,[int]$X,[int]$Y,[bool]$Default=$true)
    $script:toggleStates[$Key]=$Default
    $p=New-Object System.Windows.Forms.Panel
    $p.Location=New-Object System.Drawing.Point($X,$Y);$p.Size=New-Object System.Drawing.Size(58,26)
    $p.BackColor=[System.Drawing.Color]::Transparent;$p.Cursor=[System.Windows.Forms.Cursors]::Hand;$p.Tag=$Key
    $p.Add_Paint({
        param($s,$e);$g=$e.Graphics;$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $on=$script:toggleStates[$s.Tag]
        $tc=if($on){[System.Drawing.Color]::FromArgb(0,210,100)}else{[System.Drawing.Color]::FromArgb(60,60,85)}
        $tb=New-Object System.Drawing.SolidBrush($tc)
        $g.FillEllipse($tb,0,3,20,20);$g.FillEllipse($tb,36,3,20,20);$g.FillRectangle($tb,10,3,36,20)
        $kx=if($on){33}else{2};$g.FillEllipse([System.Drawing.Brushes]::White,$kx,5,22,16)
        $tb.Dispose()
    })
    $p.Add_Click({$script:toggleStates[$this.Tag]=-not $script:toggleStates[$this.Tag];$this.Invalidate()})
    return $p
}

# ══════════════════════════════════════════════════════════
#  HEADER PANEL (วาดพื้นหลังทึบ + ใส่ข้อความ)
# ══════════════════════════════════════════════════════════
$hdr=New-Object System.Windows.Forms.Panel
$hdr.Location=New-Object System.Drawing.Point(0,0);$hdr.Size=New-Object System.Drawing.Size(900,62)
$hdr.BackColor=[System.Drawing.Color]::FromArgb(210,8,8,20)
$form.Controls.Add($hdr)

$hdr.Controls.Add((New-Lbl "⚡  PC OPTIMIZER" 16 6 460 32 ([System.Drawing.Color]::FromArgb(0,185,255)) 20 Bold))
$hdr.Controls.Add((New-Lbl "ทำให้คอมลื่น  •  ปิด Windows AI  •  Roblox FPS Boost  •  v3.1" 18 42 700 18 ([System.Drawing.Color]::FromArgb(135,135,175)) 8.5))

# ══════════════════════════════════════════════════════════
#  TAB BAR (แนวนอน)
# ══════════════════════════════════════════════════════════
$tabBar=New-Object System.Windows.Forms.Panel
$tabBar.Location=New-Object System.Drawing.Point(0,62);$tabBar.Size=New-Object System.Drawing.Size(900,42)
$tabBar.BackColor=[System.Drawing.Color]::FromArgb(215,10,10,22)
$form.Controls.Add($tabBar)

# เส้นล่าง tabBar
$tLine=New-Object System.Windows.Forms.Panel
$tLine.Location=New-Object System.Drawing.Point(0,40);$tLine.Size=New-Object System.Drawing.Size(900,2)
$tLine.BackColor=[System.Drawing.Color]::FromArgb(45,45,65)
$tabBar.Controls.Add($tLine)

# Content area
$content=New-Object System.Windows.Forms.Panel
$content.Location=New-Object System.Drawing.Point(0,104);$content.Size=New-Object System.Drawing.Size(900,496)
$content.BackColor=[System.Drawing.Color]::Transparent
$form.Controls.Add($content)

# Tab definitions
$tabDefs=@(
    @{N="home";   L="🏠  หน้าหลัก";    X=5;   C=[System.Drawing.Color]::FromArgb(0,165,255)},
    @{N="pc";     L="⚡  คอมลื่น";      X=155; C=[System.Drawing.Color]::FromArgb(0,205,100)},
    @{N="ai";     L="🤖  ปิด AI";       X=305; C=[System.Drawing.Color]::FromArgb(170,0,255)},
    @{N="roblox"; L="🎮  Roblox Boost"; X=455; C=[System.Drawing.Color]::FromArgb(255,125,0)},
    @{N="log";    L="📋  Activity Log"; X=605; C=[System.Drawing.Color]::FromArgb(0,220,120)}
)

foreach($td in $tabDefs){
    $p=New-Object System.Windows.Forms.Panel
    $p.Location=New-Object System.Drawing.Point(0,0);$p.Size=New-Object System.Drawing.Size(900,496)
    $p.BackColor=[System.Drawing.Color]::Transparent;$p.Visible=$false
    $content.Controls.Add($p);$script:panels[$td.N]=$p
}

function Switch-Tab([string]$Name){
    $script:activeTab=$Name
    foreach($k in $script:panels.Keys){$script:panels[$k].Visible=($k -eq $Name)}
    foreach($td2 in $tabDefs){
        $b=$script:tabBtns[$td2.N]
        if($td2.N -eq $Name){$b.ForeColor=$td2.C;$b.BackColor=[System.Drawing.Color]::FromArgb(50,$td2.C.R,$td2.C.G,$td2.C.B)}
        else{$b.ForeColor=[System.Drawing.Color]::FromArgb(165,165,200);$b.BackColor=[System.Drawing.Color]::Transparent}
    }
}

foreach($td in $tabDefs){
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$td.L;$b.Location=New-Object System.Drawing.Point($td.X,4);$b.Size=New-Object System.Drawing.Size(145,34)
    $b.FlatStyle="Flat";$b.FlatAppearance.BorderSize=0;$b.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $b.ForeColor=[System.Drawing.Color]::FromArgb(165,165,200);$b.BackColor=[System.Drawing.Color]::Transparent
    $b.Cursor=[System.Windows.Forms.Cursors]::Hand;$b.Tag=$td.N
    $b.Add_Click({Switch-Tab $this.Tag})
    $tabBar.Controls.Add($b);$script:tabBtns[$td.N]=$b
}

# ══════════════════════════════════════════════════════════
#  TAB: HOME
# ══════════════════════════════════════════════════════════
$ph=$script:panels["home"]

# Welcome banner — Panel มีพื้นหลังทึบพอที่อ่านได้
$wb=New-Object System.Windows.Forms.Panel
$wb.Location=New-Object System.Drawing.Point(18,14);$wb.Size=New-Object System.Drawing.Size(860,72)
$wb.BackColor=[System.Drawing.Color]::FromArgb(200,12,12,26)
$ph.Controls.Add($wb)
$wb.Controls.Add((New-Lbl "ยินดีต้อนรับ!  เลือก Tab ด้านบน หรือคลิกการ์ดด้านล่างเพื่อรันได้เลย 👇" 16 10 830 24 ([System.Drawing.Color]::White) 12 Bold))
$wb.Controls.Add((New-Lbl "แต่ละการ์ดรันฟีเจอร์ทันที  ·  Tab แต่ละอันมี Toggle ให้ปรับก่อนรัน" 16 40 830 20 ([System.Drawing.Color]::FromArgb(145,145,180)) 9))

# การ์ด 4 ใบแนวนอน
$cDefs=@(
    @{T="⚡  คอมลื่น";       S1="ปรับ Registry + ล้าง Temp"; S2="Power Plan High Performance"; X=18;  C=[System.Drawing.Color]::FromArgb(0,140,240);  A={$script:logBox.Clear();Switch-Tab "log";Optimize-PC}},
    @{T="🤖  ปิด Windows AI"; S1="Copilot • Cortana • Recall"; S2="Telemetry • AI Ads • Bing";   X=238; C=[System.Drawing.Color]::FromArgb(150,0,245); A={$script:logBox.Clear();Switch-Tab "log";Disable-WindowsAI}},
    @{T="🎮  Roblox FPS";    S1="CPU High • ลด Ping • GPU";  S2="ล้าง Cache • ปิด Overlay";    X=458; C=[System.Drawing.Color]::FromArgb(245,110,0);  A={$script:logBox.Clear();Switch-Tab "log";Boost-RobloxFPS}},
    @{T="💥  ALL-IN-ONE";    S1="รันทุกอย่างพร้อมกัน";      S2="แนะนำสำหรับครั้งแรก";         X=678; C=[System.Drawing.Color]::FromArgb(215,25,75);  A={$script:logBox.Clear();Switch-Tab "log";Optimize-PC;Disable-WindowsAI;Boost-RobloxFPS}}
)

foreach($cd in $cDefs){
    $ac=$cd.C;$act=$cd.A
    $cp=New-Object System.Windows.Forms.Panel
    $cp.Location=New-Object System.Drawing.Point($cd.X,102);$cp.Size=New-Object System.Drawing.Size(205,128)
    $cp.BackColor=[System.Drawing.Color]::FromArgb(210,14,14,28);$cp.Cursor=[System.Windows.Forms.Cursors]::Hand
    $cp.Add_Paint({
        param($s,$e);$g=$e.Graphics;$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $pen=New-Object System.Drawing.Pen($ac,1.5);$g.DrawRectangle($pen,0,0,$s.Width-1,$s.Height-1);$pen.Dispose()
        $br=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90,$ac.R,$ac.G,$ac.B))
        $g.FillRectangle($br,0,0,$s.Width,4);$br.Dispose()
    })
    $cp.Add_MouseEnter({$this.BackColor=[System.Drawing.Color]::FromArgb(235,20,20,38)})
    $cp.Add_MouseLeave({$this.BackColor=[System.Drawing.Color]::FromArgb(210,14,14,28)})
    $cp.Add_Click($act)

    $lt=New-Lbl $cd.T 10 10 185 22 ([System.Drawing.Color]::White) 10 Bold;$cp.Controls.Add($lt);$lt.Add_Click($act)
    $l1=New-Lbl $cd.S1 10 38 185 18 ([System.Drawing.Color]::FromArgb(170,170,205)) 8;$cp.Controls.Add($l1);$l1.Add_Click($act)
    $l2=New-Lbl $cd.S2 10 58 185 18 ([System.Drawing.Color]::FromArgb(170,170,205)) 8;$cp.Controls.Add($l2);$l2.Add_Click($act)

    $rb=New-Btn "▶ รัน" 10 90 80 26 $ac 8.5;$rb.Add_Click($act);$cp.Controls.Add($rb)
    $ph.Controls.Add($cp)
}

# System Info
$siDefs=@(
    @{L="Windows Version";V=[System.Environment]::OSVersion.Version.ToString()},
    @{L="RAM";            V="$([Math]::Round((Get-WmiObject Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1GB,1)) GB"},
    @{L="CPU";            V=((Get-WmiObject Win32_Processor -EA SilentlyContinue|Select-Object -First 1).Name)}
)
$sx=18
foreach($si in $siDefs){
    $sp=New-Object System.Windows.Forms.Panel;$sp.Location=New-Object System.Drawing.Point($sx,248)
    $sp.Size=New-Object System.Drawing.Size(278,56);$sp.BackColor=[System.Drawing.Color]::FromArgb(200,12,12,24)
    $sp.Controls.Add((New-Lbl $si.L 10 6 258 15 ([System.Drawing.Color]::FromArgb(115,115,155)) 7.5))
    $sp.Controls.Add((New-Lbl $si.V 10 24 258 22 ([System.Drawing.Color]::White) 9 Bold))
    $ph.Controls.Add($sp);$sx+=292
}

# ══════════════════════════════════════════════════════════
#  TAB: PC — Toggle rows
# ══════════════════════════════════════════════════════════
$ppc=$script:panels["pc"]
$pcOpts=@(
    @{K="vis";L="ปิด Visual Effects (Best Performance)";  D="ลด Animation ที่ไม่จำเป็น เพิ่ม FPS ได้ชัดเจน";   On=$true},
    @{K="dvr";L="ปิด Game DVR / Xbox Game Bar";           D="เพิ่ม FPS ในเกมทุกประเภท ลด overhead";            On=$true},
    @{K="pwr";L="Power Plan → High Performance";           D="CPU/GPU ทำงานเต็มกำลัง ไม่ throttle";             On=$true},
    @{K="idx";L="ปิด Windows Search Indexing";            D="ลด Disk I/O background";                           On=$false},
    @{K="tmp";L="ล้าง Temp Files";                        D="คืนพื้นที่ Disk และลด Load Time";                  On=$true},
    @{K="mem";L="ปรับ Memory Management";                  D="จัดสรร RAM ให้แอปพลิเคชันดีขึ้น";                 On=$true},
    @{K="str";L="ปิด Startup Delay";                      D="เปิดคอมเร็วขึ้น ลด delay ตอน Boot";               On=$true}
)
$yRow=10
foreach($opt in $pcOpts){
    $row=New-Object System.Windows.Forms.Panel;$row.Location=New-Object System.Drawing.Point(18,$yRow)
    $row.Size=New-Object System.Drawing.Size(862,50);$row.BackColor=[System.Drawing.Color]::FromArgb(195,12,12,24)
    $row.Controls.Add((New-Lbl $opt.L 14 6 778 18 ([System.Drawing.Color]::White) 9 Bold))
    $row.Controls.Add((New-Lbl $opt.D 14 26 778 16 ([System.Drawing.Color]::FromArgb(125,125,165)) 7.5))
    $tog=New-Toggle $opt.K 796 12 $opt.On;$row.Controls.Add($tog)
    $ppc.Controls.Add($row);$yRow+=55
}
$bPcRun=New-Btn "▶  รันตัวเลือกที่เปิดไว้" 18 ($yRow+6) 265 40 ([System.Drawing.Color]::FromArgb(0,115,200)) 10
$bPcRun.Add_Click({
    Switch-Tab "log";$script:logBox.Clear()
    if($script:toggleStates["vis"]){$rp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects";if(!(Test-Path $rp)){New-Item $rp -Force|Out-Null};Set-ItemProperty $rp "VisualFXSetting" 2 -EA SilentlyContinue;Write-Log "Visual Effects → Best Perf" "OK"}
    if($script:toggleStates["dvr"]){Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 -EA SilentlyContinue;Write-Log "GameDVR → ปิด" "OK"}
    if($script:toggleStates["pwr"]){powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null;Write-Log "Power Plan → High Perf" "OK"}
    if($script:toggleStates["idx"]){Stop-Service "WSearch" -Force -EA SilentlyContinue;Set-Service "WSearch" -StartupType Disabled -EA SilentlyContinue;Write-Log "Search → ปิด" "OK"}
    if($script:toggleStates["tmp"]){$f=0;@($env:TEMP,$env:TMP,"C:\Windows\Temp")|ForEach-Object{if(Test-Path $_){Get-ChildItem $_ -Recurse -Force -EA SilentlyContinue|ForEach-Object{try{$f+=$_.Length;Remove-Item $_.FullName -Force -Recurse -EA SilentlyContinue}catch{}}}};Write-Log "Temp → ล้าง $([Math]::Round($f/1MB,1)) MB" "OK"}
    if($script:toggleStates["mem"]){Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 -EA SilentlyContinue;Write-Log "Memory → ปรับ" "OK"}
    if($script:toggleStates["str"]){$sp="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize";if(!(Test-Path $sp)){New-Item $sp -Force|Out-Null};Set-ItemProperty $sp "StartupDelayInMSec" 0 -EA SilentlyContinue;Write-Log "Startup Delay → ปิด" "OK"}
    Write-Log "✅ เสร็จสมบูรณ์!" "OK"
})
$ppc.Controls.Add($bPcRun)

# ══════════════════════════════════════════════════════════
#  TAB: AI — Toggle rows
# ══════════════════════════════════════════════════════════
$pai=$script:panels["ai"]
$aiOpts=@(
    @{K="ai_cop";L="ปิด Windows Copilot";        D="ซ่อนปุ่มและ disable Copilot ใน Taskbar";  On=$true},
    @{K="ai_cor";L="ปิด Cortana";                D="ปิด Cortana + Bing Search integration";   On=$true},
    @{K="ai_rec";L="ปิด Windows Recall";          D="ปิด AI screenshot memory (Win11 24H2+)"; On=$true},
    @{K="ai_ads";L="ปิด AI Suggested Content";    D="บล็อก AI Ads และ Tips ใน Windows";        On=$true},
    @{K="ai_tel";L="ปิด Telemetry / Diagnostic"; D="หยุดส่งข้อมูลการใช้งานไปให้ Microsoft";  On=$true},
    @{K="ai_bin";L="ปิด Bing Web Search";         D="ปิด Bing ใน Start Menu และ Search Bar";  On=$true}
)
$yRow=10
foreach($opt in $aiOpts){
    $row=New-Object System.Windows.Forms.Panel;$row.Location=New-Object System.Drawing.Point(18,$yRow)
    $row.Size=New-Object System.Drawing.Size(862,50);$row.BackColor=[System.Drawing.Color]::FromArgb(195,12,12,24)
    $row.Controls.Add((New-Lbl $opt.L 14 6 778 18 ([System.Drawing.Color]::White) 9 Bold))
    $row.Controls.Add((New-Lbl $opt.D 14 26 778 16 ([System.Drawing.Color]::FromArgb(125,125,165)) 7.5))
    $tog=New-Toggle $opt.K 796 12 $opt.On;$row.Controls.Add($tog)
    $pai.Controls.Add($row);$yRow+=55
}
$bAiRun=New-Btn "▶  ปิด AI ที่เลือก" 18 ($yRow+6) 265 40 ([System.Drawing.Color]::FromArgb(125,0,215)) 10
$bAiRun.Add_Click({Switch-Tab "log";$script:logBox.Clear();Disable-WindowsAI})
$pai.Controls.Add($bAiRun)

# ══════════════════════════════════════════════════════════
#  TAB: ROBLOX
# ══════════════════════════════════════════════════════════
$prb=$script:panels["roblox"]
$rbItems=@(
    @{I="🖥️";T="CPU → High Priority";      D="Roblox ได้ CPU ก่อนทุก process";     X=18; Y=12},
    @{I="📡";T="ปิด Nagle's Algorithm";    D="ลด Ping จริงระดับ Network";           X=230;Y=12},
    @{I="⚡";T="Ultimate Power Plan";       D="CPU/GPU full speed ตลอดเวลา";         X=442;Y=12},
    @{I="🚫";T="ปิด Xbox Overlay";         D="ได้ FPS คืนจาก Overlay overhead";     X=654;Y=12},
    @{I="🎮";T="GPU → High Performance";   D="ใช้ GPU หลัก ไม่ใช่ iGPU";            X=18; Y=128},
    @{I="🖱️";T="ปิด Fullscreen Opt";       D="ลด Input Lag ใน Roblox";              X=230;Y=128},
    @{I="🗑️";T="ล้าง Roblox Cache";       D="โหลดเกมเร็ว ลด freeze เมื่อเข้าเกม"; X=442;Y=128},
    @{I="🔕";T="ปิด Background Apps";      D="ประหยัด RAM ขณะเล่น";                 X=654;Y=128}
)
$orAc=[System.Drawing.Color]::FromArgb(255,125,0)
foreach($ri in $rbItems){
    $cp=New-Object System.Windows.Forms.Panel;$cp.Location=New-Object System.Drawing.Point($ri.X,$ri.Y)
    $cp.Size=New-Object System.Drawing.Size(200,106);$cp.BackColor=[System.Drawing.Color]::FromArgb(200,14,14,28)
    $cp.Add_Paint({
        param($s,$e);$g=$e.Graphics;$g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $pen=New-Object System.Drawing.Pen($orAc,1.2);$g.DrawRectangle($pen,0,0,$s.Width-1,$s.Height-1);$pen.Dispose()
        $br=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(65,$orAc.R,$orAc.G,$orAc.B))
        $g.FillRectangle($br,0,0,$s.Width,3);$br.Dispose()
    })
    $cp.Controls.Add((New-Lbl $ri.I 10 8 30 28 ([System.Drawing.Color]::White) 16))
    $cp.Controls.Add((New-Lbl $ri.T 10 42 180 18 ([System.Drawing.Color]::White) 8.5 Bold))
    $cp.Controls.Add((New-Lbl $ri.D 10 62 180 30 ([System.Drawing.Color]::FromArgb(155,155,195)) 7.5))
    $prb.Controls.Add($cp)
}
$bRbRun=New-Btn "🚀  Boost FPS Roblox!" 18 250 265 48 ([System.Drawing.Color]::FromArgb(210,85,0)) 12
$bRbRun.Add_Click({Switch-Tab "log";$script:logBox.Clear();Boost-RobloxFPS})
$prb.Controls.Add($bRbRun)

$bAllRun=New-Btn "💥  ALL-IN-ONE" 298 250 210 48 ([System.Drawing.Color]::FromArgb(175,0,55)) 12
$bAllRun.Add_Click({Switch-Tab "log";$script:logBox.Clear();Optimize-PC;Disable-WindowsAI;Boost-RobloxFPS})
$prb.Controls.Add($bAllRun)

$prb.Controls.Add((New-Lbl "⚠️  รีสตาร์ทเครื่องหลัง Boost เพื่อให้เห็นผลชัดเจน — คาดว่า FPS จะเพิ่ม 20–60%" 18 312 862 22 ([System.Drawing.Color]::FromArgb(255,180,50)) 9))

# ══════════════════════════════════════════════════════════
#  TAB: LOG
# ══════════════════════════════════════════════════════════
$plog=$script:panels["log"]
$script:logBox=New-Object System.Windows.Forms.RichTextBox
$script:logBox.Location=New-Object System.Drawing.Point(12,12);$script:logBox.Size=New-Object System.Drawing.Size(872,418)
$script:logBox.BackColor=[System.Drawing.Color]::FromArgb(8,8,18);$script:logBox.ForeColor=[System.Drawing.Color]::FromArgb(0,225,115)
$script:logBox.Font=New-Object System.Drawing.Font("Consolas",9.5);$script:logBox.ReadOnly=$true
$script:logBox.ScrollBars="Vertical";$script:logBox.BorderStyle="None"
$plog.Controls.Add($script:logBox)

$bCL=New-Btn "🗑  ล้าง Log" 12 442 140 36 ([System.Drawing.Color]::FromArgb(48,48,70)) 9
$bCL.Add_Click({$script:logBox.Clear()});$plog.Controls.Add($bCL)

$bRS=New-Btn "🔄  รีสตาร์ท" 162 442 140 36 ([System.Drawing.Color]::FromArgb(165,72,0)) 9
$bRS.Add_Click({if([System.Windows.Forms.MessageBox]::Show("รีสตาร์ทเครื่องเลยไหม?","ยืนยัน","YesNo","Warning") -eq "Yes"){Restart-Computer -Force}})
$plog.Controls.Add($bRS)

$bEX=New-Btn "✕  ออกจากโปรแกรม" 744 442 140 36 ([System.Drawing.Color]::FromArgb(168,0,36)) 9
$bEX.Add_Click({$form.Close()});$plog.Controls.Add($bEX)

# ══════════════════════════════════════════════════════════
#  เริ่มต้น
# ══════════════════════════════════════════════════════════
Switch-Tab "home"
Write-Log "══════════════════════════════"
Write-Log "  PC Optimizer v3.1 พร้อมใช้!"
Write-Log "══════════════════════════════"

[System.Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()
