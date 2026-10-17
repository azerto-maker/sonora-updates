@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); $m='#PS'+'BEGIN'; $c=$t.Substring($t.IndexOf($m)+$m.Length); & ([scriptblock]::Create($c)) $f '%~1'"
exit /b
::SONORA_VERSION=10
#PSBEGIN
param([string]$Bat, [string]$Mode)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
try { $Host.UI.RawUI.WindowTitle = 'Sonora'; $Host.UI.RawUI.BackgroundColor = 'Black'; Clear-Host } catch {}

$Dir       = Join-Path $env:LOCALAPPDATA 'Sonora'
$Exe       = Join-Path $Dir 'Sonora.exe'
$Ico       = Join-Path $Dir 'Sonora.ico'
$Desktop   = [Environment]::GetFolderPath('Desktop')
$StartMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$FlagsBrowser = '--no-first-run --no-default-browser-check --disable-extensions --disable-sync --disable-background-networking --disable-component-update --disable-default-apps --disable-breakpad --disable-background-mode --disable-site-isolation-trials --disable-features=Translate,MediaRouter,OptimizationHints,OptimizationGuideModelDownloading,AutofillServerCommunication,IsolateOrigins,site-per-process --renderer-process-limit=2 "--js-flags=--max-old-space-size=384 --optimize-for-size" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --window-size=1360,860'
$FlagsWv2     = '--disable-features=Translate,OptimizationHints,msSmartScreenProtection,IsolateOrigins,site-per-process --disable-site-isolation-trials --renderer-process-limit=2 --js-flags="--max-old-space-size=384 --optimize-for-size" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --disable-background-networking --disable-component-update --disable-sync --disable-breakpad'

function W([string]$t, [string]$c = 'White') { Write-Host $t -ForegroundColor $c }

function Banner {
    $art = @(
        '███████╗ ██████╗ ███╗   ██╗ ██████╗ ██████╗  █████╗ ',
        '██╔════╝██╔═══██╗████╗  ██║██╔═══██╗██╔══██╗██╔══██╗',
        '███████╗██║   ██║██╔██╗ ██║██║   ██║██████╔╝███████║',
        '╚════██║██║   ██║██║╚██╗██║██║   ██║██╔══██╗██╔══██║',
        '███████║╚██████╔╝██║ ╚████║╚██████╔╝██║  ██║██║  ██║',
        '╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝'
    )
    $cols = 'Magenta','Magenta','DarkMagenta','DarkCyan','Cyan','Cyan'
    Write-Host ''
    for ($i = 0; $i -lt $art.Count; $i++) { W ('   ' + $art[$i]) $cols[$i] }
    Write-Host ''
    W '   ♪  Ta musique, ton univers  ·  version ultra-légère  (< 1 Go de RAM)' DarkGray
    W '   ─────────────────────────────────────────────────────────────────' DarkGray
    Write-Host ''
}

function Step([int]$i, [int]$n, [string]$txt) {
    $w = 26
    $f = [int][Math]::Round($w * $i / $n)
    $bar = ('█' * $f) + ('░' * ($w - $f))
    Write-Host ('   [' + $bar + '] ' + ('{0,3}%' -f [int](100 * $i / $n)) + '  ') -NoNewline -ForegroundColor Magenta
    W $txt White
}

function Stop-Sonora {
    Get-Process -Name Sonora -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 900
}

function New-Shortcut([string]$path, [string]$target, [string]$arguments, [string]$desc) {
    $ws = New-Object -ComObject WScript.Shell
    $l = $ws.CreateShortcut($path)
    $l.TargetPath = $target
    if ($arguments) { $l.Arguments = $arguments }
    $l.WorkingDirectory = $Dir
    $l.IconLocation = "$Ico,0"
    $l.Description = $desc
    $l.Save()
}

function New-SonoraIcon([string]$png, [string]$ico) {
    Add-Type -AssemblyName System.Drawing
    $S = 256
    $bmp = New-Object System.Drawing.Bitmap($S, $S, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    function RR([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = $r * 2
        $p.AddArc($x, $y, $d, $d, 180, 90)
        $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
        $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
        $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
        $p.CloseFigure()
        return ,$p
    }

    $c1 = [System.Drawing.Color]::FromArgb(255, 255, 61, 129)
    $c2 = [System.Drawing.Color]::FromArgb(255, 168, 85, 247)
    $c3 = [System.Drawing.Color]::FromArgb(255, 34, 211, 238)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $S, $S)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c3, [single]45)
    $cb = New-Object System.Drawing.Drawing2D.ColorBlend(3)
    $cb.Colors = [System.Drawing.Color[]]@($c1, $c2, $c3)
    $cb.Positions = [single[]]@(0, 0.55, 1)
    $br.InterpolationColors = $cb
    $g.FillPath($br, (RR 8 8 240 240 58))

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
    $heights = 90, 150, 190, 120
    for ($i = 0; $i -lt 4; $i++) {
        $x = 38 + $i * 50
        $h = $heights[$i]
        $g.FillPath($white, (RR $x ((256 - $h) / 2) 30 $h 15))
    }
    $g.Dispose()
    $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    $pngBytes = [IO.File]::ReadAllBytes($png)
    $fs = [IO.File]::Create($ico)
    $bw = New-Object IO.BinaryWriter($fs)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
    $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$pngBytes.Length); $bw.Write([uint32]22)
    $bw.Write($pngBytes)
    $bw.Close(); $fs.Close()
}

function Test-WebView2 {
    $guid = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    foreach ($k in "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$guid", "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$guid", "HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$guid") {
        if (Test-Path $k) {
            $v = (Get-ItemProperty $k -ErrorAction SilentlyContinue).pv
            if ($v -and $v -ne '0.0.0.0') { return $true }
        }
    }
    foreach ($d in "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView\Application", "$env:ProgramFiles\Microsoft\EdgeWebView\Application", "$env:LOCALAPPDATA\Microsoft\EdgeWebView\Application") {
        if ($d -and (Test-Path $d) -and (Get-ChildItem $d -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d+\.' })) { return $true }
    }
    return $false
}

function Install-WebView2Runtime {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $p = Join-Path $env:TEMP 'MicrosoftEdgeWebview2Setup.exe'
        Invoke-WebRequest -UseBasicParsing -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $p
        Start-Process -FilePath $p -ArgumentList '/silent', '/install' -Wait
        Remove-Item $p -Force -ErrorAction SilentlyContinue
        return (Test-WebView2)
    } catch { return $false }
}

function Get-WebView2Dlls {
    # Telecharge le SDK WebView2 (NuGet) et en extrait les 3 DLL necessaires. Retourne $true si OK.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $versions = @('1.0.2592.51')
        try {
            $idx = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.nuget.org/v3-flatcontainer/microsoft.web.webview2/index.json'
            $latest = $idx.versions | Where-Object { $_ -notmatch '-' } | Select-Object -Last 1
            if ($latest -and ($versions -notcontains $latest)) { $versions += $latest }
        } catch {}
        $plat = if ([Environment]::Is64BitOperatingSystem) { 'win-x64' } else { 'win-x86' }
        foreach ($v in $versions) {
            $tmp = Join-Path $env:TEMP ('sonora_wv2_' + [guid]::NewGuid().ToString('N'))
            try {
                New-Item -ItemType Directory -Force -Path $tmp | Out-Null
                $pkg = Join-Path $tmp 'wv2.nupkg'
                Invoke-WebRequest -UseBasicParsing -Uri "https://api.nuget.org/v3-flatcontainer/microsoft.web.webview2/$v/microsoft.web.webview2.$v.nupkg" -OutFile $pkg
                $ex = Join-Path $tmp 'x'
                [IO.Compression.ZipFile]::ExtractToDirectory($pkg, $ex)
                $core = Join-Path $ex 'lib\net462\Microsoft.Web.WebView2.Core.dll'
                $wf   = Join-Path $ex 'lib\net462\Microsoft.Web.WebView2.WinForms.dll'
                $ldr  = Join-Path $ex "runtimes\$plat\native\WebView2Loader.dll"
                if ((Test-Path $core) -and (Test-Path $wf) -and (Test-Path $ldr)) {
                    Copy-Item $core, $wf, $ldr -Destination $Dir -Force
                    return $true
                }
            } catch {} finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    } catch {}
    return $false
}

function Test-Browser {
    foreach ($n in 'msedge.exe', 'chrome.exe', 'brave.exe') {
        foreach ($h in 'HKLM:', 'HKCU:') {
            $k = "$h\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$n"
            if (Test-Path $k) {
                $v = (Get-ItemProperty $k).'(default)'
                if ($v -and (Test-Path $v)) { return $true }
            }
        }
    }
    return $false
}

# ============================== DESINSTALLATION ==============================
if ($Mode -eq 'uninstall') {
    Banner
    W '   Désinstallation de Sonora' Yellow
    Write-Host ''
    $keep = Read-Host '   Garder tes playlists et ta clé API ? (O/N)'
    Stop-Sonora
    Remove-Item (Join-Path $Desktop 'Sonora.lnk') -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $StartMenu 'Sonora.lnk') -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $StartMenu 'Désinstaller Sonora.lnk') -Force -ErrorAction SilentlyContinue
    if ($keep -match '^[oOyY]') {
        $cmd = '/c ping -n 4 127.0.0.1 >nul & rd /s /q "' + $Dir + '\profile" & rd /s /q "' + $Dir + '\wv2" & rd /s /q "' + $Dir + '\app" & rd /s /q "' + $Dir + '\src" & del /q "' + $Dir + '\*.*"'
    } else {
        $cmd = '/c ping -n 4 127.0.0.1 >nul & rd /s /q "' + $Dir + '"'
    }
    Start-Process -FilePath cmd.exe -ArgumentList $cmd -WindowStyle Hidden
    Write-Host ''
    W '   ✔ Sonora est désinstallé. À bientôt !' Green
    Start-Sleep -Seconds 2
    return
}

# ================================ INSTALLATION ===============================
try {
    Banner
    $N = 6

    Step 1 $N 'Préparation du dossier...'
    if (-not (Test-Browser)) { throw 'Microsoft Edge ou Google Chrome est requis (aucun trouvé).' }
    Stop-Sonora
    foreach ($d in $Dir, "$Dir\app", "$Dir\src", "$Dir\data") { New-Item -ItemType Directory -Force -Path $d | Out-Null }

    Step 2 $N 'Extraction de l''application Sonora...'
    $lines = [IO.File]::ReadAllLines($Bat, [Text.Encoding]::UTF8)
    $idx = [Array]::IndexOf($lines, '#PAYLOAD')
    if ($idx -lt 0) { throw 'Données intégrées introuvables dans ce fichier .bat.' }
    $sb = New-Object Text.StringBuilder
    for ($i = $idx + 1; $i -lt $lines.Length; $i++) { [void]$sb.Append($lines[$i].TrimStart('#').Trim()) }
    $bytes = [Convert]::FromBase64String($sb.ToString())
    $ms = New-Object IO.MemoryStream(, $bytes)
    $gz = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Decompress)
    $out = New-Object IO.MemoryStream
    $gz.CopyTo($out)
    [IO.File]::WriteAllBytes("$Dir\app\index.html", $out.ToArray())

    Step 3 $N 'Création de l''icône...'
    New-SonoraIcon "$Dir\app\icon.png" $Ico

    Step 4 $N 'Compilation du lanceur ultra-léger...'
    $cs = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using Microsoft.Win32;
#if WV2
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
#endif

// Sonora - lanceur ultra-leger : mini serveur local + fenetre "app" Edge/Chrome sous surveillance memoire.
static class SonoraApp
{
    const int FirstPort = 47831;
    const long TrimAboveBytes = 450L * 1024 * 1024;
#if WV2
    const string DefaultFlags = "--disable-features=Translate,OptimizationHints,msSmartScreenProtection,IsolateOrigins,site-per-process --disable-site-isolation-trials --renderer-process-limit=2 --js-flags=\"--max-old-space-size=384 --optimize-for-size\" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --disable-background-networking --disable-component-update --disable-sync --disable-breakpad";
#else
    const string DefaultFlags = "--no-first-run --no-default-browser-check --disable-extensions --disable-sync --disable-background-networking --disable-component-update --disable-default-apps --disable-breakpad --disable-background-mode --disable-site-isolation-trials --disable-features=Translate,MediaRouter,OptimizationHints,OptimizationGuideModelDownloading,AutofillServerCommunication,IsolateOrigins,site-per-process --renderer-process-limit=2 \"--js-flags=--max-old-space-size=384 --optimize-for-size\" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --window-size=1360,860";
#endif
    const string TitleBar = "<style id='sonora-tb'> :root{--tb:58px} html.sx-host body{padding-top:var(--tb)!important;box-sizing:border-box} html.sx-host .app{height:calc(100vh - var(--tb))!important} html.sx-host .setup{height:calc(100vh - var(--tb))!important} html.sx-host .qp{top:calc(var(--tb) + 12px)!important} .sx-bar{position:fixed;top:0;left:0;right:0;height:var(--tb);z-index:2147483000;display:flex;align-items:center;justify-content:space-between;gap:12px;padding:0 10px 0 18px;background:linear-gradient(180deg,rgba(255,255,255,.08),rgba(14,12,26,.62));backdrop-filter:blur(18px) saturate(1.4);-webkit-backdrop-filter:blur(18px) saturate(1.4);user-select:none;-webkit-user-select:none;font:600 12.5px Sora,system-ui,sans-serif;color:#a7a2c4;cursor:default} .sx-bar::after{content:'';position:absolute;left:0;right:0;bottom:0;height:1px;background:linear-gradient(90deg,transparent,#ff3d81,#a855f7,#22d3ee,transparent);opacity:.6} .sx-l{display:flex;align-items:center;gap:11px;min-width:0;flex:1} .sx-eq{display:flex;gap:2px;align-items:flex-end;height:15px;flex:none} .sx-eq i{width:3px;height:5px;border-radius:2px;background:linear-gradient(120deg,#ff3d81,#a855f7,#22d3ee)} body.playing .sx-eq i{animation:sxeq 1s ease-in-out infinite} .sx-eq i:nth-child(2){animation-delay:-.3s}.sx-eq i:nth-child(3){animation-delay:-.6s} @keyframes sxeq{0%,100%{height:4px}50%{height:15px}} .sx-t{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:#f7f5ff;letter-spacing:.2px} .sx-b{display:flex;gap:7px;flex:none} .sx-b button{width:34px;height:26px;border-radius:13px;display:grid;place-items:center;color:#c9c5e3;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.07);transition:background .18s,color .18s,box-shadow .18s,transform .18s;cursor:pointer;padding:0} .sx-b button:hover{background:rgba(255,255,255,.16);color:#fff;transform:translateY(-1px)} .sx-b button:active{transform:scale(.94)} .sx-b button.x:hover{background:linear-gradient(120deg,#ff3d81,#ef4444);border-color:transparent;box-shadow:0 0 16px rgba(255,61,129,.6)} .sx-b svg{width:12px;height:12px;stroke:currentColor;fill:none;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round;pointer-events:none} html.idle .sx-eq i{animation-play-state:paused!important} html.sx-fs .sx-bar{display:none} html.sx-fs body{padding-top:0!important} html.sx-fs .app,html.sx-fs .setup{height:100vh!important} html.sx-fs .qp{top:12px!important} html.sx-host .sx-bar{display:none!important} html.sx-fs .hd.tb{display:none!important} </style> <script> (function(){ var w=window.chrome&&window.chrome.webview; if(!w) return; document.documentElement.classList.add('sx-host'); var MAX=\"<svg viewBox='0 0 12 12'><rect x='2' y='2' width='8' height='8' rx='2.2'/></svg>\"; var RES=\"<svg viewBox='0 0 12 12'><rect x='2' y='3.6' width='6.4' height='6.4' rx='1.8'/><path d='M4.2 3.6V3a1.6 1.6 0 0 1 1.6-1.6H9A1.6 1.6 0 0 1 10.6 3v3.2A1.6 1.6 0 0 1 9 7.8h-.6'/></svg>\"; function ready(f){document.readyState==='loading'?document.addEventListener('DOMContentLoaded',f):f()} ready(function(){ var b=document.createElement('div'); b.className='sx-bar'; b.innerHTML=\"<div class='sx-l'><div class='sx-eq'><i></i><i></i><i></i></div><div class='sx-t'>Sonora</div></div>\" +\"<div class='sx-b'><button class='n' title='Reduire'><svg viewBox='0 0 12 12'><path d='M2.5 6h7'/></svg></button>\" +\"<button class='m' title='Agrandir'>\"+MAX+\"</button>\" +\"<button class='x' title='Fermer'><svg viewBox='0 0 12 12'><path d='M2.8 2.8l6.4 6.4M9.2 2.8L2.8 9.2'/></svg></button></div>\"; var t=b.querySelector('.sx-t'); function ti(){t.textContent=document.title||'Sonora'} ti(); var tt=document.querySelector('title'); if(tt) new MutationObserver(ti).observe(tt,{childList:true,characterData:true,subtree:true}); b.addEventListener('mousedown',function(e){ if(e.button===0&&!e.target.closest('button')) w.postMessage('drag'); }); b.addEventListener('dblclick',function(e){ if(!e.target.closest('button')) w.postMessage('max'); }); b.querySelector('.n').onclick=function(){w.postMessage('min')}; b.querySelector('.m').onclick=function(){w.postMessage('max')}; b.querySelector('.x').onclick=function(){w.postMessage('close')}; w.addEventListener('message',function(e){ var d=String(e.data); if(d.indexOf('max:')===0) b.querySelector('.m').innerHTML=(d==='max:1')?RES:MAX; else if(d.indexOf('fs:')===0) document.documentElement.classList.toggle('sx-fs',d==='fs:1'); }); document.addEventListener('keydown',function(e){ if(e.key==='F11'){ e.preventDefault(); w.postMessage('fs'); } }); document.body.appendChild(b); }); })(); </script>";

    internal static string Root, AppDir, DataDir, Profile;
    static byte[] Html = new byte[0];
    static byte[] Icon = new byte[0];
    internal static int Port;
    static HttpListener Listener;
    static Mutex Single;
#if !WV2
    static Process Browser;
#endif
    static IntPtr Job = IntPtr.Zero;
    static readonly object IoLock = new object();

    // ---------- Win32 ----------
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr CreateJobObject(IntPtr attrs, string name);
    [DllImport("kernel32.dll")]
    static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll")]
    static extern bool SetInformationJobObject(IntPtr job, int infoClass, IntPtr info, int size);
    [DllImport("kernel32.dll")]
    static extern bool QueryInformationJobObject(IntPtr job, int infoClass, IntPtr info, int size, IntPtr returned);
    [DllImport("kernel32.dll")]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);
    [DllImport("psapi.dll")]
    static extern bool EmptyWorkingSet(IntPtr process);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int NativeMsg(IntPtr hwnd, string text, string caption, uint type);

    [StructLayout(LayoutKind.Sequential)]
    struct BasicLimit
    {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct IoCounters
    {
        public ulong A, B, C, D, E, F;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct ExtendedLimit
    {
        public BasicLimit Basic;
        public IoCounters Io;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    // ---------- main ----------
    [STAThread]
    static int Main()
    {
        try { return Run(); }
        catch (Exception ex)
        {
            try { File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "error.log"), ex.ToString()); } catch { }
            return 1;
        }
    }

    static int Run()
    {
        Root = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
        AppDir = Path.Combine(Root, "app");
        DataDir = Path.Combine(Root, "data");
        Profile = Path.Combine(Root, "profile");
        Directory.CreateDirectory(DataDir);
        string portFile = Path.Combine(Root, "port.txt");

        bool first;
        Single = new Mutex(true, "Local\\SonoraMusicPlayer", out first);
        if (!first)
        {
#if WV2
            FocusExisting();
#else
            int p;
            if (int.TryParse(ReadText(portFile).Trim(), out p)) StartBrowser(p, false);
#endif
            return 0;
        }

        string htmlPath = Path.Combine(AppDir, "index.html");
        if (!File.Exists(htmlPath))
        {
            NativeMsg(IntPtr.Zero, "index.html introuvable. Relance l'installateur Sonora.", "Sonora", 0x10);
            return 2;
        }
        Html = Encoding.UTF8.GetBytes(Inject(File.ReadAllText(htmlPath, Encoding.UTF8)));
        string iconPath = Path.Combine(AppDir, "icon.png");
        if (File.Exists(iconPath)) Icon = File.ReadAllBytes(iconPath);

        for (int p = FirstPort; p < FirstPort + 20 && Listener == null; p++)
        {
            HttpListener l = new HttpListener();
            l.Prefixes.Add("http://localhost:" + p + "/");
            try { l.Start(); Listener = l; Port = p; }
            catch { try { l.Close(); } catch { } }
        }
        if (Listener == null)
        {
            NativeMsg(IntPtr.Zero, "Aucun port local libre (47831-47850).", "Sonora", 0x10);
            return 3;
        }
        File.WriteAllText(portFile, Port.ToString());

        Thread t = new Thread(Serve);
        t.IsBackground = true;
        t.Start();

#if WV2
        try { SetProcessDPIAware(); } catch { }
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        AttachJob(Process.GetCurrentProcess());
        Application.Run(new MainForm());
#else
        if (!StartBrowser(Port, true))
        {
            NativeMsg(IntPtr.Zero, "Microsoft Edge ou Google Chrome est requis.", "Sonora", 0x10);
            return 4;
        }

        TrimSelf();
        int tick = 0;
        while (true)
        {
            Thread.Sleep(5000);
            if (!BrowserAlive()) break;
            tick++;
            if (tick % 3 == 0) { TrimBrowser(); TrimSelf(); }
        }
#endif

        try { Listener.Stop(); } catch { }
        try { File.Delete(portFile); } catch { }
        return 0;
    }

#if !WV2
    // ---------- navigateur ----------
    static string FindBrowser()
    {
        string[] names = { "msedge.exe", "chrome.exe", "brave.exe" };
        RegistryKey[] hives = { Registry.LocalMachine, Registry.CurrentUser };
        foreach (string n in names)
        {
            foreach (RegistryKey hive in hives)
            {
                try
                {
                    using (RegistryKey k = hive.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" + n))
                    {
                        if (k == null) continue;
                        string v = k.GetValue(null) as string;
                        if (!string.IsNullOrEmpty(v) && File.Exists(v)) return v;
                    }
                }
                catch { }
            }
        }
        string pf = Environment.GetEnvironmentVariable("ProgramFiles");
        string pf86 = Environment.GetEnvironmentVariable("ProgramFiles(x86)");
        string la = Environment.GetEnvironmentVariable("LOCALAPPDATA");
        string[] guess =
        {
            Path.Combine(pf86 ?? "", @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(pf ?? "", @"Microsoft\Edge\Application\msedge.exe"),
            Path.Combine(pf ?? "", @"Google\Chrome\Application\chrome.exe"),
            Path.Combine(pf86 ?? "", @"Google\Chrome\Application\chrome.exe"),
            Path.Combine(la ?? "", @"Google\Chrome\Application\chrome.exe")
        };
        foreach (string g in guess) if (File.Exists(g)) return g;
        return null;
    }

    static bool StartBrowser(int port, bool track)
    {
        string exe = FindBrowser();
        if (exe == null) return false;
        string flags = ReadText(Path.Combine(Root, "flags.txt")).Replace("\r", " ").Replace("\n", " ").Trim();
        if (flags.Length == 0) flags = DefaultFlags;
        string args = "--app=http://localhost:" + port + "/ \"--user-data-dir=" + Profile + "\" " + flags;
        ProcessStartInfo psi = new ProcessStartInfo(exe, args);
        psi.UseShellExecute = false;
        Process p = Process.Start(psi);
        if (track)
        {
            Browser = p;
            AttachJob(p);
        }
        return true;
    }

#endif

    // Job Object : tout l'arbre de processus du navigateur est regroupe (et ferme avec le lanceur).
    internal static void AttachJob(Process p)
    {
        try
        {
            IntPtr job = CreateJobObject(IntPtr.Zero, null);
            if (job == IntPtr.Zero) return;
            ExtendedLimit info = new ExtendedLimit();
            info.Basic.LimitFlags = 0x2000; // KILL_ON_JOB_CLOSE
            int size = Marshal.SizeOf(typeof(ExtendedLimit));
            IntPtr buf = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(info, buf, false);
                SetInformationJobObject(job, 9, buf, size);
            }
            finally { Marshal.FreeHGlobal(buf); }
            if (AssignProcessToJobObject(job, p.Handle)) Job = job;
        }
        catch { }
    }

    static int[] JobPids()
    {
        if (Job == IntPtr.Zero) return null;
        int cap = 512;
        int size = 8 + cap * IntPtr.Size;
        IntPtr buf = Marshal.AllocHGlobal(size);
        try
        {
            QueryInformationJobObject(Job, 3, buf, size, IntPtr.Zero);
            int n = Marshal.ReadInt32(buf, 4);
            if (n > cap) n = cap;
            int[] r = new int[n];
            for (int i = 0; i < n; i++) r[i] = (int)Marshal.ReadIntPtr(buf, 8 + i * IntPtr.Size).ToInt64();
            return r;
        }
        catch { return null; }
        finally { Marshal.FreeHGlobal(buf); }
    }

#if !WV2
    static bool BrowserAlive()
    {
        int[] ids = JobPids();
        if (ids != null) return ids.Length > 0;
        try { return Browser != null && !Browser.HasExited; } catch { return false; }
    }

#endif

    // ---------- garde-fou memoire ----------
    internal static void TrimBrowser()
    {
        int[] ids = JobPids();
        if (ids == null || ids.Length == 0) return;
        long total = 0;
        foreach (int id in ids)
        {
            try { using (Process p = Process.GetProcessById(id)) { total += p.WorkingSet64; } } catch { }
        }
        if (total < TrimAboveBytes) return;
        foreach (int id in ids)
        {
            IntPtr h = OpenProcess(0x0500, false, id); // SET_QUOTA | QUERY_INFORMATION
            if (h == IntPtr.Zero) continue;
            try { EmptyWorkingSet(h); } catch { }
            CloseHandle(h);
        }
    }

    internal static void TrimSelf()
    {
        try
        {
            GC.Collect();
            using (Process me = Process.GetCurrentProcess()) { EmptyWorkingSet(me.Handle); }
        }
        catch { }
    }

    // ---------- serveur ----------
    static string Inject(string html)
    {
        const string add =
            "<link rel='icon' type='image/png' href='/icon.png'>" +
            "<style id='sonora-opt'>" +
            "html.idle *,html.idle *::before,html.idle *::after{animation-play-state:paused!important}" +
            "body::after{filter:blur(60px) saturate(1.7) brightness(.75)!important}" +
            "</style>" +
            "<script>(function(){var d=document,r=d.documentElement;function s(){r.classList.toggle('idle',d.hidden)}" +
            "d.addEventListener('visibilitychange',s);s();})();</script>" + TitleBar;
        int i = html.IndexOf("</head>", StringComparison.OrdinalIgnoreCase);
        return i < 0 ? add + html : html.Substring(0, i) + add + html.Substring(i);
    }

    static void Serve()
    {
        while (true)
        {
            HttpListenerContext c;
            try { c = Listener.GetContext(); } catch { return; }
            ThreadPool.QueueUserWorkItem(delegate(object o)
            {
                try { Handle((HttpListenerContext)o); }
                catch { try { ((HttpListenerContext)o).Response.Abort(); } catch { } }
            }, c);
        }
    }

    static void Handle(HttpListenerContext c)
    {
        HttpListenerRequest rq = c.Request;
        HttpListenerResponse rs = c.Response;

        // Securite : uniquement cette machine, uniquement notre propre page.
        if (!IPAddress.IsLoopback(rq.RemoteEndPoint.Address)) { Send(rs, 403, "text/plain", "forbidden"); return; }
        string host = rq.Headers["Host"] ?? "";
        if (host != "localhost:" + Port && host != "127.0.0.1:" + Port) { Send(rs, 403, "text/plain", "forbidden"); return; }
        string origin = rq.Headers["Origin"];
        if (!string.IsNullOrEmpty(origin) && origin != "http://localhost:" + Port && origin != "http://127.0.0.1:" + Port)
        { Send(rs, 403, "text/plain", "forbidden"); return; }

        string path = rq.Url.AbsolutePath;

        if (path == "/" || path == "/index.html") { Send(rs, 200, "text/html; charset=utf-8", Html); return; }
        if (path == "/icon.png") { Send(rs, 200, "image/png", Icon); return; }

        if (path == "/data" || path == "/key")
        {
            bool isData = path == "/data";
            string file = Path.Combine(DataDir, isData ? "data.json" : "key.txt");
            string type = isData ? "application/json; charset=utf-8" : "text/plain; charset=utf-8";
            if (rq.HttpMethod == "POST")
            {
                if (rq.ContentLength64 > 20 * 1024 * 1024) { Send(rs, 413, "text/plain", "too large"); return; }
                byte[] body;
                using (MemoryStream ms = new MemoryStream())
                {
                    rq.InputStream.CopyTo(ms);
                    body = ms.ToArray();
                }
                if (body.Length > 20 * 1024 * 1024) { Send(rs, 413, "text/plain", "too large"); return; }
                WriteAtomic(file, body);
                Send(rs, 200, "text/plain", "ok");
                return;
            }
            byte[] data = new byte[0];
            lock (IoLock) { if (File.Exists(file)) data = File.ReadAllBytes(file); }
            Send(rs, 200, type, data);
            return;
        }

        if (path == "/update/check" || path == "/update/apply")
        {
            if (rq.HttpMethod != "POST") { Send(rs, 405, "text/plain", "method"); return; }
            string upUrl;
            using (StreamReader sr = new StreamReader(rq.InputStream, Encoding.UTF8)) { upUrl = sr.ReadToEnd().Trim(); }
            Send(rs, 200, "application/json; charset=utf-8", path == "/update/check" ? UpdCheck(upUrl) : UpdApply(upUrl));
            return;
        }

        Send(rs, 404, "text/plain", "not found");
    }

    // ---------- mise a jour ----------
    static string UpdJson(bool ok, string msg, string ver)
    {
        string m = (msg ?? "").Replace("\\", "/").Replace("\"", "'").Replace("\r", " ").Replace("\n", " ");
        return "{\"ok\":" + (ok ? "true" : "false") + ",\"msg\":\"" + m + "\",\"ver\":\"" + (ver ?? "") + "\"}";
    }

    static bool UpdUrlOk(string url)
    {
        Uri u;
        return !string.IsNullOrEmpty(url) && Uri.TryCreate(url, UriKind.Absolute, out u) && u.Scheme == Uri.UriSchemeHttps;
    }

    static string UpdDownloadText(string url)
    {
        ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
        HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
        req.UserAgent = "Sonora-Updater";
        req.Timeout = 20000;
        req.AllowAutoRedirect = true;
        using (HttpWebResponse r = (HttpWebResponse)req.GetResponse())
        using (Stream s = r.GetResponseStream())
        using (MemoryStream ms = new MemoryStream())
        {
            byte[] buf = new byte[65536];
            int n;
            while ((n = s.Read(buf, 0, buf.Length)) > 0)
            {
                ms.Write(buf, 0, n);
                if (ms.Length > 8 * 1024 * 1024) throw new Exception("fichier trop gros");
            }
            return Encoding.UTF8.GetString(ms.ToArray());
        }
    }

    static string UpdCheck(string url)
    {
        try
        {
            if (!UpdUrlOk(url)) return UpdJson(false, "Adresse invalide (https:// obligatoire).", "");
            string txt = UpdDownloadText(url);
            Match m = Regex.Match(txt, "SONORA_VERSION=([0-9]+)");
            if (!m.Success || txt.IndexOf("#PAYLOAD", StringComparison.Ordinal) < 0)
                return UpdJson(false, "Ce fichier n'est pas un installateur Sonora.", "");
            return UpdJson(true, "", m.Groups[1].Value);
        }
        catch (Exception ex) { return UpdJson(false, "Connexion impossible : " + ex.Message, ""); }
    }

    static string UpdApply(string url)
    {
        try
        {
            if (!UpdUrlOk(url)) return UpdJson(false, "Adresse invalide (https:// obligatoire).", "");
            string txt = UpdDownloadText(url);
            if (!Regex.IsMatch(txt, "SONORA_VERSION=[0-9]+") || txt.IndexOf("#PAYLOAD", StringComparison.Ordinal) < 0)
                return UpdJson(false, "Ce fichier n'est pas un installateur Sonora.", "");
            txt = txt.Replace("\r\n", "\n").Replace("\n", "\r\n");
            string dir = Path.Combine(Root, "update");
            Directory.CreateDirectory(dir);
            string bat = Path.Combine(dir, "Sonora_Update.bat");
            File.WriteAllText(bat, txt, new UTF8Encoding(false));
            ProcessStartInfo psi = new ProcessStartInfo("cmd.exe", "/c start \"\" \"" + bat + "\"");
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.WorkingDirectory = dir;
            Process.Start(psi);
            return UpdJson(true, "", "");
        }
        catch (Exception ex) { return UpdJson(false, "Echec : " + ex.Message, ""); }
    }

    static void Send(HttpListenerResponse rs, int code, string type, string text)
    {
        Send(rs, code, type, Encoding.UTF8.GetBytes(text));
    }

    static void Send(HttpListenerResponse rs, int code, string type, byte[] body)
    {
        rs.StatusCode = code;
        rs.ContentType = type;
        rs.ContentLength64 = body.Length;
        rs.Headers["Cache-Control"] = "no-store";
        rs.Headers["X-Content-Type-Options"] = "nosniff";
        if (body.Length > 0) rs.OutputStream.Write(body, 0, body.Length);
        rs.OutputStream.Close();
    }

    static void WriteAtomic(string path, byte[] data)
    {
        lock (IoLock)
        {
            string tmp = path + ".tmp";
            File.WriteAllBytes(tmp, data);
            if (File.Exists(path)) File.Replace(tmp, path, null);
            else File.Move(tmp, path);
        }
    }

    internal static string ReadText(string path)
    {
        try { return File.Exists(path) ? File.ReadAllText(path, Encoding.UTF8) : ""; }
        catch { return ""; }
    }

#if WV2
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")]
    static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")]
    static extern bool SetForegroundWindow(IntPtr h);

    [DllImport("user32.dll")]
    static extern bool SetProcessDPIAware();

    static void FocusExisting()
    {
        IntPtr h = FindWindow(null, "Sonora");
        if (h == IntPtr.Zero) return;
        ShowWindow(h, 9); // SW_RESTORE
        SetForegroundWindow(h);
    }
#endif
}

#if WV2
// Fenetre sans bordure, coins arrondis, barre de titre HTML (injectee par le serveur).
// Agrandir / snap sont geres ici (pas de WS_MAXIMIZE) : la fenetre et la page gardent toujours la meme taille.
class MainForm : Form
{
    [DllImport("dwmapi.dll")]
    static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int size);
    [DllImport("dwmapi.dll")]
    static extern int DwmExtendFrameIntoClientArea(IntPtr hwnd, ref Margins m);
    [DllImport("gdi32.dll")]
    static extern IntPtr CreateRoundRectRgn(int l, int t, int r, int b, int w, int h);
    [DllImport("gdi32.dll")]
    static extern bool DeleteObject(IntPtr o);

    [StructLayout(LayoutKind.Sequential)]
    struct Margins { public int L, R, T, B; }

    const int Edge = 5;
    WebView2 wv;
    System.Windows.Forms.Timer dragTimer, trimTimer;
    Point dragCursor, dragOrigin;
    bool dwmRound, full, docked, pendingUndock, wasMax, lastMax;
    System.Windows.Forms.Timer fixTimer;
    int lastPref = -1;
    Rectangle restoreRect, preFull;

    public MainForm()
    {
        Text = "Sonora";
        BackColor = Color.FromArgb(5, 4, 10);
        FormBorderStyle = FormBorderStyle.Sizable;
        StartPosition = FormStartPosition.CenterScreen;
        float dk = 1f; try { using (Graphics gg = CreateGraphics()) dk = gg.DpiX / 96f; } catch { }
        MinimumSize = new Size((int)(900 * dk), (int)(600 * dk));
        Rectangle wa = Screen.PrimaryScreen.WorkingArea;
        ClientSize = new Size(Math.Min(1360, wa.Width - 40), Math.Min(860, wa.Height - 40));
        Padding = new Padding(0, Edge, 0, 0);
        try { this.Icon = System.Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }

        wv = new WebView2();
        wv.Dock = DockStyle.Fill;
        wv.DefaultBackgroundColor = Color.FromArgb(5, 4, 10);
        Controls.Add(wv);

        dragTimer = new System.Windows.Forms.Timer();
        dragTimer.Interval = 8;
        dragTimer.Tick += DragTick;

        fixTimer = new System.Windows.Forms.Timer();
        fixTimer.Interval = 120;
        fixTimer.Tick += delegate { fixTimer.Stop(); FixLayout(); };

        trimTimer = new System.Windows.Forms.Timer();
        trimTimer.Interval = 15000;
        trimTimer.Tick += delegate { SonoraApp.TrimBrowser(); SonoraApp.TrimSelf(); };
        trimTimer.Start();

        InitWeb();
    }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams cp = base.CreateParams;
            cp.Style |= 0x20000 | 0x10000 | 0x40000; // MINIMIZEBOX + MAXIMIZEBOX + THICKFRAME : agrandir / snap / Win+fleches natifs
            return cp;
        }
    }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        int pref = 2; // DWMWCP_ROUND (Windows 11)
        try { dwmRound = DwmSetWindowAttribute(Handle, 33, ref pref, 4) == 0; } catch { dwmRound = false; }
        lastPref = dwmRound ? 2 : -1;
        if (dwmRound)
        {
            Margins mg = new Margins(); mg.L = 1; mg.R = 1; mg.T = 1; mg.B = 1;
            // (cadre DWM natif conserve)
        }
        ApplyShape();
    }

    async void InitWeb()
    {
        try
        {
            string flags = SonoraApp.ReadText(System.IO.Path.Combine(SonoraApp.Root, "flags.txt")).Replace("\r", " ").Replace("\n", " ").Trim();
            CoreWebView2EnvironmentOptions opts = new CoreWebView2EnvironmentOptions();
            if (flags.Length > 0) opts.AdditionalBrowserArguments = flags;
            CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, System.IO.Path.Combine(SonoraApp.Root, "wv2"), opts);
            await wv.EnsureCoreWebView2Async(env);

            CoreWebView2Settings s = wv.CoreWebView2.Settings;
            s.AreDefaultContextMenusEnabled = false;
            s.IsStatusBarEnabled = false;
            s.IsZoomControlEnabled = false;
            s.IsBuiltInErrorPageEnabled = false;
            s.IsPasswordAutosaveEnabled = false;
            s.IsGeneralAutofillEnabled = false;

            wv.CoreWebView2.WebMessageReceived += OnWebMessage;
            wv.CoreWebView2.ContainsFullScreenElementChanged += delegate { bool fe = wv.CoreWebView2.ContainsFullScreenElement; BeginInvoke(new Action(delegate { SetFull(fe); })); };
            wv.CoreWebView2.NewWindowRequested += delegate(object o, CoreWebView2NewWindowRequestedEventArgs a)
            {
                a.Handled = true;
                if (a.Uri != null && a.Uri.StartsWith("http")) { try { Process.Start(a.Uri); } catch { } }
            };
            wv.CoreWebView2.Navigate("http://localhost:" + SonoraApp.Port + "/");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Impossible de demarrer WebView2 :\n" + ex.Message, "Sonora", MessageBoxButtons.OK, MessageBoxIcon.Error);
            Close();
        }
    }

    void OnWebMessage(object sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        string m;
        try { m = e.TryGetWebMessageAsString(); } catch { return; }
        switch (m)
        {
            case "min": WindowState = FormWindowState.Minimized; break;
            case "max": ToggleMax(); break;
            case "close": Close(); break;
            case "drag": BeginDrag(); break;
            case "fs": SetFull(!full); break;
        }
    }

    void Notify(string msg)
    {
        try { if (wv != null && wv.CoreWebView2 != null) wv.CoreWebView2.PostWebMessageAsString(msg); } catch { }
    }

    // ---------- agrandir / snap : natif Windows ----------
    [StructLayout(LayoutKind.Sequential)] struct PT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct MMI { public PT Res, MaxSize, MaxPos, MinTrack, MaxTrack; }
    [StructLayout(LayoutKind.Sequential)] struct RC { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] struct MINFO { public int cb; public RC mon, work; public int flags; }
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr h, int flags);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr hm, ref MINFO mi);

    void ScheduleFix() { try { fixTimer.Stop(); fixTimer.Start(); } catch { } }

    void SnapHalf(Rectangle r)
    {
        if (WindowState == FormWindowState.Maximized) WindowState = FormWindowState.Normal;
        if (!docked) restoreRect = Bounds;
        docked = true;
        Bounds = r;
        ApplyShape();
        ScheduleFix();
    }

    void ToggleMax()
    {
        if (full) return;
        if (WindowState == FormWindowState.Maximized) WindowState = FormWindowState.Normal;
        else
        {
            if (docked) { docked = false; Bounds = restoreRect; }
            WindowState = FormWindowState.Maximized;
        }
    }

    void SetFull(bool f)
    {
        if (f && !full)
        {
            wasMax = WindowState == FormWindowState.Maximized;
            preFull = wasMax ? RestoreBounds : Bounds;
            full = true;
            if (wasMax) WindowState = FormWindowState.Normal;
            ApplyShape();
            Bounds = Screen.FromControl(this).Bounds;
            TopMost = true;
            SetWindowPos(Handle, IntPtr.Zero, 0, 0, 0, 0, 0x27);
        }
        else if (!f && full)
        {
            full = false;
            TopMost = false;
            ApplyShape();
            Bounds = preFull;
            SetWindowPos(Handle, IntPtr.Zero, 0, 0, 0, 0, 0x27);
            if (wasMax) WindowState = FormWindowState.Maximized;
        }
        else return;
        Notify(full ? "fs:1" : "fs:0");
        FixLayout();
        ScheduleFix();
    }

    // Force WebView2 a reprendre la taille exacte de la fenetre (evite le contenu coupe / non redessine).
    void FixLayout()
    {
        if (wv == null || IsDisposed) return;
        try
        {
            wv.Dock = DockStyle.None;
            wv.Bounds = new Rectangle(Padding.Left, Padding.Top, Math.Max(1, ClientSize.Width - Padding.Horizontal), Math.Max(1, ClientSize.Height - Padding.Vertical));
            wv.Dock = DockStyle.Fill;
            PerformLayout();
            wv.Invalidate(true);
        }
        catch { }
    }

    // ---------- deplacement + magnetisme ----------
    [DllImport("user32.dll")]
    static extern bool ReleaseCapture();
    [DllImport("user32.dll")]
    static extern IntPtr SendMessage(IntPtr h, int msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")]
    static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")]
    static extern int GetSystemMetrics(int n);
    [StructLayout(LayoutKind.Sequential)] struct NCCSP { public RC r0, r1, r2; public IntPtr pos; }

    void BeginDrag()
    {
        if (full || (Control.MouseButtons & MouseButtons.Left) == 0) return;
        ReleaseCapture();
        SendMessage(Handle, 0xA1, (IntPtr)2, IntPtr.Zero); // WM_NCLBUTTONDOWN + HTCAPTION : deplacement natif
    }

    void DragTick(object sender, EventArgs e)
    {
        if ((Control.MouseButtons & MouseButtons.Left) == 0)
        {
            dragTimer.Stop();
            if (!pendingUndock) DropSnap();
            pendingUndock = false;
            return;
        }
        Point c = Cursor.Position;
        if (pendingUndock)
        {
            if (Math.Abs(c.X - dragCursor.X) < 6 && Math.Abs(c.Y - dragCursor.Y) < 6) return;
            pendingUndock = false;
            double rx = (double)(c.X - Left) / Math.Max(1, Width);
            Rectangle r = WindowState == FormWindowState.Maximized ? RestoreBounds : restoreRect;
            docked = false;
            if (WindowState == FormWindowState.Maximized) WindowState = FormWindowState.Normal;
            Bounds = new Rectangle(c.X - (int)(rx * r.Width), c.Y - 16, r.Width, r.Height);
            ApplyShape();
            dragCursor = c;
            dragOrigin = Location;
        }
        Location = new Point(dragOrigin.X + c.X - dragCursor.X, dragOrigin.Y + c.Y - dragCursor.Y);
    }

    void DropSnap()
    {
        Point c = Cursor.Position;
        Rectangle wa = Screen.FromPoint(c).WorkingArea;
        if (c.Y <= wa.Top + 1) WindowState = FormWindowState.Maximized;
        else if (c.X <= wa.Left + 1) SnapHalf(new Rectangle(wa.Left, wa.Top, wa.Width / 2, wa.Height));
        else if (c.X >= wa.Right - 2) SnapHalf(new Rectangle(wa.Left + wa.Width / 2, wa.Top, wa.Width - wa.Width / 2, wa.Height));
    }

    // ---------- forme ----------
    void ApplyShape()
    {
        bool plain = WindowState == FormWindowState.Normal && !docked && !full;
        Padding = plain ? new Padding(0, Edge, 0, 0) : Padding.Empty;
        if (!IsHandleCreated) return;
        if (dwmRound)
        {
            int pref = plain ? 2 : 1; // arrondi / pas d'arrondi
            if (pref != lastPref)
            {
                lastPref = pref;
                try { DwmSetWindowAttribute(Handle, 33, ref pref, 4); } catch { }
            }
            return;
        }
        if (plain)
        {
            IntPtr r = CreateRoundRectRgn(0, 0, Width + 1, Height + 1, 18, 18);
            Region = Region.FromHrgn(r);
            DeleteObject(r);
        }
        else Region = null;
    }

    protected override void OnSizeChanged(EventArgs e)
    {
        base.OnSizeChanged(e);
        bool mx = WindowState == FormWindowState.Maximized;
        if (mx != lastMax)
        {
            lastMax = mx;
            ApplyShape();
            Notify(mx ? "max:1" : "max:0");
            ScheduleFix();
        }
        else if (!dwmRound) ApplyShape();
    }

    // Poignees de redimensionnement sur le liseré de 5 px + zone agrandie correcte (barre des taches respectee).
    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x83 && m.WParam != IntPtr.Zero) // WM_NCCALCSIZE
        {
            if (full) { m.Result = IntPtr.Zero; return; } // plein ecran : tout est client
            if (WindowState == FormWindowState.Minimized) { base.WndProc(ref m); return; }
            NCCSP p = (NCCSP)Marshal.PtrToStructure(m.LParam, typeof(NCCSP));
            int origTop = p.r0.T;
            base.WndProc(ref m); // cadre par defaut (bords gauche/droite/bas natifs)
            p = (NCCSP)Marshal.PtrToStructure(m.LParam, typeof(NCCSP));
            if (WindowState == FormWindowState.Maximized) p.r0.T = origTop + GetSystemMetrics(33) + GetSystemMetrics(92); // SM_CYFRAME + SM_CXPADDEDBORDER
            else p.r0.T = origTop; // pas de barre de titre systeme
            Marshal.StructureToPtr(p, m.LParam, false);
            return;
        }
        if (m.Msg == 0x84 && WindowState == FormWindowState.Normal && !full) // WM_NCHITTEST : poignee de redimensionnement en haut
        {
            base.WndProc(ref m);
            if (m.Result == (IntPtr)1)
            {
                long lp = m.LParam.ToInt64();
                Point pt = PointToClient(new Point((short)(lp & 0xFFFF), (short)((lp >> 16) & 0xFFFF)));
                if (pt.Y >= 0 && pt.Y < Edge) m.Result = (IntPtr)(pt.X < 10 ? 13 : (pt.X >= ClientSize.Width - 10 ? 14 : 12));
            }
            return;
        }
        base.WndProc(ref m);
    }
}
#endif
'@
    [IO.File]::WriteAllText("$Dir\src\Sonora.cs", $cs, (New-Object Text.UTF8Encoding $false))
    $csc = @("$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe", "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $csc) { throw '.NET Framework 4 (csc.exe) introuvable.' }
    function Build([bool]$withIcon, [bool]$wv2) {
        $ErrorActionPreference = 'Continue'
        Remove-Item $Exe -Force -ErrorAction SilentlyContinue
        $a = @('/nologo', '/target:winexe', '/optimize+', '/debug-', "/out:$Exe", '/r:System.dll')
        if ($wv2) {
            $plat = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
            $a += '/define:WV2', "/platform:$plat", '/r:System.Windows.Forms.dll', '/r:System.Drawing.dll', "/r:$Dir\Microsoft.Web.WebView2.Core.dll", "/r:$Dir\Microsoft.Web.WebView2.WinForms.dll"
        }
        if ($withIcon) { $a += "/win32icon:$Ico" }
        $a += "$Dir\src\Sonora.cs"
        $o = & $csc @a 2>&1 | Out-String
        $code = $LASTEXITCODE
        return @{ ok = (($code -eq 0) -and (Test-Path $Exe)); out = $o }
    }
    $useWv2 = $false
    $wvOk = Test-WebView2
    if (-not $wvOk) { Write-Host '   Installation du runtime WebView2 (barre personnalisee)...' -ForegroundColor DarkGray; $wvOk = Install-WebView2Runtime }
    if (-not $wvOk) { Write-Host '   (!) Runtime WebView2 introuvable sur ce PC : mode navigateur utilise.' -ForegroundColor Yellow }
    $dllOk = $false
    if ($wvOk) {
        $dllOk = Get-WebView2Dlls
        if (-not $dllOk) { Write-Host '   (!) Telechargement des fichiers WebView2 impossible (connexion internet ?) : mode navigateur utilise.' -ForegroundColor Yellow }
    }
    if ($wvOk -and $dllOk) {
        $r = Build $true $true
        if (-not $r.ok) { $r = Build $false $true }
        if (-not $r.ok) {
            try { [IO.File]::WriteAllText("$Dir\build_wv2.log", $r.out) } catch {}
            Write-Host '   (!) La version WebView2 n''a pas compile : mode navigateur utilise. Details dans build_wv2.log' -ForegroundColor Yellow
        }
        $useWv2 = $r.ok
    }
    if (-not $useWv2) {
        $r = Build $true $false
        if (-not $r.ok) { $r = Build $false $false }
    }
    if (-not $r.ok) { throw ('Compilation échouée :' + [Environment]::NewLine + $r.out) }
    $flags = if ($useWv2) { $FlagsWv2 } else { $FlagsBrowser }
    [IO.File]::WriteAllText("$Dir\flags.txt", $flags, (New-Object Text.UTF8Encoding $false))

    Step 5 $N 'Raccourcis (Bureau + menu Démarrer)...'
    $setup = Join-Path $Dir 'Sonora_Setup.bat'
    if ((Resolve-Path $Bat).Path -ne $setup) { Copy-Item -LiteralPath $Bat -Destination $setup -Force }
    New-Shortcut (Join-Path $Desktop 'Sonora.lnk') $Exe '' 'Sonora - Musique'
    New-Shortcut (Join-Path $StartMenu 'Sonora.lnk') $Exe '' 'Sonora - Musique'
    New-Shortcut (Join-Path $StartMenu 'Désinstaller Sonora.lnk') $setup 'uninstall' 'Désinstaller Sonora'

    Step 6 $N 'Lancement !'
    Start-Process -FilePath $Exe -WorkingDirectory $Dir

    Write-Host ''
    W '   ✔ Sonora est installé.' Green
    W ('     Dossier : ' + $Dir) DarkGray
    W '     Raccourci « Sonora » créé sur le Bureau et dans le menu Démarrer.' DarkGray
    if ($useWv2) { W '     Mode : fenêtre Sonora personnalisée (barre arrondie, WebView2).' DarkGray }
    else { W '     Mode : fenêtre d''app Edge/Chrome (WebView2 indisponible).' DarkGray }
    W '     Réglages avancés (RAM) : modifie flags.txt dans le dossier ci-dessus.' DarkGray
    Write-Host ''
    if ($useWv2) { Start-Sleep -Seconds 5 } else { Read-Host '   (!) Barre personnalisee indisponible, voir ci-dessus. Appuie sur Entree pour fermer' }
}
catch {
    Write-Host ''
    W ('   ✖ Erreur : ' + $_.Exception.Message) Red
    Write-Host ''
    Read-Host '   Appuie sur Entrée pour fermer'
}

#PAYLOAD
#H4sIAOLu02oC/8S9247kSJYg9p5fwY1QTIR30Zm8O92jMqerq7u3C5jqqemqKXWrMRDo7vRwdvgtSXpcyjeAeVlBelxBEDSAgNWLNNOzgJ4E6GH1NPkn/QX7
#CTrnmJE0MxovHlm9U1EZ4U7a3Y6du53z+b/5+V9/+d3vvvmFsS62m/dvPsc/xibe3b27WGUX+CCJl/BnmxSxsVjHWZ4U7y6OxWocXZSPd/E2eXfxkCaPh31W
#XBiL/a5IdlDsMV0W63fL5CFdJGP6YhrpLi3SeDPOF/EmeecojWTJKsmyJBMayYssXRTjfZbepbvx4zrZjRfZPs/5E2ygSItN8v7b/W6fxZ+/Zd/efJ4Xz/j3
#p+kWh2Ucs83N9booDvns7dsVtJ5bd/v93SaJD2luLfbbt4s8d/9yFW/TzfO7b6Gp2ePduvipb9u3AfwL4d8E/kW2/Re80Be7Yr8rv/wszjb7x8++3O+WyS5P
#lqx2S81vkmwb72B+n30dZ/dJ9hfLND9s4ud3+WN8uB7dvvnpIdsfkqx4NsZj2I1T/rwr4qfZ9efwBWZ1fVuu40O8OSYze5ncwaN1kqVFPlvFmzx5eTPL9vvi
#NB7P72aXdmD7dnw7Ht9tZtndPL5xg8As/1l2MIJXm3SXaF46+C7d3c8uV5NVsFrBt+2xSGaX8SR2Fz58jeHVyltGDnyew/MoCFYT+LyYXbru0ksS7HeGzcfZ
#+C6LlynM/MZxcdQmr2rYVyavaQQBfGY1Dce2r3AAB1c37mj08uYnp/n+aZynP6S7u9l8ny2TbAxPbsePyfw+LcZFfBiv07v1Bv4V48V+s89mRRbv8kOcwTig
#gdmsLJsDaG028zg7EbjOHPvwdLtOsCZ9ftGVHRfr43Z+mseL+7tsf9wtdYvoj2752HD+x3w2hZbZk5l3eDLy/SZdGsK4buv2xotNepjxE4Fzg72d5ckmWRTp
#fid2/BBnN7AHo1s2TVjb1csbPNMnegBjXifbZLYEoGPPZ7N5stpnyYm3Pru4uD3s8xQbnq3Sp2QJYAVnfmbf/gBAsEyeZtMplEihdDZOHqBKPtvtd8nt/hAv
#0uJ5ZtkTYegzPHYXy7iIZ+k2vkve5g93nz1tN+aV9yV8NODjLn9H5xKO5ePjo/XoWfvs7q1r2zYWvjYYFrl2QvvaYFvBvlx5v4BGVukGRmKky3fXu/JR8t0x
#mx83yW6RGPM4T36ZJR+O8O353bU1vTZ2x+1fL4r4IYGO3eu3rNJb1hD7ksHKtvZrsJLvrnFqV663G1VtwHjh0wUA5Xy/fD5t4wwwFCxdc4fuyi1i3+F4jW4R
#KY0Zgpgh/jG/wkU28+e8SLbjY2qO48Nhk4zZA/Pi2+Runxh/+9WFmQPUjHM4/KsaWO2H9e3+IclWgJVm63QJWIkNa/CWj137qtr1sSfOAmEYkE91ln37ysB/
#cWFAJfxn0hlwwsiM4Aj4E9Pyg5EpwLcxgYNtqg15wZWB/6ChCBpyAt4QHqLQMR13alpeNKAhHxrxWUPw3piWI/J803Uc0/Ui03I1Dd3GOwBUWov4mBmumxsJ
#gBCswnh/LIB8rRDzJkaMMLCLi6Rc1HgFD/rXFDYGDn61qm4TNuKsMPFEjYxFggDwdoHbeMugbjbfHLObKbQxMvK4OGYwghvHikbGPMON3yV5fmNNAJ9X5zEI
#Xt789D55XmVAYnMDZnUq9ieaN4DBluHCDbbjX5nh1cjI9gV+iwA7QydIp6EHZ/QCMz0WQPFOCKgzTm1uF8csBzjmKKFEaTYH77KUMEuc28sbC0AyOXGyR8/+
#DSPUMaJkCyC9enmXpctb/DUGsD/gSBGLH7e7fObhahrOKlPeZ/vHfAaPjakrInA8E3fxYebg00O8XCLJwC/QYy6OZ7VJnm7x13iZZgzNzlifdf0tgARv2Yb6
#gJYbJMDxAWJNNzRhE0a0Bksg62NxK91Q2UogFCWFGVxBpiyuX5MWpyItDLiQCGN5IJjreAmYwYbDCmUC/EVjtk38sbwAsJi1ix9O5TpROcfnv2h1Zo60Crf9
#ywdtbvZ3e3mhYyDNuzGcqm0+YzBfrzIhxUfWATBQ7DsQ+2Tm4utNUiAhyhHYYYxjK8Kd4XjXiHCwEW3vElghqVPsAQiv1DkNOdktS4jBtWZ1jZRzBEENT1G1
#zOXKY3uN83wn4pTkQ2zAYdIjlbKr2a5YjxfrdLO8cUenqvJ4meDox5afvzQKerqCUc6x025f3Fg4d1ikkcEnVJfHN+McT/3sEB+BeZUwBoz5BOgTObETn/oE
#1iWovyLEvSC4pNUazzf7xf1tyUUBISmSp2JMiz3bJKuiPn5OCVHyWtIjkUYi0zmS4CGU4IEqEDJjaNdy8xoHZ7AiRfqQ0CBna8SopwYBbmzdwaVDkFqA9LpK
#q6ztlDjbBuFyR02qCCxs1UcnZY7ncI5hCW5x9eCsFfsDHIErWDXAyVv6yFbbGwqWeBbX8qH4wzEv0tXzuBwAnqtkPE+KxyTZ6c4pP2qEGyL2r2fTJvKmOc1D
#7Fh4yAheaip1PIA4tIhRroFRG5wS8RkLXDp9lqcPgCr2OGmAyUvdIgcNHSQ0GbZ6dJxk0r7juh42+alkvsbPwEkUe44w6eVw9FeeEsJkNmGjxcOJmiKumy2A
#L1A5+qwcJXwkUVP4BPsqdSmsUFhtIgoQMrUIcSChnlgcKlpBclPj8DX5UagzDOhLIaQiRo1JMqpX7xs0ly7qI7nK9ltOA0GElvk+myRO/nJklkIU/7CQCtfU
#eRvn942TfwliC7RnjwxBXDNbS0mNwanb0syT2dMej5b0KHlabI7LWs6yRSDmDw0rzAVikx/SneHnBuu+IjM68Y3RiZJEGOK+lB06ElHAtpGPpOWceSFCPpCA
#y8PjKc4PQPNhX2AQAExvpyo4InwpoCDuHK6OBnhKntmhXoyUBnJqBxWB9tQM4BXA3DaGoauns9mfxNl0IHsnkrF9rZ0IS3xfs4Ejw4uQeUcGeFkPHrDu4v6Z
#cHotaAe3DYZFZlzxGLqRDPasQ9uMTNfuYDuRK+phNFmRSqFCVEbLTtJcDMSDp5IpjJ/GnF0KbQH30Dw69ST2ZNTHukpKlKmwHgw52cTxtSJVW8X+QV6Pf7ba
#L445DL1YA4jwrkS0P1d4Z/zxS2QoknUg9fTO1r4M+Jqlu8OxOAmcNFs0WxWXaqkK2EVS09FTrQahErkUzqiCGtQ2ocBySDcbCWGTJKBbYB1L20HSPaLfAgFR
#mLIGPXG1q8SICo6SE2WNyPq7m7GDUFrCbS0Dk8T6xrpby1Mk3KObYhfMtTA0fLYaduJufSaLuSiqYZaHmmDn5c3aMdfuSRVznFrKISxgv6ydUz0oD+UWqCYI
#S756DDu4DujV1ZHlhgTk+mfwmgCV+2qWns+OKmNp7gH7nbqZwkBhLBcNEORdGNJKLDbx9nDjw3qYk4dHM/IRWnBXS9TuVOto04hCjcyprr5Hg+adASWMNTrY
#Oxm7iopc5GxvtQ81ymnWzeHUCYMTUegFiZ6JrUW6SfIhWpQsOSRxcYN0ECnAxgRUBCj8xkVm2nRW2WgkwAa1O4yDlfBOrT6w+S+VL9CRMpWidp9UVchUML1W
#HsTpGMhVlxSrhu8g1IulwrmyqyUx5iUmFzEv4UIRtT+uYZ0IlhCLP2bxocEL0Syqh8kG4CNP87KblIM3mreghWwbb0rJTxi6F2rlIB2cniEZ4OlWGFAZIf/2
#JiL1FGkNrWikobU4iaaYpTGZOKNbPcr3GGMiUBGCK89XxBJ/JHUHK1fxskLLXB+5WMMqN1VEkcCrjp84ryigaugbebLaGMS2QmhUkNbKilOul+ohtq9gj5S9
#EjEZmiIVQsUG2Cbz3lXcVgMvtWyM29gYJGSoqGsl7+vmkrtRm1quoh4MVzPN3jy940fXFc11rgbDIGI8A9wjv0MQpjFMVLUpMtzVftP8dPQID6cZAD0Kicfm
#qJvASSFOfaTIRfyC2uvj/NTLpiiVVfVqSDQ0XmgUpQTjHeofV6TmWJXvSChsSGgPxkiKkrdtC3BUwqkXVW1+MBqiC6RZqtxlafIg67KVzk+DlCwaLVNzQ1RG
#MZ2fwyjeNscITC40ouonYxx4NsiAEjL7iYGIrf5Vk2/Npks6KY22idRHslVI2YpaRXE8GFaQGyBerm9V/TVMcXHDl8S0Rz9xo22uQX8SuyRoKI6AebP99tRJ
#r353gzNA25aVDSFKABO3GrmQcx86eugzaT+zYElO5+uMnVCnNA5HyjCaRtKqU8PaGiVygDM0ieMIX723dhqMITBQeuqv6t9LTIU4W0JdDDnTCLCruplKMxPU
#XCvBXMfiVJq48sOI0I199dYjSenK2O3HjI01B9QloC9rR+fWJrRTVQ8Cobpk6Zkb1rTN0KOzylRrNdwwMz+hFUaQJZj4B8NCgzf+9QL2l3RfqPzSIPeWcy5w
#rVjRSLd3Jv5pqJ8DATMGLern/fwPqBRcpcWM2bNfz4mKjG9TNx3pmMCtsUwfTuKE6FDIxqoG267C+qew7lsmJwp9uFagpRGv7uVWng47WmOyE7GzqFhN+qWF
#XqFTq4xmnCVHp7xPs+odaVWtUq4en6UwkRprED6gccWzBreVdIts3XYT1SEvGWcnIpSMPs6ct2PndgAZRQrqWAH+XmVdNBOEczxtdOyaa+5yjvYMA5EE0/MN
#Q/a1/tUlLRJ/QQeYfyyl3Ug4urz3xRA3iJYxsSYWxcAZhGVxQ+QaA4FrpM8C1FEHsq2iqt7lhKOYB8a+nhllzIWryFaxaMLPsFPHijhql/G6gJ2xHONAVLbN
#mgruOdGL5I1TMnZ+XcRGvJ3fD4cJwfJRQ0JoKyvptOAfKgIP0hj+7o7bJEsXsyKeHzdAF+E7Hu551m03riS2LjV8o+uXN6QQ/33xfEjewYrcJX93KpVo8QHo
#KzxbcN23+p2rXkpZoylby6K1nvvivqiVIyrHOCY5mOl8OsUSI0U538oBszEaloPqkMaMOSKsfUx0ZWonVADSpPRAbVsrDg++4Arl98liTWmLa1kanOZ0pB/h
#dv/DmL7w0XWOAm0efcN5eXP5sN80uA+Hi53bZHc8KU53lSnNFhClS3YOPBmVz4AtWiRVZpTN2DadiemFMF+3zZXLrg1mg6xXRAEEZdIQv6xwpEhPRGxx7iV1
#P98Dx27xwFEQBjr5iD21641e3qAz5v6u6RAXmU5gei6sYqtDHKnom3zA8GV1xWUlZRJbBICAmwDpoTl1Hx5HGnXOVF3tSTWV2awcbWNS5c60zSgkCZA1Y6zd
#k6Cpx+PNX/So+JlRTahKwCNJXFZYthWbFhA5gI74JNtMUJ+xOwkwUcGAXxrHONtYGnxtvQa8ezv0C+QFo/NMlhI+bTCYsA5krv1EO+0LHos4S2JcmXIpyYso
#S2goAONFClQZedr9o15D3Er/BCacG2X2cV6oaIpcuhj/wVad1F5adcI4QCflDuwU9JwV0e2VVLM6JbSyESUaDW2N2t3vRVEebhcB5En1DKgAWlKsTx/WbGh6
#b3YsW7aoNffhGY9Qvaox92k1qKqeVWj9z23fY/0cyhO7SbvxAJNM5XMfVc3sBYt+6fzKfnmCY6zLBCAFa9q9xoce0ALud5sABrqpNznCTR6d6DaETF/54Gkr
#JW9vRraE1wqdol8eSTXksq3gKxR1yW1ZoO9uQMUlv5/ZQ5qn803yQjKf7jwS6suqqz+3IkbUDs8tyWirjFgdJNfWeK+9oOjFbwS9iCw22RIUfyE4XYsm9n5B
#g0q/wEYloI2seBHMJ44odzmK4BXSEip+CuR7wPaCy82NWZMrQ1PBXIvwgjLg5U1phqtkBGmGpcWHrGoNW1rTlKE3bmkY+XCk2ANFNCc44DR1vrwXCzUc/EOz
#R+KluQIWfdukxhhny431Z9rng6Z9vunOUFrsaxUEX8xKeRu26ewUtVOlLByoIie9oWJeDwW0runXbqy8bAsSbO3tDkg4RFmLRrrC8jhVeFu4JEgIlajHzL0V
#CuAtUyToAhOQr5PN6iQQdo9BZf5qX2q8o4YDoEYUDlH1NwhbLj28sKqV246EO95Y8WbTbx9Ul7SEGJ87dstbRZ3GlXdW0zsaxY1lsthnnBMAzJfxaQIj5TY5
#qVBja6+WYiz5Prqq6X2c7+LDGCXQ2ZNxyPZP6RaQCh7POFs2ZcbIV24AnWvECnKpYyZWMZTK+hxkTZq2uThwq9Ei3Z6anqmyg+2Qk6u37YucHPn/qX7daEUd
#bi73uX96SprGsz1zmyYCYcGrVUJzobTCRtWhxoIb0iIeNGPJhCs8RNdrOdEXVBS+/+dwo1H8I3sslOQjoAJf08ui4YowUtfp0On/UhQiUmtcvurFsefZQxZF
#3o2QXEHgpRH5Db7X/1FQevNWQhsb20mkHab8f2HEVnAge+nzMHthOEpgwtCRHqFtX9s3mD6u7xjbgv1L1NEhLLx5+xPjHf5nfLf++E/bxPj1MS2M3cc/7nfG
#g8tf/eStHDZgYsfOoj02ANL6MhzANI7txaQOBzCNWTiAaB4sVmFvCIBpLIYACPFz6IXhymEhAPiV6o47yFObKczwd1zg1WFjXF4fnk5Nx3ZB5Heat35D1O5W
#17KVO9KVmt57Ea/5Vo/d4OVN/nAnSy8A3o/xQ6KVKmyOeewS7+jQ4SQAcbe6I+zoL2zob5zapuORIqDd9V+9POz1XQTQVGjIgVpftfKyxcDbE/XgvZH6xHHp
#nlx9wTDd0QFvwbbq3VW3lFa4yYkuoQps1UTDVjmifiIstSUlE8zvlJYq5NKqR3KceGF0IshUTT6DGuq+a0kirXDZ0nMbly2HO+H6HZ6HegK1jJYLklB2qYGQ
#XurQBU874ssvd+v9NrH2u34nl8vJwouTpXk59TwvicVoFQ2S08WlOK5vBpHpeiy6QOMapcIDb9L5unfJurl2WdYvLzzKSr6uK6q6dd0Ug/fxBQp3bgLN8ezL
#kXxEC38RJcntwAMmdjVIyJaCkoi1xRmJDpyMndzEc8lrou2+qAo4vLNoHq3mUSUVc1GmdlXMmWwAsGVweaNSG/nu1a1yTYzd3hRVIJGAEjT+7FSBtAOHTcsq
#iVDsssujZ7ijN8xGWl4QnW15u+JqC23zOwOHne46kmI5gqZ2Xd4zHduBR/z1bCP2m2+HyLKkl0keNOX4YSViTDsu8u0vVEtYIkfwj+D7WcR3IqMs6wBL2Krv
#kTD64miWRGZm3aAp1wfEPcZ3TAfNlzCeRPNVzC4QCrAkhQ6qbKoKPScRuI3YSy7qNBNS3oVa7zDh0l/NJ098W4HWWukUkcTODA6tTMukjbNwvKk5RQau5GxU
#645TQrzE6rFbeG6kfRkINxffW6Xe/TIJkgliqPpNN8qle3QK0uxC5JG0LK6vehX3Us/EcZbThckZ68Za1PTRdSbmxAbMwiQAGqkI28Lx52xRzm8r4DX1eYL3
#AxvKBy4jC+fCj/pk5Ffc5OmRpl9oeN0bs1tq5P6SSDMuPKi9ZRxhMZwB3hEk4KjCF558/g6Vbg9xEWfDqLstQQXjL+OHNoeo5uAGaR/0cVTsbqhzvEAQ0kqp
#bNT0lSoDv7VKpKLhlQ4fW6AOkJRZkxfJPCBdhY7ECwhkHzjjRE4VXSDDUh0EDbm68+/p6E+BgnVw7N1n9FWWAi+QLQWhYClgulRfsBQ0Dv1QZ75yqFMZ9zOD
#o+7yrWtrtJXSfY/eRXSi0QDwZbilcEpRv3BH2jtk+jhIdInsrEAVHYoKx2eGTK6omGKcM/tK42DmDgl05riV5wqPdYbCoynOQRvnTK9TKFLN7jf8vYfwpF3H
#w3X71aXC3tCachpvayCAuNsi7eZsi6e2mfXwusVTF68bahi7T2BwoTPG4Lb6csv2IOlGphUFiFSzVnU3P4CVpbyuOX2xJESsEcSEe5vtNosqXpztdNzKZ1Yu
#gQRFsmJFb8qSHNrcTrWKSq5bKBOeeP6O28jOoBp+gzxhC924e/EkX0JY9OB6sjVa2cJgKuLm1Y3aasGk16pxCjPSYvSXPCrkXtKt1hkAyYdsdqpDGnHMITRS
#FCflhIiGBVtrneXO90owAZkrolPd5YAfcgf8fhnCU5D/OJI8mUQ5wQlQitB7YzKtU+l23yMCC175YbdXfihAQqi/g/7y5nK+Se+T2jzAmc50PlRFCkW7Tzy6
#8dOFXJf5fsAYU+Em2erlMl8fV+YlcB0ms1coMmpZp92M0dwYdi0YLwP0iQDNiwPN66b9bO1y6ofJSmRrJRzhad0GQ6Q4Ve/iKvpydAzylTeawiU97BRfWo1Q
#ZFqohIGH9csQs1QlZMj2qYkrHTCnvscrVTjpDaNIM0zShzQ9lRpOUYR+kBbO8NeLFDJoPI+B+nErcOkAlR+UZhVkKOA6mx0noGDSmRK+twhSLxqkw4MZNsxl
#D54xMxbxMkuM4y79cExMozjiyhur+OM/7nfGYb9YowbHNKBRKLVMDAzRfISPlXFtoBHLLY1Y7hWgJs7NTaYkzVMkQVexYbnAGV7aoR05UZsFywn1JiznRQoE
#Xcdx9gIeiLWkzIYtGRLaYq4SZ1tGVO0NAkeA1hSnItNxyFE8bHO3749gFWn98fVuGArhYaEd4Pg33fJxIUJbd8sQJ/xeNcvJ8ZsafmVnK+hUf6nOQGl8SLtD
#7VJUWcHEe9yqVObqXLy1Ov1uMdiToyHgaKTYcs1usZRsPFUDXw6wn/pRHbjabpF0mGFSXkzabvar8tLjvbbCpzdqqGLlAq12WL8/BJvfFYJNb46XTJ5eFdZL
#4K41eltXvAao8/CrZjOJWlW0gJhAtAUCGZEP+EAVbcB0tJ6W96LFJUVkn2fyC6r7kL8ksy2DER6oSXFapZ78WlOUy1Zi7nInrJfkbkrh01z/VZGK9ANv9SDl
#LIMzd+Ze/FK+JKaBv2J21GE6oaDUBdkteqBIdRgtdTmu/gqIwDZEyrqFPayXbXeoZPqxjt9QydSHvUvvQlibrouVtFWvdtFoXfSqeLGYV/qaBGZIsRddFtmX
#jXPAxdR6Dhx6BWF9zPytGBcW1m5zbnDVnYzBjeTA8YRP2pdokWaLTYKrg2ENPEWPFGDUBYztL87bdTVKKabQqBqaBnJDPrXkRXJLPrn5wIKZqKypqRhqNESa
#VvGjPb7EZK9T9EICnnOjWviV3Hn9yptWDKln6wRyyRmem/0M5V62byuSSFNgHuouGoyafnsDhHdf694t133S2X359ITrS7KUr1F0tQv+tlI9V+VloWwjmohF
#zOh6LrkoCmdCmK9vv8IcFQneCWTZ6VNPNq6jrecdW4h+eIGPqOVWH2cIqndbnTXKkW467Q7Dpe6gbABMz9G4p68EDxgibie2by+jVuNlzQY4U9f0IkrWYaEb
#72WeJPeV3Dv4NjdarFiffbe5Pfk2N++x5ao13ydPPGaqpMDl6QYQ4IVpuslc3ogWhVKuMjiprlvjrLzYzlQKXN/CBWBBMGfoqyrBgszsd6OT5BCj0S84btTv
#5cqZCU9hJl469BUoQbZc4WKyH7/I1QyFcau726Xh291omLgCct7L+T68E7dHCTLsYlb71Skm75yl6xDVE98kWb7f7eJNmtNFi6Ynb7xwZtxrAN1zF67glLu5
#F7x1H6FcMHedOb55hGLLuTuZoE/vowfFphPPwTew7CxizBhXDtArfoBhPvJ7FeNx/sgv1Xd4/fLQGouK/4OBjcqQv/1OhPrqWmcIlvtqmz7dpMA+A1wIlQHX
#SVzI6CxPxrpns70Td2RMMKPZarUatV676KzuB+oYu7zKOpsCdk1tSnEw6qwelhMR5EjpOlt3bWWt9TJi9/iVpaiFx85qXmOXFSNTMw3Twh1pDUb1a+Zj0qi5
#uR9pHUOqt8y1Y6jNugniSrgvNZ7WuMJGlSm1cXlRO7uobxU1Z4WMECZyZtLdyHuin6V14DQQNkrIEswGQ+Haax6Rml15/VJruJNubNIYRiM0isk4mdchuDND
#0nQzMTpuRQRSgedUogyK/CNLJGjt9mOkYwbZJ0z5kYbCVZVg1mmby3ZZBsMJGD8x5a9lncZjJmvXIQjk5GIi566mHaOW5nfj/SZZGqqqHq/uvjRKyKOQ37CB
#aKYExeKsMLTq+OClWaShmo/qtSF+xmBsTbUUpNcyrPVC6b1k0ip2Igoxfv7pjcEU/VquiIFE/jgi3giKatg1Vga+jAiN119f9IpWobxYFVtvSjpCIFAs9hMM
#csF5tJ6CqCkyxOtVPBAKMiujBpdVG9Jf3mjWChhkZyiDzPsB7mjUZJWBdVslu4//XJCRKDcAV8Tbj/8EX3Nk2y7z5aaUBDFmzcSlmDU+xqyplG7NW2tU7ff7
#Q7L7uyEB3ARH9yh8WCNBLD41G5SkSHW5e/wLNizeaqau4nlLsG0xuiw1wULBKNeCB6QlaYvJjX1rYnIzqSQaFA9F9QVsepkP0+OI+gMcVstV6hd6qVBDMagA
#VxFDI1KkjSq3jXCPm5bUbUngR8MYN6LcnA0HpdOAnKrGPseSQTd32WBmmxg+UJq7UxVYgL+zFjwiWHfAixzOVrFYi1kMcuAOzrjDgBElqE6Pe5YnQ0tbkE9Z
#uRUIviHkuEPjW5yRJbEysgnrYlAblT83fDGa8fVK5w9bbiUTo6WSbkfwiyNVhOqE9rpAgjgoDLxUpcoVQrS9sBTH+Fq+iU82wnbXdMX3T3BfVBxjysua+SPP
#xNPuzllf0W65vF5NQAkaIBljoZ+OPs5NBlCFLZHQCPQxyNxQAivZN71Kk6q6AQ2IEqgdA67nbLFOFvfJ8rP0teL8i6atcnba8FguT65VVWMZnXiwHxhIGVNM
#cFunK/js8Xi/WuFmlIboIteQ0sqJpfaRobLnO/pHpSIo0kbYGJAPItT44Ys3gRoR5FTSpdm8+u6q6kbbce+AnSWsPegyoEtbWxBN00TDWRzuNc6OLATR4Z6f
#1uZx9yS7ZFs0V20oRo2N5raBdbK7fnjgcc/vFnKEovCVu9sTfr0/xQCMpI2toGGepedSxGNpz2BxZus4v7HyZDE6tSdPRjqaLH4kTpOFOWoEpqhwNEqxxU7P
#amKeLmt5V3smRqs46Qir7zE/H1arx9iDZUk2bqjFJzZTi3NG60zehSmMOVkX3em01N2s6KtAtThDIKqQvyhl5dyAgdYK5J8eMpAnsuLZoM0/5c+7In6aXX9O
#q/P++pYHbswBBR+RkAHcxRug+ZtjUmqcX5RW3DNbYZpquZXN/ZmNlN6xYiOP586HacaVRs6dDtOoK414506HNPEvXMEvnHjaJoOnlzZpuYVvm3vhyyOUs9z6
#qyt/9eqvXNcAbApqSSR1y6lDmSKFws6TYck4QpaMQ6j7kCaPAMCDatuN2iiqd9WGLSCvdmAfb9jJNIQGPXrAkvv+9mbsoqqwSm41VbpCFcLAgfIc7rwdV2mI
#dHSbAQ1RNNDGlKl6MWgcY8/XV58Pqj5pdr7c3L1qDXylnVW8bO6bAhg/sNelA8gVBlLnXxiRWiuNzpO4oIQZGhv85FzTETeGSMpeGR72D8PgzrcFMPvdDQVE
#qVZmogL0UzEMMjRHKV/jid2fdKaCMYiAV4ayxPPDSQpOX7XP9VvLp5IfWD6PqiE7cuh6CQ8cTrD8lR5zEugGTzFuTQp0y5u0Ry8UEaVzzs1qU1tdAOAB8vXJ
#l0CgcR7qO0wqVD4+ONqI/r+jU2zk98njb3GwzYj+v2MwxouMHSukTOFK625L6xTJjNcFtExVdX0ATqoHoW79Lmnbe93WL/fFoeWsNK/fu4pdTGrp0JoHwelL
#g+C1QhL6hFKCBScQh8jzsDtsdT1b827s+PTS11ZkCdxDbUXW6ERXz2vuZgFU636TtKyhG5QH/saJsHK9EhO5nTWw48VhTwenkUjCG70Ega59dNihI9Ncc2WY
#GI96EMpm50s8IVYUKa1hdPiB+H8cddFAmHDZTmPS9dKNPVtaO5sr1/c7kPXSB2BDSJ9+t9k/tgTjYhm3xYjU1b1WITz1mFxjyLLBPmoE4e5wXf1Ol90OBIqv
#pHL7I7gawRw2m/FijXx/HS2Rs24rOK37VWHQSsj2MrY4SqQkMtdpdw3tEXjX2BRMLfkzZmezbNxQcuAgo98hLtYms/zR57o9DMI3Q7aOwvXVj/dZiosd8CvM
#YkOzXbEe71cU3xNAWGxXeSXY/QBbG46jz8BlxOgUu4uLpLUbt70bV+7GNaL+XqSNEJZIfi6sl2zAfGnWP6m+oFSkWCdbSotDRepGGO0z5PVAsT09tGXNcAOb
#KyelUKxNDYs93A1Tjb/9ysPCjXzOyLDLz00/GXbRXczccwCpxgPW7DhPF+N58kOaZMCvBKaFsZdMaA1W8xH4+JzwCAws2yMG4fIPfmPGT2FZiVmnTG9yq65p
#RbxRnA5vVWxpvVTbgY0FSEK569y20GiqNMbSz1lecH5rGB3P4FHshKyMRx7Jl0KwwvowbLPFlV4mxsMxwbWyFoVFOhphPEyGo0yPbUN5qSsadNXBFL6Tqbdu
#jgl1hjXRNIepD02gr9LclKaFOe2A2syI2Ny2TVSpTIiAjFEStuE5K23LtvOX9iqutkrQVcXTVXE6e/G1VTp7CXRV3M5eQm2Vzl4muipeZy+RtorcC92x6NkX
#ZS5KFe2+uJOuKtp98fyuKtp98Z2uKtp98aOuKtp9CTpXTLsvodtVRbsv4TSvvPwPgsdKCw9IzKSosebl6WiTJkqI+xx1Io+qTwsIS1ecY1YQCnGnjxqtMAWO
#YYXD0EpXvtoFJawNgm0+kruUnQ7rvlHcMlzLb8sXamWYAU53k5Fm0fYS88bRxRCTfSiK8kOOHyxKDpvWH+f1R/QIxW/rM5LWih4O5Kmp91ALtNeusA4IVyPB
#VUv1dCRBlZTYAq1bAxdLVJ0Nrlo09a5tuRhFFbRVsBVEVfK/klmZkKadrdVJDAxW3iRXK/ALMuVKajpB5pkSMpohJfFR+xPMGGgkETZCMwBHY50NlTbe0P7p
#4qe4IqvmRvrcX0oaAkG5i+1qffZEBTBwCPyC/FtUjhbwYQa7s4B9itN8vzM+M7JktUlISCP0YrIj2ameLbWxnOt7MkkErNVn/Pkzf94SRN4R0jea7IacgbTL
#rEGOf6+AiL63xcHp1iOPA0mtVAv/g6chJxUY3G/4ihVru5r2Y+6Ken+z69bmtLougtcJuanzyXTcq9J3cPvc4g7749/kRDJ40oOUr5INJBgY6Q4JlAA1dRNy
#Jne3VmtMSJ1U9hhnLT16g3uMW9wlQp5m4iD2oBEZpIaVnAL6C2382rR+4G5XB/IRzF/END4tWluahSwgEzqRHym4hdEEQFLbdJHtx0Q84wWzgiJCSuezmGDc
#ZMllyy80nOpNutlUX9D5ofx8t64+ruuGUG3Jv+iywrLwwuesWdCyZtW9EO22B3zbMUJua291I4ZQsiW9PUqMZeF2udFnCLS8b9LLWAy7ikK/B5YddfAUP0I+
#N5kv2SWG32BLGoBaroai73nzel6xvJgjbG3lf9AphEvUzkPiV/tCUBq/smnuVvWYFmty3qvu/PHIUVWkWUFoZ/pwGHjYOnAAhOEpnO0heVnwLk49hkNX6uY6
#oqxeJelesaCzHMzl2ZX2CBRTXt5c3iU8mp7+dIUdR/mFKgudNI0Urs3pQ9x2fHswOIu7WhGHBx05qqlRwHtbg5hBLtXJ8jQgDaQXjDrDiNDFSWH4KuwJGA0T
#SLKbRjwABiLVMhZGvQmlqcRAabcB5I4VmpbPpMUqapcAG6gE6ls5JfN4FWxKggSMLdF+Oi/nu/0j6nkPFKWq/vo+FWXR/UOPfutFaGiZPogn7algK2A5w1R/
#PCmp0AIzCrWto1+tI+VcbhyXAraA+QjXTTLLkI6MYYte1eK8VRvtUQg9Zo/xS2uMPj2TTqcs7BAAyKQxDIeWxmsogUFsP+Ld2uSYEVsgpYtsC2pFccXes7vX
#D+kPo1N3lCYo0vQLFuTgEuG1OphW+WbRSSyQgyZKcT7tiVbdEuX6KEkyuOMw68giLhs4kHol9/pVM8eJUWYc7CD5xd4AwGlzNRSUyT9wtn856jG6CBoanAMG
#vyyS2SE+5hg0pzE3iWkRKmTH3Q7KqIQbV0O2mwG0KFd5WD5mfilHoODoJWMgO9R6wJ1g9CLWFvJP1+0wLxlCWuXlDwu/c99C0fKRJ52Uf5ha6560WjbXagme
#5mdIRFFJhMgbXsT/CsInl+pPlx8UJgaZ49pJWS9PuKUPOfoni1AhUphuAkOXjITBY2TYbhb+RbwB1Dku9C3+MeSq2jO4q7vaS/Tr/TIxDmR6+fjHBRSsHUUv
#V7mKtkucVeI5X46ZfuksXM+X8oKogQFr5THZCtMNfinjJzeFTl+vSQ7P0iSbdVeGnWNRU+T8CYYq4v6C87bEFLbiSEsDp5JZ9sceY9/4GBECmXNU3qLh4sUq
#l/0iFPZ67ChBcxS9TAg8McZ2whBP8BFNrwxJrICp8ebeahJroo7X11wD3Urg0AVUz4YI/GW/eV30HWQTa/Fcc69M70pQxpELCyzGoi3iIDIUFHh7ciXocUOb
#9Lj+w9qMXLyZqSTl7HZQ00Sq6srZiVePPdnpCkOPsKjvUpweynhCTvGNSPYu8OPqjQaJBjJgNmgtxD2AQWFk+TaGVlp5Kqv4PDUWwBHX33HLDSBGemhuUCXh
#Ho59sb4zqnbECRAzPe0yH0lz6HTcrOSjaHTbCNXIJlK0QZInpBulqyq14IwgRVFfTT8AaGLtdNxPdHXpORv5gz41SSeOgXQTrdcdlUQZdcqOpjIWI1J9wmCE
#HS7e/0QVdyaDJB2xDUXpwpkdwAds4k8tuWPcOnmMK6SMVdPhdES7ViOotkOZFcnXefwu9gEHPe/CYSXg2ZI9igGdFyEKU6IMteMwl+y2Ay6Zd91ZVeatkETg
#jU0p6W/H6cVtBQJn0La1mn6FUnNtKWWSNlvT++G3cMVLNnLGutYzMeiWLIx8WMgQhLeeCCFoexIjhEiBx3hHA8OF2GJws6qDkC0bxo4fsnA85i9VUMPL10+7
#IqXDoLlmqBmCBlo4DAsWqbvYWt6ud5xzspW00V8vaDNGut06J5xEg1GXggdigVargssKdAapb72lhtSMMAi3NrOL+4EtEa+J/fD4QseKa4EBm5RlG9HUv4mz
#PdqE8+fdYp3td2n+8Y/w9UYULEa1ZEHciLBsOJhOYm5yNfe0D2Nsnhmrw6YnMXc+Gel9G5g7zy/J8aYLufJ0YjBv5lFcrtREl9+oS7DRqa66RAZFXgnzyoyx
#jfP7MVC3u6SpaqnZchN5SwrqSh8moRKh60dppRSU+JpvugUmZQnI91SvtKIlIG2xtAxsu4BT7Q8iznZLfyybPEXAQAiPZZu/NfZs1OHW2y+qUmbyG8RgpmtN
#Hx5NzP436ksS6WqTRLbSF09l+Zvu1nSgxKCmsklSXBuuQlEpc+U/EeQyS8zUFbQg0hVkDdFwK266kk6hlnWIW6u4VdtKdhFF3hZj5xNvKcbzCrUkjGWGZG0n
#QpRaaxIkW3UDQi3+nDL82cAzpTDpBCK+Ie8G04ke1oSrN6zsBLAJg9MJxyueffVSN1nI6kcJyfJUFAZpbOLnTQoM73a/TFdpDEdMQK/z9M46LB7mGg21AjmN
#gENVXdVod/1f/uP/+v8ZqC+C/pLsusOENyhtYXumLWUvmmH6y8jVwaiH36TYB9WECFrV0FyOdGU6K2BNyaUJeN51ksE/01il9CfezIFxE1a5tMg2FhlVhce7
#YXiKFLHIXRqfEYsxEkwjzZw6kekEQL1MazppSUDgur0JCFiRzkSdmswRcmKJ3twZYTCS0y5LNJOnXYZVMqz8bi0HUXV53AwBTJzzEkRLoRMQPdTo43g4wLaS
#Hg16lrhZwTbTlXZdEAikkB+uPmeeknquEY+iRVnuMO0/D0lgwiclpoNO7KQaLE8O/LUOa/ukpvlTI93qbnOoapmGAf6uP5UrjURSM3SFLRPSp1FFKe2Wr41x
#8ikqEBxaf8ZpVw5f7vKQ3Yv7cxMDlzk5ef6ZWymGyKsixEx6zm9fJu3+iDHYf0uIkSY8HKQQ6OKFZebFZcXrZrAOzz202DuV1B3MBzeuFYmuJ/q5evo7STXg
#a8CX80ZvCb6N3X7MIvzJiI2EvUkDsY3OoG8kKUgBVXAagtQWCTPhMcLitbF2TipPiVyNGVggjJgTdPArgYrBFMGqxFU2cgOrLCYFMWNGrSLXx+VR03uxwhWy
#niD4Bq8B36gHfAfFxynTrmGORwDLJpg2aIOsJ2fVShkcUcUyWey5VxsMPMlwMDjpZCGlkuDh2ouSP11Ol2GSKEz9JLhtZEKQgqhLCOyQJWPe27ywFrWWpSLk
#+6eKqFNHBBUYpLsugMw/cmownyIFvkLH3BXWZtnEevgmzxYaKNDniZdSP7o6QMHmjLgHvxJeV1ee3X9g9dsQUNdubfdZUmaU4OlvkKjcCZk26dyel2uZ0swI
#OXYi0ZN+zKMPQh/W+gd5FdUYl2XkfzH8PdRMVaOAQralkI9trIZOKixxOohxKifClpXHpFFoMJuKgQPj/M6kHOmgpCbT0W17Pllqhl9cYR/yk2L6gecWOvbW
#Qy7zW9ILlhelgfTRZ7URVxAevQaOkiybV6jOZ4J+8+BQMUE1wBNid2VOWA8IDyWkdS0zwr6IFJCpoEpkM2EBpEDkEDhuz1VzCnyZffzjMi1A0EjiHGX75O5O
#EGcWGYy4OH2CAUC4XlJrS2t2x/M5raJoeQ3JtLHX/VyMQtPINHbM8QkFmSzVDmxmw1J9M90RCWpOpQJ0BMPlkCQlohKtcn0yeewswQWqyphiXrru0ksSWU0n
#RI8oJ2GIxGEg+6nEs1PDstWJV3kP66w46YJq3sqx5h2WiyVyRD+u9Rwz9uqtyqXWhgRSxmXd4IGJhDgjdaOyAXc9P9lXZlvwC8fXhcvwRi9upC3vu9rwHaOX
#SVtwjWpx4h9OKmel0HmtnKpIoUAQmBSq4uyuoPaOHLVvEDw1S2uc5YM/j7N8/ENuBM0bfK/xcpLXFJXDtZDAHBElaIGeW8PiBDwsjrCjrXYYTKSkbCfPPljV
#tQCQ70VHfv2szXx9b7CrElIAn3sNWBPWcvXeFr/l185KN24e9qatsFjW10TBEdv1xXZZ7JuorbBYtgyTUy0KcBLpSVHeiC5CQw6IoKa5BMAqnldPfb5oU7sz
#a57dYnHpPnIBt8DadmTj32hh098kxL+2nYSTEP/O7dXKvFwGtr2aluWbJ81DPZ9HkYXTJ0CqIOyOt/tlMkPnU+DrZe/qw/zOcK2g7bIJLYtRrY6wwnLQnfld
#21mohkO711xhyrxJd0qrNdbHwak3mweP4c4Eguv7Cp0luYuv6eWjxmFHX+1QdtQW465h/RbvL2/JPVmfTHtkApp8WMOHEjz5JUXTC/nd0Wqhpjjtwzze7ZJM
#G0mo1Ou77lVrpL6rWmE7ddsXR0suuLUIJfsQ5PqQ1qwhp8s6xNI0PShPWuTUsMoJwmUcBcFqMvpRcL2WoIc6O3koeXvjohu+LiSKgxZdyV9fo+irt00buF2w
#7bhR07bjyWq9UHbsKZeFlnxF5sD6pRo7Xj5n8e7UjrTrAHaWcCc0UiJdOe6ABsR7PK7UgNNFNoQGquo2w/F1fYUUtTcgXdUku4UYr0tAUHSL0BQf1Lc4+QM5
#fMvs8If0jpyDznAPxTpqZLEqNpwlhvh0lCh75f0ruRBmuZaEp9+AlGjgHem9MTP2u/me4kqI8hM8FNVErpiNm+XO8Mu8zc3c9AOyLEqhiDFfvONxXyAnjMwI
#JG8f2CXH4Q89n9Isul5ECrdujdsLDZ9HsjjJGfpYvmR4fdCocwS512+k1ChblRMyM6M51+rSe9TN1MqUqHyRai1r+AKavG9x5SN9elYl2bwdHPO8y8jBcop0
#GjJ9xT9QcuvlCU8MOe9uHZKLT8vKMeiUYF9AHZX8Lt1Wwe49ZSMliUwJfe+Va7oa5vjmyzjS8XU6PmxOzDHXLqjzy6Mz6Bst1cuaWfFvK/91pHAoFy07jP3l
#BVqO9wVMj0b8/jjqqsJAoAVE8Qlo60P/S7yqv7yOCxSUBQP75Yd5sdNBJ71QXBcaRlxvak4xFXpI7mMwpQ/zeHmXtAA0MQB16nNBT+dMRB1QUw8vY5UKqIWt
#sRXlOrInfcaN+hKaAvKs3eIZAwrB3sUbxUzMMyLIZwBnf9DxnU49ba7uZPpSUnRyf9ZAZE19e4jvamMzfMClphtiAtcWgzoLaRwXeOGdonD2mdc1Fc4xtoda
#A/tEZ2DXEmrRo4Aos+gl0eOJJt42jlrvsY3M2sOCzNQfyF1HOba1O5jG9wsrrQfholDNOET+ASEnpdSObC6eNHUwzJ+qSpoDNSzV6UChXm7ZNHqvtuXjZa+7
#Uzx/mLdmbnKrtLntmZs+bM7JqfDn9ZiodLu+kBgdx5i+IkvKRJschZFRRSWmnh1RAmn3nrjVMQ8w1EHmC4p1AoWZLwV+sD4sToPiYdIsGy4UndbocxymmNH2
#Q3ESU7rXkN11vaQlWcynOFJ80F4l0frJixD26i4lpoStRCw5zDH3cyntlbDrhlgcS1ADxvwItKVMp+FGnTG0kFXs9RoRLW/MkafqpQl+tQuFJpcLDN2C83BG
#uLZKOgg10oEdVoKALhkK1qu9S5fJKj5uinoUBoOviuZP4jjCt8mHEv8FAv7zpSxd4/FCZznomBcPuleqtxejEd1PsK/eehSZ4qr22zAH1CUsX9aOzq3tuGJ1
#vCJZO43UkmvygcVn1Vo/OOgynoYYTcoDSjc5+W29kUGL2XnDnTZjmcV3NRPtBfzxvpDvc4yZA01z3cvyyv2PruLLfZmcSZClBopSZJooFU8CKpTvnoh2oLo8
#Adj2UDz3ShkaNVlleqzIrOylEXYYaj9gnoQDI9ncHlizpPV9K565knGnYXmHoryAEzys9YZwkUujRH2YF03HR1H21KzNUbHFmAc1WKAKEkhGbdH8RFnnZ3GG
#mUuPxhpmZKzij/+43xnfHvbYvHETHw6b1PhvgdXeP+bCTQ5S4+Qw332OlsOlVcx13Lytur6W6xMJHHyo4+BJ4OQ0YoDdWYhjbZQhDjt1K1GNPUEQAHEA9SVT
#n+PO0IwAcZoYE79NPLAVbt/rEw80Fc5IoRmN1BCYDYt31X/TFK7ZrkHBmZTd4wMdOwK6f7VdXAwJ0mL/DgJ9JBMYvgH/NjxYieEYHeFUFJlC9ndhDfHEmgA2
#RkhHeTBbq2stax2Wemorz8eh49XsI/NFr3oktFQGcqf25zEwUGXQ9ychfa7kDlwfn4B5a2DfVQq8tn7bQocJ24QKoJOaI7GpJ8Ki+UHNXVDMdy1SWEf2wjZu
#eug1XlsiVi1ma53VOtTHLJGvJcCUBiVVDEe3LRcEsYWuC4LUh7VfrYT4PpH2IGHBbjG2mK9Pgx3Ie8WZalEHb8X0vGuW2h0IcrOMF8NCFs7XXTcwe+54sx1Y
#9+7AuivFs++47pza6boMy04FRqNrEUFfqAALAFdr0pkG/lGbcRiowqpKQihqQCNeSRaKAhEZ9pyrxWoxT6LGPQclWXyH5F7uEpOcqqEMOi1K+sqqsvXUrN7g
#BVzZcpqsfPivkRfJicT7ZaXYFJAuE/oTjpGwj/S5NRoXpdi8zJPieGDyAAjBCUgdHMPO0vwGyZyJJMqkUILmJYIDMMm056NT484pBa6aSzzdDIjC4rgzMO4n
#fFqzJA8fjjGs+ybG7PUJJq9PALUfkgJtbRTCmZFYsyJqNSFCPM9JmEBChxEqqVSDB3eciDHhFeUQImCzhKMCpXLYdeRmK7ZftcJXSr1d17zjJ1ShE9dXgaJj
#8pEiKyKVlzkBhB5SfsrsBjEIEi/+LWrRc7znt7lmnHfFcEOZ8Xhs/DI7FuldkhlfJNmennBm/PdLmCZTw7+7iOHlxd+diM2aXbqTebBaCcID8Vyzy8BNPD+R
#nm/uZ5fzaOUpxR+hFXs+WS0d+TE04k7noVraw0SfyVR5fNfGhF9O45W9Whl44didQzcrw5/i5eNFFC4jI3Dgs79aYhEUnEa3TIGuQQN4M5DJiLPLZYjTuEUN
#i+7CqYsl53cwgXi6SsKXtkU08Jye+iWJSxcmnEQ0iZAN1sfPi2jlwOeJC5/nYZJMAzYJgwlJBN6reJtunmcX3yZ3+8T4268uzItyn+Hjt/ssvjDz5xxw7viY
#mjngT8DjWbpSrsCi/ODW1oLQBgxlc1tT1+wqB9nSs0oOXitduu1N5oMhpJzwynB9XVqAAHU5Sl6fwPIwuEVra6izcbSteRE2JyfTMqKe5kIYXKjNWeBha77c
#mt/Tmhtd0d5qICxkeiu5PcfWNsj0nEkZf0s7vFDJE+Ze9e4rk/DqrE8kGldCuOc+rKXNrT2kgjoDmtu15wBgzIWUtj1in83LyXS5CFxczVBZzolm8lIjETbi
#4GnxVvPIixFeXAVgvK6Z4/MSos2WQtpsB+1NUvYts/Utpfka2hQwFe0tbeN0dxqotZBgw3cxd5ZWbWBQgI9SJxyZjg0ccoTg7mrsk5qoNnKGSAImgyEbW1N8
#OjLLItyCqU0bYrK7a4YnuEdMAGH5QqzhhgrFUS2sQY/ORVOhY2vWS3HtRWtTmRmtszLjbzrZVDcatOSRfslL+6eC390AV9Pme6JDax3DJh5rAHU7l0QPnKXe
#c2YAjDWda6awHBOMmte5x3hEh8wXmZqpT/OFeS28kM0XWKnIWbL5TuZJHMyHz3d63jmiXQ35TWFegO242ztLcqzrmKWOMOvT+wxDEbL01TkskIrNvgIDRDZp
#m/r2SIEzwQrWM2BKVffj48gItzbingwl/EawuYHdc1wp60Wv3mjAiHvgp04U04fPOlrZpYoK5LVgGA4Fw77BnEv3s0GL4Hb1m51pxq13SLsUrWbcYauQMXPu
#1pBCs7WXp5DwZ+2gr9/CEbCCNRfiE7YGAsaQ4qCd5QLw1ykKJxgCJ2kVf/EiSi3+rnSy7zzAn4bsu9IIvq7rNqRez/MaIq/v+4q8e7ly8addXkX1ZouAaoe1
#KBvF+MPlVTvGn5e2WTfkVV5BkjS/QnWUKcibOumyu4t2FlsqxCSQnuPGa7Sw2eXbQWx2WRiwsbQIjo0/TVi7dJb407CtqeykZF/Tvmx6A3UMT2X0L+0l/nTU
#kJlTXr7VgHjpxPijnUZnJw0m9tIJ8Uezcq6PP82Vk9Yhko0G/X3LFiWZWAdB0MwD2NqgytqWp5E3ZmMI876xdzWvcJKifl/TdkdLKremkTzEZY/xR7PMvO/5
#fN7Tl5YFUwo0CV9zfv18VNko46NEoPLxR3ccV/jTszHMf1kMBSd5TohpCzuHNJQdkOo0F8aZ409nPak8EJRPgjyVCWzCi7RQr1gcPf/HUUFHvV16OmciDQaR
#o62+KufuW3bWqDLdzAP8udXlaNe3oXJ9l84Ef5RTw85yXzsD+LWKrij8mnzQRGxxJmWYp3cdOOPhNBzb4bWwk+qL2vDbJqcAzvL9OtlggtFNYvw8XaBPHCzJ
#zXwT3x2TUSsPuKNKIhe4dD0NI4i3452lhhFsFEdeMIgB9dkNdnDuITVucISaRu5arY+sDZNX0hg5HNsMPaYdKxnDZLKIiDGUWEhe0CETB4Y6QqDxl2Fl8LAD
#O3hpXzKz9Y3xkzLIyjHb3FxgkRmFk32bP9x99rTd3B6LVWR+Dt8M+LbL312vi+Iwe/v28fHRevSsfXb31oUVxPLXBhnS3l177rXBeAT6/P5zNGsYz++u3fDa
#qOx/9PX9f/mP/+E/fP4WC7z/HBt5fzEyQO432d2C9oGnu8Ox6JgYtggYNC7nh9+72mtw2WxVJS773yYw3TQ2L75L8arir5NH4zf7bbwDdruFv5aaV8wy4xCD
#m7WYYsghFcMLLfa7dFEDF96MNBC+SsuCnK25hBQHTRWhmjoVHxgO3TTtsIDIrbrQ6tQkw7hsrgiCK/EmMMw02xeG49uaa+7C/U5W7qS7uckvdr/0r2O3GaTB
#TdQXWAQPRd0FGu0OtF7LxmPNdeLlaWcKcswxMOqaRYtgVL8fJBrVxbU2iPr1OVaIKb+VNCnVFT5/INw8dWv2jq2CJtG14mthG16pGSt7mJZabtmmwEGYtKWk
#KW2kLmyzJoS9AVPDvn15lcWgqr52OnZh7XZt0Wbd+bYisaW8vwWQLsyLLzI4xMbPNjDmi4YdWXfzR71JpGWchAnVXArts2ifxg31SCHKqWjnytIU2htzuam7
#akwNdpTtH8fkLtLbS8MP9k//2783fv7Vl9998d0v/vY3xse/N77/6hcGPLwQ3SnrvBAKsmcLWnutTJv3sVzp/iQSZnFqhFnK1IguT41o94Ch3vZUncVg8Fn0
#5bPYi0papPa2w6wwMp1No/zeBeV9phyMgOFOYvMyCePItisjgM8ARrcgtBmNK9wAZJM4cDFaats5US7T9s7r1Fj1ziqqhkBCjDqFf7m58glqbnX3hOqLTefh
#gXYtQ6OIVs8gDl3arbE0n84hqCqHluAKl1Fsz+25eektkX8755z0dj9UTFVqsRUp6RC53u+SPMdAZT0npkhPmtOss13wI+h2t8cUDRr80KqwL49204k2FK5+
#93TZYnRB06dD/1Namo5Gdrp1GALqutiCQc9ON5QYTfY6aj+h/U1XUNQ8I52VszNxTENl0TGPM86hToPRW6mhxmCn8ywiNky/IRweSpssdsp49BqHIjU5Zwjn
#cGAaqJMJUSizTorPqDEzvsEYNbvYCIw//f3/Yny/3yQgyRq/jHfFx/8HJanKk1SMnhMsofOiLbsixoq+wqxkYoq/ACUuqY38ADS/W0KTyh+Omzw5aSIu4nWr
#2gktetGHfZTzP6iND85ZKEW8UzMYSk0+podEjTEkBkhyPIqQdJ884hcK7fSiX9Hf3thqQaUvQrlCZCa7J/dkNQ0nFOZBlCJsBngakChNbtWXAyipg13sjwQ8
#nbkVG9XmHfGyHAeADQZ71bZ8L1HU+u52UDwrX0xd2oCfdZkvUl85ZIkhm4jkEJCuEWP3zg77zfPdfnfDXTlD58rw4CBNI/Y3hL/B5MqcTK+MqXNlYrEJJuJz
#2HfPZe9dVtyb0t/R7RvD4MpMjOzmuE1l5mrlxt5Co8z05n7c9OjWaDIniF/ihiaz0SGNpV2ZycoTd2Xbiw6P7Uj02F7gj6jN9JBlcCLy9BV0mZIlHOdeDhBf
#lCUW5QcY28wu4/sgbgS8vASECYPeLRNjGW8AfwLKv0uMZGcsk206LhJU9hifGR//WOxTdMnHejo1M267xuQewY9scr/4WZxh+tsvofNklyfLi5IY/DrOQFq9
#6DPH3/bozC1XS+CrATbUiVeCoktUfwkB2Rh5MJywLyYbwsMw13B0aDs8mUo+H8NBjb/sKW1N0XkTxMe3mC9jipV0jsPT2vmYHO5XKyd2E8M2L5cIEwvDi9AR
#bAmfbe6sB4PF6IbjQ1ysq8MKHZnoG26bns/9mHn57lUVlYt2y5IKztTyQrWo0c0r78vzdOhOYNdKdPxy5f0CGuGTM0h7CS1NAss2Xc+yjWhieWYQWeiH61sB
#fpwaU3wdAYWFiQcYldOZWI5BlaahhXmKMSU6PQyqom5QVg9da0JtXhsYQfHdNU7+2siLbH+fvLum6B/l1zFfqXfXluNVD0uLQPUA0cYfYPDvrmnBrt+yeeHc
#4dMFgw/ycGZ+zias70Dokx2UgDA7DQgMSwhkYSBc3n6rrpfHjRUbsQ1MFGxqHXzoleFjajXzEsVQ4Da1sMngklzk+R+CzxJQWyG0RXHM3g1SGlPR2YxdJk8V
#ay1Hup2WSWrgJ0IS0kW232zmcdZyWe6cJlCcW9yflNza57XAkqE2J6VeW2zy/aSWUOKlVv44bfNo2Yw+u9r5CMET8AF+fkiTx5/tn95dkz4O/29BEQ7AJ2BT
#vEfrGG5Ev238NjEAccDLiYFFHCNkX6b8HRZ0HKpWHv8r12Or2YYD+Fjd4cfdCbD3FmsfLWWLpY/eDbTyUdnLVc7uZILcNjIHlKk3kZ2lkt0o0iLr4yB0pgD2
#wm07vlV4Vd27ddub+xQOjMiXfLEr9jvzRzQQSHyK334crWz3WGEfrnzP2ws/6lMT6IIEtzWx0TfRjF+ozEBJsFTeP7XsSbI1gHrhbxt+10FRLdvVJJfs0B83
#DABt4YgBwpCsfIlfRAVBbRBRMyU2pHIeGDszWVxsMaIvf1WY9mjUsY5WZnd5hrWClwBQOIAZyd6d/Tgqcm8EnizZ628S2LodUtyv4+yeLk5+ud+mC+Nb6NT4
#+tsLEw8n5huhrtGqjZ+AEbZsH/aqYbOgqHlGF1WjEbrdFPEchwAJ7qYwV7ZILEJx5yC8tu3g4zlHE0WdetQnWyDLBlju7N7X+Ru3bdSX+2OWJhnO/sLc7nd7
#Orwtc3fZONo2h02vc2xBx/6cBayOsCTj/jUJFdfTJFkmbf0OhQcBU6VFvEkXfJX8LviojcE8FUFTx22XmKuKsOlKfoOSqqyZdNg2KAVTR/+EfGu8OSW8GRDe
#9DvWcbkHWfPU4MQUUBdUTlyzxjJedLY62xXr8WKdbpY37qiBZBrw5vahgiK+O/XhIybff7vI0kNRoyOV2NRb5TbjljmBhqg09onmLx7AFjt8B7OME2IhHjsQ
#cGfM/DpMA7obKlfKtYS4sZEsSr5KG2vO6oC5AOLjUzdvZcWHw6mMbi2kpXKqy3Xsl98ufOg9Ztgr5i2jgdEzrw+o9jITY5BhNJlS9PAkS7UIo1w/glvagxHz
#dJmcWkSbQe3LQk+HooczJJKix/NR0eMrYrZbCdk2jy/bCMzohGU+llK3s1jBPEP0KjMvwwRGNe+RhHHm79VrIYLr9WyIx77Y1E5I/laBkhjmtm1d23EN0rSg
#XmddRoNu1LY7DLU5M/Hl8KgCQ2vTIphTwCB5Wq311HsrtS2/TjNQtlOK3q+4ezNs59ZLi4n+ybIb50fCzc1aCR20rnx7fD2zfSh1DL4hm1V7+XTQQ8Gxpf04
#C2DGV7wJaSwrRt9Yui7rVHoUXb/dEENtv7fSU79mibIffvKKhJzvsTthsH0MjSG81Bm8W+tYWm1aRycUlLr9LaX97ldb0WKWFHQXP6R3RJd7aOiuyYe1MPht
#THQHn6P3MGqXlqWMIhTp8xOD9FHEsdaZd4Zoa62l8WxS2CethTESs7G53dg+1fpYMdS+W++3iQpiygD0J0AeWjWUMk8OY80matKcwWof/Q0exgGqrD0RmjG7
#xUTRZDnNsG/riMRDCRj0e9icekxyLfA6afr+Ed05wwSHnasniJjS7jrtOwwvW0BMC1cTioTCNi/sBKsD5pt5aOuV7vqcyT/6LFVjn8hx2MkJHSJNnpF6Q7qa
#YVlian+jcDltRBxtE1fTeavyFN/B7+L0Gnx3jgq1kV2Fhj3tGXYZunEgOZRpgmjFEVvrvwjawBVTuxO+NvFcr4gVIlQKeZA78FcV5Zsb53RoS0RaTJ7UpIXr
#yDs/Kb2tkD7O90dYktwEyTMvQN7tU+vrfH3l/ehWGA6FrXOIpzDXsOnsfds0PpLts7I+1vHLx7TmI8lULkj9btSF2DArVC9ktV/xbW34rvXwYj+t3BMAyzDW
#qSVyLTsIrzSSTKRDJMJqxzS7uUsc2jknV+xUSvHn6q/AlKOwlnc1mo3iqX+rEwJaG0jnTcY5nWsG3jwmzaMeSSyJM+rotYNvwoHsO6juotj0tFCmAusev3Du
#BI1cl6RDgV/btHXzXfur9adThK4xdUNiFe66Y3ytG96unWyGVx7sjGDFr2BhhD1qlZm72SoWh7bMRwNjaDTgDwXg3dJsfVOqFBrSWoXXeapeDB/M2WjHV9K3
#aP0hhqlYOiMvn9sYT5DXT0BFnXBJmZeJcZfssqSHRLO7NZ94QD5RAiZKfA4Rb9o8iOdqYbp7DhOuwCuIBetSTgiLVyrPZ/xbrwtJrweRhUZUkpbhdOEH3h+J
#/QPQiZzl1OX50UgnLDiBHMmNdHkdLxbHJN30ACVeBMrJaOGKydN83japJ1+6Kp/4cZ76PI0DC0Reh85mzgJOM49ZA/gFr9/GQndgTEz0NmnBmJhP95BQAP2b
#CSXB4SqP35YuCE+ldwJ7XrkmPMvP+eOidGboXBPB5rdfLkcnrIfmdfJCGFYPb3/zik6X0VWp5u0+U6yMcqAxfdggYQWbV+A6bXdq7yPNqRG6b7TcMopOA6hw
#4c3sLHOGyrt5H06RBTSAJOKj4BMgiwQdGbyMnxhjdyTniu4aOvx+KlUar6cN0y5CoEtsy/Yx3a2h5aJ/gKKyhFcSLuGouY6HamF0J4Cth3luDRrgebXi7DTo
#nAySzTs4p0DIiUaftUnOGilP2oMDlAPr0DmLuRAnHTJ2Ews0IlHZ529geg6bruZdUH0igUXL4uf9LjfeAuN216tOydfJZiUmW/e7tKd5Jfi0mhrljOeiBVfK
#gt7aQbt/5toVnW4qKuwLKct47vSG75/O7uu2ud6g2qV7gH1YmRbVekjzYeXrAqdBOdbPOFPqkRFvouAlQ2OiCRbTNXUxXfgQpX87IGvUeB2aIL248F9RPxQP
#Ua/ReJbJYp/VnjntVtkk29dMLjMVhR1ngxyNtWrebgZe0ulqxCIleZjf7qhWXbR0O0SjTkM0plhp9cy2DuuOlzG+FDDAYhNvDzd0Q2Xy8GhOUa/WdOWSnb3s
#QMq8zBypWlTcZ6MGPjny8WrFDJiYqCzU8JsZ5KI8jBehwRxOWrMHCUDqAdMClpRfWwYMyQAwlIXJj2LUPR3c9g/DbR9G0w4haDH2izW+7iOImggNEr5tpMz+
#VxK/KKxDi/gVdohfSj1R/LI6ncdbIlgOkURFAWLy4wsQmISiw02NiHG2+KQZnDng9kVMt22o4S6l122KVH+4WmDAFpZdtUjG7S0UxacKX5NzhK9AZs5ZUvsB
#CqQiL/FMMsUficDpcre3N3UYqPjVgBSXaISIzfSZ5X51ia8jjlgOXzVYlytt50GferE8Ok6348t6/qkKW7wP327WSptWqbv0fCPFXWply85TFKfbu8EemEJh
#cqXTn6/KibbTVNG9vvP0ru1g/0gdl3SO4viTHDjklpyVtQ1LdSp1O5IJuLWVetrn952doxcXvG2mqrfNoHDZUp8UM8fsLvPe2ol6jv4GiZHjNTzP6x0D9ygZ
#oEuhOD9m18tX6u8b3FO3ma2ON2T2lehifYUR9zcmr293v/KKdsHBtsvfc6u7GKP39WxtQXK2mpyh2+Nw1KBSfFIsjke7US9tu56Lr7omja+tD4vBGBPKN+Jw
#y9e7hW3obgM+FH1BuKsKvUjjpa8u684cVEw8010n9MNhqNlbpKUBD7xV4flx47bJec7SH9avVIkP8GhiN6aGxCrkY6mcBFUzMoY7wDjj3fQIwxh84m0a0zbG
#TdfztqCFtieE14E60xCDCUMH9AnILwUXZuFn2LcOKr8RkMDrnbedczhkSmhfpdD1fLvrztVGpVirVRhOXJE7Ds7AWqy9DvTCC/zZ/Fur9odp4C/nm/S+TQvL
#XloiJeniaS/z9XHV6vKUHDq9oYZgvYf0ByMd5KjRHkuHIroCmFBrde56r8NTGSPADtJ+SNZOSWAR3hz2/A5BlgAbh5czU9hwphxln5KGC9rAxPQTduugcyqV
#Xr0KRXxRDymewwCOMAAevoks91VcIWewkr17BIxw6YK4VaJZ9w00co+jfdGLk8P2v2qlEZx58Iq4DdGg9QKxXkIWjQ8UsRDjAfE4WGIQrHZ5bVEo+1oOtEPi
#oOglvy+eD8k72IS7pC1gzGWeJG3urJcP+03l/9Ftj2kJVs/pC1uOg2lfjRiRER6MBs+AA1Wp1nbOmLwQsQfwbsLD9XQtib5GA0lwy5UtWK50auYfwy3Q77xJ
#p5vydv/DmL60DH7QKNs1jPen9ksVQ29JzIH1TM2ulzKvXLJVGNg1N41Vsvv4zyjvm8ZuX6SrdEEnrU/8Z2FhP/WyX9Mx6Sz+FQfRdtOiYzXRVibWPVudhBet
#9z13HQMxSm67DraKZvbKNWBDAbTG65zOvxFe36pl0f+C/kvh4k3yyB29YsQd0ZTyYq2Y7LuuL0DpjqsE8/xUuYF0NIHlSmeDSl2seB843aOI5/86nqtnW7Jr
#L9cWN9LOSfbL01Ts9R7heTHO9o+npg5xGefrZDk0qXbZ2KZ5j00VUqiUdE2NRz+Vbdvtdxheec3rBWqyW9u917WHOxDnj3+GMC3YaJsz+1AfJmwDCexssU4W
#98nyM633kqZY1bE8iY6Oih/pJLbfOD0zK0s1MM3edLm0uQLH3nmHC5puOXFn6LrvFj/CdUVo5czL9IvDPdvywbpEHh7+rKt8elZkMMKtscc5VwPaHYj1Ea0D
#IXh5t1PRfjf/dO4rKt3Xe7EKdJdaebJh1l8QuSiEdMOHr32Ps2SJCuP4h8GuK0OvPZVNr7PipERaGxIugtxq9pv/motZuvI0XJIwLbc5fXg0J6HOJalDjGhn
#ge47jZ70uii6X+fNg1n5xmySdGd8/OMCgLhbYLhc5Zqw3K1TWuV3G+ACmqGcleBVr45/5AevjX/E4gqXEa1tI/CvKjUvfB51zGnRps+ctMsHVVCsdsyhyxbg
#daEPScMDO4M3bGh4oqKFsjegm6cu3HjHJNE20+ts2BE+8ke0QXi+cmHHidrZXkEZ3umthzMkTXjvJHWxOOvEVOq9gn6XuR72fJU/vZIRbW/x0KKuiQTOJIr0
#1xRFPD7Ex7gj+i+qk05/Xl0ZTHZjHH5Ua1h3V5LBQI4L2IgKVWPcRZwVCTppPKQ5hv2/qTXfxodjvFsa8CEmFzTM0kvdjkrUfIl5Qk6V1naVPiXL2xLHlura
#AGaEMh6c/8fZOl0uk52kgKVMI4YV5IaLv2DKj3G2zG95wGWenPOFdQY0xDHLT+6pQ2F8ZYxd++p2cFoXaUyYFoaGJGv7XdOamvDbGVXDrMflNo0/1ZB1nHTV
#33iZ4LG3HL9ubbHUzI1C5gQ4qf2B/rKzs013N1EEZD5CRWftAeP5ZcpMT1WANmOWNn2AlLtiTnnxsSQcZ6ex8RvLjH5jhhXCOluBZrGBnpqYlKBebQbVFExk
#tkgQLm5VpgfnaoaWD+sRMk9syfHaDYQ1HmaVYV5yY9/loYrGmNS1vF7tCHpm9qVBlvSmGmEQA+wgLFoS20emwhgTMeLYUxhE9JoxcHWFHLHpdfGUFEoUNEWc
#Se1KWarCBG/KEkHVY0u2ysBEP8xKAdOM8v26cK112LKuODilsxsfZbYRlUJl2Ftrtx8juBsMT+qvS83j3S79+E9ZYvzLf8IkNeidcMRv/1nAsvOdimUJIKqg
#WY4XCgYyx9XnNOYCDClW2am+aUgZ8gGd7wzPioaiQShtHYLiNCCsD916mPicNeEISohASYhGVAloc7po4tZ4diNuTc2HIaacIKYMES2OykHrgF8yvX/CUei+
#4kJ2GDaIecfpO991w3PPdd1oRttvUG1qr3qYbGBP8jRvhDGullVkaqVVTWz86TKpTD5lRM3TB+dHEfTqdGJvhIR73wTGzNgfinSb5txsBWu2Mm5AmlsejRT6
#LNIPR+CAqpR7/VmZzP4UQ4+kp1ijYbD2NyAsvoLZj5E3m6cbHC+b+LBbgfpmX2mm17Zl8mXsCUp8btBXJW/bww9q2jbyXfjdDSbakdPx8RecymE2UW0SedGx
#pUoVL3KL5U2rgOfjEbi1HYxqhoMSMzV+n+4wVWMFFdbDbnMajx9yzpWQM5cTPKxNx2dMWsMfpb5ezEckXDJ5yEfGZ4QqR7ciGbn9wzEv0tXzuGQeOFPEwq3B
#8dnm5aNjjieecv3IG9B4UeyPi/U4XtQXB422BdzVaBOH/wLzRsNVc3IM/1aTKadYP5DFQmRupaC9pD+hq4lqDgwuJoDoNr8tFYkMhmgsMya7nIRicwDw8i0L
#ckvnC3MK65JbszHGC5dkP8pF3zYYbBXWY9Eql9iaebaf/VIRVeWkaldJIZwix80yNCxYWHvz0ongZ0kKK48IHpv1cM8b3YB1rIUwXGgVeIVqjHhyDVeTOyu8
#0uXqmgDxdq7kXF0TNjdNaW9khErpcFIlzrIeNiIw9slRXnRVwiV+LPO0O9MrggX8oAPTeuYMUu5GBjtybxfkxwtkiO1gdXLvsnR5C58As0tHtHFHUmRpVdKn
#24WKAdRnOdBAKywQoMAWBppJVRIW+glIqWVFax3nUFlma+nNcJGmuQuTWpSpBQWQdiymwIB98HgG3Y6d4MegLblIE5JCmlScbdvAhZYBT9lnRrUYb11gOAkn
#4xS8ShwL6imoqzeJVFTnyeJaiyZqZeOPeRkto+XUH+kJVai9Qzyt7xA3HBonOn9GJ2AOjfqDLmgEeF6iBiIs13KYeM1E26ASrmvZWlhHp3fL23Gjb7Nkq3iw
#zMtpPI1jtx7iYOFbuCZHo2WDnApj9BpjdBVZ3HU1XmTcMqe4ySIsNoo6gsNZxd8KZdP+y/4PtWfJsKjpXUZ4QrD6jCo9Risac59fgd4br3NAIti9+rok2/Cw
#BMmwBkkBOzldAVpE2BpgWNZm+2IT/ek2AcC+QSGWd8yE19MAnowA4eXN52+pxHv4sE7iJfxFWIM/mHYQ+NM8f3eBCSMvqkyCF4QrfR+otG1fGIcsASbxIfmC
#biP/BvngdxfY+IURZ2k8ZiTp3UWRHZOL958vk1X+/nOGyf4tP48gO0EnzoXx5EDr8Md9d+FA2RxW2NivVsBs0HM+F3zMDbdsrx6d0cVbpTgQsY4KbrOC01Hc
#o+Jv5VHrZ+EOmEXZ/LuLSzcIvWSuH4xQLI6CYDXRDuItW1EEXQMG8LVt+K79petjAlL4jP8C25i48Hdif+s4IXtBG+jZ9vewib+y/7sLlrrxAvNQXuLyGGWe
#1gvLd7FjoYPAhg6gncDl/+DzBL/72IFHPRmOC936NjzxsCePd+m2dOlIXUY0VQDB92/efL5MH2ht0UqrB6q3UOR9XRC4veJ59dRVlhXm8M2N5CCOXlB9+n7x
#/o1hiKUwoRUCcP1kuS/gQQptpuof6uXbPXBMMe8RGls777+Lje0xRzWB+fk8g10/xLv3eBUWzyTeis0tmDc+hPPoUK3D+7/dJUaeHIFirfZpbsyM+A8gzSRG
#EcNIPv7R+N3++N1xnmBm6+IIXKNlsJ6N/DrZARI/wtHdLbMYmj5Qk/sNAu/7vz4+ZInxeWyss2T17gKzi+azt8Ca7gDxJ9Zisz8urbv9/g6/7LdvL6DH7A7h
#87+fb+Ld/YUBMhwe9v0h2SXZxfu2mp+/jd8bSWEsso9/TIzjDpDG/g9JYSE000i+YEakf/lP1Vx+DsjL+OKbr4wHz/iX/1yX/IrULKs0Bq7D+NP/8D8bX2Kb
#mbGENUwb73B1oBFe/S3MG6dP/A1u9P0K9w/9gcotTXcMBO6T5wuD2PD1fgMY+t3Fl5g+plrydJEaN1989UNsWRZALiYmhXkeNkkBCAROMbTL/H3LhjHy9cX7
#L/fbbbJbJNnnb9lrGBQlPXmjg8v4IEIlfGvAJKpQ6CE8FhB2rsHYcNbx34+HsPMGxjae2bfnHwN/h/8q+Dv/MyHwycKLk+VABO5M7C9DxJc2Jrc2nCnbPce1
#v/eaqDNX0bWCrQEhfwlIGlAy0gLWLFAC16OOWMt+S8syVp7UWJkgTgBEYFIwqQyHxR8ZcVKD8nHapcaeH1XKeILNVWf4wiDWJ10ATmPv3iKKoQCs1cHTDTSd
#ry8YTq4eFW0tIxpfsKZ/ls436b5Yf/wnwOsl+ma/+ahpnLsEyFeRFgijvwaknCBCKfF+WzeHzTG/4EtTogyx0XR7qBr9im60ATI87uqGjW8PeNXiua2D42Gz
#j5dqFyUNEndAXKl4fvH+uy+Mn331s7/66q+/+9XH//Fv/vYXraUPm5xtFX5ob7SI7y5aCCTM9rgDCpHlzZGJH4XWgNdlneIHCfpQyuGv6FO2x8VjM0cSNydF
#CR11QogwWSRzXI07wzztC+OwP2alPe7tIT7miWncwXoDamXv4ocYEb2xPwKVXADxzqp9+hIbmFXWPIyBCPWNf/l/jV/GQN8LqA7kFF0qgFmHlWhtUJ4Wahf5
#vOgjXySpzKaaOm0hnLo//cM/1wdPUwOEFV4DP0nl9FjgwIdFG/4ofHku5Oo1Y1R9UNrC5HOsc/wETy6afa4RdiuKvmoD8xxw7mLNwZyRfCz/QaHyfwOr/ZAc
#n8bFEV0Nkc3KjL8cTuBbOgeO9H7DEdGX6wRGIrIAIkE/3omM6PGuXjLiEyTklONSv5UQTbl4gFuM+yQ5sHbuYPIV9H0TZ/H24z/hNay28VJ5PdLRd4BfBdwm
#XO1q64JqsC7mFVInNDRv7ZSF0he6ZQ/qcwUbVCQKBkei9G25StqhwGY8LLunW28JMk8ExxWm1J6ERcGKLwoJ4QGg7hGiylLkT8xLss8SNCw2fDLvt/EyMTDf
#nkheqtFlUO9P//B/SqRn/lyBRrUUP/Bl+6Fasj/97//Xxfv4hyQr9mzl1fO/TXfpBSfIiKFc2w1riMTJdJ7gOQJSE08oGJljmPlu/yjhJOpm/v43wCgJ7g80
#UJral2uQhwBjgkRBcYQk4sB/yxuZcvRH1+hbmQYA/6IbINK5CP3bfZZUS/rFHxjW+Ph/SHS4lY/Auir11WPXhZa9WhSbi7Zp4vX/emAguMTFPs1aJ47FV5uk
#b+qcmGfJQyvXgu/Y1xVjojsaxBUq+YP4uZ0RwlIDmyzHuEueWhee3p3bYJbU7NZvPv7x8PGPBdFhbQ/MtNO+uYosd19iLkIHR2jWntl2hbqIZtGN4Qu6JVzq
#KhKQw+GUEr+yjYFvcVDKe4g3x4SLK8kBPliO2PxSbb6Xn5q3TvNhvzmWXHbbMKFMxygjuxWCMatOteK/xNjlyz/9/T/EBWrkE+Pmb0ZtowK+6ZioFIYlFhEo
#LHvQTXaqvcegGPXu4zfg4kCcX8cf/29k2EDoXpAiogxzfTS2H/95yz1jW6GEmh0EfatcXI1vxAsRN79sXYnkCXZ42QaGpfKs1D/EqFOo1otjOPyrVQ7U8PEB
#mav5e3WLaGHl2dyteaOLTU27f5MUgJgyZH4LY5EYH46pkR/TArlgWk4kAMCPZcBRfI83/PvW6sNTDTZJtoWmO4DlSbs60vQqeKw5MloqUUO5yrXLpNBFdt9E
#4AuUGazyJ6Pe8XoafwPLgYTl5uP/BCB3GDyZRveLsm2UEdLtHf8Gn2D4m+LdhTg2qeamrKkQcHgwLll1+AwfGzy+VBqR4pyXLvjpq3DTKo8vGhKoXH+uYSpW
#MgKF2Q1Eoczl/xVIdJV3oVF5yTuINC7YJzIjZUM/Gk2Gpqo2f2yivMo/gSy3oS1+059I4nJz19SUFoif1u57Qfz5/C18b+OcFpt9nigo5Dz00RhBPOd6EPax
#pRja33gx+igUEwF4BYiWFUu3B2Dy4sUiOaDi9A/5fmfGh8OGi2Bv8cGFJMm8b2kpfhAaSrfxXfL2J8NqHja9NWmvcJOU7ap2CzajU4NF28UsIs7I+D4G+pA1
#rRdA7aAJKG7tQFDrs1hIpdFMYQKR2e0wClzZLRouWDFS/1ejAnr05bffW6ilckfGl2vsCKkViL7rFKaQLlITlTULMhzghCjqKRo5voAu8ePY+I5I27/8Z+OG
#ZgzSLXrnJaPKVKO1TqToZ6hoLn693+JVnU0sSBzaBhrgwz5W8LPIH0yreOLV0Ys2zpK4MYSCzqk0hJ/Hq8L45ri7h4n9NUznaxBtYIbb5C8uHfv2i+fY+HV8
#H2+PIEmOjZ//IV7+gRB92YV6EjIiknreAWB7t0gAp36x26EqrFW2QK0Mq7EH8lDCl3pSRdDMyfP//Rs0ZhXGf/MOKr9f7hfA4u4KC2DpF5sEP/7s+avlTboc
#3fKC37w7vUFt8+y6Vr57hmNbgeG4hreZGhMr+N61Y8dwmLvRGD6tx8HDOPzV9CH8lS++GTs/XLx9f22+ITWz2ObUcKLvg43jjt0Hx0ONPPdmWQDVCuHMPQPW
#jADQ312ob/ExvQ6r19ADapjFDmC0wYPjf43jXjs+K8S0xEoxJ/je/3piTDfBODDgB6q4dlUF1SpChS0O3AjH9EMlSO8ilgiNqRHiDy/wJs4ABsRO+Zi+djwj
#3FBBgxclMikWdW0rMnwrjAPYAfxH/ifjCTy1/wrnaE02uM6WoykB/zawG1jOdTbwDZ6GuC9yWVa63CnapwxQhwFrPb0wYKXdC4OcQ2hnmIsGLD88zZ749tTr
#CetjPzjxxJiUQOAb9sPYoZWOHviqol+KuGY4QsOzHCO0YE0saAT2wse/lgvfI5yCg1MK4B/MBR6P4fE4GGMhqFBB2ny/kRYQ1hhaNhx/PYWFMiIY3hhWfzzl
#5Sk4mrTiLu7O2N+MPWP6V1OAefzwK5cP/JABay+WnxC02F876BWwgEXFZPMwtNDyDW8ML6awzlPLX8AeweDxnwuTcmGinjUZu4blo78f/PahluVhupyxFUIr
#+HE69uA5Fod3uCQ+3p/GDn742vFxwaqlthEKDOxnOoYPHtSH3fapGZ+dU9Ys/J1Ao/h5YjljfIer6PIVyY87mJ944Fx+4Fw6cLJlDnfuwaU/NvzFhuDfhrq0
#AMQn1gR3blI9oeV1AbDZX9rkqYVb6o+rGgAG5QM2KHQoFeDSI7j0Kric1HA5YWDpWAGOs6wAx/nMGqwLrHdmHwOq4CqTJl9ZaIcvtEMLPREXeus6APhj3E74
#VwIjKeQVfIYrNwUYgXOPh3Ezho+w8lN2hjYEVPg2wJfwAR/8QAc33DDg/Cs8A3Bc4CMePQANdzMGAMRXToivXITREmWgnr0TYlQUgZAQxA5ChsVh1yCwjDYW
#YjJEBgAeAJcuDSiC3h34X64C48bzYigP0QH2e1dshBCQpjbOPDAabQLojZvDwH8bzSgMOl9Ro5lg7PzKq5uAZ/66UZeK0e6IlVmL5ZzrJupRaBqCYf9qqj7F
#cXwvjgKXolnZaKyDwdZ2oxlCuR+NBWU7+P20OUfD+ZW4IZg5bK3bECjIQepJgumI6KkTfQ1/NgjFHBkzlZBYNDK8XwW8J2wTkZO3hQbs76XHY8Dw3hZGE629
#+rmB3MjYQ4YnfJCeG+6anznKGS30GBpRjKPjCwk1FjYgZCAZ+O9XXu7BILzxFOgDLJCLk0aqNuUte4jQ+Wlmamtp5qHhrYOH4GsfsCtUNryv4RcMLgCO62sH
#1itA/gFe+xsg6JyiZRLHgicbKkOn7gZoHx1aiRWZfs8qosgq0mSgNoAhjGiMv35QqTwyVyXnFT/LK+JvgOhHSPlLFEGmYQF/h4Qpa0TpC3xFyDGlBrX2VoCu
#mLpaYi6ARMNcgMAaPu6tA+xI7ONZoD2D58iMTQjLUaGxT8vsPQjF8PmvOAwwVbG0xg5wjiGyCQ/hGvfCVxYMma3ICmLkMFm3ACW0jrGD122qh+WqokFFj1QD
#wqmMMnYg3Y4CU6EArhiqbjsRuOw66YTAkAAzJsA9QAiQbmTQ8KX4YowvkMAjW9CYq1UzAPK7Mb7D4b2Ukkm6eHezM1ejd++vyUlMcgtz4YD4pdfP9Wc3q7+8
#FhN5Xc+u0TXsevTZNSrBsv19QraJqkD5dMzBy60eoJ/TIj6gHHfcLaXHf9ijqo09fw+dfvP73d/9u393jb0w/6Lreuzw593NSBDBPhyT7PlbupO2z77YbG6u
#f88VMX93PbJW++wX8WJ9k7x7f0qsFET57Fffff1X79LFTWJhuTwprHRh1l9Wo5dKiPvuy3cnVMYtZ7+/vozmwWIVXpvXl8Hcdebh9d+Z17+JD8Yqi3cf/zFO
#82sslSz8aDrFUtOlM/GXUOqb/QHfuO7SSxJ84yz9ZBnBm9/sF/f4ajX3oXF8NZ86/z9x77bjOJYkCL7XVygiI0UyRNEl+SUipKA7PG6ZUR23cvfM7ILCK4Mi
#KYkhilSQlFyekoB6WSwGC8xuo6tnp3Yb6NmHaXRWYxfzMDvz0DNYoOJPcj5g+hPWzM6FhxTlkZlV25vIcJGH537s2DGzYxe37cKnpzigJC42DDSp9+CQGq4/
#oubarcGD+2381hreOzry8duLuDkM6OuB4/n3W9Tk4f3WPnbmzB+NHB89j8J3Z98/2j+kmr17bmsI3x8jo4z6Nqxfg2HngPp1cLjfeqBdSij64rm9uiAKHilK
#bWsqNOB/NBq6hjyKxsaqIVehycFpxDRofDgaMW2a0kUNSGhNDkhjPIOm9FEjflgzL/zIQwlAyrsju5m5cWjrExMlJAA1K5bq2heP+5PLXjDUXSPxs3kS1bRm
#M2t3tYbbb102tB68deitfYk20LXUxirW64m5tNH8ONF5VeNaPKylxtLWl3f32w13bLljJ3kce/5pprcM4/P9o1av0MY4BSBtLBta7T6a4t3/3GCtsXRdXzYO
#DqmYwbPsH31uKEMajOyZfYwj02dW4Nm2rRGQaif8t4vJ5syiQcNYbgolsE/mdjw+WdsQTx3DkJtuOM3s1D4O0mfkf0lPjXo9PW6dvAQ8Zg3DGOYi3aPewoSd
#Z0kQjXT12+fwzbBmjncOgJDpHVNraUZXQzm5bMPzXWyDr09my+3tJnAI+VzIomtCOKQZvUzZzqmY4cwiIb2cLD+lenmvUtuO5mF4omnd1LDggENxlb7Xrz88
#vn25NzJd+1hfaXUYR92ZznoAeg/xOczw8RgfR/R4Gx8/zGN42fTdSwMQBsLIXzz9ta1p5rm9kurb3f6l6QIC8rurzcZEVGuvYM+gZEjbmJjFhhx0OUkPgd1s
#m1jaT6irJozVu7aHDuwTcwZQzlKRxOGJuLsy3xNviwsJJwAaGQwos5yGttYamZUZVha/iK/85DGgOl2iOYIawqrnVq54PgwiTwdAK8KYLBSkLyZYPyXrUHMC
#UJZaKYxMXwJ4Bp6+NKAcPmQ4Q2gB3ZT/1ZKP349CCvaLYk7v4/dDZ56pGe7u8ZaePH0Gkzb2kVKI/Bgwggsb9TO/DcgQ9r4L+1TiyMEI8iA5o5mo9Jx28crN
#BHAPIvaIZlDsCbZAd//ITK+6+62W+YtaDUMd8wLuOJiJxzhMu4cm+p9Bl2gHJsbhNFPfPfPRFpNlYq+xfHlBh4Z4exks5fMFugdgb9Bk4o9QKwpw7bMzgKuv
#zuHPF4/gz5On8OcRpj09B6wMhFL3fstEtTNeEwC0yxuP4tNQPKLBOYAg04TCpyFwAFNnqZnMZlMjQSiiTIAaOrHTLoOc8Bpq5GOez7yvkhCLw9OpaFRuqjdn
#T+0VrkR3BTj61cfvb16TKzxK+JkJR4k36Ny7dw+fhg/u7bfxHA3hZED/Gd4DB3YFzEvs+g6r/bX78XtHVN86Ghx5B7z6o/2jo2GbV9/29537Dp2D9x+0Bx18
#2j/w9uEo5tXz45eqR6uEIKT6z+mR1887xOoX/aT67w3bXhuPuc98B45SOqv56Si6P3jQ2XdZ/WhSllH1z+Lk4x8yXn2n4x4e+rz6FlTkP+DVt44O/P0BHdRH
#zv4BDWTgDztHsnp+lFP1yXwQpFT9GT6JuR8ewH+8dmYhxGvnZAPOvds56hyxzlN3Refv32vfa7PaMZJkTLW/wSdtI9f99MUL2Ivndr+vyQMX7z2eJfgItQIQ
#X5rqR2e+rH38V5mTpc2vIuwpgng5S+0svnYA22MWBv/FHNAC0HX+1BlFPtsaWzU8AmyS4jLintkq/TSd8bJPz7e/Ps+cMMCPzy+2K37sRI6Hy/H4dPvjL50Z
#Qr72yzfb3176S6RQ4OvLv9QuL8UUnj394pW9enYGkMEn7avzrlaYoi8ewbqqM/LkaVdTJuARFJbjfQql5fCeX3Q1MZrHp11NdP6Xb7oa7+vLv+xqomubLZyc
#ZkCkAU4uoeHhPCIPD7UUUKpurLLkehXGrhOeA8kN2dGt6PPMn+paSoqB3yItDc2ev35lpXTyBsNr/dwwNq6TITFurDbAIDkJXgYBRafDqWX04I8NFYk0PI6G
#PmbX9lh9q6mfjWMP4PL1+QWgenSKstXGxrBYI1h+tTHMg1bL2PzCSa8jtyYHgrcXyCsYK8T7MBw8ugtDGpWGNPGvNQOZEmUMUBYoyFtQls0JW+LEdq6cAMgm
#3nkqiaRmYsUTAxvSWYbEQmpGN/DsDKa6Oju8alnzjbONDZiYtVQBkiSMXujxUVZ3kGY376GkwYq9xO+Z4dk043BkAwGRGZvt2fBYjwsZb5xZ1nzF6L163cvp
#EePc9nrnFhFTNv9dr1ebHm+X0yGGSsLMo3QcDDN9hTJvRr/wI/KCqWRBGmwkzWTECxBryPvVauc4x+hGI7VfD94Dr2LhoTmK9NUGduMzM/+OPTBEF86taYzg
#9RzIZGOlvtltnL4pjvAl2ehq+izxh4Bfm4nvzV3fa7LMXfZqAOtKuX0Yt2zMQuKFEXqbX2yK2/Iv/Gsd1g7Ba9L7cSAzUedchdbKnTYp7yylA+QVW58K0PF2
#ku9esABI8yyiQl7BStgaldUgDcHsMbOtt6c9WQPZujszpH0fU/RnD1BFEU14QMpPY0RNZuc+bfcSXhNWhEW0VsIJ15mOkhlzRkiBjWRuR/5V7auzF7omFAqu
#rq64KaMzC1IyhLyGjkD1e4v9Pa2BdRi9ucXuJUT5c3ojZZNUX1mWNTNhpruwXAx8qnbm3DDfy02IWhu6hDTaqNk4ia9q2MDTJAFGS39v+fhQr/MHa+qnKSw/
#4K0EQyNk85Rq4LzSe4tciqzXfTieNvyAenT6xN77LB3HSZaevB2s3w7YMzzCUtJMsYf0BJZ9nQFxmAROuB5DV7KYlA3WQEZDb9fkEQJZnvUijEfrgT8GjqIG
#hHwtBcrZT9doQRGwwFrrIaCpmhMO5tP1LPZcgIk1bEqgyJP1BGYtnvjrEG1CTwDZ+8503Tl4u3cPevfWa9RO9DFqAp6sx/DHeDvYC3KK5cLeS0Ngebx1OvO9
#/tu0eXl3PsMX5S3xF34yWBPj4ALttvaca/p9O7jvwcgHAK0s8yCOoWfuOAaA9N6md/WTrhN56/o6MuAtBXCHpvL2geBPFb52au+9uYAiOvTa+NI4EY8v88dz
#42TP8pe+q6ckAhOM7fREb0z77cv1umXc3T9qtRr43mHvR+xtn966LUmwLYBzA+RzjDoe8bAWZJyVYwemdkIJXfprQV4/fu71ytsijsLrlyhl0QlazA+0PRAI
#6d0K/WgEEM+6iZAkgNnjsAv7SqPKAc+uZnQtn0YBzF9mclcaT/wMVjo1GYiaWTwLXJ6mmdRBbGjqzHSox7BQXKgDYWWoW2dKO+0l5PFYTvu4v0AxyILYc5EN
#VtK3WX3MiZiO88OXZ2FP8XTCViDZoCPv1kIIiAjv9mCyvv0WeG9Aa6+H+sLo8YW2can1hVUckuXNE4Jv6oLceQuLzwBiVH8UJ9fPaV3aLa1e1xWEz9g8+ESN
#r9d6emw/aNXr6UP7XqdlGPV6XhVuj0cJEDa4eQQihUpJYEsZaXotfzrwPc8ZhP4tXu/Nbd4ClADIGRB83hapwWHzt9REZ0TIxGBCAJjXvd98dsJRyZ29gFUC
#8ypPTKVVYmLzRmHjsuwfaBeINcDlyxcTacjIxrQfs5i8iluy6vJwYDQV39DdVuSHF5iF+rJRcSh1ge+BE3rpsj4KfIpOkmylWym8iLrNbGynFkX3ihBaeBdX
#WdfD/c+7ZTr8Ve2JYS66P2FXm0FXz8YW+gcBBLuGR88fOvMwM6x5EiKHV9r1QBzF4QJJPL7bM0tuBHjM12BiMwFTrUrAxAlbudpEtPUnl0AiWgs7f1ekdxtZ
#cyAo0BwD5QiFna5lhAKEHMxJl6EbzaSfx3KHdXF/scSncg90NRRtaOaH7sScOsszP4VZSbv3gXOYyOMW5rKA5mqSqC4MA5a237pUkSkWhnUw4B//KEFOrjpf
#FVyIHmOweupEb35xBcdmfGXFESdjnpO3w9M3z89INkjkGPLtXGoIaPDXF9YbetO1a5gUHoRRQ19nmsldw/A3VuprINO7JLVMmUv5bttM/BCOEpN7dFoR/ooj
#arNLbTLRJE5fj9WCu/lrutLTG3cA6cchkLEkjyVUiiScgZwXeyJhA1Z5jv6KHjOvdnhPA1nZdQwAdcvA18QHoky24U8uYr1liEbxB00AYuCgfAzQGBG/soEe
#4CfoQi4nlvW2TwCcNLpN1cy20aU3zI3OrKAk03P+GWWLdCvRuS+AF4F9MQKSkWXEXWrm1eUzQXQcm1y8mpgZ7gwpOTbHfFgbxD+wYQu8LBxEKykdJk4O18bg
#M4Q5aIZISRHOLJomyr/YopUTH8iyKRA13KlpkWZGnpKuOX/FBc7QKagHRsTfYanYk6BBAEMDAcSpmRJ6kBL4WrNGp/6d9cJfxHfW8XAYuEBW7o1MKsXRiBwz
#P36XCqk+snV9aam0Q71efGcvHB8EwFmxwwqphTkwETBuz//q7DmajcboA1oHIn4WBoBt9qAPs3iGrLrs8rfYtxocTeLsiezjW3u/oQupO0CrDn2SuK7JXx+0
#HyFUrDM/9NGFJFK8QTgFOhROx/XImcIMAg09GFyvJ1F8FfreyF+nsRv42bU4OSODdRYainZOJGt/D6dNIXvwaLZheraPaqwQ1ictVigHRZ8Y7nvYOYSTPQyg
#mZbZPlROwdXIxArNELZwV2mFnzGnc4CXF/BtDrzIer31Pf+Eay1a6JSAZZOfqcCdOo/t1faphR9wKzC0Tdn6QP8JEpq//yQSdYsYXRTOf1Gn7QFyP+Fgic9G
#dzXCyx+cGPyludE0GkVZGAVnWaRn5kJKowRJy3rHR9UTB+45LF+a+eJ3vYaWVhsgE+BPiH8iYgEQpUysqNHoASEkp3U/vxMf2ccTa9QfXdo6+0XuoQE4bGI5
#fTjUKZ09sS8kw7BwJMbECvvskXLJF56RnWOqcGhr1Hi9dB5Mgf9L9NUHc+rjjQRgShMQfGRGdru1UXb3zP7znfTqOX/QEgKkqc9GNoPNBHsUhbMCMG3+rafQ
#JsBB/AjyZGYAv2S6QIgzQRWHmpyhUSjDoc14CzODQxyoRqRa+dVzq8cNRIewksryrVi/R3BKueHc81N9ZBhpw97fGKIEvNFdLPozPzKHtPPF5l7ax1CaUmQF
#S9j7nNYRVUAjQxp/vc5+4dASswXVd5R8bAnrdQfgObEcvP+DR5YKPWva+yKzIHUTM+2mDepiAodODHj+bts6hFOOMipdvYWAgY5EdbpbhEPBMJDVSDJdd8wB
#HJoDK206VrpVciV2DvQFy0HHerAmSLHp7JeDrSDqKe2h3dnk6ChiqBJqo5Z7qvztw2tcBjNT4PXKpnXJkZkgJa/E7F5Zs3k61i3LEmugDPUmmrqwVHkDO1vI
#cLg57F1x/hmOroYAeuQehol2ohU0OFD/hp0nWgXWStne/fUFYC7crcrgF0JqJZmIAietCgmmfhHJ0e4nGvYceLc+zA7djZvwAPxDQleunMcUJ1HLuKSlAagw
#1IEWEUxXLlKOarowNRzdEFFVHiKjbXRxnkhSB3hi6hWf6PVaFdHOs1iwsXy8vZxGIkKugOQdTxxCfEKBtqXK+x+CSxwc2zC4tzxPrKwU5LNuEEHW40oE6pRB
#kcueksdOeh/O/CGsy1hHT7QotdV++Nu/B0DLa4dFrzRYZm7mPn6foiuD0CFzXF8zSFpfuAUokYRVsIM6C2QxrStgk9ly4IxxAjaRunj7BWLjmqc56B+TbKe4
#U6DbglfCdvl4mCW2j17lPn4PhwbRsT/89u8149MznwnChm0ldcp57adzV7iX4OUCeMqSeL74+L2mdkcM64Pdz/LF4AtBgMBW7EPvQwAYHpgO+gQkUM41QBld
#iyMNI/UEUabzvvG+/PPf/fU/1dhwYRe76EyvW1gxdBb0x39kaASW9Y//BMulrhavB9gOf55AWa3hS5kxHtkl1kB4KLpRjI48B/YdDgAzMNNJMLMZbgCYQKYU
#xsDGnSU4cD1oAELmk/y5fOxtg4TY/nZ/hTs3A4IH9+8C/i7MAP4Gmwo0kSNVppFyS2qkXObIE3YZ57yhn0B+I8ZSJjyHmQrMJoFlQawqDvjhoSA51cn4EDTa
#NB9IYqlgwhm4Hl1CMR0pJAarIULwkXiZe+uWsrcJx6poqfkhgCPMEEisp4BkxKdVxz4Zn6ulaOtF9fqtyFrU6+qX47Yhhh2VroKw7s2PhioJKsTResAA48QV
#UKrAnJzaslHfqdybE+p9Q9E0K1IRxcloA7FQGGgXSpNrdbZADGcG6q0WAwQE3QX6+sIDia03LAz6pilIB+CYDU7ekfl8mrj27TsrP3Ux0dhIK/p3XS33ZgOn
#6zvh0UZkzoxNbvsufKtF3LIYGGlZq4O1clvkr+MgQXyMhqYUni3U2PHm3z5W8hdM0t+JYeClaGEcKMzgepio4UWqWyQP+ck5q2FWZkWqMn0dGcP0q5mHDqsz
#Kj74caWlmIVNAsdv/5l7OtV6fL8ObLlWvYFSJ78v1NIrZwafFnHg1QYW89b4DQrLCrkJC/OsBb0FqBjWrEc/Zd2F3c2ZD/COsigoInyNVMSbJJ75SXata80m
#zS3BFfpfvLNCFGe8EyrYPfh8OpuF1zhzkR+mcfTEdxOfZnJ2eIHYhABWAWmO1FY3aE9biaI2ndjHScVSuPNEMyVmrtfxtr3fSHKF6ksggeR3WK6c6tj8IpfL
#xRH6zpvYQuB1i0mt+N5HdBY8bLHaS/JXuW3xm5nLAkcwgfREMkXdIGmdkBOiwI4LCrsVssMe9gxRUrlnGPXklbMoSOEQVNE+5NN5AfOwqgUuF/lzIoh99mfl
#ylCWBnMy68nP1bsCxaOsDXI9pVTjKyq1fwJxJchN3+K6/hdkRo/T/QjVioHWexyiPvEZwBEcNbBhXvrRHI4xPM+H+IPeTzv7Ld5PxOfl0ZJO6y3828tzVA8Y
#P4qafH9CNZFhu83lxwyQpDpCDh1P+H0c02fxjKJQGRkxGhgJrffardZdz8SlNDasNSbSrmxsWwRerM3oyffKzT5DkbBaoKF9ruEgUXeDbtKdUC/ulPUaN0jx
#rHSVwT7miwVYSTfM6mkwZ7Z34u55d2GwLD6jO7mANdFd0xOHHW53o6CfMZxmukv42qv85tE3vjbMbcpMSdk1ATMaM2dk6XRY0YlyUwfI68rOLjBnLsVOyLSb
#u7HZkO4Y21f8VFL3lSC3CMWtfuoWYeCMesJKLXiSqK+oKwzEK8EqHX0KTh3ME9i9bH8B6qUrnr0O22nwzm559joEuYqijmw1E30Oba46JamtUChzIwv9HL2f
#Vmp0Y6eOAb3J7CgtB4I6wHsQumKQX6QiFhDo2UZS2+gwaQDsOWrssMbHsEioL4Fyr3HR0ILZWYxtfUx2FjeYWYylAsQM6DGbdNgpwM6JpphC4JmqNfiXhrYr
#FA8KQkR18EmtDWvXZ0a3bIXxaXsL7gAag7U4g6FraN13ny6E9iF3VjBDOjft2NTuHzIDEv5NVz42DpkRCct00PncMN4pkDD2E2S++ayTxOUJHZkIsV+iOg3g
#hpE9fnh0oj1CFyi1CPh9rTt+2O5QynvIQ6/36bXmALv9D2lzGnhoqvMIXb8HiZZLemahrarmCd7rPpOrway+K/nqyMgPCbPl8pD0xWnelNx5ugvp5/sODGYB
#y7FBslcuuNbdMpL54ff/HnoIZLiWU8WCBhczS2Q40Or/5j8VPPm8E9onmippeldwQAsTW/SGNQGMcfv4/PWr12en3A3WuA3tjTbMbWXBxf/D2fGv5pqfZk3y
#egbHnXA8WztBJzAFD8losECjDTeqf613mxLjLqd9p2Kv2IgrhvFnYVqg9dWV27FcUQDN3FmhvpdFeiezELVO8JWmH1fhRKvB8Y3XID9tYbMB7rONsqw92Ll8
#92FtxRUP3K01Z4yKtBcr2bRsqtyozqLbO+CCgoBSkxy9MeJ0w8RCW+nAqmokT8VmqGhVc+j+BMeBbBU+K73aAX1IrpIh0S4yia3FLbYWxAjIpd0mEAe2JD/I
#1xWy8BaVAzw/MEaxjoZLkICXYIOc1Pc2hnrCACJ5E+o4WVyp1u7L03FmkyLuTGsgqrHwsDN28+8PHjwwTKWiTU+FQhJtz7ZPEnEGzGiw6GS9TGcKEcgsQf/A
#upZ7SorKXthrXTb8qF6P+CV0PhY+UpHeK87QjM2MOjVTJImX5rVJ1z+01W7iwzC7wopN7eOp1HMtKL7drGw7VZVtqU5IYpQPkg757dDSpP1O7G+z00F7vtky
#zwxkRZ73muX9koiMZudIZEbKjSnX8V7r/dAcXhoKlO3qLYNx4tNVUi6E98Ly5ZPQGyIjNi0oBw+4etZu9eEpbQT5HViVp6jhgpsHfYDB5sO2gBjnlHbFrmAr
#U69XfGO2x459G+q9fWla6BVYM4yfvc4bVeshZ6sQivDeUZGesyvJogEfiT65Cd+tHN0JFN7X/vt/+Z9qSAPRNpPMxaxgzPcdI/2+U0g/I0dxtA93kXXiiuGU
#3RzgxYFojevq8AxPPn7/Hj56TpQqOS7lnRaNlUGWICX72g//8/9ZexGQK1B2F0EjwPG/QsY7M9Ao54d/+x9qigtmkpMVXZKyYkRZn3o4PN4stUbD69MdyVaM
#BrxTMD+BUm7EJEUMYvbZNF7KaXsjCmOgnI/f02UL61wJlfS2ZfUBuTaTTut2nPtuujiLr1I9lQwMvAHGpnvnBC1Sh2jR+oHf5CA1jl/wviJ4KM63XtBoGNKy
#Ou0zCcMHkuq6eMre1phovB802pciYdjAXyzLIIG3wV7go8uelDo+MKlKIdmEmhK2SkNACNDZYrG3kbZes6dEy3sEL/V63h/IZUBHenlNOA/sJYEXnJG8buoc
#MqioVi+uh6qLbvhphGkFMVyS+sz5nJ4t1Xtjmn+xKvjJHNuY1m9dMj19eVkW2OMif7ZHO7JGZupEiKx/g89S8XYp4M4wne3CTGQs88rr5AxZvHrdIU5PGQ0n
#4NvyhgVFhf0MpYH0IxojXJOgXXXWVT+YTldP+k5wybV+SNFqr98zL/cM1JPkJlGFG12YD5HxbXLyNtpjtYf2cSib4715FMeojCszSJWaUNaQNvrNH3771z/8
#9neX8LyXa9rnZNvK6U6hM2bWnebj5dfnzRpsxy7kgP2RdUOmlkc0B2y9Ms0ByeSkUQoigKfEtIyJGwtpiJ9KaV44wjkax1cvY88JhbCSez0sNSbz06GkMwGG
#qDWOWPhgm93a+Yr2iTzMMCsCHMkJh0K8tNVdbqqimIfdKg/T2Br3kFB7rq/21np71WDqatuqdXyU8aQ8nfkuSGx1L5X7KM+P/Iqx6h636va2SOWVx8HBDWBX
#4miGcBFLm6QfQvR5cSFY07Iv+UW7KAuUeSUZSQqfJQS/mPs72bmEsEcCRNqbUJpr5HPARqmprKQP59b1bRZaAYOZ8Xg2tWlMZAvjKzV1Lya0tYAWCQxkBlVH
#nYK5Q9Yt2Eg+rtkMundWkoYMTIwPXGL7ImKBGm3J+xTCQhzTHcgnrtnoPhW1D26HznfX5Vu3zf9vd27FABSCTiRfz6JdGDq74DrRBJ98rKQJwcX/gZxkycGp
#SnceA1knM0B5gIITrZwR4/gUna3fPv7hb/9GloOWeNAqNgiNixgKTKhypglZZb453Qxv39xMSnQLsgFjpVxIz+wtzxOkaUVcOpchMBQzE4cQ3yfMkwa/3SZ/
#GoI05RfeqpuQApjOxkUxzSAY1WbuQo3kMXMHeTQZwpu06rMYVh2Ixz9V9CScypdC/gxuH795cfrrF8/PL1RxUVEMgaKicqmfJZGoCMBU9LvrUNCanTE6ZreZ
#lOwT0UFSOZGcZIfdmscf+ee/+91vf1RslZl744JARf/mvyigX2R88k2wFbtE2QsRBmWkzfCvPzkqT5Y7n89mcCZgwX/+u//1r9RtJGY5n1kKHwE4GpeMcDVd
#Y7KLJuWCnoniysSEch1ar29dhMpiacUFq3qTyu7biKKuum5TNI8KTewU16h1k9yD68XQRSmwwPz3U7IY4LGceQ3WADgm4cJoi3Fi6bZIqBICMWQk+sGxjDtV
#BF4//q6GuC15k8kCezfum/2+huBWY2GHmJNy8nWeM4aAT1jd7OZpFrJJxvs1YG8v0VrQdTK9tD1PqOZ//X/X3nC4Rk28NkbDwN3M2Vx38Qwmjd3yz4zLyy5q
#O8n6GArqI+f6N7Uzfwq1JL66VVSvO7JGVHGZIS3GqjM2OTi5ytLBPNJo3EEpUV1zj6+5VwGH0M1hkEx1Te4apqbG1pU01WonUH6lnApVog08I2B752LA4qHA
#Vl8yhPnxw6Smq+0DAj/gA1OXqijJTnlRloEZc9+uu9nOQmjWXCqDSYUiq08cV+SSiMcGo0eOr++soE/pozAmmEKv+eyoYM1zq0XpmoTOHQxzUEZDlJ1TTifp
#xA+JAzW6OXpiKq1F/KQ4PdlyAWdqb+IZpsYoTtO4zzfu7A3+Ci9v6FxFOHSTzt4ucwniiCjMFdcb/wliREXuiTOmQVJBe+mL52TzwO8E0NkgI3QaOH0j5nyQ
#EkoiyOCEqffrI6kfbY6MLsKOTpfOtD4A9lWCSeQtpGqhQj4B5C4MWgV7UYHIenQ3yarnwQ+RI3STOAwv4pndYqwnvw4QvcVX5posHfvhwkfRjskfTzO7ZQL+
#O8+/TIPlY+51zHvMHYdwb39PX509Pbf7P22J2VLuWmrpE4f7a7UdWGWHFJidS0XU5EgVvl5w3OoFzaYQNr23dyv/oWKj0es7/eDSdPrvLy/tPv6YmHApxDKO
#Kp53wpDPhUrExnP00LZtrywdgJHxtKpxys9AKMiFo7QJ0cmPy/Wnk4/fuz5Gfs6k5xFRRZVpNHcuxvEHKZy48TfAfNfrt6hc3FFamwToyRd3MFTOWn6jKEIj
#s4IBxktmfnhkbXJlVl5tvc4fLA40Ruld7lLAxLILXHgkZvDNhXCiQqxzqsNhP0TbYFU5d2lFx3anbM4RNR0rWq8HFgBNBs/4Y6hqu8ImA7H+klSCl5ZjBvA3
#MBfwd7Ex8kG9uRDkr32wvTwXeaCukAKwz1N+86p6iHlzsSkMLg49u+QBjw8qN+yJbTHiPpOfS3vnW/F6nV+FNWMa4HGnfffJ6a+V1YBGZM8PmbIsbND1Gv5Y
#EZx/+XcDN+4q6uYpZtbl+wurKUzeprc1CcAJoizECUKcgz/+ZwIV5iQHdsIgDNS5wOazDWmU5xKTcFKaDyTewokkWItwTX7ybl6LooeecKI6fZjFcUgIQ/h+
#KNAIoZO9ZBcdgr5i8AIrwxfCzIDIEWBpVO/yl8ESyGxoSC7BEVsCxJbrNf6lRVCyGIRIYRmUNGUdMLVq8qElJncBpkgOmOrns8yhBgtyQq/YVfIteMK3JhJw
#hRMmp20UszpYaED92gX5VYWJZIheQsk9blujR1zMU+SD8KC7swqQ1aWbfXGtPyJRxgmeo5G8oGcnbqScuFz/gdEr0Sfvu/+8eiSKdsGP9KRallVlwe2c23+X
#18cVEza33+HQ/79QTciW/6KqCRi0lSkmUASWSs2EfIHId3QJjpjQz1niQjVncp9Ie+Yb1mwkJHCRsbVoUdWasK7qq22PxGyCyScxf+aOh9nbxiDo3ALSTy1A
#xOf+T565dGwrBJlKj/RIsqWnY0U2xlEaeSDjL8UrIrz6tlW6HugFqIHzmEghAH2fjtkGT80Ud3hqIf1wgn+w8aGeGt13DwG3sOtCLmzCL3dW3EEJAmslbXOi
#1RKXSzELsioeeo3NnnBzsqkKv+ZguCYCA5KOpgFUdTokqSuPDVlSmNkZsBFmv4Nrkcq7bQ6aqg8aY6dMG92/lnuyS8rtopg7KA3aDX62+BoHWMCYss6ZgC7h
#fqIkcVbbX5b6k2W3izLwrRJZWhJmM3bzk8te3szjgSLDzhXAuODsl281J5j6YiQli5J8Sd+VxZXK6SDTOaD+GD09YtJqY5fEpngMVkyBomCXt3VnhRiu3Pad
#VRwN2PEKOXDrbd5VWD4yJhEPYO77uVf0CW3y1ecOd3NGkJEmguwW1JRCPEq27uFRC//jzGQuDtnmJafO9cBH1kJXb762suXuEvxhanMnsILM9dBptNxB3J9x
#bqPs9dsF/1uJL8zm3yTxNEh9C9EcFA+BZMT6aQfSpOl9ghAzQfUhTiQJqkjfbXpf7ccBw4vR+zROMzgB5iH6pK90G8DGgJrF3UR1FbDf2hjixIqTKd5N08AE
#a534BbkUd7dFptXzEEEGjnN0SSIuEJVjWLEt5/eWOZOeL7G4zCwCgWCGfd4BcTzkzSc+cl/kuxutmI0q+7zEd9I4Usz0arWd4IPe8vASugA/FUa+TEjygXGh
#xkoAPD/rFrZsQHhLYHSwkFmdAV6BiXeylFHFJCH8wMxYd26TKuCly0/qg/edcM3A9R0ATD6YYTANsi76m7CysR+htoIwEbZ1ZtRUtiUFdnXw7dBBur9lKDQo
#TrAjdycN0LbThbFKFxaK6WxHEU1XGFGS40466v8lXV+pUH4I02B+UDwL7LdUmP+RRp4MegTdwbWH5MhRVMXMf9L5AObeZtE50J6KXOeRVxhYOwwUej4foWR/
#PnrVaBSN7yDtQtgsfMCbxg+l2/neByGo+yCkc0yjwM1KGrC5tGdk79Lpi0eXbAPFIwNx/Rd2PJJasPGoB0l4S8LEZspeKSoUxIPdDUQD0cJAbGpgBRpxrmwL
#Weh7NDj3Q3KFgT4P+Kvnh37mUwxKEkHzZCgHaeYK/pHrW6U6fAe4iwcV+sOpH2pFSccE5xgqRXUM6sXEiCeWF6QIS54tmgu+8x/uS2MkVsRlJVzDLeh2KkVg
#W6cfvw/Z8R19/F5r6MpXyaaoE0puwspT+RnvoLglhldmIykwQXWRJV42YINork53YsM4cf3X0aAEu1sLOnCq9KbRmINrTju570J38spZqAeqk+yEBoafOEA4
#iRzPzI/4fUPDyQ0uuescJYVdnOUthbsBj64nREvhoNAUXVM0IDVvCpNMNYWY20IKw7aKjnK8s3E0WORtT2NGs/SnsayJPtu3KpN3L8qHdGd7H3hjH1IxToEj
#Uln7B6XrYVS1vmHEagmj7YV5dI13DvApn7JIqXBcqWg/HrAKx4Nck3I8UDIgA6IZZqZwiP2GK5tILzlFoSYGl72CwVdPNVmr11EGlhuU5dq93AGCsDnLhK2Z
#jzeXsG//0hRPvzZ2r4E7rhonUt1sIQQ6dSUFM7Ldsez7SMhIRzfdtmwUAK9qDohLAdeGdMCpzqATKlPIuGzBIfZ20Cec/6mkOnbdzmzPjlc5O7TINCtedX9d
#b3d/y7bR4oOplgqUOcsq5ywjTUFy9x6SpDPL52hU2jTqp3x5CgV6RX0drtemZCE7ifxKfqs/CevMraTsFEI1OIeNQUbowaVZtb/krSAnBwfVhuSBijFtBefx
#co4QzGlIAJV21o/YLD9p/+XkUq0m7pSpA44HQCKUGFzo5o8ww3ZJe6HZ7rTwmaswHGzXneA9NalyqMacu/UrKhQT3XgeAk2YCg14oXBQ1FVcOAkcf9kb2Ld0
#4wjPF0BitPDhL/xrVHxVRNedpT42UxPgMd2z261WL2Q/wrFXBBxi1BjvAbH6ebtjOnZ6V+oZhma7GRrmEDOFTeeulEU226bMNNEjo7mfvz9oYoqJXkNk8K7P
#tEZ/qLegKv0+/jngwnHgB9jlI66BvrzbOTxEn1085lT7aCv2lSK4UK4fMR7PdDZHEm6qiOhf2fsd09153+060cJBvVGXmQDbLjf9tV/x2VlCEhqDI9G1hBId
#TxWnf2MHUyAWYIROSKY/5pdKCjPw4dD/zd6Xx22rU6/Dw8O2dXBoLC0vca6eo84LdNpsmV/etdqdQ/MbfLh3CAkt85X5ihOkW7n5R8Ud45KiQ2AOYHsdXWSh
#jWg+sk+TxLm2hkk81Vfci0u7syHtFX111W2ZY/iXwj/0XMu486LJgpebLNgHBQ3ExPYAeezB2pkjfGy02cuAXjrsZbq0JfQk5sgcGOY0yq2ieFJo69NlYxoZ
#ex3TC+3psjmN5F1e+NBqr9fhsfVgf7324K1130Cf4UHEPINJWbDthXt6u0mVO4NU79wN0YkNWWaMZXXQI9tO0CpaHzUHxp4XGp8fSRMJ+jrCr4Nmgh8bHfYN
#UpLmiFIOemRSfdRqYMQ5MqNWunEFO6miF2ZsP+rLcbfbJm69dcu47MXWVcO+gp9xwx7fxYe0AXXgQ9iwQ3goXBemSWY/Eox1bB9D8eOWuAaeASNqH3+wrpoz
#6yoXfySZdLwGz2gscPWw3Sm7ZuYBAGyWxRy37VNrvHdqXZlpO1+yB538buLwvnlqpZgFnSE07sMwQyXr0YGStQNZQ5GVQRotTAfmst3o3KeJNNOOnbbNsGOH
#bQGLnJkiY3YYiLAqEPg8HtswdXswDabn5W3L+Y/HzXHbMKHyZiktvy72vGP7oFWv41za2EWrY6ygZ/G4Bx2qHvqhCQuFzYqh98LOjqG3IGsoskLGASCkySa/
#n1y57S4h7LaJg4feuh2W0IEJgdkwMOYUzwGdOAJketXt8xz3WibMnsk/37tvHhzIt/v3TQDRy03hWlPxgrOScVhyd3wiypkgHoQ8aL0mx9wrdu40Gr383FGO
#JYH7HWzhnFfKjmTm7RKLwMFtBfU6K6a0w4ksONUaDdaMGbAwBQwHAj0wBXQep+nrJBgFEZzsURxdT+N5yiwpp8DwowhF6s1BXbdsm9UlGkKREe9x8QjJZTXK
#gDa8z9DjXnlQsk0KHnJjo+oUKRNXXSHedGB7v9hshZtCJ3WvyHVRZeS/V09ffPvE7qN5IBx7WS36439o17o1F+0SgD135jUf9ww5i0bTPDwSca2YPQepOLLa
#Lc3UeDsOaj26Afwh93jZvBahLSCGIUTNj5qXxAGKuvE99RNsjO5OsYoX6DV7PsNcmAnH68y9ILFqL1Gly48cOKDzpjKoOB5AJQvfqj0Pa3jPUfOjYYCOOJAi
#/vhPGaOZgQ3ByGb5MA86ME6kntBpEY2Soql4ARBS7+fphzlU/fHfcYvlWpx4rIOPfeGa0E+c2gBpwY//MaMRh04CQx5+/APUEJHSjxPyQVEIxhg1PuAgqn38
#Hk01F06Ic8TDM2I043ga4Id8Qs9Qvy2EfsqZzeI5uoVIa4kT8EwXig2kw+tO4WvANFBDHAdGP2MyXjwJk4//kVwXQgcgM9bxfDrDUaRzUvbm3omg3Xbth9//
#e7TqXPhJyuw7t5Ybpoa8V3gIMziFOBbMUssXMx58/D7I+PxhIZzvIhhBri/mQP7WzuezBD0sWqi/hig/8sMXDrBhBYK15I5rVdIqQbhHtXSWTUNcVGRuJpwX
#QI5hAgiGNyIyiTYn+L2g+PbQ2j80pHvIv/qrmtagTdTfqSlHn8VdwqVR3qN4R0MeP3FhKzcpc2zx7ddPz+wjNiUYNDKdiJikW1664fOZ/0GfGZXxyGaV0afU
#6WPRKbk/eW4mKBC1CJS0qWj08dh3J/rUieZOWIjxdHPl4siY0zLy4nyK4WwRxsTkPQvB2YG9CJgDIC4tzl5ZelmsCni2sZ9wcyIsJ4pJ16U4te8J34uwUHwm
#tb05udDbc3GEmoL5b2gFbc7SNBhA/3VEZIH0IZqiFXZIOGSBwn2KJFY7Mcr9v/WewsWV23hvTdNRKeur+XQABN57C3aqcZxDTK7TeIvVUa8L4BGwLoFJ+M7l
#lJY9p6mQEbb0uWGN4zQrRqSjuqW6+UtlWmtekM7iiCagSxgEwURrUB8bWk0PADicMGReVbVG3ukGgMbb6BzqcNmncUN7G72NXsDi80KAZqbyRKidcLeEgFRr
#aD/sJ6jxPpsHKb4mPk68n1jAGOJgc3G1VCUvriGvDJGUGIue97/QT63qYi5vZJV7zb34+D0MFS9JR+wYZdx7JSDm/lB3ASJRAlxuQ1AirAZVCOEtP2dTxrRT
#cz+2+ZQlPhxEUydJfNaFKhe2H/8Vwn5FpzVyOVpyh4Nh2D7+A+kXFjFaMd850ScUBTVyaod4IpMdRUoHajyf4floQl+SjHYtBnbIfLM2cKIo+PgPSZXM483h
#+dMXtmaF8Sg2rSjoRnGmW7PQMK10DPyDaaEDoRpQu9ZsTD8O+/kwrg0gT8YyAb6azyAdDh1e6+PXb57a2mduBrU6C/OzDwMsY36WeuGIysEjFuIlZocvYyZ5
#mR1e2C34u32KQRpKbpJUT9FPuw+bMkeb6WynTAJVUGDx05mqgp9EVxomybssGyoVaG1iY+3rNfGekC6MtPW3acPYy51jXAlDAHJ0rtDalLL3G8h+Z4+ZsF8B
#TwXNFSIHFvt74S+zV7Hnky/0Ks/NV1efGuLVVWGIVxrrSzk8/JXxafcnZZOFJKwlGA1+cvewIqj8vbKfFHeMnSlaHPSAr2HjKU3EFeOmC5Es0lnRU+jhN4kz
#0/2w4NS+PINA3nzjhBNA7X5o4lw+I07eOv/y9TffXjz9ywvDjCBVupSgtbqCPvi6HtlXViSWAH2KoJWXhdm/Vi5xMcRYhGFEoVXMKWS6aA62nYriYoAzA4Wo
#0CzTr40IY7AEaVXCFFoLdXD7czZFOewrfTKDu/swIqPkVPXwDE5MJKYEA4qbq+AVXlJ8s0NNgVrMhzeoLpKoruJtere/GMIf+YZgy2QUDz2qljMeesETjrly
#cXQvyPk9xRGfDwCh+SLqOSBGFwaNwjemWlEe6Tkq5qjmEZFdHqbNhsnJpjhSznjsmMEwDypszzNC+q9ZTxN9muZ2PnjqcQc0U8WJ6VSI9nFNLq5nPnl4Fald
#+TlfVhlMq17PcuDJ7wY46kR1Ht50rbYqKBoAgiSHuqqHX7Hm5kHLYFtM6Ovn0FAy7cIIWGL8W4t+sysogmm55hSThwPrN0E23onX8hvNmOsqbYqr+dhJ8vAG
#t0qBZrckGWjrgBZ9hy6/z0eDArQ0kA6ZFEnupyLABp7NaiJvTYphlvYwkIqiHTRyC46VlDZPURX5vNtC7/nl0/Pz0y+e1p48Pa99/frF06/OzuEZOZRzqd9c
#KJkJK7qH/vT4h9/+rnYejCJg+bpkA/J1zC4ynjnIRk99utJgdMnDPSigeEXwisuGd3leVjIBy1GK9jpCwmYRI6GIJhZx4pPJhSYCeXgFi7PiFP/M0Lj7bfJm
#WgAA4SR6tW35oGAs5E/h36fgo8y0MpJCZOMExqQCngbRnwueoKZteFJt/g8zCSw//P4Ptaevai+ePr746uyphA9U5ObuII4L2rTV6zwouZ7NrAyZx95WRkYx
#lPI6lPdPWNMHfE0VeWhRCJej6gsFU5tn+YSKBz6lbOXNmf3m7Gn/AjXipv7leg1vcFrHkaDY3LYN5F3bdDv42zGv4OfKDCfwE0447uel6UBAIhpvLdv2BRTr
#QTH47fSu7D4UxnraQCFMbLe9EWWl6FaKVrE0e+RViBeshz9fYS38OZxgZf0+ulJ32xq2YbKXDrx02Es40aDb7PkKMl31W5f8rYNvbfG2j28d/pY4nmZeYOQF
#cnzHEt0YY4TBuOCXpwCCvaIkfFCyppSa8iTF2rU/wYi19vFZwS8xJKpatI92r57U5MLcj6Q612DUjFEBFRodULgfejN6hRykeS0y4ItQrzt/CaslD/dpEAWa
#eX6qpjnAtGhKbVHcvHIWvmbeurDwIQVy6CX8OzWKmRCRUCbCKMq34bKZxkPqz3BJ0U3xDWsp1TBKgNGmKuhpRzukyU256Kn0lRns4ld6UrUAFnb1wYzKJQup
#UOAsjJWzKGxuGNICTl/mBwTAmfxyrbVzKVcil17sPf4KNjyP79RzFtzjYu4RmO4LlBqZ62Lxjnw+Ksczl0MsDWsl/XrZMN4MZH4R2ZSBR6qW0LLy5YWyBFQY
#BkoQgPkEvQJuVoEDLtHsfcK3JXK/CkUTKq4gQjKCJNwn/T4oxN6+ERWmGdo/0eAPnPEwCTz8g7SiZVqhBlcOJYppDCeMn7Byr7lwOJNSZeDmgyy+9ilgUFf7
#1Ry4en++bGZz4YY3qZ0Uh8fmmeo7+/j9DK0kUTztiZuNvFuIqMkYO3MGsGVmM81MsycBbPBiyMwkvrL10PRM13TDFHjysjVKmjUx9PsdoFPTsnFNFnLTpJCs
#ku6svJN30izMk3ZeqjlFoTgZRLhFSwvRsWxkAyqCnkGHoAPUx3cPQ2fgh7KCK2ie3OPXUCGZ/Nq6k0G85OYyEzR6mWzgT34a9SeXJ1qNMqLNHRrNPQwYnbdH
#lZOVFJ8b0QUT0BAqLptzNkEyQk+h3l7uso73VjWgSRbMoUKy+JY6hX4QNndWc2lGow4kQXczpVGwtzm+zeENuoSP8IMvzpJenCW8MO9nt7F+xVJo1r2z0hdN
#yG/s6ZCRnvBadfP5bRjzJg8jH4pRx4WpT2lXSbc0Ual7aJXCTJr6CzO6JDCKZ0QmqB0qrQW6XIL1YHWLBbmzimBWWOGS6Q3LqKzRIIts3YHuurY2GmsVhqMI
#YcLFlpvhu0O9DRV7H9VtvTMoW66q1IwwjsFtZbONleupAbqh+dZMjcnzUEaIYnqUeasOCczas2SeBehS6BRFcChTTfzaAHiA2iAB8hy4AMOsvYTTD3YQ+vqq
#6RH6AYMdPUC5pckk5/5w6Gcp5MwFhzpg8RE0gNnNKiEi1vHx+yyms6kWz8WVGnT3SeBiLBMU8tIVWRKMkG0wLOploT9qk1Ahr4ME/SjRRWamNgOSIsG7N+wF
#3v8BeSTQe8E7A5ApdKibWmFa6AOjADSlaUoGVsHU8i788G//B0rmZ4K8kisMCi+pgABivHcDIRtOKqZAhv0h1zppDV31jT/+w9THuUFvqD7WkgU+XvUVUeMV
#M1vjLgdg3BjqVwfylRv39dGg97ICJqHknVVOslZ4K8/GZOtHvsoDsYsVv/34LSd2TzSA1MDN3fij3lLtQYv8/w+H+94DB34f3NtvH5mfdTru4aFvftY6Ghx5
#B+Zn9weH7vBI5MP4ADuCApB1cXvDfjsb492Gccj4Hm2qTKmFBxcT+hdqFRNfY/2H9Y29YBj4zLMRV+urwX4NFmz62Yr88R8Z2NX++E/lxXBnk/JpgBR9jqXc
#toIakTHI7QJFZ9qfqKFTrKGzXUPntrQYZIPNRmiPy7kLhLJqjUW8GxeIAvYNcGQkFdil3+jN+d27H2EeyKADn0Y0Rz5bJlCUvksTmsGBkgbMJ0c8d33DEotB
#SGswwq0XRx5unHmQESJC/5IMjdRmiBFQYQBxzusXT58Q3hiG8KfUMdEfttkj1OjjddL2ZHyB9opXynY+cgKacD+V70+cOSLn4evXzmhO0wGziDiMKzDECTY4
#cFKBaFkfESGRe2fo2QDvcuABRpOQEoJSOyfntS/477MApwoIPgw8mM651W9eb6Ew4ya0U0RL5NYElQfw0j+ZzwjbjD5+H1GjVg0Wfeaz2tIgPxFqicOwDCai
#zsB8we7DYCJHH/8Q+cVVGi5x6gJyWkbXwKJp3D7OstatoSlkEJE+BF0JZ3NE8mZt7IRx7cM8oDiaFE8T1iiAD2jWFbhzyrQIUtSDSKHvVu1JPMcKc7jB68M5
#J91pbYGEYO3SIjL+ScNiCoYdUSQqnKUkAegKqFNA7AB2mWPpVs2uAaWDkE6qMAg2LfPgwNRqwKoqtSALq71AcStepvoVCwvfNbNz0DL377d48fJRPRzKoxoX
#kLNp2gVNkhK3AqBn5EcJfUSFlRHqL8jZzIEQYW/szDN5yrvu3A/CApRwbk/Du4qECfXyup0a0nl4wEDyAKCDpjmeE+Am4vbcUieCsf2yz6gtEowiIjgQ5LCn
#NQGs5r55pBZl8gHtgjyusKXgmy6l2WvD7OEMlicf4euCeUjBBnmfqcgRmuwpWP2cGVWlpSlBCGCW9AjtUydFpsUdO/jDqyuj82RERysAmvR+BLVUGoET/DG/
#ReQAijsbQm0a4eGEZyEXMDiaLZ8vPMPLgIBadY7Cv5C/EyrKfZDRXMyc6xRFKuy0nwi6t8il+C53HMEJ223XDT+ekbm4iX/hAkTBxuw6hUv7AghquS9wuTHu
#GGBcCixWQ1TDLsSdEVtyjIKMMPK5CubhdRK45KOLK3ehFsAY9nyQip0yC/0g4rCpwEOoaIQRKOdAbWLryXU2nioHnp4KXYgXZ49fPH8EtOkFnGhQ0wvhSDjl
#EAbkL9ALJjr4gy0NjxY+UiYkhx0UiAOctszDWgo42k8yOAYkYKCmHqqozdjpwvtYPAJgx6IrMvRz/fH/iqg6WV4G7MVp+dUcNybsakbLYzACPwHKFsbIdQ8o
#4LGvVlCMiFxoOAVC080kWpFqajId9gkpCqTjOMkAt4dwasAP6fWhqREhuQUq3cUpuqSe0alNtwNz9h7GER65hWaj+DTMCOnT9NbSML7yvdpeDY1pkwE8pDN4
#n8+UHuBycIURVNULYcMG2BXADKQFwjAptEq0Cq9IT535EE/FbM7IIIYJ05xsIWzzBnYfmzHFMeBXJJaG7Xf65rnco1btZRxEfCGhkA2HLX//MI8zZwf2KRH2
#Z0+/eCUoe1fs9SJhn4xcJA23fBO4xhaFn4w4b8rRwiepZ+UCnYb/KkYC5BzglsgBYJCywAkF5QLTQNI5GhrDLRWsOwrsSHzAlPLs252D2zVVdnX7ImbRraN4
#qlC/6KnjQroqeldYlXGcxTTTSTwk3A8o2fGIkULyEHDJx+/N2giOI9IAQ1VMn3QgnYSOz+JSAINPawG/KHAk4NrygkquMqTMkrImU2dBbZO/ac3IZVCF3p47
#QHRhXxC7CQfrtGMmRDnBW5zQ5sIoFR+/H4XQHCG0eUQuuQM/ubHL/hJ7/HSJXtexHxuejp77Sd1UpFd07mVBpQ+QMte8ukFdDBAZV7rDyZFRhoTOFoYlUfQG
#3aAJ0Ekkh88oXaFUxkeI94I1PSvTR/lEpIgjUUwCiAUOUtihJg1vPvPYyrPesLUqKkupIz3dqcgIdBI6ivdgFd2sNs6yGUMoSDHz+ec49NvnQiHOGjiZ0Lgm
#ISkispu2AdPELEE+tdXd2/vht3+/V9XCbUR3YUhnsX2bpKpbO0RR8VT2CSJT1Ixj58fXgAUZ71s+bfFOJk639MwwH+nxEbOQ4qqFtWvyc03TrCc4Y3iAMWVu
#DixMZESYwQXWySth08eYBZHmr+P5xXzATntay4l/TZtO+sB2Q4xgUIBUWDHulT4ldDEk1K7IVZp00lPv4eiP+GV0yTUkHOZz1JRewhDTlPiVRYKgLCoHAGG6
#jNwfvgC3OBooeGGq9KbYzy8L+5m04rGPT4dDZJ2BRqiiMDkFEVb0lzfvhomsBZ9G45o3KrZ8JrYMbYupj9Ya81TQP1JHEDF5TCYacmwJ+g7B8hzDAySobVR4
#xpdXshQIWVWkoyDVKV78aoZ5baeD3HKYh5FAsrAYkA9ocLo/0E4JRQPcMb4d+ClI4xQ+piAliSyTiww0k9KRUO8NHQTElZPDBV+hmdFVRKWEDLpxZ8Vp1Cr5
#GHwQArJd5ycp+KmOeKVst6cO3L4WUWDZbKVV4bSDSMTuTovBu9Ot6N2UFZIr7qLYZYpyG6UnpBuWVMeHnWjwtRjHHm3/5fIybf/MoGnKeqXFJx/vIlZKysKD
#YHEjf1XDvNB1UYyVXwjh+tkZKU+hq+4+sYEqL5azXApnJXkoyTJdsqAwHOYqYqARUmYx0CSc+uFOpwoTbst/yw/Ldgx+bug9MctCexzdArNk7HJPEzyWdgKJ
#nKHqKt/pDkY7aUASIfWueBDePcpZjRW6ENkR51dfNOEru33BB2cp3skKjmIR81unBe7RZPGt1pjQSJOFkRTvexcNXRnrnB0v0CvkDu0F79+EBtnW1mv21JGG
#3F/uvNLvfbkNzABcUVaORs/gxOix33I8+i8rNxCviEU6FsJvLsDu3XSDm15lypYZFOPdq0EoFa8gY0UTRNjQ0TxwHskQt6FC1Z/bnZdUWnqFkni1U68vuNah
#IZTaepU5+FVEwULmERzMAP14Zcvlk5XXuPJm2NIKPcgFyZXGhOgIvl7PzfyluaIS5pl0BAsmdSVDOnWuUBRQr9+i4tIFmAxNzkidRU8m7IL9BYtxzSo+OyNn
#QhODB2xVnORL1xa/2HCkwZFW0X2S4lkHyspsQoaRl5NBqaR95E6sAggUzit+8yKekpF4ctzs0vwspUIc/WRbOmkV14QZd7AqSt7URcou4dcZGOz0K6TJK+YK
#TL/ZqgMWS2wzNbW3A9Qp57PlLt8rVQ1vN5qMcqcyaqoZ2Cpb7PnL1+ikSQb2XpEelsggPMYaeZLiI4LZquSfSPMa6ipsaT7IG/otfG/k3YRlVr1vIOsmtelD
#OgofhfFA7/8SOC4rJZ8LwfBaPzfJuKFjXJor5hmNxPsu0Yh7aCSmbdBUf5deoQMgFVrjxB/aX5294F+Z7AGNjQYhfvbiK2agq6XEizRTybmSHZoGeXi0j7IS
#H1aa+It4olTK2jPMDrpvFOYxOTNc85cixNi24w4KOneHWFglxkhvy3cIMusGqQndlI0YdUNy74jIdgBo1SIWqkKm05DWd7QrylmQlyEcVtqAeOT6MG9KzJRy
#UeQxqopK910Ed8KzF9OyKXhq417G6CCFcpWe6ofMx6447Ib2seJbbWgx72pdeiAXa0PuWc3o5V6KCr1G1sQoBELhbAqx+4p8w2P3XCSGrOZ2RJwUFj4A7SzO
#ASkBHceGx/z1q88d8YKDE88OoMTVRqxxRawUeQxwqFR5Nuw68p6bbW8yFCpFHacMRSMZrVxsobBZYlQCdYsIAqidMIr01cZ88vSZueLIposu4CFBIJ/LTTXe
#+RTs3jTwDbm6yQGtKm4wHicyii7vAJ4YqopXHohD8fHZqmqZww4/dvm+/knxG2WKjCVZiOhYsOTzbEKgFE1RL4Z2ZGerlztdN7Ixqp+1pOHVLXV9SV7D7mlJ
#DJxKDhN1B+Z+KG7JXLqdzlEmLbpq0nVuewCbLuw53+a/uBOpOzzIgKH6ghehgSnKOPOfzjakuCorBRPoXwqjjU9BWv6dUMEugNqxuGW/SUoJHjRmG9fn4SQV
#e8eltHd8xqVsQUSG+hQamBlf5yGnmCeUXNufRYxC1zvp0kyvzfTKTMc5ZfDTPQx1Do96276Fil5+lKbI4w+UwX+SCHCBWUBzIzz/NJIb772f+SPNtO4fqu6R
#ZHSqeRIawqO+DS+7nVPxWYU8J1KVoTYlnRac126eqMTCQnwERB2QWFqpeTXclhKBVMYbFBFThWuRgskrizfqK9oi0vpY9cb0p/gHyffyj/LpRIqo13YLFsb+
#slfp3mkF35lHpx5mQpdOGxFHV/qG+QaBqCeXR4Ey/ZvmFH0gpdcNPR2z56k5Nba9yMqFCCLHdX1mlq7x+F0llyQ3F+kV/Y3ImGsSb/5UjCniU8ptxXAorPGs
#5I+usHTmvJJsHBoVC7c1pfCddpoJD2yr7ZhgkZHNrS6zK3PdqyI058YNM0sjqAUh4NTinM7ZAcgox589oYUj6M8zdZ/GXeYnZncLtbU79z+J2j49/YTxoCr8
#t3XSCNr6Rgy4Y/l+NDX+85d55DvlcI0FOaex5fhP6j6llX5ChsvXEVVTsiMrxAQaYjw/prmk6v9yLnhpXu9SAUawuqi2S9tlymSSMVLJROkEtRC7wrSp8nMH
#P3d6qmD0Zus04i9yw24MRceYh1MghYMB+mvSZvEMTzTN1JizB40zZVyA46YpmnWiZsgw62qNJRoOwQE3g+drem42kza8uO2Ghs8dfO7cbFrmAxOLpwa2Mo6v
#3rAu6AI/f8usiT8ln1RMjr5k8kmcM1gULuwv8r3YmLTv+1JKImWRDao8lewUmUdNsfiEQACWdKOIRVwMZLQACgBtugyYSPbsuB18+Ww4HGqX2x4B2we9oNHI
#nejfbPBvOnaw1z64e2R17u83io50rEPTs/ePSqmHHbbvfRUEBggBP2FlvSW8UL1unOqOcdcTH67FhxQwm/yg6CQDFKT94PP9SwALQlaQoh+WOnnPoGIMe+3O
#oJUslbcBakvM4ee2ivdbreK1CXfRv1J8hVOwaLdCUk15xW2PW7jsccvicZG3IBynRCvjgQGAzyp19IZGzfY9hEgR9oBdygRxT73hY58EeOpM65RHIxH27RrQ
#KrWrAKb0yrjRnBblb7ERbFuJB8xwvqpyHdiOY8XBgR8xNtSPrCDNC0QjYwVJUuBamLhFgGQ+tDuPhPcAmRcZUWC44zjrqk6OTWAF/RRv57tW62hjfMLw6zM3
#q1HswKFqzz7mHPN4y8QuzV25Awla7u8s8Vl/RW+BEmUeC/jN6gTtZmBx+3AK88tNeNMq4xlVxiiSrxN8pwBFOyILaQ2tHC8I2q+IAVQVaCerTpYxXrkBMhr9
#A1LS71Fs0mLEG029Ys2Hj1FcbTZoqqLYy4R1UVV7jG5LpUUlI/Y7kJb3NxhJV/b3vuyvxnjULAjh9CgzqPMI03V2f0o5jBXZ2uLdJfxc08+UvU2vlRixM6Bq
#qADHqWwDyxuPGZDBSpObjezEmTMEDoi+LcrdwVThJ0nm7d1wAPk2q4jdhJa+7XS1bZJtMHMDlE4MebnEOoxeovEXqCI4rcUMle5a+dh8xe9pgreqO/xCm0s7
#v09osrjWxl7CqeLr/OOv4SMcRPhtLB0B77pPxeXR9WXTOjTutjto1PosWPqe3oHF9/wRI4OqSy6xpHXYvN5V8oZmERz0JbkilQXbBru73VkGu3pdXYYxjRQh
#ZFvEh6w3gRa7Gudw4zO2n4GIIUAl8QGZpZm0RXiGhgW6BCogdFboYTJY+NLTyicahuNsIQSMKsgKqMAqpCt9pOBDVGsgRn+0tEnjgk5M4E1G13anBYC/tEdL
#M7u2R9dmMo+EFaoSwyfzZ2xDSqQ+DjzPj4xVnp87ThotG7aeLZujJdBC7d7oGl+vm6Nr9sqXgqwXYN9ObY0eQyCy9gGXN0ZE+JjwQFSP2TKECxnp6JZV/tBq
#HdbreSI1gYkVfapeBBwVStXkMCd0ucACq8752EhwfFN5qODTELK05U7rwTzLndVjTW4DgZzn7brRvdggCIPsmrHemomVGLyq3uYXK0JrEz4FhVgE27UxVZtc
#Xp3lHmUnNw2egZ9ohIHbtV0d+KCnAs6NxubCN9LNXinKGzmFjXxt9HZa6I89uhLaim1D/UPp8PXxfdg2W6ugEKnTydfBd5JIXXyC01uoVP4i+E7bZjgOj1SG
#Y7dDsACIq/HY7myR4q11qzcoMw/ACiDdbh2Us1sPigg1Ba4BeYDxGPAdPKdYbDzeQ2QILILk4ZueHzrX3SZ8LVZYQtCpBoMuBTrfSQNSZByUKsyQMog8fQGZ
#y875FJuEkhwBJ3GYvuZ73BymF/gPowYox/YwJXWMohP9ASHEYSoUIsTdh+Ls7WcJwA9u8rFf4e++cwD/F8IqVfq8Z9lohxD6ToBIGcG/Afy7slu5k7mdnu25
#TFHxV4/u7U3m2N5kLu2Lzuurvk9sq33Y0MmDvYEe8HtJg/zk3530Rg3uJh+eBw3uJR+erxr2hHnESvbsq94I/wzwjzLobT/6zL3+li99Sq70p898gOZXUB6L
#VTKl8AtFn/iQsOUXn+fKfeOzTGX/+Dx120e+6iYwdTLbC0+q/fVjQAI3HxbkNa39I1IwY30fjBRHHwS6tjZO0b/HWG403Jo1rZG6hZTPa53O54YmqykhxyEa
#kO6oKe+P22i3zEOFEGI17x99zknRXFhf1dPP2m5n/6Cl9Xa0/9n+YH94z9GKnP8w/Yr8hHLPU7Q1s21HSj364Gx7TeqF1y9ih3xN5WGHxQ7vDStYeXc8EtKD
#YUF6MCwzlSxnyX07oRlzau8tgrd7ev83e5cN4+3enuUvfQrfStp+5jiwpyeaUFEPrOssmI4sN55CsT2tMe23LxvaHgA9sMwei3JnvZ+NtC7dVsiIUyTdThPX
#HA742XwL3m4SmX/iomi3K3kal6gZxQ7Fe6OHQCTW60MZLQdr0OGVLQwMDvFp4trwr6fg3Y3SaJUv+XKrUKOsmXThStXTBKttINnLb4ekh3n4RwlU0zgwySc/
#/IH2xsEJPHSpFDnL2nIHW2Uft+27Nbx+6U/t1cYE8AsiP2X+U8Pr597SbnbggUWwCa9fD4f0iwKmRORiCoHw8Gielhy+hNevkCJO7WM95a6n4xfxlXAJJJz9
#6Xv93zjN71rNBx//XfPj/3PZ2BuZ6LtUOqqWGyy8fgzcQsT3F+JKx9a5uzGlurfp3Sb8Ax4vcO/sBWbh48JfxFuJkFtn/vadcC0c7xtvB9ZdkTV3mk03jNhs
#tt1s/63+tv/ffvu/XPZ/89Z4e/nffvtXl5DGn8SwCgX++3/92/UlNoOt0MKr3xv6EM7st9bJesj++gjGKO56m+Z9Uwv0mz/89q9/+O3vLk8qx7Rm5pMnaw4d
#ayDcZzLUwBrd/sfrsbc+mOwYvbjVS4UvW7VNeN4TjP4016zjx/YLmwGEPu234BQ+Fa9OHuPj1ul6DX9yY7YX6Cn1Rf5+ahiGY2MFSp9qsB5TGXOEC4xqzRyE
#lCgejpl2ARj56hVjboTXb0hPJFtmqi/QOekfFQKdhBH6v+WhkDC7nI3k5G20ZxRi8EztMAKaAI+bvd/o+kn3bf+t1+jCP3juW91LeDJO3l4agHxhzay7xp09
#JguZVsbQwVMDpqBTnIK8c1mKnUO0zFpFEeXe276OzXTpL2+XnrHlvZHocX7sZGl///KEezjXWpbWoBQ4+XswI0wRcpV1eQb41r40kJTIE4DUagxhurG/G1oD
#/IeF1Tg4MytrfrAyqTmB3znkdE7gpcvkV1vuvsPrL/xMVxYKl3Zj5ygCyDwBYIzMEJBJ+K4/uZTon78rfhnngNuBWvau63XUw/ETJGafwAGCTRsn22k6zoss
#/0uuxzQv6C8UAwLMFef+8eSEfRJ+/mnQOYmixABix4MIDxvbxyXD0VhYjS6Zw71lQ7O1hh+5sed/dfYc3aXB6QX0/0LG66rDGT8AjGzLMz5MAC0MrMjP9pwZ
#nPHSOyLfCEIawzr9Sx1LNzSYjhOt8UFfMXuob0lHyWFaSewl5dGrYBFG9TqQVjBJvveCUJLhMpgaycgEbikUdFJqjwXrY02qjZiF9jdM0YvF2ApS+tUTw3Dt
#pBjXWu3L5md04UNXApqM3/DnaLoUAAqZgnly3IIu8X2EN4g8VhtS6DowaBwq1+uW0YQXI6ff9evtr0ZPFUfpLmLXPBOVxz/HB4dqZzaF6OcCd1LhwoB4pyGT
#IXYaxvRWTYzxrYCHz+HsRukEXnXRLc/CCXVOeBg9lQIpFcNodJ8sB1Ry4aM7MdudFvvO1HGVOlmSuALjJNJ6fYvQA/wi5751N+/aOYp4PE/QaTM2rRsNoqIa
#VudQ7KnAJkrrYeuk2e7So7grO7aBSuUNAnNqZceuEdjNdu5sHPjUhzyDjM4tCwAPa2UPbSjTaIgqgTekJpQOMzpPIdTfMI4jRNsyi/xqQ/dVgc974E/fP3wj
#OPP3KPZ5039/ucNS5j1a1Rm9HTlmDuR4GBS05N/0cewnQbd1KXTkDaVPuyWuv9Y5D8hiFrIyTM0aVoBpiN21Dpq6w5mli3jWEM/s817HoEthQ6s8czh/ttrm
#z8wJxp8KBPdW8jzNyC5jRcQ0rIcA8Z5Kc/cENV3J61HkiUL4kQlF6aJC9bouQZOR4kZhjbFeyN5TuT/qS48T7sI2aVfHiPbvCaagpyyH4pNYy6HoBceU4phW
#gsJzhoVdBxHnRD0p9FdlJthkvhB7bfUjJkd0/kVP8OHlvr5gx2RINpHvHs6YqWdAhp7o/SS0UnRxqomrQv82eQvEZDS3hl+jq/3w+z+gpf+sbAn6I4GV3wVs
#8eo0GInN+N0Ng2TVPkmoAW3fwM244dAM5qyEsaTfaoafUt+fXMS6FFu1BBPYb8yUgMtAoxEIGCaz9BRwsFGYM8fNnqVSpFwtt6DhOe6WjR+wzpAx3bLuq1pq
#Km7ut0jvQpG9vJ75kV5QYZW2aNyKiutl3n6BBu01T2PBjchbAPNqcluFIRLJsqDpuVynJ+StpTFRFF4piy2oQDlJ4DTZ9ZJmagTTkJfPFofuL79h1zSfVkay
#kCNA5zG6li6b2Jzx5TfWLE6zl36aotiE+qDaLIhu8YuPZ7D9UozgFRk7v+jqfl2pygdffmMzXQ8LhQpTv14vvFpX/gA1/guS6y8DDIWxUlCLQILKNs9xnxSF
#V0y2AALyRMYA6cfMOi6jVgSXx8ykZiW618uX4c+3CmIJZI1DOcW8zvxqyF8GN6zA5hesf9BMxfUca5RdzqHDe8aY+rSDMQQz9Kbb0up1QqBixLisN9zL5V0V
#93JC3HVr93BkE3x6+f3vMB1kkYK+2G5lS7cspFM5XuZTl9W0h3IA2M6bobumNCO3f5S58nJ6mLoljVDSr3auVUsyyscTb85KOTECTCnnCvqdvHIWDKdEZIOy
#Yblnib/4dO5mW+RnsboLhwGkD3iy6EgefNzlJCg7JnbF1S6G8aa437k1L4//zdQqGlyrYq9jkipFQ2hSAPW04XOFJwv1kYzubQ6Z7AySxjlVjDTdrhrF86mo
#b423enc9dhRt5KddJsHFssw+uPeLbWAB8ggNH6V7AIy89PzVm68u1hjx5/Ts6en6/CmGVeCRmGS9mTPCm1GjXs+Trmd098ut9Qs6cL7F6Dbtaeo6M18rbxnV
#anE77wfcOMaHC0Y+E5oslMiLfNDWa/nyKw0FaQAJWRISuQjPUz9zxLMTZuyRkVg+XmXi9Dxh8nzolWiycLTkrQ3V1p79qNYqm8H2T+RcdMWxrjaKWXCueWM1
#rbKirY25XUXe+1Dt/Ysf2fst8t7epviFRjujPLY+n0gvduR/lvyVdGUa+ZajNCM/HtVdanCGJE/YHiSn59TRmupoMT7finGltpJ4Yh12m9ZhTvELTlgYdYlO
#ag2dSh+3TrQGuk3hPG5BBalWIklKS4g+O6/OyIOrwRBj76acLwAF8YyAE5kJf/n2g/ns9ObMbSZpuUcROrRBT1Y8MuQ3RLmkRulOhBMCuiAWVKJy7Nk3qmUQ
#pTn2lB0/9sq0YjZQb+LShT0j5c3FqIaU06N4ad9u1Vq1dgf+v10bBmFo347iyEcP60k8QZ+NDJ8/Zj6DWWqTXeLfbluHMgmdKwPeQGVOwPeFZGRXRPqx1pih
#KiN04Vhh4V6e/uVzO13o2kPyhwXdgu5c01/e1v3bNa4ygI/JEls/ur13DPT52dPzysL7kEEUP7IO8grohVVxCFU8nAFLAifE7ZcHVqcGpb7eP21bBzX8R7NT
#O7SO4O3oywel9HYLHvcX+9ZB6cOD2j3r/rjJe6hcZsCJ65rj3PDm02F5cnUYt6dG5RlT4Bsu1vI2Kjs8neDKo4+6kvuhbBAxd/3ZYCqdPL/0o/ltJUJUwH0R
#Ba59exonPo8XJTwRbVeJdzqi2oGs9g16mvr4PRDF2a7a3bG/kL780ZwP9WVGSeD1JBPbTWJ0c66376PXb+Mn9WUo+3I+DxbOJ/pRrFldtMd8Qt2qCR2L1say
#Ne48aldraLB6Q2tnvDVUm/+Gnq8qGo5ka2cwx/MAl0lr0CaQ0NypHY3vEwDijqueshwMTsnNbpBgPbgdd5dZyjLPKA5rRcuwX+BfeGTdr8G/lw9gY8D7C0yH
#53KftC0lBBh7OrPH2zHB0hnL/LigMTU0emc8QZeGVybSqX4YsicR1MX8xuCoUmhQvTAfm2eETdOZAelqxZDSKxprBOgTMHvkA3D6+tgzi1+HQcIjr1Are3to
#FEs3puRxba/m8FlGt3ZePB+EftNFNzkY5JZH56bjhHVxB0uS045Et7FZhCOrRTRDWULDPptEG5u4p0zHtNL5qIKR9BIHDYjEDG037w1CInFk639ae+htmzf3
#zdZSRyU2ZasweSSrLDr9VFFnuavo8hNFhbMcKPxp/ljg+CKTTFyH9BaDnelqyDm3jOqR5DifvO5g/rZ2gqdeFzfqRoBa5CyCEQsCPMuRL/qvZegv32NXXuF2
#Dd5fT1Rz0IUNSX34xwXvzbYMA3Pr1gLouwURwRjmBMiI9Zq/1+vsV/HBsO0Oiem23EEUNygzoghQlB9rKdmmzRNqrAcPFlK6FILTRrcFPewo85YzTwwy3QJu
#VlcaGlY1RKMuWyDQyGHFSXaEDSzyxtZrmDTsg72ospXnxli9akVeu5V3Z1zqDndhID5PK4WvP565BlQz59wz8MyDGLbjtHEfvdv/8L/9vvYmd8vIxCxFm1T0
#b/jPf/e7v6oJx5hT5hgTfWiy/Ns+ZbDMD//jH2rC7SvJOYVTidr5LM6C4bUsHJGjnULZ//0/1d6oSqv6s3bbYAWqZF1U5m//pvareYDRILmj1Or8fL9eXjJw
#UO/jCBIkIFbcKKErSAUeexKWduUVINWTy1x9T1XeExuzc0gWm4a+rc4rHZDqT3z/OxhuA7iJSTCD7R04PGIOrpBRaTPsffeYhYp1CKTRW+V3z+2W6X13ard6
#Is+vCB+Ity9itkvYzR/kfHhQr0MmeUMNSY1GD1OYuxDstiqf977TkRYwyQVoaq82CluD3BV+bGjAxJVcTrH8QlINXWdO1Xx5w1R7k8ToM9YCCIxDjM0LeWAf
#sDzKPS8OmefV8T7YTPz3hoiNix0nfKEbebhcjmYGtvbtt953wGo2GjBTQKZ8qzWeAAlqRfGVjmplHJnvH6GdPbZDZudCn8GZBZZH60Rqi8DuwFi53kytVtKg
#WFmWxcZsxvMMzsuuhkoZM810nTBERNZ1B4rfJBnbcG4xdQDazCl5UZIBDhW12t0a2YCXglnGbVuy2BwGue2KUoMHvKDEmJBHIEvMTtLCwtVKFgO1BGdX5nMj
#zb47uOylbm6uDIDTbPYQwnSh41iD5st3MStsl3Drex1n+CmqQOoah39ALnC8zeLIQzf2eKKg834yeWYV5o3DiSkrQ4gCMLZIn9IoVs1TLX56A2sF6RiVgzWJ
#/mhJrRLBLWXgZnrYv1T3pBolYBe3qK954zCYF2PV9YahVkSOBHJwU+jQse+UqFSXD10442ETLAKUi/uUaDjN7Mg+5gawocX0p54BieYASAyT5rMzzVxFMQsq
#3dUAgGd48YFB4oLpfPoMY1vDlyfBKMjSbptBJhYmBQ+BQK4TnHbdYzqLTFeuZR7I7wgz0amqq/lnV6csKxNy1urCXjnhYD7taqf4o5lpgHFauto5/QLRNutq
#T9/A9oORB/jhMT2weDQymNyYFE35uTxmqunDMIa1Tff2jwAQhbMMphuQorp7a++oJdWwxieA/mpjdHLOVndqAB7w2C1sx9RayB5hLDytO+UPG+YsYhDEwEHM
#xgH6SM+Pgdqzsxp5kH76Kkf9UQzApU5zhIsVBt/BKfTq2RN1Fvtv5639VquJP0dDUh/drUL7Vrfunrw1eKYtzdptpVou4/nq3N7D+51snSD0ztnPGrXh4Qfv
#Rd01TnycBhhqaP128OSXbwfrWRJ7c5enDIB7gjRcNz9hFSRrbx6voa14DbhzdJVA6WRN67xG829WM9BHa36S7gW9srbFFcykHgLBQ96ulNNqnmuqaQ3M0NAs
#zDzzYdatOBntXRHKn41ncJzx0+Bcwc36iu2ZrkakvWayHcMQvWYyb21d7a5mjpCBcIDs73JdL82kzTxKE/bexb41qJskBk/gBJVBMmhiKUATTSeqE7BxAznF
#ZquGcwcMMNQXBtMAunCkmRjMrqv5S1Rqy9J1EA1jDVk3Sp4nIWyJZQCnVdzV2vgMax2QhQ5/5zVR2KTEZ+7sU/y2UXj691xBQy8qJRpcA9GMbAJVneZe8TqC
#Pu3soj9B/T1jkep1/mBRLoP5F2RKao6JWv8O47CaA/ZrFLVqURGZNVDQn814T2YsJilXbbD4/KzX8pGTQg/vt9BXVUl3Fm8rkLoDrKhHQsN0H9imLNcujqDL
#Uf6aGfBfvQ57hN345A0J/Il4hbtelxrGtBB5Vrbf0L8XJOJ96Ryd9OufguATYCsw+HdjRpMZeIaJ+TY9rkZb0ArcUlRCLiSIdblvciXUAV922lwIrmxz4ZxK
#e4hBrnm64YX5F7UsXqyzqByF3KWOIX5UeGDAg7n/E8ETrhSfNpKyF3o/M1zggudChq0le0Yc4ayKI5z9HI6wYjaRGTslNPXoGoW+euJcKZ2ObHZ4UjIBp6oQ
#yK9LZHgKdL38x3+EUyaCQ+SP/4QBeY2iz0KhZAoEO0c6ewxJAh3woRuZbHvDQW86NrCUKL7AMWPk5VyR3in41EN/YoAv5gsHaBoWGkHpQ0F1qqYMV3fQ+afD
#g69If325hzNOkGFkEF/QaWQTtXMGde5NVF10lFqQGIHkFCU5gsy2sFeA1MRMCKekPAy0ZqKBDKBUutg3sSLaKqNYXxgVZpGOMsesStiIgcdJtQWN2GYD7y0s
#IHzgBf5itIFvl7B/87dBMFJfp7CD4YzDa4CFNQQ2EGsZfAtP8B4NiMRhSXQYygUjgLXtheKZms4ZtpH5EqDbpgi9kq8WFhAd9mC9ZvxBVQWbgkFmH8g3E5qE
#AyG85IMXfBuwNShrCH1P75cmpKHtQUEAPAZ0nUOAuu0sNJRU5sJIv1XZoGkHI+/KfJ2NcSmnHNqx4R9wnk42T+kwnYd4+wUlTnT8QsdNDu+kwbcESgrgYsnO
#BtPp6kuLtVqviyc2ebhK+GAGlAe7DNifPzHHi3L1CqkGFCUY2BhGt3+pzmrq+5GMWyBHwqbDhp8dg8Ev5cGoutz6NVBwgFNS/1vUO2OEYhhjHDGkfZ3Eh35v
#5TAUpfKVCFSg85mpsL9qaGutsSTvuYn3LaoskLwdhsTdpgtcy1284ge8wJxIkpkp0cg5WWCf7IT8U1QNOxFhDfJhK2X5BrZ3Q3TRbrNcYoHsoi3RUPWe2IGa
#cMEQM9F6m4zM+LkIijExUBlV05Wzzyrv0t8/FWNhG0WExS5/HPaLBvvkSNThcM1QFnsmhMUzQMYJUGL22UXfUQHhEjrIuDEJ07SToEKxuRx1c/VEhudeVZbA
#gwzXcJTZ14nuFCAXnQuguY0jLQ4ggcIKQhL9ih6wYJY2kJL8ERtgT0yEnyOFkX08siThyvTsM2D/He7TFEuyp7xkfnRmCScP12v5+FAnnM0KIV9tkGEPVVqx
#LIg2KWsRJxoc8LNEoZlUm+tsLJdMoCL+ni+ZWHCq34Ye/lQ0KNaKgDDoZuONYfxLb0IkC/F9nnPGGHHCSTzAm1DDMfyhgTnb8XpGQS3xRJh1BpYYad3CAD0s
#lU5vHhjLkaHjtnxWYaHiuf3/tvdtvY0kWXrv/hWp2hoys5hikbpUV5FKCeoq9aK2u6oESd3ttiB0Jckklc1LUplJiSqKQD+tsTBg7+yO126jgbEB77hrFmsY
#Bjx+mAUMtP5J/QHPT/C5RERGJJOUeme8mIdtoEvMzLjHiXNOnIjznb23O+GwZ6GZR2U3U0BBlj+AGh9YsucPBv676we7bxthGw/A2irA2gIaltmiJdhY2Kqv
#v746v97DaEZCYwT9inLSB6dRZmUqKFdsqV7AtvPH/40qXXeYqpdosUAlhO7lyAoLwxeJORi0CuZgqkGSThckpWJoUioszpecLFJ+YGCn2lwxoxKjPdX41VTn
#V21HRWPiU26Znnl18ey2F6ezfef84f586Qxay2rPvVg6tcD/TMmNQfrMN2IiMQDVwxkw5mkxY16YzXnBdMZp8jHoDXyiRVsrfCXO//CnYG8wUHnwuKCtboEM
#/bgXjtYRvLG+NZ4WQsrtCopMlsDJ9eKOdf6OqFusc1s1IqNMCfv2toG+JFLHap94KbKBglofztK5VuNb7bwjOZ90u4OAUIUZRWOgzkrwG9vKEfoeHpbc6Mfz
#MnxlD1zNoGgix6hSETspHx5NbHrausuQ0CXESSaMqhQ/YocOfN3LXy3Blw92P/z5X1pHQQrbt+yahtgnE+N1Zu1UO5nGTBVj2CBNCwZuvIungmzhRu7SPsfD
#S7rowKFyGxYTNJdKLi4PZ7wr2ssv7zGod2JtXsiVcamY7nMZlDFR4WYzktUCZWo7UGHCDfyOZzTePzcpz4e1rWgUmweceu9thuWxTqjDjUk8sMuyWZDEmZcd
#qvnBrsxULhfybpPOJzBy+0cnL49PDkSS8/qu3l1YmrSbR4Ksm3lBHU64OuTGa+RUhWtOD8wMaSi+HPJvTufMiXkLJMK3zBHULnJJfvV9bhG/1d7s1vfKJArm
#epGLCIdvFU0JFlkqrRGhFtEXzpMJv0hRqMsVidNoazCJmocWAd1kJZgz3cZrYTkyg6XI17r88UAx4s/oktWHv/nNsntRYUtkSs6NTBTCcnD73k8jKuJ3v/zF
#t8vK6In7ZH43whEOk0+iwSC6klS+V/7w/V9jNMlkEuLw/t9/+DfWMUWTLGexArWRffxYOzEQQ9FC4FUx6Liz9zwg4ACDV3YcfC6bQV+tQQeXFq5ausMk4tSr
#UoEOFTJlduuWipaX7zHqskdvCIZGWUSfSgAfqDUXavbhDDMRMcBXvJiN8cEHZbmYeCnIEoukYAtEMabEchYYCQ4zsRG84AhpuQqmaVWfvFkHldI0Qrdh2FN9
#qJmqfYuiHD3Qm4VBFkD+i4BeD75uDfxR/4GFu9YHowh3gnhx7liG/daOcmzRiKph6P/kCJpx8Lo8d3Ye+3KK1T3nZfMmYiZop0ZkmsOLyWSZoxDFLE2r2iye
#V7z7SumNDZTSD2coOu3yx6oiDgkcRnNN0gqKFJHAx9F4wqHENfMmWjTQOLqHIksQSkNhLdVrrvbeWdVU1aSTfG3INXGkcJnFwDQwKf61qWhpbh85Lns8CNIC
#Qspq3q3XCkjKQmJqGYTFnWG6Eh0rfxFhLFcM1A0zSg/jwSRZIKqFYWNTD17nosPKbNT8gWdLSxBvTHWPf02jo/BVpNGhypv7II488eZl757lranycOeX+6DK
#01Ac8JjBBlXf7bupw0r/KqVQzmEqZizT70i5ExsI+/K0f7YHZTWwPDl/9Q0nm7qsot36xv1m7uGsz1IbCzfn7CSapBTul5QNu1zJiq+UnRUT2SjL1YUjYfsD
#F4ZvAPISI86yXdOp0KekR5+OR4gAxofTFKH64FCh2675A+WIv5b0st9KlDp3rg1ZqTG8wXCcXgvWwUQnmUZ1QXcWbbHJHMe0Itbm3XXLa01JOAzNlblCj8d6
#CnR4ojFdXzgXt+lAgOcu22nLeC/TueEft+Y09FAzzKcWwsxgoUn+Bp+xAYCyVMpulL96KJEPODJa87Da9Q45PpqK+Or3pbxXliJIgjAyM3G9hh+lfwzoA6OA
#VAJiJbAzv8zOUVhCzDiHh4GdLlWYNU42F+HL6F9qCP2iqKtoTxO1aJqHqgH2/A1St9GkHKJvEQZT9m//O1CMuNEsInNTOGXRIBXEUBhpCmI9s5l01V5GmMf+
#WLYzzAiLdjPLdh3o5+WdsrFSF2u66IPxJSpEzydd/Ajl2oH/XTJq7p0PbfpBr2xpwuQlyXt11wLeLgyeZ5KlfxxFeKDItkxouIK0QruAs7CsFsdlnNsptUJz
#o0SGFX2rZG6S+NQDtklWm05LH9ML4JRaBo5C0XPkNoqLRMQEAYqwfBPF1dhselb2DDyc+BxvjvDhhOIn2iZLmtKX7bKgcNnLAQZRitdhl9NGE3t1czxtdoH6
#15PwXSCsGCT/ieHltlL+IES1MGdgzEzcRWZG+dXRNGH5Ruy2Hs6QujTzjtjR4duiXRhHdM/vwmiJ7b1d2HABC1cbLrmpbvxx7aqy7UChmmfqdm+lTJUCg+Jh
#rhQdDNaly47m/QSDtEgnk14vSDjWT6es7vjKAMrCpzDAYJXiMF9ZryErxQdGlwoOQjbpnbjwz2uMRTbpvUyDIUbQw9/HsN9AGB/FXs/DTnA86dnODL7mDVHn
#FAevqfLpKM5+3Od8GCoS8xaFtIYWZTEF7BYhniwLa40IQVyTo8MlYBwdrCjEXhD7V12iV1nr6P4DvVPGNtU7jdtiWzXgGIOaYR+oWRM5vgOXSJAtvoBsERRJ
#qvIDfniQlfHABHQxbP3J0Cfzy1JTPyXILMW0kHQGMT6vkSFAsxmxPWUuYke0Fkz9GFYCS5U9w/bc03CPpVNWFZKiyIDPY7qIlCHIR5fm0E0im1DaAnxPTuep
#AEvx5Q2WbPKQlisVXFEXKiK3uCEh3rUGEzwgWnp/RCRb9M8htySBL4HSTb+/jOtIYhlceHrtGvwhOkXLk7oNWkXY1CLCk3vaSgUTiWEzcGfofDgXenDllRxx
#IQfDxEA7RryCXpdKBW2FbxeOXEz63R1jN8cksIbOR/rlqswhobl8KAtQDEy6yJBLmDIWsMtGihgkwlcOt4B8sF9gJYWO94IV2Py3Und+NmoqRjUvAjegAj8f
#36e49XpldHeBBxThqFTiPBTzu6BkuQwEv5uvwF1wMlJaPfzdqD1JtGi55kgW0kSGk7pqAWOt+P1O70N5za8gLgtKAr7ot2o4Kq0M+Inj9K4AibnT8fBPukBi
#avSKPPUDDOscW0GvB4o6+V0G1vbtf6B9yo9/Z/nvgjiNrB9/a9nRxEIYS+vTCBhK6BTA6PvvUNz6707QyyW9PtHjxOIL/a7hvUK/CXgmbdVQOcayEeHhxAct
#gN7QQ7etf/sXZRf//Ab+fPj+B3r4q+/53f/Cd3//l/Tw6/f86f/wp/9Gf37xt0XR3T6qcbAF7ebAXSHemkaktnZ3iqHadPzxYHga/iyQqL1nMrxbcTS33BEY
#R1m4vJKBF+r5cHEbT29qjgzuhik2qlv5JNUniyEdMECcbVZGkXg2arWswHhJomciUSfoLQSAWOzCQvW/X1i4J9L3JRM6rTtgBVr6DI1bPqpH5WZL15MOsrUi
#zD/WmtArXh0cPX9pvfjw7Xefn7z87OXxwZF1/Ob1m6N91C72/9XB0ckbqUeUV8dPbC30q5X1a2tL9EsKRtSw3wFLW+b4qBEvRrTo72w1+0C7eeciCSlrNouj
#WhD00P7o+j7oQ27/0ea2aKGuRjA/AC5Hf/O+TVnERrGK3SfbheEasRVmuE6Kz/gn3e5m52mdAzIGMPf4a2OjsxkE+Mt/ur3d/Qh/1WrBk4+erAjcuLHxkwM3
#bmwsD9y4Xcu9fVb7vQM3ki8Iek90cbE0363TXf7Gs80/SEjHthSWRmjHPEN5mg/tWJzg91vDz0RoR0niS8WfUlyFNi0yNP0CcZ6c+4jSxUEbfCNog5/f+sm0
#eWIGAQeFv1sgYxZ/dQxJCZ9fK9xXfO95m44wGj4XjhEfvv2V9btf/vxbZb6GdLvetjOjcppCYkpTI0oytDX6ieI9gwBvZ8Tovwp8R0jqNYqKkQXt+hTWh9Tw
#3PwvUiMLfhPEj6sDA634gKZ6HxYT8ZiQoqfcoRj/ZGyvBS25z2BJglZhdOt7/MK4Ytugd01oVB+SfHraD8/2+mGl3rD5uXa2V2/U5PD3cff9qdo3U1cWJuHX
#763nmRIkcaNo1BElkLQrL/+f9erNycHnR9aLA+vo4PmbV6/2X7/YP3n55vVxQVpl03ix/5X39MlWsK3uE/XJVZG8cYTPw8jRvM0sdj+TydGaLkIj00/+c3Mz
#8xuzuZviP138Z9SoKTe+TtD2rxHX3I6qdNHyEa3rcXRlA0OzM6ffdUjgpzc32RvHeWxv1h5Bqx3VBHlWj+1eW7PZvs+WfefU70PzNRfrEw94O0Unufddym5L
#3KL86VfKy+SOJZRhKwl7I38ytTrl2/dtWM94/oxWnEkcWLBbAAXasmEv5VryMx7lDW5/SOX7pB+OrdgfU8r1OihAlqYYt8ccr0OiCgq3Yk24Dcf7dup2nJl2
#4AFsiB1a+iYggzwocSPvsOqf9s9ubmz+4c2SRo3PMQSBYBmunzayeYJuw9x6NNN25FQ6TZxJL0vQPKyOKhVN9EKPR+kh6G0G9LJqRdgRwMvUnvQ07HCD6Bde
#yoZ1DNMILcHrrtXQvYR/L5HsXOC3KVAfrcAIa23iEX9itAZhiquXTlS99OAvP4bwGGIEl6YcubqmFfWVhxys/gRbQqX0pWjbRSUKnow7/9je6Vl19Kge1Dcr
#4gnbAqSOT9fGt2vxLfPlpbiP0szX93bVqVSKh1Rk6eAjHl2pIXMyu7jC0AKVzFJzslyQ9jBOnUkM/9I8BJ0GByoL4ph/zfMFElJcG4lJgtmP9YW63h7DhGMU
#npoJjdjehS9QocN/vDZjQcITXhHvqMAA46poSanEKXezUFQbwCU4w83Ns2fPQA/acrBnMotwkVcUBV/SfADnDn3RWp+DPfHaY6DxS0+spqZYXc3c6uI+yYrp
#CmIbGwat5kbT06PqUxC5TEbtKhEST9Rct0hAdaXSWhtPsEolfShhJHdxJEWhMKp6YcQIZHlZjCBrDNpHAsw2yZAsGlYrbA3CKD2//QH34BXJahLL7gTDcP0y
#DKzNmvWNA59ULoSxCRPJajLfXVLMEn2/PcwgL1x10popTZ2OR/6K7hWsZ0fzYEEuLV0U1/o3N2v21W4thxATeUNGnECf077BfyivewXUG3ZQzkTVq4p3RVGh
#OriIO17YaQ4FWkPE3v4IpNpBXAn2EZCLKgUNC9Qy5CObfGUeJJpAVEn0qL0402MsGqElsaxynoBm8+a4oPgF5ttGnmq3icXCXpbM6/i04z11ZFvqGOuRmmMf
#44UPUHuETXGx3UANlNJ04AXenaWOOHXEzlKSSxdnY0GqsnY5a5ezPnW7MAYGAggeUwxldufM8A1uVa/W/eqVU+CAKQ/emED6QPkjuTj5QRRPD7qOZtKOTFZb
#OFvHgjCMOb2RyeSBe947017lnmlQHRuGNzPHD9N7rDsAsTeVCtW0SJHS/X8waMiogyZizAhqBlUCNEaPfdQp7BhUSlBB6A3+Fn6DyqU5Syp+5T5ledDzWaaR
#dwP38HND4fdbaog8fw9N/Y1aU10jMIbQ8B2VszBXIBiDsHUc9sRxnrH05In743JFX2tx0JnAOAHljHHbUxmb6V00+0AWXQgbqp+ybEt+SO2IJwIpB/ja7XtQ
#/W9/oFtqCB6qgH4aVi/200mYulbNuphEqW99FU1OJq3AULjw4lWGbu7i45dANVI05Ai8NYHN6BGksWEptQNJ3LIQ0xFvUQE68mjhRxvul57ivEL+fJmdi+RL
#IcAtrK9UOjKEyhGK5+1HiJARbJZKoI6t20dVwhPZqW9A6irMGIaeoHmznYWSVe9lWImcM9vQn37pfYm0dpVzp+wkcn1p3qnQCanlPOVbETx+V4pjwmrmXIpV
#XDETukIWJMkx7Owhug9KmDmHWHIyr0l160I592txyahluYg8GjSPjIMzSBZda23Oi61OQCvTvWKTaqFf7AYopOzqS8dB2SFRhggPT47BHoj1KVfUL6k6GJ6r
#Kix2F1vwEkZWfjZalBCTdtv+qKOBUvGdIEqnjo4TOnnFXmI4GvXad7+Rxx1cD7mP+lRspt7pIWmxLpLXlAg3hG7SBgndhVFrnJ7Nm+1q0q54dlK9wriSXzqP
#7Pr6N49tWbXgChsOBq/FTIwclYj7WVR8Iop3287cHCqYEw8FESXLyyJWxq+h/vUp/ONAm4Lk3IM8kk7asJOk0eZugqJb9SXLNMK0ReM3XVAucnO+4FP99D6T
#bZIZing1mTmhL6l3s8YrJaXZPQdB1VFZsPecx4VfOZYrM5mV4hlT3tNZ9NPvB3yBtNtyR27Uz5Q3ETovQ/iYIsKHuH6BWRxSirWQb97IacWB35eBajzYlfOm
#3O3L6DqQA1sjnJRBIYz6KNIU3Ad9FI7KKlQd6PhZgDnE7cEOPH6MoFXtyfj2fezLUyKY6tsfBoEup/3hocdrIQNOksuHptkWiwgG6NAjiskzrLZMidQitSJ1
#MhC08xVsijhuvOZ0dqLWH5OjD+S4uO40JibdKLl6+sz0lsZo6MAAbcgGnRyNDQ69RSaWK3UJP8vBAWzr7Mye5hz4/QG2AsjQH7hff+03eBETY17B7rpRrn1L
#NFPt5jHV1s21mDTUfGwis6pTmH53dOXCJCF4wv7AhcoLIBTsU/0BaQb2OdobpA3zDU67g2UeYpGHuOB0YXgeDC6DxJM6IxBr3bFehVNENf8mItiN+uNNvI8E
#lYWDMIhda4NfjKLJZeBPTBo+AeVjWEWdDlk8TD+RFi5f/E0TjHRFYnMTltvuGvMIiQZgjAr05sQbXS0tjhYBFufrBRIbKixvGE6xp6KxG55kEthuWFfZC6xY
#5GQoxO6GctcebSjjKW6Z1RMUzlwAXglwRL6rcWeK7mKKbpZiLvUD/Cg52BNHzJyIkQlqcRm+lwUeQFmbwTIHR0wamF9j3BK6A6Z8w0Fw0HZg4ZY8nWR78g/f
#/srkIMce/MNMg+CmmHPYM1FtcSmwZo15F+3hAtTk9sS89kBGuL1VU6p6sYG9MK+1GCo6jpNwNIKmK2UCXY1lSjXl8oUaF7zDALkwjOziWLdqZZRqIoE2lJuO
#9ZrXRXr7Ho0fVqrbP+wdq76F/gSJow3sQISkRu1Ytz7Xtx4JW3M1jV4ev5GIgJo5znE7k3GxzBQ4GfsDGmI778yROQOzD0f2vAs69zD/cidr4YrWODkNRy9h
#JbiIArgqwheZVoFpE5LICqQRMuNNxoWwIvi+CFUka/pWNuuIICLW4+LEwyCUXbxTLEA4ErXkVkx72aWrhQ0oWSOVLcc6MWiDzVyOsXn3gGnnNw+qpd0VDYV8
#qqFUQ9bSk4KmdfWWbTuWctK4/c+IZA4r+TIOY61pCLCX00LqW0oNIWELWohLWAINVqBppWStxxLUQt0q6AImWNaH4vbJ3mBOrT9PHAsmBrfZP/6dxul+/G3G
#G1RgZ7XjmBJrK1j6QIUhnoZAD6fUn2wDJxIv3cKJHbQ3M83fowbsfl3Y6DbkZtcVRc1ztg651V0I28s2cjzpD0cg9hFMTbcNZGaQOKBJQzsA2UI0q4CI86Pd
#/L1uBfRJWam14DJJ0MZvpnF9TfSwVFImAjXF8HJNGRtmylhBXRIQHiYGm0TysKx8I1nTa58rHnHlyfKaOSsIOim1QWxfOYuI5BmKlR4HzSxgbp5lIDUew9yA
#Ni4HJWF4GygVL8cr8Dh8sGXM7nLmslRGDLWK/qKZL0cSu6PALvL+VNiCYogEvhOcZCAR90VKAL2aLl7Pl/l6ae0T3mP/BM0TrfpniJA/LEQIpwKpSoJ0jte3
#CnFDVuB/FNOJGPtyuakdBMXQwYjDEaQBsuII78khC25In2DNE2JMgDQK9dxxSZb2otvfponViqKERKwwg+ZsnJ13x+RUGNupO9LOhRZNd+rYWdnidYcy1J3s
#QvS+JaY00/gumFJf2boybihsZqdX1b57Vb06c3Tc0xA1UtQ/xHYad85Jw7h0VLGv+tIoJE1Ce9WPGqwK5+xLaF7KlJyPFJrdFDufHYvFKewAZ9I3UDtTn6OQ
#o1Zp3YI9fpEFkpBeRLuNMfOry81RsXKU0S+qF+7KC8Dw0MREYcmwmUtMVKCUnmk2KrYWue1Risdj2s242Ks1Y4S7zwxFO6NmXKk45t057L26aW2kzd+WnSLS
#IO56TmP2d5hm5iMxkrEwPeHYye2RMkIB5fd9OqSLxXQxG86w825ubOjIad+ngzuQsFkFOpCeSOPpiSt1zWwVOxqoKrwuOB1jX934JMKF5cGgzpbAierrD3ut
#/K+9TSkv4kIwV1HDVyecVWMf0agVgYgCHomXt89h8xQy1ItiGdqZCCQm2Dy6iQIPf+qR2zbBL7eDN6OWOCyBT8f9cJw9kbIEfEtYFeEz8ADNVs3v37z++E+9
#GZbYqLmHCFa0ueEe+fC3/sQ9itr9Rn17w739C7xWE0fwdtMtH5U+LjfqT7b1QAnI9KEx+tl1z8Pm4pjJ1nheT6pX8lVPC94SjrwB28T1DFpX4EtvzaNitXIY
#VXClykV3d2ENo5MrLmHs9WnvDM1uUg8XK3mzpi1laNGyZYyfTonZacoUNAavHOuDMOp6dx+osappyxmFZbAmprNUGnV3Nhe1z50tR24J9QDii/g/Uk95ESbr
#o2iSWJk9ww+HJvLUWGaCyscIlYKUCVQ5YcAAa1O/98ChSqzkw7ffBUDsQZwyEAcIRMTcjuANnQkOwyk5/OPvkbalRE8FqH8SI17H2JTp5+GYpLo+cjhlCqgw
#rwphjoczxBhB2tgrw0wwwArrNlFPqhY9UmmEZ6l4scJDbG5i+0hi82g1OjNF9M2VmiPSBXYHZ6cIoCDDpFEQNJoWIuLWr4nKc5uxf1yNS1y/NRZUtT5PwwHI
#QvThzFw3aYoTwumxJvKOARZCmP2JgMKqLupp0KDug2UYQfBx+mCXY7DlPV8L1bGf2GuBsyFHUJnbtpyVcIlYXkjZgHVm5wRAXkkwMOgLuPD90BR1h0jy5v/+
#ryX5/XECLS5fFHfOLmOcifmN+g/USKI7+c4mDGMnTBBbu0NjufsF3diM7wKUYmI5RHiIFKRolpzGVqRoi/mW1c2t5Pb9gGlmdPve+LaA8FVAeSaT3x+PB4Zb
#lAGCMVuEocCLklyhNMcAzRGSRab1MqSFryAtfB3SwkhHdOZohdI9d4wDbKgETakSkEVCmmrozp281KiQ1j98/ysy3oldSYKYF4i70IP1EgO7LjvyhkJm41Dg
#pppdhdSc4tvUn7z87MB6Ud4/OTl4fXJgVaznn718br04evPypPg+9SHrwp4WjnHTenJe34Q/9Q3x9+n501f1j6z61uVHg+31zer2O4zJKLWbCx1oGrUpigQt
#dKSLF7HfM33KLzBld+QoLZBaUKX9nnvhKf38rNkd2RdO84I/eXGTm3rRvDhie5Ste4LjHZzXGHk3VYYnLliewVyEO6CBKkf8U7Q2pvMzt7bohdv2+CN1x0+9
#ixBUXz7U8dMdvdhS6YIVa4507Kegrvgp+zdQRy+83Quy57Qxr1tz26DPXLCa3Va35z/8u79n3Pu0mhLyPQp73xpMgEAYRcxUgqi2fbw69wfsbNZeDo9X2ND/
#+D+s/W8iVC/Qikq4jCjg0MsiRXe9BZdunJbo6v9TQ8XA4vyIoVUl8R4Pv+SG7s8mwzF6mKt41eGZk8sV6oQF1EYOMpwFPSEuwpubNZVXKMmyUTPVqhBvzGKW
#nYvQuQjX1+dGsa+wUDRxu2lERePvHSo8jfgvvtn19AFbqI2G5nR65qlqqcg6rhvxIo128d1eGq3XG2kEAzV1zKY8Z95GQ4LzsbRLNJxzRQ2f5Obeugw7t+/R
#KVjyBpClCJGaVsNFwUpuvMtladkQ5BcgbT5892shPcpNY34EN9AjX1yEu15tjy9f+1NQRPRRXIfZqDuwGWuR337L7/SEN1PLcD0d7T57tld+9qxSboyaRcgU
#5ALtro2Urz+yPgdaJCGpTTrit5qL3kRwPwyR7k7GotXc1CQbcQFGz9CUZWn7xfiVBJylKQkXA6l6H5B3QpyY8lZPGlIDdDyKCwakwFmj0g0F74JAWoQGg3E1
#UwkfkWn6+Np3cjJexTW+CC5kKGOl8S/vwO23QgmWpYl6JmMJfaR+acBH6p0Be2S2SFZslKRsP9vifpKdun0nh+4LYwbjBSKthzqV9wBltDmAlXqFoeCEXEhB
#ldVGoBNlhljJR8c+4l6FPDQCXpmmIF0xAWnR8KeLg6/n9zP1kVFxfehBNM4D5ZDAQZSd/7mgJqpscRYK+ihIIV+Meva/X9hYMGCOUmvJHtUwUFUuxHbpKIQt
#LogUsfGhTRBwl2FE/pE7rXj3OcwQDH4UMlSYwlz78Od/hcJTbz1IUB2hUkSa48WuR9Vpyjc6FtxCKu/aXMgnvPojNhazukMhlRU06t4avW1EIwHtdjFeGt6T
#eUZTJkqCdD9N4xAGMkCDaOivA5fpYFAjcXjOZXPc0ItWOrqr5KWsKcuvgxDJ7nH50yVfxcEfJmkPYi0RCxNGomit8k0NdNdU0HcLcCFguZWFwT01HRVCrxKm
#GRyEWwQrcSqo9Uy5kbZIxGUwEkDJnleOh2UnE/IUulFI51DoD5kmguJ8DTUAR+oRjLsB2ngPdvKgta1jDG+yzBAJg2IfxZ0IySvzX7x45cf9xBMhbmmYCvCR
#otStRvhNu4MyLXDcjdDVFBM6q0YduVaC/lQ6Gsfdw35zE6aFIC3A6jOwCVbzjSlpcjCVk9gfJd0grgbdLvRtH30eg45XxqaXm2gMzqWDzC/g2S6jIH5MEeQU
#5VM1Cnpm6szmRuPINTmLSr56LPB8TvncUsGZ4lMAQsJTZkvAn1UDJ8gkLZXWVo1dqWSMF1IVdU/ti8LlQZsXuo1e8/j9q5088sAe0keD6GN+16jgacu9R+Tu
#geBosYb+et/Buc8ouDkmAFqpt2Icwgas5Ww3gSoxj3hTbVLVJJvKeVNxzbvJChIKt/vFUlesdabau1Y6p3Kkey6G7kZgmkKpqDu90S21VxjoO3Wn7rVLIQC9
#0zNNFR30vTD5rG8zGCkFBceUpySxT8sf/uY3LGCHFNFx5I8ELFa2vztzZVrYzOrCWEvI+/MspdxNAnNcspukvNp2V+Yd9PfKH777W0toH2T6HoR9NKMg0uN/
#UeWi77L4wPPCEvKzEK+DEpdTGniphGdo6hE9mPhmt4NXbrL3GRap6glCq2s90UOaIygk1QwEo80Bqo7ZSPzulz//rxbhBg+w8yKIioq4bgT5Qy1PZIT9MM3l
#mXbaOcygOQxCAyrDaVUMapitseFyRoOHcRwUfpd1JFpO60+doYDlwOhoapv11NUTycW3LjAvBGRFOy1WCyIKFUptlMoBcRA+lpM0q0O8FHCeuDGKUrua9J2y
#47aLUrT9uKMlEqMRy9EAphLrPIViaQn0uezsC9EeRYs4unxGh0jGcu4FyTFWuGYVELbBxSiQ87Mz3bm2jc6zsjHJmg6+P5OXsT1gmMd88+u0oqU+g7Yn56VS
#cq6CS6mfesLwTJ5+pCu4vc5CJJP9l+rXVzw9GghZ695z/IdRAFNPGmSaRldwMH96b1jH2yucW2RRgi0ppfHsrEG+MKL3LeAX9+u/9CZRzKX5e07EOkLxYTPu
#BhpZwJIr5hssoJh1KAE19HaHCo9mSX28f9Kq4+ktlbSJFhKu6J2mEnDlclD+8c1kptvMA72Bxj70YxTeOeQ2mMp+l/Y2yaQ1RBKFrixVhfq4v4QhzcNAog+v
#M8Ml/2lwjXcrWhFwHwoEDxniAAg4D/uNSz8adcN4aJefn/sUkDn1Qdbfvrf2D19ae6ghyRLRHxevSaOox6tYkd9RpS+nxGwTJhSAovU3GPHyGzgLUmigFp8/
#knpRKxjkUXB1jHR0/0jDbtgWLk3GFr/MRfiXUKq+n8xaiPweeB2wyvSEG7pMapH6ooRSvebG1ZgE0cZWzXGlQKs8dXGB/6fvLAq+ffsDXirLZO6xuLRqg7BF
#Af2Ln1tyKobZVHB6bR6p1Zznw7/+tYWnwDFqBbpKYB2PcSCuVeZROBxrec8c/doHkwuySh/PxLJ2yUsNnx58RRjE0ICJaWfIYa0STvF4MaSU+JxtcwsL05MW
#lJTHdeWLR7jjDORtuaZ4VN63w/4X4Tu1gO4FfChADSlscHkBJCvDSxMJ3I0NAxcuWQ5c1o7DMZJhUkUjtYqDfXV1Vb2G8ictIL9o+DjsArEEX/vjsJyxIjwO
#N/C7EgnqfxkNFCqtdhMaXjfVV9ak4NshbMECxFUqr6/DXsxMXyn/rKzrDFmkaRhoLelk3NmfpFGpZL77PB7kwe3g7fPzAEiOrTnudk1gy4U4WDbbNTSWeBmO
#oKEYsjnAEOJhtwDp8nJ/hJ4pqLJd0g4oj+hDheDJQqoi/iDjvBz4LSHrB5JcENEGlPJq6MwGYpAyXLaXGETLKxNAfOXPjt+8hhRoJYB1RUcLGF2jOVigXx8D
#R1CQg6VFmtkUXVNOzQ54eUx4vIQvSr3OQX+McpiBRZINOQK0Ga0Ba3cTv5ZxFK0jdCRlpHHmO2AONYQACWxhyhJv/ElCUCu2bL9+EPHF0ZsTD+HZ3C+OD557
#T93Up6ORy5QmBdLxtOIr8rAAkULAlYF9OkvJdBPFw0Y5jlJ8V+sECMDvFnzafCI+nrkzGVi1gdWjFwY/Jo2XIPpGYXoNYsVoPTaEbtdNUkr5ppUE8SWIM5oK
#kBn8bBvj7s58aU9NOKStev6EfGQap2Ua4bLwyfpJNeTm6idXRhhYU6/mtq89Rn2CP2lE/9bgH6S9jjhMv/IT8YvGQ75OgqB/guk5elRNu6Q76qH8JEkIYnW0
#kdmJ1tvXmfq43p46j2D6H1PKw5dZCQhvpCCn5VVM4HXXDGkfxHv8B0XxCzGdtnNzU2vUhJXuaw1Xgy5pAEkV6CPjiLiKAREt0J3FkULNXF6xhwUt0wBgSPOY
#nE0Y4bxRiC/IUsBcKAwZMDfjuT/GGz9QuWjXy46T9Ye9K5m7kSTTJqmpT02TJrJJswpzYcsQLVghTqYxktiXQ/p1TCsFzQ/1JhABpdLG+bnQgUJk//o4K/rA
#XDVupSCKtLa4kpgAV04HWWmN6WBmY8AnqDDQ3EOk6I7nr2Ovyb9uFyjL6ax7sPTpeWedXlToBY+NiPJLLWxn3fNs264svKWryJ3HkPsRMg7nZ/hvJfspxjhK
#K16H5AlNT6nEy6CV2PDJ2d12eNakKsK9o3c3N2s05gW9fOF1CEoe074wvsMbGH/gxkwAzkwQApWPEy4mkF5/AUI8snWSMmZLYYYpHTatVaDV3Gfg0C6osS8Q
#S5jrfiispsbhNaL2c3mkriGXUIoIv3/8AgGStY/L9BBbT++wHqK7XHuQGLm8P2pr2HSjdeJMu/UnNdisEJMa6SNBryJRtoyxYY7IXEetHnW85ZSo6xpyPQu3
#lJ+wptEsxsTCBDBb2lzeSfKkO3Jq4c+ymc0A3GUINdEKVLIfsiKQ7QDEemAFg9bqnUt1grb7UcdprkzVxikaiJRLi1xuKSD8+kKU9oU+zHnyVCfmDv6Lu1Pc
#qosL4Li3gbc7j1n73oVfKLPx73k6HOz+i/8H4zWHOl5VAwA=
