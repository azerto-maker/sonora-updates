@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); $m='#PS'+'BEGIN'; $c=$t.Substring($t.IndexOf($m)+$m.Length); & ([scriptblock]::Create($c)) $f '%~1'"
exit /b
::SONORA_VERSION=3
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
$FlagsBrowser = '--no-first-run --no-default-browser-check --disable-extensions --disable-sync --disable-background-networking --disable-component-update --disable-default-apps --disable-breakpad --disable-background-mode --disable-site-isolation-trials --disable-features=Translate,MediaRouter,OptimizationHints,OptimizationGuideModelDownloading,AutofillServerCommunication,IsolateOrigins,site-per-process --renderer-process-limit=2 --enable-low-end-device-mode "--js-flags=--max-old-space-size=384 --optimize-for-size" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --window-size=1360,860'
$FlagsWv2     = '--disable-features=Translate,OptimizationHints,msSmartScreenProtection,IsolateOrigins,site-per-process --disable-site-isolation-trials --renderer-process-limit=2 --enable-low-end-device-mode --js-flags="--max-old-space-size=384 --optimize-for-size" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --disable-background-networking --disable-component-update --disable-sync --disable-breakpad'

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
    return $false
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
    const string DefaultFlags = "--disable-features=Translate,OptimizationHints,msSmartScreenProtection,IsolateOrigins,site-per-process --disable-site-isolation-trials --renderer-process-limit=2 --enable-low-end-device-mode --js-flags=\"--max-old-space-size=384 --optimize-for-size\" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --disable-background-networking --disable-component-update --disable-sync --disable-breakpad";
#else
    const string DefaultFlags = "--no-first-run --no-default-browser-check --disable-extensions --disable-sync --disable-background-networking --disable-component-update --disable-default-apps --disable-breakpad --disable-background-mode --disable-site-isolation-trials --disable-features=Translate,MediaRouter,OptimizationHints,OptimizationGuideModelDownloading,AutofillServerCommunication,IsolateOrigins,site-per-process --renderer-process-limit=2 --enable-low-end-device-mode \"--js-flags=--max-old-space-size=384 --optimize-for-size\" --disk-cache-size=33554432 --autoplay-policy=no-user-gesture-required --window-size=1360,860";
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
    bool dwmRound, full, docked, dockedMax, pendingUndock;
    int lastPref = -1;
    Rectangle restoreRect, preFull;

    public MainForm()
    {
        Text = "Sonora";
        BackColor = Color.FromArgb(5, 4, 10);
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(900, 600);
        Rectangle wa = Screen.PrimaryScreen.WorkingArea;
        ClientSize = new Size(Math.Min(1360, wa.Width - 40), Math.Min(860, wa.Height - 40));
        Padding = new Padding(Edge);
        try { this.Icon = System.Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }

        wv = new WebView2();
        wv.Dock = DockStyle.Fill;
        wv.DefaultBackgroundColor = Color.FromArgb(5, 4, 10);
        Controls.Add(wv);

        dragTimer = new System.Windows.Forms.Timer();
        dragTimer.Interval = 8;
        dragTimer.Tick += DragTick;

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
            cp.Style |= 0x20000; // WS_MINIMIZEBOX : minimise depuis la barre des taches
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
            try { DwmExtendFrameIntoClientArea(Handle, ref mg); } catch { }
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

    // ---------- agrandir / snap (sans WS_MAXIMIZE) ----------
    void DockTo(Rectangle r, bool max)
    {
        if (!docked) restoreRect = Bounds;
        docked = true;
        dockedMax = max;
        Bounds = r;
        ApplyShape();
        Notify(max ? "max:1" : "max:0");
    }

    void Undock()
    {
        if (!docked) return;
        docked = false;
        dockedMax = false;
        Bounds = restoreRect;
        ApplyShape();
        Notify("max:0");
    }

    void ToggleMax()
    {
        if (full) return;
        if (dockedMax) Undock();
        else DockTo(Screen.FromControl(this).WorkingArea, true);
    }

    void SetFull(bool f)
    {
        if (f && !full)
        {
            preFull = Bounds;
            full = true;
            ApplyShape();
            Bounds = Screen.FromControl(this).Bounds;
            TopMost = true;
        }
        else if (!f && full)
        {
            full = false;
            TopMost = false;
            ApplyShape();
            Bounds = preFull;
        }
        else return;
        Notify(full ? "fs:1" : "fs:0");
        FixLayout();
        System.Windows.Forms.Timer t2 = new System.Windows.Forms.Timer();
        t2.Interval = 180;
        t2.Tick += delegate { t2.Stop(); t2.Dispose(); FixLayout(); };
        t2.Start();
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
            if (wv.CoreWebView2 != null) wv.CoreWebView2.NotifyParentWindowPositionChanged();
        }
        catch { }
    }

    // ---------- deplacement + magnetisme ----------
    void BeginDrag()
    {
        if (full || (Control.MouseButtons & MouseButtons.Left) == 0) return;
        dragCursor = Cursor.Position;
        dragOrigin = Location;
        pendingUndock = docked;
        dragTimer.Start();
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
            Rectangle r = restoreRect;
            docked = false;
            dockedMax = false;
            Bounds = new Rectangle(c.X - (int)(rx * r.Width), c.Y - 16, r.Width, r.Height);
            ApplyShape();
            Notify("max:0");
            dragCursor = c;
            dragOrigin = Location;
        }
        Location = new Point(dragOrigin.X + c.X - dragCursor.X, dragOrigin.Y + c.Y - dragCursor.Y);
    }

    void DropSnap()
    {
        Point c = Cursor.Position;
        Rectangle wa = Screen.FromPoint(c).WorkingArea;
        if (c.Y <= wa.Top + 1) DockTo(wa, true);
        else if (c.X <= wa.Left + 1) DockTo(new Rectangle(wa.Left, wa.Top, wa.Width / 2, wa.Height), false);
        else if (c.X >= wa.Right - 2) DockTo(new Rectangle(wa.Left + wa.Width / 2, wa.Top, wa.Width - wa.Width / 2, wa.Height), false);
    }

    // ---------- forme ----------
    void ApplyShape()
    {
        bool plain = !docked && !full;
        Padding = plain ? new Padding(Edge) : Padding.Empty;
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
        if (!dwmRound) ApplyShape();
    }

    // Poignees de redimensionnement sur le liseré de 5 px.
    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x84 && WindowState == FormWindowState.Normal && !full && !docked) // WM_NCHITTEST
        {
            long lp = m.LParam.ToInt64();
            Point p = PointToClient(new Point((short)(lp & 0xFFFF), (short)((lp >> 16) & 0xFFFF)));
            int w = ClientSize.Width, h = ClientSize.Height, z = 14;
            bool L = p.X < Edge, R = p.X >= w - Edge, T = p.Y < Edge, B = p.Y >= h - Edge;
            bool nearL = p.X < z, nearR = p.X >= w - z, nearT = p.Y < z, nearB = p.Y >= h - z;
            int hit = 0;
            if ((T && nearL) || (L && nearT)) hit = 13;
            else if ((T && nearR) || (R && nearT)) hit = 14;
            else if ((B && nearL) || (L && nearB)) hit = 16;
            else if ((B && nearR) || (R && nearB)) hit = 17;
            else if (L) hit = 10;
            else if (R) hit = 11;
            else if (T) hit = 12;
            else if (B) hit = 15;
            if (hit != 0) { m.Result = (IntPtr)hit; return; }
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
    Start-Sleep -Seconds 5
}
catch {
    Write-Host ''
    W ('   ✖ Erreur : ' + $_.Exception.Message) Red
    Write-Host ''
    Read-Host '   Appuie sur Entrée pour fermer'
}

#PAYLOAD
#H4sIAKet02oC/8S925LjRpYg+J5fAUUqk4QSRODCO5ORLaVULfUoSypllqZqs7K7QBAkoQAJJgAyIsSkWT+t7dg+rNnO2ti22ZjN7sP0tHpt1/
#Zp56HnqfNP9AMzn7DnHHcA7riRkVLblCqDJODX48fP3Y8//ejzb56/+uO3XyirZB1cPXiKH0rgbJbTi0V0gQ88Zw4fay9xFHflRLGXTC92yaIz
#vEgfb5y1N73Y+97NNoySC8UNN4m3gWI3/jxZTefe3ne9Dv3QFH/jJ74TdGLXCbypWWgk8hZeFHmR0EicRL6bdMLIX/qbzs3K23TcKIxj/gQbSP
#wk8K5ehpswcp5esl8PnsbJHX7+hb/GYSm7KGi3VkmyjceXlwtoPdaXYbgMPGfrx7obri/dOLaeLZy1H9xNX0JT45vlKvmLrmFMevCvD/8G8G9o
#GI/nfrwNnLtpfONsW+rkwV9so3DrRcmd0ukA7A7x3SZxbsetp/ADxtCapLPeO8HOGxtzbwmPVl7kJ/F44QSxd3wwjsIwOXQ6s+X4odEzuoYz6X
#SWwThazpy21etp6T/d6KnwKvA3XsVLE9/5m+vxw8Vg0Vss4Nd6l3jjh87Asdwu/HTg1cKeD034PoPnw15vMYDv7vihZc1tz8N+x9i8E3WWkTP3
#YR3apoWj1nhVxXik8ZpKrwffWU3FNIxHOICtVTXuoXp88MlhFt52Yv9Hf7Mcz8Jo7kUdeDLp3Hizaz/pJM62s/KXqwD+JR03DMJonETOJt46EY
#wDGhiP07IxIEIQzJzoQMg1No3t7WTlYU36fqwq20lWu/XsMHPc62UU7jbzKiB21QkfG85/F49H0DJ7Mra3t0ocBv5cEcY1ydvruIG/HXP8xbnB
#2o5jL/DcxA83Ysd7J2rDGqgTNk2A7eL4AHfggR7AmFfe2hvPneiaPR+PZ94ijLwDb318cTHZhrGPDY8X/q03B7SCHTo2Jj8CEsy92/FoBCV8KB
#11vD1UicebcONNwq3j+sndWDcGwtDHuEku5k7ijP21s/Qu4/3yye060B7Zz+GrAl838ZR2EWyim5sb/cbWw2h5aRmGgYVbCtvzLbNvtBS2FOzH
#I/sLaGThBzASxZ9PW5v0kfdqF812gbdxPWXmxN5vIu/tDn7dTVv6qKVsdutv3MTZe9Cx1bpklS5ZQ+xHBJCt7VdhJactnNojy96oWRswXvh2AU
#g5C+d3h7UTAT0B0JVXaJkuEfsN20udIAnpMGoxRmqhfYVA1uK7OPHWnZ2vdZztNvA67IF28dJbhp7y+68utBiwphPD5l/kyGrsV5Nw70WLILwZ
#r/z53NuwYZ295B3LeJStescWZ4E4DMQn28td45GC/5xEgUr4T6M9YPaH2hC2QHeg6d2eqgn4rQxgY2vFhuzeIwX/QUNDaMjs8YZwE/VNzbRGmm
#4Pz2ioC410WUPwXhmlI7K7mmWammUPNd2qaGjibABRCRbOLlIsK1Y8QCGAQifcJcBsFkh5PcVBHNg4iZcC1VnAg9MwhYWBjZ9B1SrjhhMlGu4o
#VXE9RIBLF5dxwrBuPAt2UXsEbahK7CS7CEbQNvWhqswiXPiNF8dtfQD0PNuPvd7xwV9ce3eLCBhirMCsDkl4oHkDGqwZLQywne4jrf9IVaIwwV
#9DoM7QCXJV6MFUjzDTXZIAwUFEHXNuM3F3UQx4zElCStIMjt5pKWGWOLfjAx1Q0jtwtkfPPmJs1UGSrAOmZy+XkT+f4J8OoP0WR4pUfLfexGMb
#oamYi6jwPgpv4jE8VkaWSMBxTyyd7djEp1tnPkeWgT+gx1gczyLwbif4pzP3I0Zmx6zPvP4aUIK3bEB9IMslFmB2AWM1q6/BIqgEgzmw9Y64lF
#a/sJTAKFIOc3YFmbNY3Zy1mBlrYciFTBjLA8NcOXOgDAZsVijTwz80ZkPD/3S7B1RM3zj7QwonKmd2+R+CztiUoDA5DT5oMwiXoQxoB1jzpgO7
#ah2PGc7nUCaieMM6AEGJ/QZm740tfB14CTKiGJEdxtjRh7gynO4qQxzskJZ3DqKQ1Cn2AIxX6pyG7G3mKcYgrFldxecSQS/Hp2EG5hTy2F5pPy
#9FmuK9dRTYTNVEJe1qvElWHXflB/O2pR6yyp25h6Pv6N34WCpoVxUcxpw6bcKkrePcAUiqwieUl8c3nRh3/Xjr7GJvLlEMGPMByCdKYgc+9QHA
#pZf/RIw7Irr4GYxnQeheT1IpChhJ4t0mHQL2OPAWSb79zBSjZFjSI5FHotCpSvjQl/CBKhAxY2RXt+KcBkcAkcTfezTI8Qop6qHEgEtLt7VoE/
#g6EL2m0kXRdkSSbYlxWWqZK4IIm/XRyJmdGexjAMEEoQd7LQm3sAUeAdSAJq/pK4O2fS5a4l5cyZvih12c+Iu7TjoA3FdeZ+YlN563qdqnfKsR
#bRiyfycWbSAvmlnexKaOm4zwJedSuy2oQ66Deg2MWuGciM9YkNLpuzx9QFSxx0EJTY55ixw1qjChLLDlo+Msk9Yd4boN4kMqfHXuQJJIQk4w6e
#X55C/dJUTJDKJG7v5ATZHUzQDQFbgcfS9sJXwkcVP4BusqdSlAqJ8tIioQMrfo40D61cxim/EK0ptKm68sj0Kd85A+VUIyZlSaJON6+bpBc76b
#b8lFFK45DwQVWpb7DNI4+UtVS5Uo/sWVCufcee3E16Wd/xDUFmjPUBVBXdNqS0mNwa5b08y98W2IW0t65N26wW6e61mGiMT8oaL3Y4HZxFt/o3
#RjhXWfsZkq9Y3xiZRFKOK6pB2aElPAtlGOJHCO7T5iPrCAh9ubgxNvgefDusAgAJkuR0V0RPwqoIK4cgidCuRJZWaTelF8GsihHlUE3pMLgI8A
#59YODL24O8v9SZJNA7E3hzK1z60T/ZTe52KgqthDFN5RAJ7ngweq617fEU3PFe3epCSwyIIrbkNrKKM969DQhpplNIidKBWdEDRZkcygQlymUp
#ykuShIBw+pUOjcdri41DcE2kPzaLSTGAP1lOgqGVFGAjwYcTJI4qslqkaR+vfifPzjRejuYhh6sgIU4V2JZH9WkJ3xv25KDEW2Dqye3hmVL3sc
#Zv5mu0sOgiTNgGYU1aVcqwJxkcx09LTSgpCpXAXJKMMatDahwrL1g0Ai2KQJVAG4SqRtYOk28W+BgRSEshI/sSqhxJgKjpIz5QqV9Y/tjolYmu
#JtrgOTxvpAX67kKRLtqZpiE87VCDR8thXixHJ1TxHTTbJhppuacOf4YGVqK+tQVHPMXMshKmAcV+YhH5SNegtUE5SlbnEbNkgd0KtVxZZLGpDV
#vYesCVgZZrO0u2yrMpHmGqjfoVko7BUES7eEgrwLRYKEGzjrbbsL8NAG+xtt2EVswVVNSbuZwdGgEfUrdM4i9G0aNO8MOKFTYYNdytRVNOSiZD
#upfFhhnGbdbA+NODgQlV7Q6JnamviBF59jRYm8reckbeSDyAECDUgRkPC2hcK0Zi4iVRVwg9o9T4KV6E5uPjD4n6JcUMXKihy1eacWlcwCpa/U
#B3E6CkrVKcfK8bvXr1ZLhX1lZCBRZiklFykv0UKRtN+sAE6ES0jFbyJnW5KFaBbZQy8A/Ij9OO3G5+iNzihoIVo7Qar5CUO3+5V6UBWe3kMzwN
#1dEEBlgvyH9pDMU2Q11IdqBa/FSZTVrAqXialOqkm+zQQTgYsQXtndglrSVaXuAHKZLCu0zO2R7gqgXDYRDQVZtXPLZUWBVEPfKJPlziC2FEKj
#graWVhxxu9QJZvsB4lFhrURKhi7HAqNiA6zTeZeZtFWiSzULY5UWBhkZGupq2fuqDHJrWGeWy7gHo9XMsjfzl3zrWqK7zqqgMEgY74Huw26DIk
#xjGBTNpihwZ+tN86viR7g5tR7woz7J2Jx0EzoVmNMpVmQhfUHr9W52OCmmFCoXzat94qGOW2EoJRxvMP9YIjfHqnxF+sKC9I2zKVLByFu3BDgq
#YdeLprZuTz3HFkizLEqXqcuDvMu6PzucZWSpsDKVF6QoKPqz+wiKk/IYQciFRor2SQcHHp3lQOkz/4mChC3/k7PvikWXbFIV1iYyH8leocJS5C
#aK3VbRe7EC6uVqUrRfwxTdNgeJZqifWMN1XEH+JHFJsFDsgPJG4frQyK/+2MYZoG9Lj85hSoATkwq9kEsfVfywy7T9SAeQHO5vMzb7VUbjvloY
#RtlJmnWq6GslJQ6whwaOM8RXV/qmgmIIAlQ19y/a31NKhTRbIl2MONMIsKu8mcwy08ulVsK5BuBklrj0i0rkxnh0aZOm9EjZhB0mxmpn1CWkT2
#sP71ubyE5WvdcTqkuenpmij+ocPVVemQxW5ztmZgf0wgi6BFP/YFjo8MZPu8c+yfaFxq8K4l6zzwWpFSsq/nqp4UfJ/NwTKGOvxvwczn5Ao+DC
#T8bMn/3hkqgo+JZt08MqIXCtzP39QZwQbQrZWVUS24u4/ktE9zXTE4U+LL1XySM+uJeJPB22tTrkJ2J7seA1Oa0tnFQ6K43RTLLk5JT3qWW9I6
#/KTcrZ43sZTKTGSowPeFxyV0HbUr5Fvm6jTOpQlnSiAzFKxh/H5mXHnJzBRpGDmnoP/y6iJp4JyjnuNtp2ZZhbXKK9h4NIwulZwIh9bn+1yIrE
#X9AG5l9TbXcobF3eu3tOGETNmFgTbnLmDPppcUWUGnuC1EjfBayjDmRfRVa9KQin4B7odKuFUSZcWAXdyhFd+BF2aupDTtplui5QZyzHJJCi2K
#aPhPCc4VGKxkkFu25exEC6HV+fjxOC5yPHhL5RgKRZQ3+oCDzwHfjc7NZe5LvjxJntAuCL8Bs39yxq9htnGluTGb7U9fEBGcRfJ3dbbwoQWXpv
#DqkRzdkCf4VnLrd9F39z00uqa5R1a1m1rpa+eCxqFojKKY5GAWZVMZ1iCbVgnK+VgNkYFd1Ec0hpxpwQ5jEmVWXyIFRAUi+NQK2DFceHrhAK1T
#2li5W1LW5lKUmaI7V6hOvwxw794KNrHAX6PE4N5/jg4T4MStKHydXOtbfZHQpBd5krzRAIpUV+DtwZWcyAIXoki8Iom7GhmQPN7sN8rbpQLiN3
#mJ3lvSIOIBiTzonL6qsF7YmYLc495e73j8AxaiJwCgQDg3zEnurtRscHGIwZLssBcUPN7Gm2BVCsDYgjE31ZDjgfrJYIVjImMSAABrR7yA+1kb
#W/USvMOaMitAfZVMbjdLSlSaUrUzejPmmArBllZR0ESz1ub/7ihImfOdWEqoQ8ksal99O2HE0HJgfY4RxknwnaMzYHAScyHOimzjEuNqYOX6Pa
#At68HNUAsnvq/VyWEj0tCZgAB3LX/kI/7RG3hRN5DkImBSVFEUUeDQVwPPGBK6NMG95UW4hr+Z8ghHOnTOjESZFMUUgXkz8Y1MnsVWlO6PQwSL
#mBOvVO7BUx7JVMs1VG6MJCpGS0b1SY3bsnSZSNy0UIeShGBmQILRnWR/sVG1p1NDuWTVusdPfhHh+iebXC3VdpQS3aWYXW/6X9e6yfbbpjA7+Z
#DjDNVN73w6yZUPDop8Gv7I8tBMZaTAEqUE3jpPPhBGqB9Lv2gAK180Ue4iKrBzoNIfNXPnhaSinam7Et4XWBT9Efm7QaCtku0CtUdSlsWeDvVo
#+KS3E/470f+7PAO5LOV7UfifRF2dGfiUgRK4dnpWy0VkfMNpJlVESvHVH14ieCjqKITb6EQrwQ7C63TL2P6FA5rbBRCWgjSo6C+8QU9S6zoHj1
#CYSFOAWKPWBrwfXm0qwplKFsYM5VeMEYcHyQuuEyHUGaYerxIa9ayZdWdmVUO7cqBPm+WvAHimROCMAp23x5LzpaOPiXco8kS3MDLMa2SY0xyZ
#Y76+/pn++V/fPlcIbUY5+bIDgwM+Ntv85mVzA7ZcbCM03kZDcsuNf7Almv6NcoQV72BQm+9voAJByibEUjW2G6nTK6LRwSJIJK3GNsTYQCeCYU
#GbogBMQrL1gcBMZuM6yMPziWGs+o4QCokYKEWIw36NccejiyqlnYjkQ7HuhOEJz2DxZBmmJMlwd2y0tFnTpZdFY5OhrVjbnnhhGXBIDyRXyaIE
#hZZUmqX+Frz0DRkWIfraLrvRNvnG0HNdDxrbKNwlt/DUQFt6cTzcs647BbOAF0XydWL5Y6ZmoVI6msz7O8SaO6EAfuNXL99aEcmSoH2J6zc6t9
#+6IkR/F/xbhu9KKe7y7v8vh0nyyN947MLbsIBIBnUEJ3oQRhJeuwwoPbJyBuK8YSCUd4iK/nemJXMFF0u/8SYTSF+MgTHkqKESgiXznKohSKoB
#bhtG2Mf0kSkaiVDl+dpLH384e4SdxMkCxB4aURdUtyb/dXIenlUwl1YmwjkzaZ8f/ImK0QQHY8FWF2ZDRKEMIwkB6xLcz9G8wed2obG4L/S7TR
#IS48uPxEmeL/lFer9/+w9pTf7vxE2bz/Kdwoe4u/+uRSThswMBzTrc8NgLw+TQcwchzDHeTpAEYOSwcwnPXcRf9kCoCRI6YA6OP3vt3vL0yWAo
#AfqW44gzwymMEM/zoJHh1WOunx4dFIMw0LVH6zfOq3j9bd7Fh24Yx0Zqa3j+Ix3+yx1Ts+iPdLWXsB9L5x9l6lVmFwymOkdKeKHA56oO5mZ4TN
#6gMb1SdODc20yRBQH/pfPDxsnzoIUFGhpAdWxqqlhy3OPD2RD95Wi09Mi87J5QcM/Q1t8BpqWzy7aqXaCnc50SFUQawaVIhVpmif6KfWklQI5m
#dKUxNy6tUjPU48MDoQdKqynEENNZ+1JJVWOGxpW6XDlucH4XYbIg+rGdR8OHdJQ9n4CmJ6akMXIu1ILn+4WYVrTw83p4NcHg5c2/Hm2sORbdue
#I2arKLGcJinFtLpab6hZNssuUDpGWZCBA3+2OgmyZqld1vXTA4+yka/piGoVXIPk7HU8QuHGRaA53vtwJB+R23WHnjc5c4OJXZ2lZEtJScTa4o
#zEAE4mTgbOTIqaqDsvWkQc3tlwNlzMhplWzFWZPFQxZroB4JbC9Y3MbNS1Hk0Kx8TY6U3RBDIUSEJFPDtVIOvANqiBkojFFjs8eo9w9JLbqFIW
#xGBb3q4IbaFtfmZgu6k6jlTwHEFTm6bomYblwC3+4WIj9huvz9FlyS7j7SvK8c1KzJhWXJTbj1RLAJEpxEfw9UycpSgoyzbAFLfycySMv5gVIJ
#GFWatX1ut7JD06S2aD5iB0BsPZwmEHCAVcklIHZT7VAj8nFbiO2Ush6jQTMt71K6PDhEN/uZw86BoFbM2NTkPS2JnDoVZoGdRJFqY90kYowKWS
#TdG7Y6YYL4l67BSeNax82RNOLl7pqd39odfzBkih8jfNJJfO0RWIZhMhH0pgsbrFqOKT3NMzzfnI1bhgXYJFzh8tc6ANDKAsTAOgkYq4LWx/Lh
#bF/LQCHlOfeXg+sGR84DqysC+6w1M68gec5DmhTR9peM0Ls5lX6P0pk2ZSeC+PljEFYJhnREeQglNUvnDn83dodNs7iROdx90NCSuYfOns6wKi
#yoM7y/pQnUfFaMY60+4JSlqqlanlWKk08VutRio6XmnzMQA1oKQsmhwl94B0FHooHkAg/8A9duSoYAtkVKqBoaFUd/9zOtW7oEB1cOzNe/SDPA
#V2T/YU9AVPAbOldgVPQWnTnxvMlw51JNN+5nCsOnxrGRXWSum8x0kgmkP1DPRltCUxU1U/sdTKM2TVeZDoENm9ElU0GCrMLnNkckPFCPOcGY8q
#AsyscxKdmVYWucJznaHyqIlzqMxzVm1TSPyK1S/Fe58jkzZtD8s6bS4V1oZgynm8UYEBJN0mfrNkm9zWzeyErJvcNsm6/QrB7hcIuNAZE3BrY7
#llf5B0IlMf9pCoRrXmbr4BM095XnN01CVCXKGICec2630WWb44w2w4lc+8XAILGsqGlWpXlhTQZjWaVYrsuoYz4Y7n77iP7B5co1tiT9hCM+12
#b+VDCO4JWk++Rj1yFWYiLh/dyL0WTHvNGqc0IzVOfymiQu7FX1cGAyD7kN1OeUojTjmERpLkUNghomPBqPTO8uD7QjIBWSqiXd0UgN/nAfindQ
#i7QPw7QymSSdQTzB5qEdXRmMzqlIbdn1CBhaj8fnNUfl/AhH71GfTjg4ezwL/2cvcAFzr92bkmUijavOMxjJ8O5Fos9gPG6AsnyRbHh/Fqt9Ae
#gtShMX9FQUdN69S7McoLw44F42GAUypA+eBA+bjpabF2Pur2vYUo1ko0wq4MG+wjx8l6F6HYlbNjUKy8UlYu6WGj+lLrhCLXQqYM7FfHc9xSmZ
#Ih+6cGlrTBzPwcr1ThUO0YRZ6hkT2kHKlUCooi8oO8cIx/jlLKoM7MAe7HvcBpAFS8LTRbIIYCrTPYdgIOJu0p4XeNInWsIDo8mWHJXba3lbHi
#OvPIU3Yb/+3O05Rkh5BXFs77/xRulG3ortCCoynQKJSaewqmaN7B18y5dqYTy0qdWNYjIE1cmhuMSJunTIJWwYdlgWT40OgbQ3NY58Ey+9UuLP
#MoJYLO8zjbPZ6INeXMiiE5EupyrpJkm2ZUPZkEjhCtrE4NNdOkQPF+Xbj96QxWw8p4/OowjALjYakdYPuXw/IREH2j6pQhTviq6JaT8zeV4sru
#baArxks1JkrjQ9ps85CizAsmnuMuamVWVYh3pU2/WQ225WwIOBopt1y5WywlO0+LiS/P8J92h3niaqNG02GOSRmYtNzsTxalx3utxU9bLZli5Q
#K1ftju6RRs3aYUbNXueMnlaWdpvQTpusJua4nHAKsi/LLZDIa1JlogTKDaAoMcUgz4mSbaHrPR2pWyFwGXDJGnIpOPaO5D+ZLctgxHeKKmQtAq
#9dTNLUWx7CXmIXcCvKRwU0qfZnU/KFNR9cBrI0i5yGDOzJntHNOXJDTwV8yPep5NqJfagowaO9CwGDCa2nKs6iMggtgwLMCtf0L0MowGk8xpqt
#MtmWTyzd5kdyGqTcfFUt5abXapsLpUm+LFYnYaa9LT+pR70WKZfdk4zziYms+BY6+grHdYvBWTwvp52JzVe9R8GYM1lBPHEz2pB5HrR27gIXQw
#rYFdsCP1MOsC5vYX521ZFUYpZtDIGhr15Ia61JI9lFvqUpgPAExDY03OxdCiIfK0TB49EUtM/rqCXUigc9YwV36lcN5uFk0rptQzqhRyKRieu/
#2UwrnsrlHQRMoK87nhoj21HLd3hvLerQzvluveVvl9+fSE40uyll9h6KpX/I1C9bioLwtlS9lEdBJGVzMpRFHYE8J8u8YHuKOGQnQCeXZOmSdL
#x9FWs4YlxDi8XhdJy6Q6zxBUb/Y6VxhHmvm0dR4ttc66DYDZOUrn9AvJA85Rtz2ja8yHtc7LXAwwR5ZmD+myDh3DeB/Gnned6b1nn+ZGjxXr89
#Rpbls+zc17rDlqzdfJFrdZUVPg+nQJCfDANJ1kTk9Ei0opNxkciqFbnSg92M5MCtzewhVgQTFn5CsrwZLMhBv1IAXEVNgXTGt4OsqVCxN2QZg4
#NtgrUIOsOcLFdD9+kKucCmNSdbarQm63huepK6DnHe8fwzuwThhBzjuYVX90iuk797J1iOaJb70oDjcbJ/BjOmhRjuR1XHPMowYwPNe1hKDc4F
#qI1r2Bcr2ZZc7wzQ0Um8+swQBjem9sKDYa2Ca+AbCzjDEdhByQV/wCw7zh5yo6nfiGH6pviPrlqTXcTP6Dgalpyt/TQYTV1SuDIdjdV2v/tu2D
#+Ax4IVQGWidJIeq9IhnznrX6TixVGeCNZovFQq09dtFYvdsrjrEpqqyxKRDXik0VAowaq/fTiQh6pHScrbl2AdbVOmLz+AugyJXHxmp2aZULTq
#byNUyupVY6jPLXLMakVDO4VisDQ7K3LLTjXJ91GcUL6b6K+bQ6GTXKXKmlw4uVsxuegmLFXiEnhIaSmXQ28pr4Z+odOJyJGylmCW6Dc/HaLm+R
#XFz5cFBXSCfN1KQ0jFJqFI1JMh9G4O6ZkqZZiKmSVkQkFWTOQpZBUX5kFwnqm7CDfEwh/4QmP6rgcFklmLVfF7KdlsF0AsonmvwzrVN6zHTtPA
#WBfLmYKLkXrx2jlmbLThh4c6Voqseju8dSCXkU8hs2kIopQTEnSpRKc3zvWC5SMs0Pc9iQPKMwsSYDBdm1FH3lFnpPhbRMnBj2MX/+4YHCDP2V
#UhFDifhGJdkIilaIa6wM/FCJjOc/j9WGVqG8WBVbL2s6QiJQLPYJJrngMtqJgmgpUsTjVTwRCgoraknKyh3pxwcVsAIB2TxXQOb9gHSklkVlEN
#0W3ub9PybkJIoVoBXO+v0/wM8YxbaH8TxINUHMWTOwKGdNF3PWZEa38qk1qvY63HqbN+ckcBMC3Yf9/QoZYvJLb4OSDKkWD48/YsPiqWbqypnV
#JNsWs8tSEywVTOFY8BnXktTl5Ma+K3JyM61keFY+lGIsYDnK/Dw7jmg/wGHVHKU+0ssCNxSTCnATMTQiZdrI7rYRznETSK2aC/xoGJ1Slpt740
#EaNCBfVWPcx5NBJ3fZYMaBA1/omrtDlliAv9NdnhGsOeFFDHsrcVfiLQYxSAf3OMOAGSWozonwLFvGlrokn7JxqyfEhlDgDo3PvcctiZmTTYCL
#Qm1k8dzwQynn10uDPwy5lUjMlkq2HSEujkwRxSC0D0skiIPCxEvZVblCirYju+IYX8sn8clHWB+aXoj9E8IXC4Ex6WHN+IbfxFMfzpkf0a45vJ
#5NoJA0QHLGQj8Nfdz3MoAsbYlERqCPs9wNKbKSf9POLKnFMKAzsgRWjgHhOXZXnnvtzZ/4H6rOHyvaSmdXmR7L4pdrZdXYjU482Q8MJM0pJoSt
#0xF89rgTLha4GKkjOokrWGkWxJLHyFDZ+wf6D1ND0LAyw8YZ90H0K+LwxZNApQxyRdZVsXj52dViGG3DuQO2l7D2WYcBLVrahHhaRTYcd3tdEe
#zIUhBtr/luLW93W/JL1mVzrUzFWOGjmZSoTrQ8jQ887/nSlTMU9T9wdU+kXz99xQCMpE6soGHey85VUI+lNQPgjFdO3NZjz1UP9ZcnIx/13F9J
#0mRpjkqJKTIajVpssqkWNfGeLn2+zCMThwvHa0irb7M4H1brhLMHy5JuXDKLDwxmFueC1j1lF2Yw5mxdDKer5O5axl8FrsUFAtGE/GmqK8cKDD
#Q3IP/FNgJ9IkruFFr8Q3y3SZzbcespQeeqNeGJG2MgwTtkZIB3TgA8P9h5qcX5WGjFumcrzFIttxJc37ORNDpWbOTmvvNhlvFCI/edDrOoFxqx
#7zsdssQfuYFf2PG0TAq/XlojcAu/gmvhxw2U0638pyX/tPOf3NYAYgpaSSRzy6HBmCKlwo698y7j6LPLOIS6e9+7AQQ+q7ZRqo2qelNtWAKKag
#fxsc12piI0aNMDdrnvH9odC02F2eVWo0JXaEI4c6D8DnfejlVoiGx0wRkNUTbQ0pSpenLWODp2t7r67Kzqg3Ln82D5QTDoFtpZOPPyuhUQ40f2
#Og0AeYSJ1PkPxqRWhUZnnpPQhRkVPvjBfV1H3BkiGXtlfAj35+Fd1xDQ7I9tSoiSQWZQROjb5DzMqNhK8Qp3bHiochV0QAV8pBRAPNsepOT0Wf
#vcvjW/TeWB+Z2aDdmUU9dLdGB7APBndsxBr2rwlONWo0S3vElDPVJGlMY5l6uNjCIAQAaIV4euhAKl/ZCfYSpi5c3erMzo/0faxUp87d38AQdb
#zuj/R4ZjvEjH1Pt0U3ihdaumdcpkxusCWaaqVX0ATcoHUVz6jVe39lVLPw+Tbc1eKR+/twp+Mamlbe09COapaxDsWkzCmFC6YMHsiUPk97CbDL
#q2UfGuY3bpZbeyIrvAvV9ZkTU6qKpnl1czAa51HXg1MLR66YZvm0OsnENiILezAnE82Ya0cUoXSdjqsderah8DdmjLlGFeGCbmoz6LZLP9Je4Q
#fTgstIbZ4c+k/51hEw+ECaftlCadg65jGxLsDG5cDzeg6/l7EEPInr4MwpuaZFzsxm0xI3V2rlVIT92h0BjybLCvFYpwc7qu00GXzQEEhVjJwu
#mP3iMV5hAEHXeFcn+eLZGLbgvYreEiUQgSsr+MAaeQKYncdZWrhv4IPGusCa6W+A5vZ9MNXFAK4CCn39ZJVhrz/NH3vD1MwjdGsY7S9eWPw8hH
#YPf4EWaxofEmWXXCBeX3BBQW2y28Evx+QK0V06y+gUtxMCh24yRebTdWfTeW3I2lDE/3Ii2EACL5uQAv2YF5LNc/FGNBqUiy8tZ0LQ4VyRthvE
#+R4YFqu7+tuzXD6hncOCmlYi1bWIzzwzCL+bc/cLNwJ5+pKkb6vRwnww66izf3bEGrsUE02818tzPzfvS9COSVnqZj7iUNWgNo3oAcHxMdgYFF
#IVIQrv/gL+b8FMBKwjrd9Ca3amn6kDeK0+Gtii2t5sV2YGEBk1Dvum9b6DQtNMaun9Pt3v1bw+x4Cs9iJ9zKuOOZfCkFK8CHUZs1QnruKfudh7
#DS3UQnG40wHqbD0U2PdUM55hUVOuqgCb/J1Zs3x5Q6RR9UNIdXH2rAX6W5FZoW5rQBbjMmZjOpm2ihMhECckZJ1IbfWWnohhEf66tYlVV6TVXs
#qipmYy/dyiqNvfSqqliNvfQrqzT2MqiqYjf2MqysIvdCZyxOrEthLoUqletiDZqqVK6L3W2qUrkuXbOpSuW6dIdNVSrXpdcIscp16VtNVSrXpT
#+Ksyj/rRCxUiMDkjApWqx5edraZIkS8j4PG4lH1qcOjKUpzzErCIV40EdOVpgBR9H755GVpvtqXbqwttdbx6rcpRx0mPeN6pZi6d26+0L1CG+A
#qzrJSLOoe4n3xtHBEI19SZL0S4xfdLoc1s+/zvKvGBGKv1b3uLRWjHCgSM3qCLVe5bErrAPKlSqEahUjHUlRJSO2wOtWIMUSV2eDy4BWPGubAi
#PJkrYKvoJhdvlfKqwMyNLOYHUQE4OlJ8mLFfgBmRSSFZ2g8EwXMmp9usSn2J/gxkAnibAQFQMwK7yz/UIbD2j9qvKnWKKoZg2r7/4qXEMgGHex
#3cqYPdEADBICPyB/icbRBL6MYXVcWCfHj8ON8kSJvEXgkZJG5EVjW7LRPJtaY7nUd6uRCpibz/jzO/68Jom8KVzfqLETcgryLi1HOf47QyL6XZ
#cHp9mO3OlJZqVc+T97GvKlAmf32/8AiNUdTfs1V6V4frPp1OYoOy6Cxwm5q/NWM61Haezg+q4mHPbXP8mJbPBQjVLdIttAhoGZ7pBBCViTNyHf
#5G7lZo0BmZPSHp2opkf77B6dmnCJPr9mYiv2UKEySA0X7hSoPtDGj01XD9xq6kDegvFRvManxmpLs5AVZCIn8qMCbWE8AYjU2nejsEPM03GZFx
#QJkj8bO4TjGrtcNv1Bw8ne+EGQ/cDgh/T7cpV9XeUNodmS/6i6FZalF74PzHo1MMvOhVQue48vO2bIre0tb0QRStZcb48aY1q4Xm/sMgKanjc5
#KVicdxSF/p5ZVm2QKX6F+9xkuWTjKd2SWFJC1BQaBXvPgw+XFdODOcLSZvEHjUq4xO1sZH55LARd45c2zcOqbvxkRcF72Zk/njkqyzQrKO3MHg
#4D79cOHBDh/CucjXPuZcGzOPkYtk1XN+cZZatNktYjlnSWo7k8u9QfgWrK8cHDpcez6VXvrn7DVj5SZaGTspPCMjh/cOq27wkKzvKuZsxhX8WO
#cm7U472tQM2gkGpvfjjjGki7pzamEaGDk8Lwi7gnUDS8QJKdNOIJMJCoprkw8kVIXSUKarslJDf1vqZ3mbaYZe0ScAONQKcgV7h5PEs2JWEC5p
#ao350PZ5vwBu28W8pSlf+88kVdNNyfsG8dhYbm/l7cabcJg4Bunmf645eSCi0wp1AdHLsZHOnO5dJ2SWAJWIxw3iTzDFWxMWzRzlqc1VqjbUqh
#x/wx3dQbU309U5VNWVghQJBBaRgmgcYuGYFBbd/h2VpvF5FYIF0XWZfUivKKXbGz13v/R/XQnKUJipTjggU9OCV4tQGm2X2zGCTWk5MmSnk+jU
#GluWUYV2dJktEdh5lnFrHYwIHVF+5ef1S+40RJbxxsYPlJqADi1IUaCsbkH7nYP1dPOF0ECw3OAZNfJt546+xiTJpTmpsktAgVot1mA2WKjBuh
#IfvNAFsKR3nYfcz8UI7AwTFKRkFxqHaDmz31KNYW7p/O22FRMkS00sMfOv7msYWi5yP2Gjn/eWata7JqGdyqJUSa30MjGqZMiKLhRfpfIPgUUv
#3L9YeCEIPCcR6kXK1PWGkMOcYni1ghcphmBkOHjITBY2bYZhH+KJ4AahwXxhb/GnpVHhnc1F0eJfoinHvKllwv739yoWAeKPpwERfJdkqzUjrX
#lXOmPzRdy+5K94IUEwPmxmPyFfoB/kjzJ5eVzm61Jbl/L0uylnelGDEW1UTJn3AoY+5HnLcuXmErjjR1cBZulv21x3hqfIwJgc6ppqdouHqxiO
#W4iIJ43TELSXMKdpk+yMSY2wlTPMFXdL0yIrEAocae2YuBU5F1PD/m2quCBA5dIPVsiCBfnnavi7GDbGI1kWvWI81+JBjjKIQFgOHWZRxEgYIS
#bw8eCXbcvkF23O5+pQ0tPJlZuJSzOUCtIlNV052dePTYloOuMPUIy/ou5emhG08oKL6Uyd4Cebx4okHigQyZFYKFuAYwKMwsXyfQSpCnsoWYpx
#IATBH+ppUuAAnS594NWrhwD8furpZK1o44ARKmR03uI2kOjYGbmX40VCelVI1sIkkdJtnCdaN0VCVXnBGlKOur1u0BNrF2Gs4nWlXXc5buD/ql
#l3TiGMg2UXvcsXBRRn5lR9kYixmpfsFghBVOrj4pqjuDszQdsY2C0YULO0AP2MRva+6OsfLLYyzhytjidTgN2a6LGVTrsUwfysd5uk3iAw561k
#TDUsQzJH8UQzp7iCSskGWonoZZ5Lc945B505nVwrwLLBFkY0269Ldh9+KyAoNTaNlqXb9CqVllqcIkDQbT6/NP4YqHbOQb62r3xFmnZGHk56UM
#QXw7kSEEfU9ihhAp8Rjv6Mx0IYaY3CzroM/AhrnjzwEcz/lLFYrp5fOnTZnSYdDcMlROQQMtbM9LFll1sDU9XW+a97mtpI7/2r06Z6TVbHPCSZ
#QEdSl5IBao9SpYrEBjkvraU2rIzYiCcG8zO7jfMyTmNTD2N0faVtwKDNQkLVvKpv6tE4XoE47vNu4qCjd+/P4n+NkWFQs11yxIGhHAhoNpZOYa
#N3OPTlGM4I6JOmx6knDXJSd91wDhzu6m7DhoIq78OjGYN4soTiE1qLrfqEmxqTJdNakMBX2lH2dujLUTX3eAuy29sqklF8s1lC0pqSt9GfQLGb
#p+lVZSRYnDPGhWmAogoNjTaqMVgYCsxRIY2HKBpHo6iThbreptWZYpegyFcFvWxVtjz0qebr3+oCrdTN5GCqZZ+mh/o+Htf+qpSyKtyksia/mL
#XRT5y+HWtKHEpKayS1KEDTehFDlzFj/Ri2WRmJkrCCDSEeQKpmFl0nSmnUItfevUVrGytgu3ixT0bTF3PsmWYj6vfiULYzdDsrY9IUutPuh56+
#IC9Cvp54jRzxKdSZVJsyfSG4pu0MzhfkW0OmBlB0BNGJ4OOF2xjUfHvMlENj9KRJZfRaGQxca5C3wQeNfh3F/4DmwxgbzO/KW+dfezCgt1AXNK
#CYeyukWnXeu//Yd/918UtBdBf17UanDhnXVtYf1NW4W1KKfpTzNX99QT8iblPsgmRNhaTM1lSkemowRgSiFNIPOuvAj+acrCpw8nmIHgJkA59c
#iWgIymwt3yPDpFhliULpUnJGKogmukfKfOUDN7wL00fTSouYDAsk5eQMCKNF7UWXFzhHyxxMm7M/o9Vb52WeKZ/NplgJKix8uVnETV4nkzBDQx
#73dBtJQ6AclDTj522y0sK9nRoGdJmhV8M03XrgsKgZTyw6q+M69w9VwpH0WNsdxk1n+ekkCDb4WcDlVqJ9Vg9+TAp75dGYfiNX/FTLdVpzmKZp
#mSA355+ipXGolkZmhKWyZcn0YVpWu3upU5Tn6JCQSHdvrGaUtOX27xlN3u9X0vBk7v5OT3z0ykHCIflCFmcGL/nrpJ+3TGGOy/JsVIGR+2Ugp0
#8cAyi+LSnVU5WYdtbWv8nYWrO1gMrpMbEi1bjHO1q88k5Yhfgb5cNrok/FY2YYdl+JMJGyl7gxJhU+/B30hTkBKq4DQErW0ozITnCHNWyso8FG
#VKlGq0ng7KiDbAAL8UqRhOEa5KUmXpbuCiiElJzJhTK4mr8/IUr/dihTNiPUD07X0I+g5PoO9Z+XHSa9fwjkdAyzKalniDbCdn1VIdHEnF3HND
#HtUGA/ciHAxO2nOlqyR4uvYklU/no3nf8wpC/aA3Kd2EICVRlwjYNvI6vLdZoru5lSVj5OFtxtSpI8IKTNKdF0DhHyU1mE/ig1xRJdwlejAvUz
#18E0duBRZU3xMvXf1oVSEKNqc4J+gr0fUi5Nn5B1a/jgA1rdY6jLz0Rgl+/Q0ylaVw0ybt2/vdtUzXzAh37AzFSPoOzz4IfeirH2UoFnNcppn/
#xfT3UNMvOgUKbFtK+VgnalRphSlNBzWuKIkwsPKcNAUezKai4MC4vDNIR3rWpSYjdVJ/nyw1ww+usC/xoeD6gec6BvbmQ07vt6QX7F6UEtHHmN
#VSXkF49CF45EXRLCN1XabolzcOFRNMA/xC7KabE1ZnpIcSrnVNb4Q9ihyQmaBSYjNgCaRA5RAkbtsq3inwPHr/09xPQNHwnBh1e2+5FNQZN4IR
#J4df4AAQjpfk1tJc3LG7nFdRtrySZlpa69NSTIGnkWtsF+MTSjKZmh3YzM676pvZjkhRMzMToCk4Ls+5pEQ0omWhTxrPnSWEQGU3pmgPLWtue5
#5sphOyR6STUETmcKb4WchnV0zLll+8yntYRcmhKqnmRM41b7K7WIamGMe1muGNvdVe5dRqQwopk7LauGGGQp6RvFHZgbuaHYxHWl3yC7NblS7D
#Vo/WsLJ816pM36EeB3XJNTLgOD8eipJVgc9X6qkFLRQYAtNCizS7Kam9KWftOwufyqUrguV7/zLB8s6PsdIrn+D7kCgnGaZoHM6VBBaIKGEL9F
#ybFqfH0+IIK1rrh8GLlArLyW8fzOrqgMjXYiB/9ay1eHWtsKMSUgKf6wq0JqplVUdb/IEfO0vDuHnam7rCYtluRRYcsd2u2C7LfTOsKyyWTdPk
#ZEABScI/FIw3YojQORtEMNM8BMRK7ha3p2LRRkbjrXlGjcelecv1uAfWMIYGfg5dgz69Pn4ahtcf9PFzZiwW2sN5zzAWo7R8eafZaOezKbOwfw
#tEFZTdzjqce2MMPgW5Xo6u3s6WiqX36g6bEFiUDDoChOWkO7Nl3V7IhkOrV4Yw3bxJZ0ozGFfnwckXmyeP4cEEQuj7AoMleYivZsdqabNjrHZf
#DtQW865h/ZroL3vOI1lvNUPVgEzuV/AlRU9+SFGz+/zsaAaoEU57O3M2Gy+qzCSU2vUt61Ftpr5HucF2ZNUDp5JdcG8RavZ90Ov7BLOSni7bEF
#PX9Fn3pA3NHFc5Q3joDHu9xUD9VWh9JUPvV/nJ+1K0NwJd6ValRDHRoyvF61cY+vJlq0zcLvh2rGHZt2PLZr2+HNiTgoVAviB3YP6ymDte3mfO
#5lBPtPMEdrpwJnRYyHRlWmc0IJ7jsaQGzCa2ITSQVTcYjc/rF1hRfQPSUU3yW4j5ugQCRacINfFBfoqTP5DTt4y3P/hLCg66R3go1ilmFstyw+
#liik+zkGUvPX8lF8JbriXl6TvQEhU8Ix0qYyXczELKKyHqT/BQNBNZ4m3c7O6Mbnpvc/lu+jNuWZRSEeN98abNY4HM/lAbgubdBXHJNPlDu0vX
#LFr2kAxuzRa3Iw2fZ7I4yDf0sfuS4fW2wpwj6L3d0pUaaavyhczMac6tuvQebTO5MWWYvvArPWv4Apq8rgnlI3t6lF2yOTk753mTk4PdKdLoyO
#wW4gOlsF5+4Yki37ubp+Ti09JjTDol+BfQRiW/89dZsnu7sJCSRlZIfW+nMF2cF/jWlWmk2a2y8WFz4h1z9Yo6Pzw6hr7RUz3PhZXuJItfRw6H
#etG8wdmfHqDldF+g9OjEP51HvWgwEHgBcXxC2nzT/waP6s9bToKKsuBgf/h2lmyqsJNeFEIXSk5ce6SN8Cr0PoWPwZTezpz50qtBaBIA8qvPBT
#udORBtQGU7vExVMqQWlsYoGNdRPDnl3MgPoRVQnrWb3GFCIVg7Jyi4ifmNCPIewNlvq+ROM582N3cyeykZOnk8a08UTbvGObGrpcXoAi3VrD5e
#4FrjUGcpjZ0ED7xTFs5T7vWKCvdxtvcrHeyDKgd7JaMWIwqIM4tREici0cTTxsPac2yqlkdYkJv6LYXrFLZtHg5WEfuFlVZn0aJ+8cYhig/oc1
#ZK7cju4kHZBsPiqbJLc6CGXgw6KHAvK20ao1fr7uNlr5uveH47q725ycquza2/ueltcJ87Ff5lIyYy225XuBgdx+h/wC0pg8rLURgbLZjEintH
#1EDqoycmVcIDDPUs9wXlOoHCLJYCv+hv3cNZ+TBplqUQikZv9H0CppjT9m1yEK90zzG76XhJzWUxvySQ4m3lUZLKOHkRwz64S0koYZBwpIA5Fn
#4uXXslrLoiFscS1IAy2wFvSa/TsIaNObRQVDwZNSJ63lggT9ZLGf3yEIqKu1xg6Drsh3uka8u0g36FdmD0M0Wg6jIUrJdHl869hbMLknwUCsOv
#jOcPHGeIb723Kf3rCfSvK93S1em4VZ6DhnnxpHupedtVVTqfYDy6tCkzxaM8bkM7oy5R+bT28L61TUusjkck86CRXHP13rL8rJXeD466TKYhQZ
#PuAaWTnPy0nqoQMBtPuNNizCNnmQvRdo8/DhP5PEeHBdCU4Z6WL5z/aCo+D9PLmQRd6kxVilwTqeFJIIXy2RPRD5SXJwRbb5O7k1pGhZkscz1m
#bFaO0ug3OGrf4j0JW8ayuT8wF0nz81b85komnfbTMxTpAZzeflXtCBelNLqoD+9Fq5Kj6PbUqC5QscaZBzVYogpSSNS6bH6irvOZE+HNpTtlBT
#NSFs77/xRulJfbEJtX2s52G/jKvwZRO7yJhZMcZMaJYb5hjJ7DuZ7MqqR5oxj6msJnKEjw/SoJnhROziPO8DsLeayVNMVho21lmFNPUARAHUB7
#yajLaWdfGwLh1DAnfp16YBSkffuUelBR4R5XaA7VYgrMksc767/sCq9YrrOSMxVWjw+0Ywrk/oP94mJKkBr/d69XnckEhq/Av4AnK1FMpSGdSk
#GnkONdWEP8Yk1AG6VPW/lssbaqtah2WMVdm0U+njveinVksehZj0SW0kTu1P7MAQEqTfp+K1yfK4UD59unx6I1sO/sCry6futShwnLhAagQ/GO
#xLKdCIvG2+LdBclsU6OFNdxeWCdNn3uM15CYVY3buspr3a/OWSIfS4ApnXWpYl+d1BwQxBaaDghSH3q4WAj5fYaVGwkLNquxyWx1ODuA/KQ6kw
#H17KUY3e+YZeUK9GItzRfDUhbOVk0nME+c8WYrsDq5AqumK567pmXNqJ2mw7BsV2A2uhoV9EgFWAK43JLOLPA3lTcOA1dYZJcQihbQIa8kK0U9
#kRie2Ffuwp15w9I5h8Jl8Q2ae7pKTHPKhnLWbilcX5lV1m/L1UuygCV7Tr1FF/5XuhfJHIrny1K1qUe2TOhP2EbCOtL32mxcdMXmw9hLdlumD4
#AS7IHWwSns2I/byOY0ZFEapRLUHiI6gJBMa64eSmdOjw+eXpIx9gq+rDxnDp/YFXzACBU3cOJ4eoHXiVzQbXyfhbfTCyYxdQ2lbxgXyjbyQIDY
#e59SEpTvUCOZXuCgLxQ82d5hHU0v8DLDi6unoC7GV08ZUP+Sw1Tx59CJeaHcmtA6fFjTCxPKxphNjvkm6DmNdHqBjzuimH9jqheXheIA6oYKVr
#mC2VDcpuKX8qirZ2GdMYu0+enFQ6vXt71Z9WCEYkzLqRzEJYMo3hujwABewI62jOcWLI89hO/4r2coAws+B8ZLE5QPekELaBvG97CIXxr/w4WC
#XuzpxS4K2g8RPArnBgDJroUdCx30DOgA2ulZ/F8fz/3CZxc7sKkn0IWh264BT2zsyeZdWjVdmlKXQ5oqoODVgwdP5/6eYIupfaqR6hKKXOUFeb
#BLU1lWmOM3bSkFd9MF1affF1cPFEUshR5qROD8CSi78MCHNv3iB/XyMtyEkcN7hMZW5tUrR1nvYv/tztOegvb1FO1iV3iWMD2qGeswb3wI+9Gk
#Wtur3288JfZ2gQdSlI/HDp0fQpC3lcSBkbz/SfljuHu1m3kK0KhkB8RWV1jPStzygGOHO9i6m3nkQNNbajIMEHmvvtntQZl76iiryFtML1ZJso
#3Hl5cgb4JA7+luEO7m+jIMl/gjXF9eQI/REvHzb2aBs7m+UCIvwM2Oaeq86OKqrubTS+dK8RLFjd7/5Cm7DRCN8Acv0RGbaSSfEntU/vn/yuby
#OVAs5dNvv1L2tvLP/5SX/ArWMsGzrEAblZ//x/+V4pW9SJkDDP3SO4QONMKrX8K8cfokE+BCXy9w/fDq3HRJ/Q1DgWvv7kIh7rUKA+BI04vnmP
#00A7nv+kr7069+dHRdB8xFeRnmuQ28BAgI7GJol7GUtGEUbC+unofrtbdxvejpJXsNg8LRIPkt4yWo0wJWwq8STuKNRPQQHgsEO66g2LDX8d+v
#R7DjEsVW7tivu1+Dfvf/u9Dv+F+IgA9c2/HmZxJwc2A87yO9hH9ARM0RWz2QPL63y6QzLpLrArUGgvwciDSQZOQFrFngBJZNHbGWuzUty1R5kF
#NlwjgBEUH6UTbOnuPir0w4qUF5O218JeRbdbMK14iofraHL5Q5UI+O7wJNY+8ukcS4O88Pso1XNVB/trpgNDl7lNS1jGTcZU1/5s8CP0xW7/8B
#6HpKvtlfPmoa58YD9pX4CeLob4Eoe0hQUrpf18022MUXHDQpyRAb9dfbrNGvyGQHxHC3Ec7+c+tcXQe7bRA682IXKQ8SV0CElDO7uHr1qfLZV5
#99/dU3r758/z/97vdf1JbeBjFbKvxS32jiLC9qGCTMdrcBDhHF5ZGJX4sYueV4R53fCD/uknQg4t8HQmvFttZOyhvwGzy5KPe5Qjhm3GVRB/IY
#9r+74iBn7AfLvy1wnN/tPGXv7W47yQ6T4yDLj5Rn5zObms5BOroO+KZ4zrIXCOxIZC67pSgU7ZY5yIhnSRslRlBfSkifAg9zq1973pa1g3pJhr
#Hf5jlz68ZL5as3QHUH+FPYZygQuOyG+7ouqAbrYpYRGNoSs9pOmUoldMseZB0Dp98mXoGaIIF8mUKpcih428K8ebr5kiAjJzzOdm3lTnATVtxN
#pM0HiBoiRqWlKC6fl2TfJWxwAz6Zq7Uz9xQ04omkLhtdBPV+/rv/KJHB2V2GGhkofuRg+zED2c///u8vrpwfvSgJGeQJ14Qh4JGBC84clH/+z6
#BLWP0cI3EyjTt4hohUphOBPM81x6JNeEM86ue/+0daDepmdvUdMG0F/o/m8l3k0UBpas9XIJuDdA7SLcwn8iRCxf/KC+nPeFeYw6yWgWHa4WaE
#8Gci9uPJ1gykn/7AqMb7/0PiCbU8DesWOUE1dXUrWb2bBBd104xXu0U+MBCinST0o9qJY/FF4J2aOmcskbev5aD4jv1cMIGuoUGEUMqrnLt6po
#ylzmwyHePGu60FPL27b4ORl7P+797/tH3/U4JKWHUPzAtdv7gFveI6pVxEDnbQrDE2jIx0Ec/C+3ChYUyDlerNHuiEsEtJTF47oHmYqHHsnWDn
#cdHZ28IX3RSbnxebP83ba6e5xwA+T2KtpWFCmYZRDo1aDEYvaQZxFvX589/+XRr32f6dWjcqkGZ2XpHDsHhOgcOyB81sJ1t70B7CfPXxlzIGuu
#SunPf/Dx55AAXQJaWYiFGMLtv1+39ce0xJqsUSavYs7FvEIjS+FXODt39TCwnvFlZ4XoeGqSEn1YUd1G8zeHEKh5+VimqOH29RuJpdFZeIACvP
#ZrnijbpBzru/8xIgTJGSYGSG6ylvd74S7/xEQQMAghMZAMhjEUgU32OWzFOwenubo40XraHpBmS5rYSONL0MH3OJjEAlWssWcSWYCnyRJcwW5I
#LCDBbxrZKveD6N3wE4kLG03/8bQLnt2ZMpde+mbaMuhVlP2C/4doGHOKYX4tikmkFas8DAWf6/7CV8Lcn4UmkkijNeOuG7L6NNi9i5KGlDcv1Z
#hVCxkAkozO5MEsqysH4AEV3ETWRUBnkDk2YJVX+RMJI29KvxZGgqa/PXZsqL+Bew5TqyxS7vYCxxHizLVrsE6dPKuhLUn6eX8LtOcnKDMPYKJO
#R+5KM0AmfGdXL2taYY+oJ4MfoqFBMReAGElhXz11sQ8hzX9bZoxPshDjcaRQUxFewSH1xImsxVTUvOXmiIspBefnJezW1wsiatFS5SYbmy1YLF
#aLSm0HIx67ypKt87wB+isiUduB00AcX1DShqp6znUmk0mWvAZDYbUDS8LMTKSxRWjEzR2aiAHz1/+b2OFhNLVZ6vsCPkVpiU0Icp+K6vKeEO2k
#ObE04Iq5HBnWczVDrKK2Jt//xPSptmDNotOoE9NXMbVFrKfbxHvWC5+G24xvSTgSNoHJUNlNCHfc3wx433mp7c8uoYuedEnlMaQkL7VBrC584i
#Ub7dba5hYt/AdF6AagMzXHuPH5rG5NM7R/mtc+2sd6BJdpTPf3DmPxChT7so7oSImGS17AC4vXE9oKmfbja7oF4aIKsMqxECe0jxq7hTRdSM3c
#jfJlcP0LGSKB9PofLVPHRBxN0kOuDSF4GHXz+7+2re9ufqhBf8dnp4gJbPcSs3BNuKaeg9xbQUOxgpA733vWU4FHWE7twOfFt1evtO/8vRvv9l
#V3zTMX+8uLxqaQ/I5Cm2OVLM4fe9wLQ61t600Trs+pELGOYC1+rDnrsDqjkERJ9eFN/iY3rdz15DD2jtFDuA0fb2ZvcFjntldlkhZrEsFDN733
#dfDJRR0Ov0FPgPqlhGVgXNKkKFNQ5c6XfoPypBdhexRF8ZKX38jxd44ESAA2KnfEwvTFvpB1RQ4UWJTYpFLUMfKl297/RgBfAfhR12BvDU+Brn
#qA8ChLNuVpSAfwGsBpazzAB+wdM+rotclpVOV4rWCU81KQDr0YUCkLYuFIo4oJVhAQcAfnga3fLlyeEJ8DH2pjNQBikSdBVj3zEJ0sM9hyqmHh
#JhhiNUbN1U+jrARIdGYC26+Klb8HuIUzBxSj34B3OBxx143Ol1sBBUyDBtFgYSAAHG0LJidlcjAJQyhOF1APqdES+/3QWxhO2WhavT6QYdWxl9
#PQKcxy9fWnzg2whEe7H8gLDFeGGih9oFoGLmOxhaX+8qdgdejADOI73rwhrB4PGfBZOyYKK2PuhYit7t2FCjC1MZdnSoAnPT+9AKfh11bHiOxe
#EdggSgiSsH6/XC7CLAMlAbiAUK9jPqwBcb6sNqd6mZLtunrFn4HECj+H2gmx18h1C0OETi3QbmJ244i284izac7CXCldtb9GHAJzYE/wLqUgcU
#H+gDXLlB9oTAawFis09a5JGOS9rtZDUADdIHbFAYEyTgpU14aWd4OcjxcsDQ0tR7OM60Amzne9ZgXWC9e/ZxRhWEMlnyC4A2OaBNAvRABPTaMg
#HxO7ic8C9FRjLIF+gZQm4EOAL7Hjdj0IGvAPkR20MBIRW+7eFL+IIPfqSN2w8Ycn6NewC2C3zFrQeoYQUdQEB8ZfbxlYU4mpIMunq0CWOKJAIx
#oeeYiBk6x12F0HIY6EjJkBhgjKwJPeKAhtC7Cf+Xq8C4cb8ohYfwHRiU2AgRoIraOPOeUmoTUK9THgb+CypGodD+Gpaa6XXML+28CXjWXZXqUj
#FaHbEyazGdc95EPoqKhmDYX46KT3Ec34ujQFCUKyslOCgMtkHFENL1KAGUreD3o/IcFfNLcUHwLP+qakGgIEepWwmnh8RPzeEL+AgQizkxZiYh
#sehQsb/s8Z6wTSRO9hoaML6XHneAwttrjLVb2flzBaWRjo0CT38vPVesFd9zdJmv0GNfGTo4Og5IqOEaQJCBZeC/L+3YhkHYnRHwBwCQhZNGrj
#biLdtI0PluZmZraeZ9xV719r0XXaCuUFmxX8AfGFwPJK4XJsCrh/IDvO4GwNA5R4skiQV3NlSGTq0AeB9tWkkUGX3PKqLKKvJk4DZAIZRhB//8
#WOTyKFylkpdzJ0OkGwDTHyLnT0kEHS4S6HefKGVOKLuCXNHnlLKCtJ6sAF0xc7UkXACLhrkAg1W6uLYmiCNOF/cCrRk8R2FsQFSOCnW6BGZ7Lx
#TD519yHGCmYgnGJkiOfRQT9v0VrkW3ADAUtoZ6z0EJk3ULWEJwdEw8dZY9TKGKDpVqotojmso4YwPRbSgwEgogxNB020jA5TA+sw8CCQhjAt4D
#hgDrRgENX4ovOvgCGTyKBaW56rkAIL/r4Dsc3jHVTHx32t5oC3V61aKAJSlEyYIN0k0jUFpP2otnLXcX4SmP5xhG0xq3MEyppT5poREsCq898k
#1kBdKnHY5eVvYAY25cZ4t63G4zlx7/EKKpjT2/gk6/fb158+5dC3thsS6tfOzwMW2rggr2dudFdy/p7EwYfRoE7dZrboh501L1RRh94birtje9
#Oni6j6mIvnz14uup77Y9HcvFXqL7rpb/WKjHTIl79Xx6QGPcfPy6xTP2tbTWw97MMmf91hut9Z2zVRaRs3n/nxw/bmEpz+0ORyMsNZqbg+4cSn
#0bbvENy+uEb8x515sP4c13oXuNrxazLjSOr2Yj0zVdePUFTigK5Y5BJp2PetTx48+oO9OYjYYmvjMWg37fw3dfY0Zcett15t7QoC57Q8PGwXzn
#LZeOh1Ha8N6xvb7do5bnA9dYwPvnqChj7Acb12xhdWlc3Z5tjFpvMiz6y6+mh1ckwaNE2SqBogX6T4um3kIdpcXm2kKtopVNrkVKQ4tPp0VKW0
#sYYgtE6FY2oRbTGVrCGFukD7e0V95mjhaAmA8nG2bihsG0fa2hhQSw5sCeutNXz19fv5n4i7arRl6yizZKq9NJzHHrifvaePOkNYFfFv0y3+Dx
#fCWeYhPv3l1rt1NMDRa1eVMrJVwosXo7bd9+YptP3JXurpzoeTj3Pk3ahqo+svvGROpjFQOSPrl90qLTrb3hI5X1xp6327dPuj2qpvIidv+RKk
#xptpxup1c4s/ZW9+fT6bRFSNp6xj/H+Fjb6jRpmMvplEUsSC/Jjngllqpmm26xTqbx9MqPf0PnY9ux+vhxfGU8ewF0TF8EIcAivqTRAsBeJpG/
#WbbFd4/gnapvnflLzJPbtrSW0VLHLbSTZ33MPRf74OuTTLPt7UbAhDxuZGm3UuNQS50kwnaOUwgnOhnpM2B5MbXLRxVPp5tdEDxrtcaxqgODQ3
#NV+/L146dXF28ul5o7vWofWo9hHo+d9XYCqPcUvwcJfr3Cr0v6eoFf3+5C+HF87b5RgWAgjvyrL/44bbW0l9NDFko8fv1Gc4EAeePD8aghqZ0e
#YM+gZah11LDIFEqQc5K++NOOqWFtL6KhajDX+d104cA+0baA5ewpijj8ISUf9ubpr/2rDE8ANRKYUKI7T1rvWk8SPVH1JPwaM5o+B1LXzsgcYQ
#1R1Zd6HgS98DfzNiCajGNZJT/++hrbp8dtaDkCLIv1GGbWvgX09OftWxXq4ZcEIYQnWDvZ/5To/U/LwFli3LUTKfP3Py3wOKtQ4JNL3tPnX/wG
#gLbyUFLYeCFQBBc2Kk+TCj9gn2Y0craEMijOtDQMwI3H6HLTAN39DfuKR7bZN9gCY7uvxTeYXlF7oCiY7oxXoERY/GsYxOMeLGI0vxmbw66GeT
#W02HO/8/A4DSvEfobZj6+JaaS/Xvi32fdXwCr5G+gy8pYYFQW09jffAV79/iX8+cvP4M/nX8Cfz/DZFy+BKoOgNB4aGoad8ZYAoV3eOW7zMeAd
#C3/CbwsQ+9fOLTyKGFuOxww9gjuoxie2285/HwVYHL59mrac7Zxvv/tiekBwjw9AiH/7/qdmwN8gv+CMEfjFfGYNBgP8thgNbBOZZQDkn47sjB
#xAfZh86HoOa/0b9/1PTtq80Z/1513efN/u9xcmb970bGfoELMbjsyZhd/s7twGfsub5zyWmscweD+g9l/SV94+HxBrPx0ntT9YmHMTedlDzwF+
#SQyZs8B0+LORZbusfUxRnVDzvwmj9/+Y8OYty+31PN68AQ15I9680e969oy4cd+xuzSRmbew+lnznF9T89Fu5sfU/Hf4LYU9HXXirbMjKbx1Lh
#sg7F2rb/XZ4Gm46eCHA3NgstYpQR61/i1+ax2zdf/0669hw72cvn7dyrgqOjd+E+FXaBUw9Y0mvnR2t8r7f4O3U3R+v8GRIh4XiyjfhXcOkHQs
#wpBcLgE9gPDmrZ3lxmP4X2rhMyAZMS4jboxS7S/iLa/7xcvy268SJ/Dx5Vevyg0/dzbOHJfj+afll3/lbBHzW3/1bfndC+8WxRB4++IPrTdvUh
#B+98Vf/nZ6+M13gBkcaL9/OW5JIPrLz2BdRYh8/sW4JQDgM6iczfcLqJ1N76tX41Y6m+efjlvp4P/q23GLj/XFH8atdGjHEuGNE5DEgPAWaO1i
#t6EEXEoMdLOtHpLo7hCErhO8BLkaiusgHH+VeOt2K6bov79BgRm6ffnNb/WY2Ku/uGu/VNWj6yQocauHI2hBToQeHxDb2sCa1An8mUJD6TPkOQ
#s82thuXbL2DmsvWYVzwMtvXr4Ceo6H7kp9HFWddYL1D0dV6xp4X6yDt1oq2UTQRYEKgXpA4g7TQf4sTWlZmNK1d9dSUfMQ5gB1QUz8COoymLAl
#jqbOjeODbMQHTzVRnoz08FrFjtqsQKSjyNJWkUH667YIHd501nIjtLEDDYsWGkC5gwkFEz7L6gESdPMRZoKWPEp8n6jzKUEc+DJICYl6LENjzk
#YsFWyELOu+Yvbzx4/nudChvpzOJy91kpim/PPdu8NxwvvlwoYqyim7TbzyF0n7gIZtJqRwlviKxV3BM9hILY1JKCCRoYKnKC8RxgngVDz9hrJA
#6ahVLDftwxF242+0/D2OQE2H8FJfh4heX4EsrB7EX1MTwbfGGb6gVCWt9jbyFkBfO5E337ke5pDmia7wpwr6KZX2YN5ZZzpKKEyaOz44ytvyX3
#l3bVg7RK/ryXkocy3CXMTWyp12XdxZwgCS0ImT9jpFnXmtjD7394Bpc518rr+FlZi2qG4LniGaPWfJFKbrSdYCdq47WxRwn6/8YN6eA6mQycQc
#5PV1iKRJs4a03Qt0LT22JpO1Ak24S9poftG2RBTYTHbTjXej/P67r9utNGrg5uaGn51ztn5MJ+/uYCDQ/OXevmw9wTbUyU5nzoe0/kv6RRElcf
#ug6/pWA0iPYbkY+lTtzJ2q/ZBtQgzNaGeYRhs1WUXhjYIdfBFFoE21f8CbTMLo8WP+RV97cQzLD3QromufdjG1wBWiH3Q6+v3u3WtgT0fOoD77
#9PPp5cN4FUZJ/OxPs3d/mrHv8BWWkiDFvsTPYNnfJSAcRr4TvFvBUJKQIgregawMo31HB6VRr3m3D8Llu5m3ArVBAWldiUE89uJ3eEzCDyj05N
#0CyBS7nvHdNpy7gBPvYFOC2B29uwaohdfeuwAPIT7DA+/O+p3V/dPlAEb3p/kT5Vl7heF+z96t4I/6p9mln7JbkKpjQXlcTy+/fdV+Nm5DLfVL
#9Vn69UX+9aX67FL3bj23HZOdKdUe18/aT9ag8b97Z6ifgAJuPMHfFvvdZ79s+jU2MoFpD+oRbP4rDKQIF4qfcH2JMazWM3owpr86lPXCr+aTIl
#qGm+DuBZoy2rRahJyIAvRLD7zNEvCNDRLXMUWlOcccwOoWNQ1U7rAlz3e88WE7JRrPXPK5lwCcY40hiJaEW9/lz1oaDQ87WjvbNrSj6miRa4NY
#o4qIuyY8fwFl5qzk9Or1Hi0Ne9KAM5RjbbFUOm2EDF+Y/XSNfAF7gMcqMZuP9qn9hSjeBMD0N38Dqi0QlG8W7T1mCaAlnuIit/e6PB19vmMXAl
#H32QD2Op890jJvGUZ3X9GKmEbr8eO2QGqZFgWvqPN379rx1XRkPH4cP50OLENVHz/Om0LE/CwCkQLRNiVh0CjZQ6kggVb31jNvPsfsuR/xdpv7
#/Ag2I5BFIK15XxRlht1/JD50lrSNVaZjA1wv//rhM76JP770WSMAV1yzdKdjgtepsAYx/Ehb1JLVNNbpdvkNQpPvgkMynuPO4KPQHP4Tb1veeM
#Er9nQ/vge+a/64nax0TOAFW/8dfOUp61R9FwWoexT2A7DtMNij8MF3QqJniAJfc5y8njL7hlJl3+AiF6enXJx4ff0GhBd9P81/C8ajY9ayn8pG
#+d7MNxuj+8XNBiIGwGTMtmJLo4/nGQaOEf/Ywy8yHBm3UOluaW/H1xpo7N95MUAlHg+PasYGAJISAVAyYU+aBCzsa+ONSGSwMqyCCv/4ywyVsj
#Xna4LLMGGC/0QE8/HBDWUS08MNZ69fUR73T7/96jsyTJGYgPokN1kBgfjjK/1b+tVu3QFIeI6NFqZQa2k8ywb/xWp9D+LjmExmMbvFaGxqkRcA
#idV4Ao4D7e5wQ32OqU9mF0PgTVgruMO+J39S+8nHQA7DAMQrMgYSoUHRQkWNgH0jJRibfIk5+56zi8TRSQBFmS8AUNpQ8WfkgbCQ9eFdvwrbhp
#p2ih8Yfx6CZO/BflY2JEcfYQT4CoaQGymzds1ngEwtcuW1NFMd0y8sjTebQ00WZPsBdWV5iuSvr0FGhl2xBFGGFcQ9quXN5ZAg+YIBF+3iW9Xd
#ooTBYMyndSTaMnkg6VhApg+ZaZI0DFwblUMISxCEKEIOKDqBicrvSzJc5IG4sHZAxabTggVZDnUd8rH9jls7YVDQDsyI/4alYt9S3uxsUDDgXL
#5AHDLzr9JRiB9+/G7v7cOP34WLhe+CuHO51KgWJyLZnDlzuhVEyOW03b7VRa76+LH8m/3g1MAHiZ+RcuSjOxBuYd5z7/fffYVnFoGhgBgNwuU2
#8IHWXMIYtuEWVchsyH+DY1NAoUrZ7GZ69dHlX5M35GOQoRYenTF5R/l+oP8NYsW7xAs8zD+DkpgfrN/FGP34bumsAYIg281md++uN+FN4M2X3r
#s4dH0vuUv5ykZlg4WONrWAZP1fItgEuQEZ1xTAU2Zk2CCsTyw3mE2KXjHa99TqAd8LfOjG0MyeIG4clho2qAWwhcdCL5zDfLoDfPka3u1ARn73
#rvQ+f4VrnfZgFZDlmHNU0Jqc59NDmWfhC9wKjGxTsdcgGaWiJf99L+GtJKbtj6KglbY5nQNxf8bREr+r48MSPQ8IGPwk2LRaNIuikQQ42aadaP
#vMSpIKe2x0fFaTlN2+hOWLEy/9BNV4OQaF2cE/Af7ZkGiMJOVa3zx5MgGZLwOrnTtkl9Ora335evlm2mafKFU/ARp2rTuvgaXTc/aNvSHdWseZ
#qNd68Jp9pVLZD16Q8THRaFGaNfo2Xvpr0Eui9uGttvbQUg6UUgMCv9E2U9M4Crt7O/31+LzI5btGathYe2xmW9hMsEfRaJgi5pS/mwiSCcjXZw
#gnW1XVXBBSmflEEs5x4wlS4WLK5G4tARYOEiOK59zraUz42cQFrKOweAc26iXwKDfYzb24vVTV+MnUPqppDfhFbkAgL+2+tqB9n27t2+kV1KYn
#WQO3sPO5pJM2AZ0saPaPH7NPYFkprKB5SyjHFvDxYwewOdIddD3BV/YURtaZ2mnhVMyNtHgcP6EhRsByQqDyn5h6D3gcFRSG+hGihY65v8itBS
#xBVVEMj5J229FmwDJnetxx9LhU85DuGxgL1oOBTWBNUF5rs0+OtHx52LOnU+uYE6MNI5TQGvU8Ea1Cb7/BZdASAVtvprQuOSlLBcmbFLo3+nYX
#r9q6rqdrIEy1SZ6WlirvoLaHBKeb494N1yuBcT1JUR41h0XUetaSggcw9INxk1YFzYrZzv3jK6BbuFeFye9TW0qmQEhapqg8rz2ZxNHeJwn2JS
#iprwE65JbV4AvoDhF5+7j+lfIhQ31DSwNYIWnAMnkZZ4uUE5oxgIYTG6auFabIJJt2yk0yQQf0RRoVB/S7d6LhcJeEqV7J5zvJJSQS4yQS78xT
#FsQBCpItNf76rf8GJ8c2DO6t+Txd2cy8zIZB4tiE+69FkEGVNxOhzDSavP3OW8C6rECYYrbE1s///u8B0fLWYdErz8qybFvvf4rxFH3g0ElQr6
#WSDVmyTRcEwircQXc5HdZtC2iTTLOJM7UJVEQa4sXXSIvxahlMi0jHdnhulItUU8J++XzYIWAPk2u9/wlYBkmxP//t37fU05BPUrGGbSUR5Lz1
#T3dumtmA1/PhWxKFu/37n1ricNJpvZ2+TvLF4AtBiMBW7O3krQ8UHlQOegUCUK4zQJ12K9xAu1uQH5M2Hxsfy3/7D//2nxQ2XdjFLuYUG0srBh
#3g0SYiI7Cs//xPsFziavF2QOnwdhHUbT3xMksmMuyCYsBzPTQbd1HjwLEDA9B8Lb72t1NGGwAnUCWFObB5JxFOvO0/AYLMgfwo+zopo0S6/aev
#D7hzExB3cP/u4e9e8+Gvf6wgEzlRZcEQH2XBEG9y4gm7jOvdME4QvpFiCQDPcaaCsmXIsidFFSf8tJcKnCIw3vpPTIIHClgimnD1bUKuERaeg6
#JgNUakWiS6GD/6SNjbRGNFstR56wMLU1MiNhFQcsPB2sYxqY/EWrT1No8ff7TR948fi2+uTDWd9qbgoMC2j2djVYYqpM/OQf1FwEkkNaWcXNaa
#YqhNcTTPaPRPhCAnWYqQgWGCsCBNdAy1KTErWyBGM33R18IQAVEXVgLzoEjGAOCr/rM/01HtOHKnFx8fvNjFh+oxO7H953Erz5wC7PTPafaUtH
#CiHvNz1mlOqQ0/xQp6c9aqg63yc6/fh36EBBgPNXp0vrDF+Jl3cSWUl44//3nCp4G+OWkeaLvgMX8YTURhQmT+uHfJaiTNiqIYGX+zURfx77dz
#TOaeUPXZebUzqwoDAido/5lneGxN+AadTbO1msyENrnbqhXfOFt4tQ/9uTLTWZa6f422Mak0kV1eVHKfQ8OwZhP6KLrQ67vTRugqk+1CRKBRbP
#g2CrdelNy1W50OwZbwCvPOfXxAmqb+OQ33ncDrT7fb4I7IjoConFQdGsJx9UiIw42mV1EFvN1d1NIyevv4MXp2Xz+J8gjdNyDYZO9hTXJZ4vgg
#t7WFIJ/67vU0NWJ9xCxRfEcjkfKfGqz1gk0124z4Tsvte0uAEn0jO2FbJQtcavtDIxw3/o0r7IETHBkSmuLIMN3/b529ZFlDfMQDB6fLAj1hTa
#cUOi2fizbstbctNob2MYDJdpK9rkZ9NHmyPiiXkdCMJ8Ro/gKRKRUiPZ0Hj7+ic9kI7s8wThUkuOcBBqh+B3gEDAR2xQtvswPmhFx6gR+Y2tGy
#DT5OpNLF2VKQ5Ef4d5KXqJ4wvkxb8rxraolOSk+5TZghUub6zrHjc+6BYrETc1U2FKN6RRMjQ/SlaRifzDVcSvXIemNm6srOymZtuTV1kv2u3N
#FbNPOKFZ60HrVwkhgnQF5bJ2jLO+XdO9wgMgd0hck+54sFpKetatVg0LbT+TP3cv4JTJZlD3evX8GatF1trnJWgNtdlWIBFuuk7RJRnle+m9M7
#vjYsD8dWeFIHgC3NmaunxAIOxDaaBkBpPGqHwLKDyIPInjUP43ikOCW2rzjrEfdVKkQRiTvcd4swdMbAU6EVZBfiTww+BZGUcJX4m0BTZ7sIdi
#/bX0B6yW1zabGdBr+Z5+bSIswVgkKyXpN0zMGUh+lkMlSQRgejYvwV3iFTGSKMg7oC8pYVRws4iMk++jbIbZC9yYJ+QOxOjpkMjRl4ZqB0Y3QI
#63wFi4SxAWjNWsmR+yxwfzVtryhwvyFuf5U5+7cgdE0pKJqui3vWEmLrkXG2nvA3T1qqwtLtX9Lv/BoqNG+kzcErsTVsvb1Vx8Ww/tMB/Dy7rf
#ZwYTizhau2xn8+XQkPHHx8AAi1+VmBozLssRMJ/F1bePmkx04lsEJd65Gq/lnAhJUXoUrNoU52lM+JZSLGfomhG0AbltPV0/6z1meYU0PZgBbf
#Gq+emhY9ARU/op9D+qk4oET/Q9xZ+3M8+/EZ5rX2o1Zuv9kGUzEMLNWohsxaBlD9cyH5Q0KJLdjhoDnKtwjmYyE/pLvPkhh/DJPZw3IcUbbNFr
#w1Lp26+Pnv/iOMEGTtVi76poJ2ClmStUEg/3f/n5Qa5s9prEVLtB/9WcpoCoCV0ytdA8W4uHr5zW+/+e5TnldpZUJ/yyPLgyjlL3+6vfrdruXF
#SYfSaAG7SzOZKs8wq4iU/hUj4Gm2wVFM2PTnY0Edz8BeG0SabkSuw2yDWBLoxZWrWa6ND918fMDYIp0iLbYBxlngTwI/rsKzlgLsG10b91vYZI
#b77Cgs6wR2Lt992Jq84r5bWnOmjWQHkAqHJI5VeTm3m4savKBLkqlLTt6YcHpkxp7Sc1BAW2QlxW6oalV3mE8D54G6E34XRlWDfSiu0smUOjGJ
#rcVHbC1IEciWtiwgzqaZ+EHJk1Ax16ke0PmZugzbeBIGHqBja5aL+vOjKnIYICTfBm0EFg/gnL7OuON2SkGf29YTJDU6Mju1XisfjUaqJjR0nI
#hYSAbrbZmTpDxgS5PFDNJFOTM1bGwjTDjbbuWpdzbFFNPKmE1/8/jxhjuW87nwmabPJzKEtgwyImjWKBLfandaHjTWpIdhcUEVW0+v1llMpRTm
#1RzYuRYDO6lNeMQkHxQdcp/PrUb7nXTcjmXhAbHtbV4YxIq87B0r+yUJGR2rnxZGyY2Fk/FRt18H2uKNKmBZ3WgZjpMyLopyAfyWli8HwmSBit
#haCkSd8RC4+lDVNW2E7D2oKl9g1ApuHkwqBZsP+wJhnEvaFbuCrczjxxXv2GFWZ3oB7V680XRMM9tS1Q9e56MYyZCrVYhF6EsUbOLMzSifCCOD
#Jj8T9lFO7lIS/rr1X//L/6ygDETbLFMuttLpsB+Z6PejIPqpOYmjfVgn1qWOg0+ZPwDdAWlvPP6GF/j8/U8/wMu5s4mFEm8yTxXNlWFWKkq+bv
#38v/zfytc+5ZZkHgaaAc7/t6h4JyoeAPn5f/9/FSGnLxnD5ByXrBpJ1p/OcXq8W+qNpveaPB+lBPToKdBOkJRGSiJTEO01A+ObDGzfppXxFpD3
#P5ELhQ2uQEomZQs8u4wyy4JWw/fdeP9deBO340yBgV9AscmbHOERxwUekXzL/TMojeMb9EL4T1P+NvGfPFGzo7rxa2ZheEu2Whe57EWLGbxf+0
#/MN+mDxRP8xLoME3gf7Ae8dNk3oY23zKoiPdagpYit0gIIAgxWrvanTevdO/YtauUjgh+PH+fjgVIqDGSSt4RwYD8i+IEQydumwaGCiiHcqdOn
#uuqRcyN8Jpnhothj2czaya3oDSb4p6uCr7TVFJ+9Nt6wmPDMBeZPV7J+dkk7UqFzzySIvPtr/J6Fmt6meKdqTrkyswtnZTMncYIq3uPHDml6wm
#y4AG9mfhM0Fb5O0BpIH2lnRGsiPKibjMUXmjNuR68d/w2P5KHgqcvXE+3NpYqxj/z4jeSnBXikBf8UPfvT5pK1Hkyvgqw7PprPwjDwnE1WIAuT
#CbIW4ievOz//7b/9+W//tzfw/TKPKs/FtoMzXsNgtGS8zufLneIdBbbjGErA/kjGAQu1I5kDtl5R5oDHlPUvM0SATonPEmZulJ4hfSo8mwdLhN
#EqvHkRzp0gNVbyNHqFzrLyxJTazICRthpivuPN0psyX5wnxJRkzAyLIsKRnXCRmpdKw+XHIoSjSB8Vp6mW5r0g0p7HoP1J/9PNExaCVg6X47MM
#r4vgzHdBNBX3UnGMGf/IHYdV3tkqn6ws5RXnwdENcDej0YzgIpXWKOqD5HN5IVjX2Vhy93laFyTzSjGSgjgLBH6/82rVuYioRwRC2rdBdjghhw
#GbZUtUJekm6AuWqx9vatqCdo/pMNchiS1Mr2yJezGirQWyiK+iMihmfkyVO1Td/GOmx3U6/vjjQyZD+prZVYtq34ZUoCdmpvtI9wxckaPjhC+N
#vKQYU3AROD/eFV1rx/9ujjX5RoNUTqTkwWm/MHXmxXrWSvXkK+FZarj4P1GTLGTMFOXOKxDrsgL/f3tv2+M2kqWJfu9fwXS7kqRFKSVlpsslmZ
#lwuVxd7na5POmsrqmbzqmiKEpiiRKVJKVUWimgPu1isMDs9E7P7O29DfRe4O7crh7sYnGBnf3Qe7FA+594f8D2T7jnJSIYpKhMV3fvYD7cQjnF
#l3hjxIkT50Sc8xzID1RwbJYTJpMyevedo7e//FuVD2oSEXn4I0yxxVBQQrU1Te5V5pPTz/CIzc/Ujm5hb8BeacfMM3cDyoDsp0hLF3sIzGJmch
#ES84ShGcSZNQE0SNFUHGPruBMFMp2Nits0vXBozPyFjI/g9/LIJMQyacBnMQw4yI1/7K6TBCgvhY/p3Tl68ezRl8+evjzVd4qKOxC4S1TO9Qdt
#RlQE8yliuHoUAGVrvIfZHd4guyXSRKo6UkjrMFHzWBa//9XPv721CP/GsYAy/u6/aQRfVHdy0t8IgaHNgCnGmaMp8Fe3tqav8r2cz2awEmDG3/
#/q3/5Mnzyyg/NOpSgEwJlxtIhD0+ElHy9pZ++8AVcWIbRD0N3djeNPlS2tOFbVz0/5lI3k6KpDNs2KqFDF1k0avWza7RA2LnQ8Coqv+L1tBwY0
#K29uwBiAniSRcDbUJX7uygdVWz/MgmQ7BG/xJ9o217uf0JCOpc4vOTR77YFzdmYiuRkcvYaxrgkyO1cHgYtw2XzeNIu4k/FUDZTac/SK873MKs
#3MYyr5r/6L8ULQNVrVtTCoAk5kodz6i4+h004xHzCd8/MOWi6p8pj7nKG++rfGSTCBUpJAnyo6eIsqEe0nZyiBcXH2OicnXxs66Ef6Gr9XeqiP
#eV+Meb+CDqGZgzCZWKaaNWxyxuNKVmfGMeRfaWtB1YYGrgwwvfPNv+JSwKOv1MB80eG90tXmsoAv8IJNnypy8tou8zKZMQq45WdbM6HjbCkPPi
#pkWd2ySBGyjQgxRZeCVd9dQZvSD6OYaArB13mV4OqROYFsqsAvaMlBtPwyG6LkQl46TsdBRHqn3cnZE5unFvmTBquxgSTmmC/iGT6NcRPNFNBh
#AjMM/kqwMITvkLhgCjPsPN83HJJcuRI24N9j81Db7cQeM+FRwTDpR0/Je0GcBCBmHYs3Ney+IWPY0YPSxmN4zIb61lDZOjtDu4O0Y9FRM40PkH
#3VdiRqFMpMUBOagHIXNo2Cu6hgZF06keTiRQw91AP9JI6i03jmNlnhFIcAsrV4ywhX6SiIFgFu6Dji8lHmNh3gfy/zN5Nw+ViAV/UfC2gKARr3
#5PnJk5fu2fcbYh7KbUOtUFcE7KfrwSh7ZIzsnWsbTJ4yx+uGR81uWK/LLaZv3O2GfGikaHfPvLPw3PHOvjk/d8/wx8EH53IzxtM35b0oEn2hi6
#7xHIG+lCdq7g0scaTISVi3HhVrIGQUW6I0CRFGxhe20Mmb7/wAg9lmCttCFrG2t1UVC/5BZiZ+/AWo3Lu7O5Qvbmu1jUMEhMUZDIVzzS80o2ZU
#UTBmcslhD5esdW6YKord3RUXDUE0dulezVLgxKoJYstI9uCLUwnTQQpzasFiP0AfX93QdtmYHrntsmvGtO41ptfXvQYQTQbX+GPrJrjSvwK5/p
#LMe5cNzwnhb+gs4O9ibecf9eJUSr7uwebwnObxniKKKT1PxXmrjkHy4nRd+Lg46rslIDXxUbmTTuzKLz7jXXPlt7wTX1/nB2D1mD7wqN2699Gj
#L7XRgEpUyw/Z8BUm6PU1/GlMYf3L39s4cVfTTv7EyTpifmExhc5bdzc6AfQ/3AHxwgj74Hf/lUiFYVhgJvSiUO8LrD5bk3V4vk8SjUv9gcJbNF
#YCa5GuCW7t5rEoYsBEYx3YYBbHETEMiW9QkBEiL/uUjzekfMX0AiMjBsLJQMiRZGlXz/JPwyWI2VCRGoL7PATILa+v8S8NgpbEJkYKw6A908YB
#n1Z1PtTEuy2gD6kPpvJFLwuqwYxC0Cs2lSDqjsXURAGusMLkso3mIAcDDazfPCV4TuhIZvSKSt4XfjLWVGzuFPUgXOjurkLUcuk8Xx7mD2kD4x
#jX0ak6lucVd6qtuMLqgeWV6a2n3H9a6xHNpuAdATnLO1RZeCdX9L/OyxPmCOs7X+On/68wSMiW/6QGCRj7k80RKJBHpT1CPkAEQVyiI97q85Y4
#UPWZmifKM/mGMRvKfbepvTFo06ox4aZaq01gW+5ggrYV1wK/lu/WNlHnBpHeNgBT0fd/dM+lI1cTyHR5pEv7WVY60nbEBEsjjCtxUzwYwgNvV5
#frQV6AEoSOiRICyPfpiCd46qQ4w9MGyg/H+AcrH1ip3fn6IfAWPiQU+0z45u5KAI0gsVbKNsemkfhi77KwTSUieHHvSbiSdVUULw+j/hAZ0J5o
#GkJRjwa01ypCDJbMZLbG/YPeb+NYpOpEW5CmxkLFIVHVTjaiiJZbsm1v28fN7bD00X74B29a4wcWOKYqcyapSwJJlPaZ9fqXpfZk2Z3izvdGji
#wtbWGzunnrsJcn86in7VznZl9i4+zHr0wvnATyS0rOIvmQfl3eqdRWB/VcEOq7WOeRkmaMfNoxxWWwogs0s7q8rrsr5HDluu+u4mmPl1dIgVNv
#/XWFFyMribgACwjhbhFa2BGjLyBdc0WQRRMpdktpShMelVr38H4T/xPKZL4dsqlLTryrXoCqhaWfd20ky4EPgkHqCphRKeb2EXtYzSABi5v7G/
#fPWue6jVISSAf4F0k8CdOggWwOskcgMmL5NAOp06wzohAnQaMhISRJqcja7kRfjciAUarofhKnGawA8wihzSsBAPgb0J64k+hO//vNtS1XrDiZ
#4Ik0fZhUrZOgsC8lYKXITXoeIcnAco7gIvLYUFuGNT9xcVqZK+n5EMsjzCIRSGU4EA2Qy0NefRKg9kUQ0OiRbFf52iWBl8ZTzeXOMLaSTxIsAj
#x6LtBPhcMub5JcsBZqryTBi7Vu4aoKJO4By8Fyz+oE+Ap0vJelLBXTDuEFu6RunSZVxEtHntSG/msJsiCsHIBMLpwonIRZB5EjGtkomKKNgnT3
#dS12ZSr7hYK62vtq4KHc37Q1GRQ72FOzkz7QddOFvUoXDdymcz1ta7rCIZKgIWmp/6eEsNKp/JCpXAF/NHWKf0d3TaYdKXUIiyH13bhRxS4/6b
#wHPe9yiAf0oSKAOEJ3gZHDaJMv50Pc158Pn9dqRa86eHYq/RQu8HTxonQi372Q23QXcm+OrQj8rGT1mu/1DN1tdnzx8JynTzy0kdP/yI2HyvI1
#HnbhEZ6R8KaZNlOKRgRxb3sF056soSenNCgCtTg3sIUk9H7aexlEBGqB6AXith9EQRZQIEPagBaPIR88c1bwj6BVteLwHqgu7lXYDKdBZBb3Oc
#bYx1AommBQK8Z2PG70wxQpqe/K6sLXwcN95YDEWXzO4dt+wZ5TywKTOn3zXcSL9/TNd2bN0t4qJUXvUIL7KnflD0UD5ckw3LLzo+QD1VmWeNSA
#FaLjOZ2IDeLEDz6b9kq0uzGgPa/KVhodOIS1tCebgs+eewt9OfWSrdTA3EkQhJeo75kFU3HaUPNyJ0sBgaM94WOzvKZoO+HR4YSsKeoVqqJDih
#o8zavCR47+hFTbwhPmtZpdcry1cnRSFHVPYpZYziaxKoleuzuVj7cPykW6tb4LUdlFKr9T8ohUlX6hNT2aVo1vNOVSounmwHx4hScO8CrvsqlW
#4KjSuH7U4wJHvdx6ctTTEqD6YdpOpumHZzVfVZGeC3lCfxiedwtOXl3dTW13F3fAciey3KJXQBlIP7NM+pcFeG4J8/bPHXn1pb19DPxR1XeizM
#0DIdmpr+SXoeuPVNuHcod0eNNZy1oj8KrqQLSUdG0rGE29B71I60LWsaV+2N0inQjtp1Lm2HY2s9k7/creoUGmXulXt9fvb29v2R9avnD0XKHW
#Z1lln2VkHUhw4hHtc2Z5Hw1Lk0Z/lQ9PIUO3aKMjbNm0JOQbkR/Ib7Qn4cbsJGV4B93JHCYGOZ6H507V/FJngkIY7FU7j4c6x3Q1nifyeXJbzk
#QBqDSz3mGyfK/5l4tLhiFPlKkBXh+IRJow+NDMd3C99sl2od5qN/FaGDAcbJad4Ck1GXLoDpzbrSsqjBH9eB6BTJhKq3dpblC0T1x4CSx/2QuY
#t3TeCNenIGI08eInwRUau2ob1+2lNXJSB+gx3XNbzWY34h8J0TUF/XBaG+2BsPpeq+14bnpP2RZGTqse2c4AE0V1757aiay3HJVobE3t+n5+/0
#EdnziI/6EiQP3QrJ0NrCYUZT3APwdiaxy0AT56xDGwlvfah4eIviUCF7XubwRQ0rYttMNHjPcymc1RhJtoG/TP3f2242897fa96cJDW1Gf3X5d
#X7j7us9F7yzhETqAo9C1hBztvr6Z/oUbTkBYgC/0InL3cT7RnrBTj6D+L/Y+OWo12ru7cPGw1Tg4tJeNfuJdPkWLF2i003Q+uddotQ+dL/Di/U
#N40HSeO8+FQLqRWrzUYBWXFH0AU4DS61kyCU1E50P3UZJ4V41BEk+slcBjabXXZLtirS47TWcE/1L4hwi0rJsX3RT6uZuCe1CwOkzcPjCPPRg7
#Z4iXtRbf9OimzTeTpauoJ3GGTs92JtPcE0o8ilxrsqxNpvZe2+lH7mRZn0zVSV70sNG6vo6OGh/sX1/34a75wEZk7HDKGF9qJ9jtR3tWq06Fe7
#3Uat+LEI6GvDFGqjhokesm6AltDes9e68f2e/dV24R9HaIb3v1BF/W2vwOniT1IT056JIb9f1mDcOWkeu01oxLmEkVrXBi98Mz9d2tloNT77pp
#n3fjxmXNvYSfUc0d3cOLtAZl4EVUcyO4KBwWpknmfijV6tg9guxHTXkIPHMu0BuncVmfNS7zzY8kUxBqcI0OApcPW+0yxLIIieNyEmfUch81Rn
#uPGpdO2sqH7IN2fjJx+MB51EgxCQIg1B7AZ0Za0vsHWtI2JI1kUqY0Gpg29GWr1n5AHemkbTdtOVHbjVqSFoUyRQ7s8CHSk0Dy83jkQtftQTc4
#/X5et+r/eFQftWwHCq+XnuWHxf3+kXvQ3N3FvnSxiY22vYKWxaMuNKj60w8dGCisVn56N2pv+fQmJI1kUkjYA4Y0Xuenkyu/1SGG3XLw46G1fp
#sftKFDoDdsjGkkUkAj7gMzveyciRTvNx3oPUe8fv+Bc3Cg7h48cIBEz9eFQ00N3mal4nzkwHoyipYUHuRu0PU1AWyveN2p1br5uqMtS5L3e1jD
#S1EoL8mMW4lZYOFuhLu7nE2rRwhZsKrValyNEzIQP/NAkAcmwM7jNP0sCYfhFFb2aTy9msTzlL0nJ6Dw4xaKspqDsnZcl8uSFeGGkWhxcQnJ92
#q0D1qLNkOLu+WPUnVScIobK9W7SOu46gLxnAPr+0HZFR13fwkXEPEDKuPHsaP8Vz99coIYoDjDMOBZOpZB8zaQfOH1SXBhzezKWDqzysgp+hk6
#R1YTmNPC7UgSgQzysa6o9PEo8MfWxJvOvagQn+TmwiU5zknQFtnF1hrQrXROJDSeCK/6SZCm6GWQFnuvvDNSLArkwVGQCPcEzCezKYBD7NpviJ
#ZkSBPRk+benHC39nz8QlOjqhtqQR+WNA170H4LiSJUSIMpenXC4zRIFrhxSFFwjGO73P6dbyjUUbmObxqTdFhK+nw+6cHi8U1jEST2UU4xubXU
#DpexuyuJR5KxIiaJsCm4uDunrlDRYay53RjFaVaMpkRlK0PWT7VuNfphOoun1AEdA9qFwN2GWaM2gp5khUAcoJsy9qJZyxtdA9J4NX0JZfj8al
#QzX01fTZ/B4ItMQWKgjpkFU2+aGccCy8xYeAb6IwYJ2tLO5mGKt0mAHR8kDRA68WPzrTBlpFocQ1EYKE3qW6y8/YV2mlVb/nklqxxb8/TNd/Cp
#ePwyJKlVaAaVhJijJm4jROIyQickKpFeSDqFiJqfcpex3VuOdpl3WRL033w38ZIk4CZUAV2++Uuk/YpGmwRMWILXwBBCb35NlktbPLJKbDLnFq
#duziyck1zklxdC6GcnfGfmvjh5cnbaoPCa59fXcNfAoI9yOvstd9bwW7D64m/buYSfS1h64ScaC8YjcpMbDgUTBL7Zck8hWxeywW+7e+meQWYs
#B8Ppjl2/tZZ51eKqFj/MzZeiCHmD5YjrSyxFXEdjLOzsDFHs/BYGSkQ/bbxpY6BEvonGJjSbry8xoCTIc+KujXctebePd21xl3h90zlFlEuCI+
#CHGBEUn+KveILBQekRXmhJU3qaikeaNfLZGKPmuEcnBbQoeKifcn64ffTUXjum/lBtuPeG9RgPCKHSHkEr053dLaSgk3GZAG/099O4joFTTWfn
#tEERVEsvMToZvcQL/d1gWU/jAZU8WFI8GLwr5aZArJSdrkpv6Zyc3tJV6S2bQ+NbutJ3WRZuNR4Cbt4t1IaNtwApZlE4PIDPoKCp5GAFxMgxns
#2Xam0lN2m+jz+fzVTkXG8hUCxylCWSx7QSGQ5K3iOvQ9MDduPkZ1gqWS+oilHyygLCvCZz68zrwRDNZqaTZh+FQCLF8BZJfOlakdN3fMePUpCe
#yvYmaVbH8GF3V/C6bD6TRcL4KCK7o7ur/vHXyvCrryy5dIOJQnYyefCLthQq9vAQg25Dy6BB0ABq49cPI68XRKqAS6ieYO8MPHIkvBp/3IuXwi
#BmjGYt4zX8yfnZ2fj82DQoIVrVoVncQwRTwn9UONlBib6RTXBA+cCjSWfOHaTwdAvldnNXdNFa3UQmWbDLRLL4ihqFng7ru6u5MpTRPyRBh7LS
#V/DdHO/mcDcJyQ8UfvDGW9KNt4Qb9mq+g+VrtkCzzt2VtahDensPFtslXaHqtH7vDnzzOg+FFsmvjgtdn9KMUI5n01Lz0O6EjZbOFs70nMgont
#FCozeoNBboSgnjwWXLAbm7mkKvcOaScQ0n1Maol01dy4Pm+q45HJkVpqFIYdJ11s/w3qPWRppFjw5H5/XKtqn6eijNX3BauTyxNAgClJZ51xEd
#DMgbKzXQp3v05teTwIjnBJsRoOSZhcG0YTrFuXbJlk7CSh3YC8Z5sWBFFfZgZ2gDel7xkZDz7ipfRStgrbIRmYcRqFUoyUIDeMN3+fp7bMKnh3
#6O94abXcYHTQKK4wjMjgiD7Ih4xY4Iu+yIgM4yHQLJbUGPI4PU1pp/22v7a2wcTEW8n66rrG+l048D7YtMjpVQ0zuewxJjON24Hw7CgJ3hxF6w
#gYEJF9z9PCK/+weDohcbv/tteTD82bjMXlDIyMneb2lzDWWV3JRMNqZ1SwntYgntzRLad5SRGX9sNkQTTiHwIJVVb3Oj0wsqaqT1zHCfnJwJtm
#2K9+cCdyCYYhpIYCXBhLAP8t5yYJkEARQ7NAMOlYbsxhFjINKGHAyYoSgiYJTneIqRsJ/PQXgGDQTN86CIKbqpz1CeB1EcSzE+e/bkIxvnxiCC
#P6WGyfbA6IB4JuKyU5kkH7GoYj4XhdIzEk5M6bEIMpPWcySPwNufesM5dQf0IjQLH32EPhYJVtjzuH+g/7iNBkbIJY3Rg5cJ+S/C1yQerN6mVr
#qQTcwfid+PQ+wqEBYQdz6dC0PRvNxCZhaLzEfww54wGGoabYeSOSzokHn45rspVdowYNBnAZeWhqyR00BjYDXsSXyIQAnzBSs60JHDN7+ZBsVR
#Giyx60LycyX9XlaN08dbgoKC1nPh1AtTctdJjWyOUpVjjLwoNi7mIYVRoHAKMEYhvEBLoNCfU6JFmIJGB3rKPGkYH8VzLDCnG9QL50IUpbGlaP
#NYLw0iC4ImZstHMBkSZDH2UpIAdYXUqBkGFfTmmLtpuAYsnUjp/SQOMySbpnNw4JgGSM9aKShVm89QEUQtOagYWHhvOu2DprP/oCmyl3n/YKB4
#Pw6gkD3NU+okDeAQqGcYTBN6+QzeDNE5TPVmToRIeyNvnkni83x/HoRRgUqECAukFXGUi0ArG/RI+HpcYOBxD6iDujmeE+EmclukoXcEayKqzV
#5iRCHHQH+JJIctNSSxOvvOfT0rqyzmKTnp8FCISZdS77Wg97AHy52P9CUCK2OFos2U5T7aeWlc/SVb4qSlLkEKYONrpPaJl2KsCFDs8UcUV2bn
#yZCWViA05TAHpVTaDRP9sasb+QwK/7Q33+VOMSLJM44VXeEmJBJ8GhJR6/404g25yFBWGQ0e+2LmXaWo5fFqP5aCVFHsDXzhayAkpU1r/3eXjE
#9vEoiFBbeUi7etwqV5ARJaLhMNGaAaOC4hUGPIe7HTAaoODTkGwUEaeU8n8+gqCX1y6/SSGCkTt3dGMOfDVM6UWRSEU0GbGj0IMqZMRMo5UTtY
#e3KVjSbagmelcpPr2cnjZ08/tBvGKaxoUNIziTiTCgpLHJQXHPQJhykNlw28pETwTb6HW2JAp03n0EiBR3PYPEUYUyBf0BmhOUTNoo3FJQBmLH
#qvIiDSm/80peJUfhWvBbvlz+Y4MWFWI4fBbUxg8QlI9PCNYlOJ4t0EegHFgDiFijmirGIrEm3dUM9hngBnhwcUK9YxMJQt/KjQzcTkFiF0Q5wi
#dtGMVm302YP5SfdRPMUlt1EQ2l4AuXMTNeftz2lrCuj90YunalI0jE/jcCp6DjK5sLqJ+4t5nHlbpntJkj558qPnUpT25eQqStLJ0EdZbMN+3L
#c3ROpkKLQLMQ9vFVc1DwD6/OcxrvgvgVBo/Q2nsDJ6kRQVoBtIx6dP48lcoXyh2k8KIJ9FunfaB3cMEtxGcdQPEvfOaczRhKbxRBM30ZviVLmT
#fV0YlVGcxdTTSTwgZgs80OuT5oLyGEzeN985xhD4P+2lQ2t9GH4YNC+h9ao4FKCi0VjAL25bzGdKN9KQKsidQe18UNJk4i2obkICMu18F6HQ2p
#ceSDnYFmQnEvqKSHRMogrcxQlRM+IHvvluGEF1xEHmUwJLCoPkxiYHS2zxkyXiYWE71uI5YqqBiDZRzysa92nhcAS4oNjDvmHjHTiHOL7AzlH4
#r3L3GwEjtRMYP6z3MYz6nGZgpG3Piy9E62LDysoCSd4RKTIlVHRhJsPKBZK8Q583n/V55Lk1PFbFbWf9Sx9tPRICwQQhvPowin5mjLJsltLXoI
#gq+l8wra+eyqOFRs/LKABUNge5vheFyDlumgZ8plWifKqrs7f39tu/36uq4Y6RAp+JaPFz79C+2MYM0Q7LtHmCTBPPGJhh/xRERlY2y8sb7svG
#6caOPaajExGSzlMctci4Ihgi6mYrwR7DFQNPQBSx8LEVcQYfdJW+XeSmjzEJMk0RaJmWVxrLcXBFk07hFPkRYssVKBVGTOCFpcQuBvBR5PAsNz
#LqtLRS62GtxdWpwn0fVk8YsQCEfW+epqQgLBIkZVk4EAifCgmkMklu8bSn8YWJ1ppiOz8pzOdh/Oa3GbbxyWCAuiosylUinViyo4r2iur9KFGl
#4NVwZPSHxZpP5JShaTEJ8Ex9nkqBQ522ICeP6SBdfVuC/h2YX3B4oAS9jgrMMnUsQyFqtL2olGIEpXhgbNrOlZv2cvtOAfCHclgRKh2EXtoBNh
#8Riwa6Y0UZFBh4JkRqfIKiG+ooFCmNnswIReMFLQSkBpNZfKAJqWjQX7klBc24uxJCYdWGFLyQO1Lb1k/yatLBUtTuXFf/cPdKxufg3kqrohmF
#Uxk6KS3GTko3gidRUnhcgYzM2+EaNrKVkI9mUh25Y2zC22LcMLTQVsObsWWrTd2UdUuDTzhcEsUyZeBGzG7ntzoAJ234x1j4qdwePTnJw1GS3q
#UrP7mOo6kySmlROso5w3UKmqtApyamzOjUik6DaKvp+1hYXO8EUdGUduwGuTnu2Clvu+LXLTAJqTQuYumwUmMew0OhwXS097SLbh7X4BEx9Y68
#kD4Y5aT2Ch09tkRgsRZ1eMv753jhLeU92SpRlBhxbrDAOZosvjJrY/rSZGEnxVOjRc3SvnXOywu0CtUxdyHaN6aPbJnX13zVVua2n2w91ut+sk
#nMQFzTrBwMjOnE7vJvORzYJ5UTSBTEMWjkbrPYMe7ehCeeXmbalOkVw43p4QE0342RdhosLZ2oH4RSYsvzLGk0IayDS8fael/m+6aVBlcIlSXi
#9JEptDLp0sLfEEBWweyoZGyktxQ1393dYmzAlQrZxILGoqsebKO8Bcf+4YJPTsjhamyLQBYajJgy///BWkxZwTKKLmaa9xHkVcmkyp7nU2C9eY
#zTbXMa2BesFuKgQV4lQ3nl+dm588OUMonJn21YqFUcs2QCgkLmvKmJlFxRj9ezee0pPFNHdBV8dr1RBgyWJHL9aXcLoVHKj5fb/FOqKt6sNBnm
#jjf6Uyd0daW0Hyw/Q0c2FfBoRZYQMoGKeZk/0uzo2eYmf0XYL1BWYUKJj7yh3dI/IW8mDLPuoYCKk/yaXkQL0YdR3LPOfgz6TiMlu/RwcGW9dM
#j0vm2fOyv2HaXdbJ8ktD00djPXaM68zfbcA5KKGqMkGLifnzwTb1nzR6OpXoSv+/ElGzGaKWkC9VTpjWRPZ0IagYfYLTFDLDQJFvFYK5Trs502
#OrhLM59cFTWCpYRe3nRuIDDuu6RAaiiM3Q3/ClSVbTrqvykZqcm20p2RkW0h0KpBLBSFKp+trAhpVpSToCZBPKw0ASkcIPSbhipZzooSflVW5e
#JIdCe9H9lKoeDNKjwxaRmDfJVYXgNGIZFLzcA90vxPBw32QO3QBbmhDoT3qd3NPbkKrUbFwC5ARQolgZRtbXehz8c6tOtWrWtIJEkZCRijAsPE
#yQL+PEY006/b8gY/Tl57wBJXaznGFWiSahkQVKlrTNh01PzWmx43BCapf6cC61RqTr5poCk58qsk65YYa4iuN5xaq7Xz0ZOPnZVgNh0EyYIHkv
#mcr6v5zm20e9OHr8kdKCe0qngquJyo6CKiAbhi6CYyOVShhoLQrKpZ0I5YdsW8/l649sU4i0IayZHuCxaJfZcYKKHMW0XIe15b+zkslZ2N0Hyn
#mUd61seXdkv4WJI2YVOl3+FR+TyI5KGQT4exOcukQc/bZhgv3T7Qpg9zLnDFL85Eao6AYbN1tCwVfQ+jLzHCFE9IeTJUgls7O5cwdLdRWv6eWM
#E2gtoyuGXfMi2HgNXc5PU5zL5mt7lUdpsfiz2ucApjC8WbBAeL2kwOysveInkwDsbURfekdOmkV0566aSjXDL4/l5Y7cP73U3/q6InlFYVeUVB
#HvynhAAfRHX0h8L1z6Rd271vZsHQdBoPDnUXMoXfO08iW2KOuXCz3YFP9CqkOVYn98aETDiwXzv5Qw0tGPkRCHUgYpml6nVAYi0yg8Jhl5EkpP
#tFwXSX4zAEmnGEsqLWPdb+GB+KfC6/k98bGfJduU0YGPeTbqUL3Ares9dbFxOh29taxhdR/jNfIBF11fBoVGZ9UZ+gn1h6VbPSEV9PnIm9ibSh
#BiKcer4fsHm9KRCOS24bN2fpFn0yFCq14pvfl2NK3H41rZiHwhjPSj67haFz5pVi48CuGLiNLoX3NNMcuOCptqWDZULuW0sl1/q6WyVozu0bep
#a+wAgj4KnFPp3zAsiS4x/coYUl6E/TdbfzLueW3t1gba32g1tZ2+3dTxwPisJ/GyuNlK1v5IBbhu+dpfE/fJiHgVcGtC/sMtobztHK1Cet9Hca
#LD+bUjF6F0CWAmrqABHP2VBHt58UWvDSudpmQolkJay/y3sA25wJHHIHKDkJHKPRXUc6F1S+buPrdlfflrw5NCHpFwqtO0GwblYeHoEoHPbQp8
#2cxTNc0UzHZKcVUyhlYgPHT9NTIEM0hBhkHbO2RNN9WOBmcH1F1/V60oIbv1Uz8bqN1+2bQwQGoMTiqoG1jOLLF9wES/Lnr9gV6LbdQc3o/xPe
#HcQ+g0ERW+1FvRcrU4ENP1H7gCrLGi18msXjC0YdkINPDARoybJLEcER6nUBEgB6VdjQkXzt+W28+eFgMDDPN72mWwd6WLdg60ii2QrwEc8N91
#oH9+432g/2a0VQ7sah03f375eeHrZ53gc6CfSQAr7HyPaXcEPl+nFqefa9vnxxJV+kwNnUC80EF6ggPQvf2z8HsiBmBU+sw1Ij36ewll3mXtsT
#mPwpNxDUxjZHoAbbeQDDWji0ECBmKw1PiYLo+BX7xJRWnrX4haMWv7w5LdMWtqbpYSMT0GmgZ5UaekOlTut9pEgJDMdHImHc1c/X+JUkT4uNLA
#Ve42c98ghMTJBVjMsQuvTSBvmhxAaLTrxhbIcxAlD5GJOaEC/wRcwLZUXhFqgdRxpkeTBlNTSYNsI0zzAd2it4pDZcCx23CFHMh3rn05iLtVRa
#VERB4Y7jrKMDwTigCgYpno13Gs37pZikm5v2P/Qzg9DVB9rWPciWrDGPNtxk0hzuCkTQcntnScDtla0FSZTD04lzzTH6HcDgnsEqLI4W4c6sRH
#ytRHFVt2O8JwjXLdirZs0sI6pC/RUoqVVQpFn1YxUFQ4Qla3Ckdut9it5QxAQ19QPO/PMxzoXLH01FFFuZcBNLgcmqQ5JJAz4RVkzFEjuqCv5V
#bO8D1V6TddQsjGD1KCuo8yk+t/j0klLYK/J2w5ND+LminwnfTa60KBozDN2KGQRP5QmsTjxmIAZrVa7XCihvcxcHtSvKrc4et603wVaEIYcc7j
#rTOLOAgm0zjzGJbUBwHPwFQQcWYPnRpcNL0dxAg3tI8JhyCxyOs3TzI4I6B/Ox9xIh6F7lL7+El7C24LuRwj/ZdkCJPW5Zy3rj0L7XaqOv2cfh
#MuhbbRjPfjBkyaY65xJzNg7rV9ty3lAtjrC1JAQGlbFl82Ho1jzY1KvqPPLk6qYRh6UCh5xHA5Ir2C6UhCM8nCeFebh08+DRIOMPr9x2s+lkS3
#e4dLIrd4hGA7cSFSRXg9WFXGpw1gh7CarsImDoT+wmS82PKI5nPDt2FIsdhf1+MLVXw2XNtbJlfbgEQaTVHV7h7VV9eMW3MrY1WsrDpJm4Jl1G
#IOHsAyOtDUnqcOCCRA6naZvrJABunGbKd+DjhKDfoBHAZIFg1z9Y0Vwei53NAj7YZh+wYUW+P5rlKA9j3qWtrpD3NmQlPCxXbjUYWfdmt+Iy0a
#RANFd2d6uT5qhfGXKeq8PNxaujB9AXG6OmyTiT8U/D10rGWdyiKCx0IXERvjY35dXD+7q8uj1SUEhBgkoiJgiMKN01DsryXeOD4hxNQbYkSbG9
#IQkiFA7Mq67S9ur9IPKuOnVIXUxamvepCd9XChq0VVognEnUP2e4hkz71sLeCP2sG2uXNE7sr0EK+iZRjTNIT/EfYnBp680gpYP7IiRVj6b8IJ
#VH53KXXMMN+oO2Sg9uQqyqQI9qH8D/BZDSSgQpTkaHpSKWddMZwr8e/Lt0xQ79jThRYvdJQ39CsCiHYaIcBogqQkFVvR+7jdZhzSI8KBvxpLpJ
#jVCn7o27w5oAnYLrXk1gTsH1Zc0dM9ZEsudedof4p4d/tI/eRKVisKoNZCp6XIlOxagX+WFFn5H/JgRmVkSYggcbKFMiVY40xYnKaFPi6Sbi1F
#oHvvIytx8dV6NfIbyXn38WpHUa+/fJEIjb3htqbt1Euq45StGbe6QmGs5Nw6ylfuHJe0a7/Z5tqmJKfHCAnnVbSsrb49daTedQW1+55P377wkJ
#J9/WrWrpD1t+e/+gaXa31P/D/d7+4H3PLOqIg/RzQsYQCEg0NXEZ1+2egDN36YW38QImxdWz2EPoQS2Eh5zh3UGF0uePhlLPHBT0zEFZ/eCUJT
#AkYjPOxN1bhK/2rLO/2Duv2a/29hrBMqBQCGSV5YxCd3JsSlPisHGVhZMhKPcTyLZn1iZnLdDX94DoQbnqM2Z045vZ0OzQvrbCb6V90DTxnUFP
#rKo7cHfT5uotRwrbgZnou2TJqKAWTxgeghi0uztQ2JNYggW3PDDwcchPE9+Ff12N7661SquQmcq1QomqZLKaKhVPHazXgfJ+Hq9zIttAD6ikUe
#gQwhX8gfpG4TFcdCgX6pGbAChVjkOb6I/R1afBxF2tHSC/cAqqORmjRFdP+0u33oYLxoOMrj4bDOgXtyISmYpNx+Diw3laglaIrp6j+Aa6vpUK
#sKX4WXwpASDy2OJnf+HVXzfrH7z59/U3//28JiKNK2imXKi8eowB5MX8Ql7puRgRgwvP45en9+rwD1SH0L+7FxbjmC+CRbzxEFJbMfpPhV50zR
#eg3rzqNe7JpDlMFJ1FYbXZZrVnr6xXZ//j278+P/uLV/ar8//x7c/O4Zm4kp9VyPA//99fXp9jNVgLDbz+vmYNYM1+1Ti+HvDfAMkYN0ZepXnb
#9Axn9bff/s3bb39+flz5TdfsV3Z8LajjGoT5maHeevN+GF+P+tcH4y1fL89/2J4qK9YJ13tSf5zkNlhi2X7mMkFYk7MmrMKP5K2XI+btPLq+hj
#+509Eze3d351l+/8i2bc/FArQ2GTAeE4XgJ7YWjHpOQhomnuekHSBGMXpFBLvo6gVZFGTLrDLsYA4bGE0RN1AAi2Jy1RvJ8avpnl1AtJy40RRk
#Alxu9v7Cso47r85e9Wsd+AfXZ43OOVzZx6/ObWC+MGaNe/bdPVaxJ5WIlLhqQBe0i12QNy5LsXHIlrlW3Mzae3VmYTUd+ivqpWuseW8oW5wvO1
#l6tn9+LDC9zGbDrNETWPn1cGkdkQDetc5tFCXyByBq1QbQ3djePDYdZtZRJWeNrH7RyNQZO74XlNM+hpsOb7xsAFxFVz8KMksbKBzatZuzCBDz
#JIGxmCEpk/jd2fhcsX9xr+GfzoG3g7Tcv+KwzkGCwuxHc47baB9vPrOwX1T+HwuLl3nhpLsIgTfX4Ozi8TG/ksh29NG5iKIhavLyIIMtxO5Ryc
#Evlt59SwZHAl3ZNWvB1I/7wecnTxEcB1YvkP8XCv12F9b4HnBkV63xUQJsodeYBtmeN4M1XiFZuXpQq6H4nh9bmLtmQnccm7ULa8V+K1+RNYvH
#9it8kwosWBiE4e4uiFbQSUH/GbEk22eaGiosPr8UViUp1cfQ11ylXolTqH/NJkGMWBum9Gsltu27STFGjN6W9R/QhIuOIjSFWPinqLoEp4pKwT
#w5akKTxDzCsyaBfIwSugUKmqDKa1B/63Bj5/K7dbX5llqZp/CRu+aJKD/+OTo41BuzLkQSkryTMhc+SDQaEtlypmF8HN0VFO8KfPhlRrtHdChC
#5wELL7KE4GF3dQmklA2xnW/NB1Jy4aU/dlrtJr9nw02tTH4k91aFiHR9vUPsAX5Rc984xfXdnEU8FoHNQzSeqpEUVWu0D+WcCl2StB42j+utDl
#3KU5UjF6RUUSEop43syLdDt04ItpejMAowsu5DkUBFulEZQIdtZA9dyFOrySJBN6QqtAaznKcJ6i9Y44jQBwhhwqI+NF/f2/kG9NNvHr6Qmvk3
#uMPz4uyb8y0eDd+g95Pd3ZJi5kGKh2HBnvrFGX77cdhpyjignq21afv24JeW0AEZAZzzsEEujADbEt1rHNQtTyhLp/GsJq/59V7bpuND26xcc4
#R+ttrUz5wxormGUnsrwd+y2GWvSJiG8ZAk3tVl7q6Upit1PcJaLABujgnzljLt7lqKNFkUtwtjjOVC8q6u/VFbukJwlz4k2xpGsn9XKgVdbThy
#3zTTzKnomeCUcpnWAiwJhYVPGUhzopYU2qsrE9yZz+RcW71D58jGP+tKPbzc1me8TEYivuCsGEHw7ipqpBxLVRwqBXcIlwsfo1ss/Nod8+0vfo
#Me2bOyx947EmuTdzk2dHX6GMXNhGkYU7LuySINRjYPdmbCxWQGfVbiWLKXBX9Kg2B8GltaUFDJP2ozLXwJyGhEArbDHnmSDgpBu/3s41TtHlfv
#W9Dnef6GLxaozpAw3fDCqhpqyu7sN+mEXtt7+WwWTK2CsaPyWhL+NsKC784zdDw2+ibD+ZJXN8M93NFpiLZkOQRRvq/TlfutpW+imBZqL7ZgLO
#MloVfnow/TMYmmIa3oLUHdn3xROirZaraC4YYJVcMy02Udq7M/+aIxi9PsUw76xW3Qrdtls8SRxccw/VI/CdiLsvqNtREQTR5Tf/KFy1YBDdxU
#mAS7u4XbxmXQQ9vwws71J2EfIy1qrEUyQW2a57xPbYVXdLYkAoJoYkJ6l16n6GpFcnnMzhcr2bxuPgx/ulGQQ6BKHKguFmXa6lWwDG8YgfUPuH
#1QTcWRHVfKB3YYNpsV04BmsE1xD9NO09zdJQYqvxiHVdW+WWjeVDaezE/DdrZ/jqpCdK84zRykvWyqsS+erTx0y8Jzyify3HbmTXMoJ4DNtBni
#2KQZ4aFR4s0jS8rsl2wH74owrprPEaUTD29OSimnoPOWUq6g3clzb8E8ZUreCmtOjQH3bk9db8n0HPmmsBjA8554LBuSh/LxhQjKy8S2KDXFoD
#gURSf3+xTRdPi0viYO6/faDp3Q1+QBPUhPa9FXuLJQG8k52hWUyWuQcuOoUqSxHX27uD4VLXP3Ws3mvT4vRWv1apvzaDEve5J2f7BJLCAeoYuc
#bkqx9/T5i89Pr0+f/Pnpo5Mnj65fPnn25PHpXiMLKLCQKDfzhngIau/u5o+uZsFO7lVdsJYKGiy3mU9S35sFZnnK6P5tm2kvcOLYF6csPhObLO
#TIs1yY19fq5s9M3EgDSsiSiMTFHYwSmXny2osyvmQRqyIGpKyysLTktQ302j5+p9oqq8H6j1VfdOSyrleKSbCvRWWGWVnQxsTcLCJvfaS3/tk7
#tn5DvHc3JX5p+8ySx8brYwXvRcCchCvRUc8IdIue2fnyqM9SWygk+YPNjxTynP61jv61iEi/Yq3U1R4eNw479cZhLvFLTVi6/8hGmjWLch81j8
#0ahYZkHbdg2WKURJLSECKY4eUJQVvazBi7N6V8FgxkQuCJbDJTPv1gMMP+nPEEyR56OkXgEUQcErEQviDJJbVLZyJCEFC2LLpQOeq7N1pgkKQ5
#6mszftQvy4pZTz+JSxfujMz8FkOK1fphvHTvNI2m0WrD/3cMDFfs3pnG0wCxjJN4jGB2zM8fM5gqP63zIf6dVuNQPULUWeAbaPYH/L7wGNUV+f
#zIrM3Q6A2acKSpcJ8++vOnbrqwzIeEWwTNguZc0V9R14M7hjAZwMtkibXfv7N3BPL5yZOXlZn3IYHMfr9xkBdAN1zEIRTxcAYqCawQdz49aLQN
#yPXT/UetxoGB/6h3jMPGfbi7/8kHpeetJlzuL/YbB6UXHxjvNx6M6qKF2mEGrLi+M8pdNPq3WL70NcsXH+5yrXKEhwpyX7e/1tXhyRhHHrHESj
#AxWW/KwNhZb6LQbzFcHOEUS6QnGeLed+9gzM07AqBQIMZsFolnOrLYnir2BSICvfkOhOJsW+n+KFgo1Gx0/EJ7mWES9rtKie0kcYbqUOsBwiHb
#36stA9WWl/Nw4d3SjmLJ+qA9Fh3qV3XoSNY2UrUJkJ9ttaFr4w21nYja0MD6C7q+rKh4qmo7gT6ehzhMZo0mgaLmtnF/9IAIEGdcdZflZPCI8E
#fDBMvB6bg9z1Ll+Zgij1TUDPMF/kX3Gw8M+PfpBzAx4P4ZPofrcpvMDSME+PZ05gI/2zB8nnHixwWLqYHdPREPLOWi46CcGmAwUEeD8He+sAWr
#lBZUz5zHzglx03Rmw3O9YHjSLZr1h4jdln0YAHEG1qjvFN8OQpBcKSvVsreH7pN0YkrIWHuGJ3oZ4cf68bwXBXWQGS7mGNYFsf0kNi43cYtKks
#uOJLdxL8KS1SSZoToOpkOysYNzyvGcRjofViiS/cRDVxPZQ5vV93sRiTiq9j+uPoQhFtV9sTHU05KaspE5FME9N7NObsvqLbdlXd6SVcKqQObb
#9WPJ44tKMmkdClcEG9MxUXNu2tVfkvN8wmfB9C3zGFe9Dk7UtSS1qbcIhxz2ZpYzXyC6lNlfPscu+4XTNbj/bKw7Di5ceHQG/8TGe72lAi7s7C
#xAvluQEIwBBUCMuL4W97u7/Kt5628C57Bty11kcb2yIooERemxlJIX0zyhyrpw0UBJt09YFejg3sWGMq7KPLG7KuZ2XtGgqiL66rLxOn05jDjt
#HWEFi7yy62voNAoQvKjyqhZuO1vjAefNGZWaI5zd5etJ5ebruyvXE4z/ytoz6Mwi7usDhP1+++9+YbzI4fN4m6XovYg4dL//1c9/ZkgAwwkDGC
#LWIaffRB/BPG//5W8MCc9J+5wSfsB4OYuzcHClMk8JkqWQ9//4R+OFbrRqfdxq2Zyhaq+L8vzyb40/m4dZpgAtq9OL+Xp+zuSgn8cRJShCrDhR
#Qsg+jR67ipa2pZUk1VXDXH1OVZ4Ta6d9SL59trVpzquAIq2PguA1fG4NtIlxOIPpHXoOw1TiCNmV3qX914/Jzu1Tj0gaUQVfP3WbTv/1I1fG0u
#2//jPiB/LuRzHPEj75g5QPD3Z3IZE6oYZHtVoXnzCwBDZb35/vv7ZQFnAIqjF1V2tNrUHtCl/WTFDiSuBEnF7uVEPTGX4rUCdMxoskRmzPBlBg
#HC0CSgPzgNNo57z4ySKthefBThJ8Y/Nmi4Hfy/zCUo/UaWrPNb/6qv8aVM1aDXoKxJSvzNpHIII2MESzFuN3/z56ZMtgccqewZuFjT6NE5ktgr
#oD3yrsZgyjZEGxajQa/M1OPM9gveyYaJQxMx3fiyJkZB2/pyHsqDhU8wabA9BkTglvRwWj0sxqt1tkA18KZ5nw3shiZxBO8zMwzbYadEHFMSGN
#ZJaYnHYLC0crWQzSEqxdWSDc+c783nk39XPHViCcer2LFGZJG0eMGFc+i1lhvcRbv7Gwh5+gCaRlCvoH5gLL2yye9hHfG1cURDUn51guMK8cVk
#xVGFIUkHGD7CntYtHiaUOs3qBawXMMV8BVIm4omVUiuaVMbk4f25dafWVGCdzFL9pr3vgZjDargzTYekHkcp6TmyaHjgKvJKX64tMlbAt3MNke
#a+cp08Ekw4DYwlUyarD91McgonlAEoOk/vGJ6aymqHHBLO6YQMAzPPjAcEzhZD75OPFofn8UDsMs7bSYMjEzGXhIBnKVYLdbfbZZZFu5pnOg3i
#PNTB/ptpp/cnPKsjGhUK1O3ZUX9eaTjvkIf0wnDTGARcd8Sb8gtM065pMXMP3gy0N88ZguOFCHCts0IkNTsS6P2DR9EMUwtune/n0gRAmrwLYB
#KZq7N/fuN5UZ1ugY2J8xQjBqHt3JRrxweI8CbmciLkTM9V4YgwYxG4WIZZ0vA8bHJxz/8cnznPVPYyAuvZunOFhR+BpWoecff6T34tmreXO/2a
#zjz/0BmY9uN6F9ZTXuHb+yRaINy9pNo1qxx/P5S3cPz3ey6wSpd84/12gNDz94LupfY8fHaYgxWK5f9T768ave9SyJ+3NfPOmB9gTPcNyChAtI
#rvvz+Brqiq+Bdw4vE8idXNM4X6OjMJcM8tG1WEn3wo0QspfQk1YEAg/hIhWCuSrObtYwQc1sYOJZAL3eiJPh3iWx/NloBsuZWA1earzZWvGc6Z
#gk2psOzxhm9KbDuF4d857pDFGB8EDs7whbL9OhyTxME77vYNtq1EzaBk9gBVXRA6hjKXINdSeaE/B3gzjFvWVg34ECDOVF4SSEJtw3HehcIPlg
#iUZtWXodTgexiaobPZ4nEUyJZQirVdwxW3gNYx2Sh464FyVRPJkkYNjxFN+tNZ1eRvW0ikaJtrBAdKYukapFfa/hUyD6mVtEnrO+YRVpd1dcNC
#iVzUh0bKTmOWj177GGVe/xr120qkVDZK6gYD+biZbMONKfMG1oiP65vlaXQhR6+KCJqEYl21k8rUDpDriiNZUWpvugNmW5dfEUmjzNbzMb/tvd
#hTnCJz55RZJ/Il8RENnKwpgGIk/K8w2RoOAhnpfOEUzduo2Cj0GtCPsuiCrUmWHfdjDdWkZtL1gFbhgqoRYSxpaaN7kRak8MO00uJFeeXNinyh
#+iVwyvi5ll+G0tLx6sc/SEQupSw5A/ajqwHn5V6YQrDf1ESfbS7meGA1zAuGNurdQz0ghnVRrh7A/RCCt6E5WxR8SmPrzCTV8r8S61Rk9dXjzp
#MRGnbhBYFfn5d/8Aq8wUFpHf/bYi3q40MgWBXTCdPWaSIAdcdKYOT29Y6B3PBZUSty/wmzHOZm5I7xXQ1xB5CvjFfOFhJGSCsNfaUDCdMrTPtT
#yEifREkIyKiLxCIMMIDoGU08gnamsPWgJ3Uh903LWgbQTapyjtI6hkC3cFTE32hISvFEE/TQcdZICl0sG+gwXRVBnG1sKucIv0tD7mImEihn0h
#qi3oi13+8O6iAYIP3MBfRIX/agnzN7/rhUP9dgIzGNY4PAZYNAagBmIpva/gCu6nPRJx+BEthmrAiGBdd6FhGNM6wxNZDAEC/EwRPXq1aIDQ4f
#aur1k/qCpgXXDIPAPxzYEqYUGIzsXHS70N1Brca4iCvnVW6pCauQcZgfCY6NqHQHWbSehTUpUKY2pWJcMg2BjjUqVrr+1z1eVQjwv/QPP0snlK
#i+k8wtMvyHFs4RtabnJ6Jwu+JUhSQBdLXhscr2MtG1zr7q684s7DUcILJ6Q02GTg/uKKIfrU6BWe2pCVaGBt252zc71X0yCYKnx59SXcHS78bP
#kYfFP+GN2W27oCCQ54Shp8hXZnLChShPYAZV8vCaDdGylszah8JQHlLdEzFf5XNfParC0JZzXpf4UmC7TfDp8kALYlrxVgoPgCDzDHSmRmIxrV
#Jwtsk5sQ7EHVZycSfj7/bC2vmMDudoou+m2WcyxQXXQVG6qeE1tYEw4YciYab4fFjD+UQbESA4VRMR3V+1x4h/7+sRwL6ygyLD788fgXffMJct
#ITdM0si6+JYYkEkHAMkph7cnrm6YSAAZtZG1M0TTMJCpSTy9MnV1cmeNqvShL2IcEVLGXuVWJ5BcpFHAF0t/GUxwE8oHhr8Ih+ZQs4yp8LoqS4
#xAr4irfwc6YwdI+GDSW4sp19Buq/J9AvMSdf5TnzpTNLhHh4fa0uH1rEszkT6tU2OfZQoRXDgmyTkhZ5oi0IP0s0mUn3uc5GasgkKxL3+ZDJAa
#fyXWjh92WDcqyICMNONlrb9j/1JESxEO/nuWaMsQm8pA98E0o4gj/0Yd5mXJVhaCR9GdCYyRJjGjcwkAo/pdVbBDDyVIivDXQjzFRct4+/fhhO
#hgZu86jsxRRQkOFFUOMdQ375nch7fXXn6OtO6OMBmK8CYW3gJhVbtAVFCVv11VeXo6tjjDojJEaQrygnvbA7JgtTgVmzpHgBaufv/iuKdINJph
#7ijgUKIWSXo8KMV4WZEWMQ9SrGYKmBVy43VkrF0OSqsDlecrBI+IGOXWpjxYxK9PZS41dLnV/5toqaw6fcMj3z6urR9TeH0791/FA/3zqCxrba
#Sw+2Di3wv+LKjcHUik/EQGKgoLsrYMzLasa8MZrriuFMsvRDkBv4RItUK3wkzv/wUrA3jFpfghkLfGUFMvGSYTitI8xf62C2rAQfOxIUmW4BHh
#smfWP0mqhbzHNLNSKnTAkQ9nUHfUmkjOWfuhmygYpa766ytVajHsc8Hc0Hgygg/FlG0YjUWQm+471yBEmHmy0W/Xheho+syNE2FIvIMapUhF0v
#h7ESSo+vuwwJWUKcZEKvyuVHaOjA192yaQk+vHP09l/8tXESZKC+5WYaQk8mxmuv/Ew7mcZMtUK3QZoedNzsCE8FeYcbuYs/wsNLMnTgGKIdgw
#maSyUXl7sr1oqOy9N7BuKdmJsXcmYsFNN9LIPnpSoOZ06yWkBDTQMVW7iB13cLjfdGRcrzYG4rGsXmAac+/jrH8qgTPm1nnkSWKZsFSey1aVPN
#d45kJtOs5N1FOp9Dzz06OX368vSJSDJqHemfC1OTtHkkyFYxL4jDKVeH3HiHnKpwzukRayENxQFD/s3p7DUxb4FZ9zVzBKVFbsmv3q8N4rfak6
#PWsUlLwVovchML72tFU4JF7u7uEKFW0ReOUxGoj8LzmjWJ6GdpgHqahxYB3eQlFEfaR7OwEpnBVGSzLm8WKUb8jIys3v7dP26ziwp7IlM6KmSi
#UIPRm++8LKYifv+rn3+7rYyhsCfzBjH2cJh+HEdRfCmp/Nh8+8u/wah/6TzE7v2f/+1fGS8p6p+Zx3TTenZvTzsxEF3RQ4hO0emo2bsuEHCAQQ
#b7Nt6bxeCcRtTHqYWzlmyYRABvVSrQocIwzK1uqWhpfI/haF16QjA0akf0gQTwgVpLIUHvrjATEQO8RcNsDJwcmXIy8VSQJVatgj1YijEllrPB
#SLCbiY2ggSOk5SqYplV90rIOKqVhxNDr8zDTu5qp2jMoHs4dvVkIxw/rvwj9dOerXuRNx3cM1FrvTGPUBNFw7qWMh6wd5ViiEY3CRv/HJ9CMJ8
#/Ntf1wz5NDrOyct42bQNfXTo1oaw4Nk2lnjkLJ8mra0EZxVHPfdZVut3GVvrvCpdMyP1QVcejWMF5rK62gSBEieRbP5hxjWdvexB0N3Bw9xiVL
#EEpHYS21mo723L6pqapJp+XakGtiT+E0S4BpYFL8tahoud0+tR32eBCkBYSU13zUalaQlIHE1CsQFn8M05X4MPOnMcbcxIDKMKJ0M4vm6QZRbX
#Qbb/WgORcdVua95kWuJXeCWDHVPf41iY4CHZFEhyJv6YU48kTLy+E7lrejykPNr/RClaehOOAxgwWivjN2MpuF/puEQjmGmRixXL4j4U4oENYC
#w6pDWR0sT45fq23nQ5dXdNRqv9vIUch2HDeK2V4Ys9N4nlFYVhI2LLOWF18z7RsGsmPK2YU9YXmRA90XwXqJkUF5X9Ou0at0SK9eThEBjA+nKZ
#LwkxcKNHXHi5Qj/k46zK/VUmrfOjdkpYXuDSaz7EqwDiY6yTQaG7KzaItF23FMK2Ju3l63NGvSYq1vjPOGHI/1VMjwRGO6vDAS1nSwgJeM7bRp
#fJzL3PDHadodPSiJiFlfDkiChaZlC76CAgBlqZSDuGx6KJEPOIZW90Vj4L7gSFoqMqc3luu92imCJAgjsxLmNXwr/WNAHpgGJBIQKwHNfJGfo/
#AKseIcLoYAWqiAXJxsLQJd0V9qCF1RdEzcTxO1aJKHqgF0/g6J27ilHKJvEQa99d78J6AYYdEsIihT2FvRIBXuTmzSVMTk5W3Sm3QZsT32z0Wd
#YUZYpc1s0zrQz8s9481KfVnTlz7oX6JC9HzSlx8hXGOYdoc2NY9HE4su6JEltzB5SrKu7hjA28WG57lk6R/GMR4o8l4mNFxBWuG+gL0xrTb7ZV
#bSlHphUVGijRVdVSoqSXzqAWqS4dNp6R49AE6pZeB4BUNbqlFcJCImCFCE7UoUV2Px1rPaz8DDic/RcoQPJxQ/0ZQsuZW+TcuCwuVXRhhuJ6mD
#luPjFntjf7bsDoD662n4OhC7GLT+E8MrqVJeFKJYWNpgzLe4q7YZ5Vtbk4TlE6Ft3V0hdWnbO0Kjw6dVWhhH3i5rYTTFjr/eULiAhSuFSyrVnX
#9eWlWuDlSKeUXZ7mu5psoFgyIn3rh0MFiXvnZ0321hkDvS6Xw4DFKOCtM3lY1vH615pRMIMphEHear3WvISpFk0aWCw1XNh6cO/HmOUavmw6dZ
#MMFYa3j9EvQNhPFR7HUU9oOX86Flr+BteSNqRBHTuiqfDtjsJWPOh0EFMW9V6GFoUY4+b/UI8WRb+GFECOKabB0uASOuYEUhfgWxf/VJ9ChvHd
#k/0DO12aa+TuO22FYNOKZAzaAHaruJHAmASyTIFk9AtgiKJFH5Dt/cycu4UwR0Kez1pxOPtl+2bvVTgnynmCaSziBmoyZtBGh7RryfshZRBnob
#W/0YgABLlV+G7XnHjXssnbKq4AVb4sQXaEciZQjy0Vdz+Ewim1DuBXiuHM4zAZbiSQuWfPCQlms1nFEXKnazsJAQz3rRHA+IttqPiGRb46dLy+
#+C/TLOI4llcOHqtWvwh+gULU/q2jSLsKlVhCd12loNE4luK+DO0PlwKUjdjSY5wiAHA4pAO6Y8g57v7la0Fd5d2HIy6bY7BW2OSWAHnY9046rc
#IaG7vSsrUAyKdJEjlzBlbGCXTRUxSISvEm4B+WB/hJVUOt4LVmDxb61lvzftKka1rgI3oAI/n71LcfVWbXp7gU8oFs7uLueh6NAVJctpIPjd+g
#bcBTsnpZu7fxD781SLq1rsyUqayHFSb5rAWCu+v9X7UJr5VYT7wJWADf1u6o5aHoI+5IiuN4DE3Op4+MMBkJjqvSpP/QADACdGMByCoE5+l4Fx
#+Obfkp7yu38wvNdBksXG735rWPHcQBhL4ycxMJTQroDR917jcuu9PkUvl+zqVI8oig90W8N3ChIm4Jm0WUPlFKaNCCQmXmih1iYuum391V+aDv
#78I/y8/eWv6ebf/JKf/Rd89h//mm5+8x2/+u/86v+mn5//h6o4YO83Oa6CZjlwWzCwbiGmlz9YYlAvHX88mJyF7wUStfdcBgKrjvtVOgLDSCY1
#c3HZrddTfNsqBxZrP6BADBwGjEI1NA7KSRr3N8M6YCgxq1gZBXhpN5t5gcmWRB+IRP1guBEAYvMTNqr/4wKI3Ze+L/mi07sFVqCnj9Cs56F4ZH
#Z7upz0JJ8rYvvH2BFyxadPTh4/NT56++0vPj99+uzpyycnxsvPnn928gili0f/25OT08+kHGHeHGmvt/Fdvfy7Dg7Ed8mFESXs18DStjk+asSL
#ES3GDw+6Y6DdsnORhJQtNoujWhD00KPp1bugDznje/uHooW6GMH8ALgc/ZZ9m/LYfmIWO/cPKwP7YSuKgR0pkt8PB4P9/oMWh+4LYOzxqt3u7w
#cBXnkPDg8H7+NVsxncf//+DSH+2u3vHeKv3d4e4u+wWXr6QfOPDvFHviDoPTHAydJ9XSdb/s4H+3+S4H++XCwLQQDLDOVBOQhgdYI/bg5/IIIA
#ShLfuvwpwVVI0yJD16tYztORhyhdHLTBKwRt8Mqqn0xbJmZY4KDw1xtkzMtfC4MXwuvnCvcVn7vuvi02DR8Lx4i33/698ftf/exbtX0N6Y7cQ3
#tF5XTFiim3GnElw71GL1W8JwrQOiNB/1XgO2Kl3qGoGHlYqp/A/JASnlO+IjGy4pogfhwdGOiGF7hV78FkIh4TUvSUWwTj743ttSEljxksSdAq
#9G7rmB8UTGw79KwLjRpDkp+cjcPz43FYa3Usvm+eH7c6Tdn9Y9S+f6L0ZvqUjUH4zXfG41wIkrhR1OuIEkjSlVv+z/j0s9Mnn58YHz0xTp48/u
#zTTx89/+jR6dPPnr+sSKv2ND569KX74P5BcKjsicbkqkjeOMLnYWpr3mYGu5/J5LibLoLo0iX/XF+vvM5q7WT4Z4B/pp2mcuPrB753hbjmVtwg
#Q8t7NK9n8aUFDM3KnX7rkMDLrq/zJ7a9Z+0370GrbdUEeVaP7d7ZsXh/n3f27TNvDM3XXKxPXeDtFJ3knW0pBz1hRfn9TcpNcscSwrCRhsOpN1
#8affPNdz7MZzx/xl2ceRIYoC2AAG1YoEs5hnyNR3nRm19n8nk6DmdG4s0oZb0FApChCcb+jON1SFRB4VasLW6T2SMrc/r2SjvwADbEDi3jIiCD
#PChxYvdFwzsbn19fW3zhrtJOk88xBIFgGY6XdfJxgs+GsXVppK3YrvW7OJJunqD7ojGt1bSlF754mr0Aua0AvaxaEfYF8DK1JzsL+9wgukKjbJ
#jHMIzQEjR3bYTOAv4ukOwc4LcZUB/NwBhr7eIRf1poDcIUNxZ23Fi48Mu3IdyGFLhd9lxLk4rGykMOZn+KLaFSxnJpO0IhCu4KNv/Y3uV5Y3qv
#FbT2a+IO2wKkjndXhXdX4l3uy0vhBOU239g9UqdSGR5S0U4HH/HoQg1tJ7OLK3QtUMkqKw6WA6s99FN/nsBfGoeg3+FAZUGS8NW6XCAhxflITB
#LMfqZP1Lo/gwHHKDzNIjSifwRvoEKbf1yfsSDhDk3E+yowwKwhWrK7yymP8lBUbeASnOH6+oMPPgA56MDGL5NZhIu8oih4k5VD/fbpjdb6EuyJ
#68+AxheumE1dMbu6pdnF3yQrJhNEHxsGreZG0909DJ2+YjLyG0RIPFBrfUcCqtvd3fHxBGt3V+9K6Mkj7ElRKPSqXhgxAlleHiPImIH0kQKzTX
#Mki47RC3tRGGejN79GHbwmWU1qWP1gEtYXYWDsN41vbHilciGMTZhKVpP77pJglur69iSHvHDUSWsuNPX7LvkrOpcwn23NgwW5tHRR3BlfX+9Y
#l0fNEkJM7E4YcQJ9TscF/kN5nUug3rCP60zcuKy5lxQVqo+TuO+G/e5EoDXE7O2PQKp9xJVgHwE5qTKQsEAsQz6yzybzsKIJRJVUj++KIz3Doh
#FaEssyywS0WndnFcVvMF8fearlE4sFXZa21/HuofvAlm1pYVhHao71Eg0+QOwRe4qb7QZqoJRFB17g3XnqmFPH7CwluXR1Nl5IVdYBZx1w1gfO
#APqggACCxxQTmd0+L/gG9xqXda9xaVc4YMqDNyaQMVD+VE5OvhHF040uoxVpRyZrbpytY0EY8JqeyGTywL3snWnd5J5ZoDreGN7PHT+K3mODCJ
#a9pRSollWClO7/g0FDpn3cIsaMIGZQJUBjdDtGmcJKQKQEEYSe4LXwG1QuzXlScVV6ledBz2eZRtoGHuPrjsLvN1QXud4xbvV3ml1lRlDowoLv
#qByFtQLBiMLey3AojvMKU0+euO+ZNX2uJUF/Dv0ElDNDtac2K6Z3cNsHsuiLcEH0Uzvbkh9SO5K5QMoBvvbmOxD93/yarNQQPFQB/XSMYeJl8z
#BzjKZxMY8zz/gynp/Oe0FB4ELDqxzd3MHbL4Bq5NJQIvDeHJTRE0hjwVTyA0ncspCiI96mAHTi0sSP284XruK8Yv35Ij8XKZdCgFtY3+7uSWFR
#OcHl+fAeImQE+7u7II7VrZMG4Yk8bLUhdQNGDENP0LhZ9kbJ6utlWImSM9vEW37hfoG0dllyp+yncn5p3qnwEVLKecBWEdx/l4pjwmzmXIpVXD
#ITukQWJMkx7B8jug+uMGsOsWTnXpPK6kI592txyahlpYg8GjSPjIMTpZuutRbnxVanIJXpXrFpo9Ivtg0CKbv60nFQfkiUI8LDnV1gD8T6lCvq
#F1QddM9lAya7gy14Cj0rXxdalBKTdnxv2tdAqdgmiNKpo+OUTl7xKzEcjXrsOd/I4w6uh9xHPSo2F+/0kLRYF63XlAgVQif1YYUeQK91zs7XXb
#+R+jXXShuXGFfyC/ue1ap/s2fJqgVXaNsYvBYzMXJUKuyzqPhUFO/49rrYVTAmLi5ElKy8FrEwfgX115fwx4Y2BenIhTySTnzQJKm3+TNB0G14
#kmUWwrTFs88GIFyUxnzDp/rBuwx2kcxwiVeDWVr0JfXuN3mmZDS6I1io+ioLfj3nceCqxHJlpmKleMZU9nQW3+mNAzYgHfScqROPc+FNhM7LET
#6WiPAhzC8wi01CsRbyzZ3avSTwxjJQjQtaOSvlzlhG14Ec2BrhpAwCYTzGJU3BfdBL4aisQtWBjJ8HmEPcHvyAvT0ErfLnszffJZ48JYKhfvPr
#KNDXaW/ywuW5kAMnyelDw2yJSQQd9MIliikzLF+mRGqRUpE6GQj8cgX7Io4bzzmdnaj5x+ToATluzjuNiUk3Sq6eXjO9ZQludGCANmSDdonGoh
#fuJhMrlbqFn5XgAA51dmYtSw78XoStADL0Iuerr7wOT2JizDewu0Fcat8WyVSzPKbaBqUWk4Rajk1UrOoMht+ZXjowSAie8ChyoPIKCAXrTL9B
#mgE9R3uCtFF8gsNuY5kvsMgXOOH0xXAURIsgdaXMCMTaso1PwyWimn8TE+xGa28f7ZGgsjAKg8Qx2vxgGs8XgTcv0vApCB+TBsp0yOJh+Im0cP
#riNQ0w0hUtm/sw3Y52mEdINIBCr8DXnLrTy63F0STA4jy9QGJDleVNwiV+qWhs25VMAtsN8yp/gBWLnAyFOGgrd+1pW22eosqs7qBw5gLwSIAj
#sq3GrSkGmykGeYq1lA/wpeRg920xciJGJojFJrw3BR6AqY2gycER0w7m1xi3hO6AIW/bCA7qBwaq5Nk818nffvv3RQ7y0oU/zDQIboo5h7US1V
#aXAnO2MO6iPVyAGtyhGNchrBHO8KYhVV/Rxq8omrUURHTsJ+FoBE1XwgS6GsuUasjlA9UvaMMAuTCM7GZf95omrmoigdaV+7bxnOdF9uY73Pww
#Mn3/w3potA7QnyC1tY6NREhqlI713efWwT2x19zI4qcvP5OIgNp2nO3057PqNVPgZDyKqIutsjNH7gzMPhz5/RHI3JPyw4d5C29ojV2ScPQSbg
#QXUQBXVfgiywYwbUISuQFphLbx5rNKWBF8XoUqkjf9IB91RBAR83Fz4KETTAdtigUIR6qm3A3DbjpkWtiBkjVSObCN0wJt8DaXXVDeXWDaZeVB
#tXRwQ0Mhn2oo1ZC39LSiaQO9ZYe2oZw03vx7RDKHmbxIwkRrGgLslaSQ1oESQ2ixBSnEISyBDgvQNFPy1mMJaqIeVHwCJtj2DdXtk1+DObXvuW
#8bMDCoZv/uHzRO97vf5rxBBXZWGseSWFvF1AcqDPE0BL5wSd+TK3Ai8VYVTmjQ7qq4/T3tgPbrgKLbkcquI4pal/Y6pKq7EbaX98jxpD+cwrKP
#YGr63kC+DZIENGi4D0B7IdqugIjzo1n+XvUCeqV2qbXgMmng47vi5vqO+MLdXbVFoIYYHu6ozYaV2qygTxIQHkUMNonkYRjlRrKk548Uj7h0ZX
#nd0i4IOin5sGxf2puI5DmKlR4HrVjAuniWgdT4EsYGpHHZKSnD20CpaByvwOPwxpIxu83cZclEDLWa/qBbLkcSu63ALsr+VNiCaogEtglOc5CI
#d0VKALmaDK/X23y9tPYJ77F/guaJVv3/ECF/WogQTgWrKi2kazTfqsQNuQH/o5pORN+bZlc7CErgA2MOR5AFyIpjtJNDFtyRPsGaJ8SMAGkU6r
#nt0Fo6jN/8NkuNXhyntMSKbdDSHmf/9UtyKkyszJlq50KbW3fq2FntxesOZSg7WZXofVu20oqb74IpjdVeV84NxZ7Z2WVj7Fw2Ls9tHfc0RIkU
#5Q+hTqPmnHYKRkc163IsN4XkltBx4/0Oi8Kl/SXcXsqFnPcVmt0SPz4/Fksy0ABX0jdQO1Nf4yJHrdI+C3T8qh1IQnoR7S70mdfYvh2VKEcZ3V
#C9UiuvAMPDLSYKS4bN3LJFBULpubZHxbtFjj/N8HhMs4xL3GY3Qbj7fKPo4bSb1Gp20XYOv15ZWhfSlq1ll4g0iFrPWcL+Dst8+0j0ZCK2nrDv
#pHqkNqGA8sceHdIlYriYDefYedfXFnzI2dijgztYYfMKdCA9kcbVE9da2rZVYmugqvC44nSMfXWT0xgnlgudutoCJ6rPP/xq5X/t7sv1IqkEcx
#U1fHnKWTX2EU97MSxRwCPReHsEylPIUC+KZWhnIpCYYPPIEgVufuSS2zbBL/vBZ9OeOCyBVy/H4Sy/I2EJ+JbYVYTXwAO0vWp+/tnzD3/krrDE
#TtN5gWBF+23nxIPf1n3nJPbHndZh23nzl2hWk8TwdN8xT3Y/NDut+4d6oARk+tAY/ex66GJzsc9ka1x3KMUr+WioBW8Jp27Ee+J6Bu1T4M1wx6
#VitXIYVfBGkYtsd2EOo5MrTmH86rPhOW67STlczOT9pjaVoUXbpjG+OiNmpwlT0Bg0OdY7YTpwbz9QY1HTkiMK02BHDOfu7nTwcH9T+nx4YEuV
#UA8gvon/I+WUj8K0Po3nqZHvZ3jhpIg8NZOZoPIZQqUgZQJVzhkwwNjX7R44VImRvv32FwEQe5BkDMQBCyJibsfwhM4EJ+GSHP7xeqqplOipAP
#XPE8TrmBXX9FE4o1Vd7zkcMgVUWBaFMMfdFWKMIG0cmzASDLDCsk08lKLFkEQa4VkqHtzgIbYuYvtIYnNpNtorRfTdGyVHpAv8HBydKoCCHJNG
#QdBoUoiIW78jKi8pY39YjVtcvzUW1DA+z8II1kL04cxdN2mIU8LpMebSxgALIcz+VEBhNTblNGjQ4M42jCB4ubxzxDHYyp6vleLY9/xqgbMhe1
#Bttx3YN8IlYnkhZQPWmZ8TAHmlQVSgL+DC74amqDtEkjf/L/9Gkt8/T6DF7ZPi1tFljDMxvvH4jupJdCd/uA/d2A9TxNbuU18e/ZQsNpPbAKWY
#WF4gPEQGq2ienPpWpPDFeMvq1kb65ruIaWb65rvCuw2ErwrKKzL5R7NZVHCLKoBgrDZhKNBQkiuU2zFAc4RkkUu9DGnhKUgLT4e0KKQjOrO1Qs
#nOHeMAF0SCrhQJaEdCbtWQzZ00alRI629/+fe0eSe0khQxLxB3YQjzJQF2bdrSQiHf41Dgptq+Cok51dbUHz999sT4yHx0evrk+ekTo2Y8fvb0
#sfHRyWdPT6vtqV+wLOxq4Rj3jfuj1j78tNri98Howaet943WweL96LC+3zh8jTEZpXRzoQNNozRFkaCFjHTxUeINiz7lF5hyMLWVFEgtaJC+51
#y4Sj4/7w6m1oXdveBXbtLlpl50L054P8rSPcHRBuc5Rt7N1MYTFyzPYC7ChyCBKkf8M9xtzNbnTnPTC9d3+SV9jpe5FyGIvnyo42UP9WJ3dy9Y
#sOZIx14G4oqXsX8DfeiFe3RB+zk+5nWajg/yzAWL2b6ynn/7r/8j495njYyQ73Gx94xoDgTCKGJFIYhqe4Smc3/Cj83by+HxKhv6v/9n49E3MY
#oXuItKuIy4wKGXRYbuehsu3Tgs8eX/ooaKjsXxEV2rSmIdD9+Uuu7H88kMPcxVvOrw3C7lCnXCAmojBxnOgp4QF+H19Y7KK4Rk2aiValWIFrOY
#5eFFaF+E9fq6UOynWChucTtZTEXj9UMqPIv5F58cuXqHbdRGXXO2PHdVtVRkC+eNeJDFR/jsOIvrrU4WQ0ct7WJTHjNvoy7B8dj6SdSda0UNH5
#fG3liE/TffoVOw5A2wliJEatYINxdWcuPdvpaahYX8Alabt7/4jVg9zG5hfAQ30CNfXIRHbvOYja+9JQgiei/WYTRaNihjPfLb73n9ofBm6hVc
#T6dHH3xwbH7wQc3sTLtVyBTkAu3sTJWvP7I+G1okIamLdMRPNRe9ueB+GCLdmc9Eq7mpad7jAoyeoSlNufeL8SsJOEsTEi4iKXo/Ie+EJC2ut3
#rSkBqg41FcMCAFjhqVXhDwLgikRUgwGFczk/ARuaSPjz27tMaruMYXwYUMZawk/u0f8OZbIQTL0kQ985mEPlJXGvCRelaAPSq2SFZcKEnt/RwK
#+yQrc8Z2Cd0X+gz6C5a0IcpU7h1co4sdWGvVGApOrAsZiLJaD/TjfCNW8tGZh7hXIXeNgFemIchuGICsqvuzzc7X83u5+MiouB58QTwrA+XQgo
#MoO//PhpiosiV5KOiTIIN8CcrZf7uhWDBgjhJraT+qU0BVuRDq0kkIKi4sKULxISUIuMskJv/Ih73k6DGMEHR+HDJUmMJce/sv/g0unnrrYQXV
#ESpFpDme7HpUna58omPBbaRyr4oT+ZRnf8ybxSzuUEhlBY16vENPO/FUQLtdzLaG92Se0ZWJ0iB7lGVJCB0Z4IZo6NWBy/QxqJE4POeyOW7oRS
#+b3lbyVtaU59dBiOTncfnLLW/FwR8m8aNES8SLCSNR9G7yTQ1011SQdytwIWC6mWLDPSs6KoRuLcxyOAinClbiTFDruXIj7dESl8NIACW7rplM
#TDtf5Cl0o1idQyE/5JIILuc7KAHYUo5g3A2QxoegyYPUVscY3rQzQyQMgn2c9GMkr9x/8eJTLxmnrghxS91UgY8UZ04jxneaDcqywnE3RldTTG
#jf1OvItVL0p9LROG7v9uvrMKsEaQFWn4NNsJhfGJIuB1M5TbxpOgiSRjAYwLc9Qp/HoO+a2HSzi5vBpXSQ+SO4t0xciPcogpyifKpGQc8s7dW6
#0DhyTc6jkt/cF3g+p3xuqeBc8KkAIeEhsyTgz00dJ8gk293duanvdncL/YVURZ+n9KJwe9Dmjc9Gr3l8/+XDMvLAMdJHh+hjfVuv4GnLO/fI7R
#3B0WIL8uu7ds679IJTYgIglbo39EPYgbmcaxMoEnOPd5WSqga5KJx3Fde8nawgoXC73yz1hrnOVHvbTOdUtnTPxdDdCExTuSrqTm9kpfYpBvrO
#nKVz5VAIQPfsXBNFo7Ebps/GFoORUlBwTHlGK/aZ+fbv/pEX2AlFdJx6UwGLlet3545MC8qsvhhrCVk/z1NKbRKY4xZtkvJq6q7MG42Pzbe/+A
#+GkD5o6zsKx7iNgkiP/6cqF32XxQseF14hn4VoDkpcTkngu7t4hqZu0YOJLbttNLnJn+dYpOpLEFpd+xI9pDmCQlLNQDDaGKDomPfE73/1s//L
#INzgCD9eBFFREdcLQf5QyhMZQR+msTzXTjsnOTRHgdCAynBYFYOa5HNssp3R4GEcB4U/YhmJplP9gT0RsBwYHU2pWQ8cPZGcfHWBeSEgK/ysWi
#yIKVQotVEKB8RB+FhO0qwO8VLBeZLONM6sRjq2Tdvxq1L4XtLXEoneSGRvAFNJdJ5CsbQE+lx+9oVoj6JFHF0+p0MkYzn2guQYK1zbFRB7g5tR
#INfn57pzrY/Os7Ix6Y4Ovr+SxtguMMyXbPl1VtNSn0Pb09HubjpSwaXUpZ4wPJenH9kN3F5nIZLJ/rm6+pKHRwMh673zGP9pBMDMlRsy3cKnYG
#d+/69hGe+4cmyRRQm2pITG8/MO+cKIr+8Bv3i375feJIq5dP/IgagjFB8243agkQ0suWq+wQsUsw61QE3co4nCo9lSH+tPWnU8vLu72kCLFa7q
#mSYScOWyU/7wZjLT7ZaB3kBin3gJLt4l5DYYyvGAdJt03psgicKnbBWFxqhfQpeWYSDRh9de4ZT/SXCFthW9GLgPBYKHDEkABFyG/capH08HYT
#KxzMcjjwIyZx6s9W++Mx69eGoco4QkS0R/XDSTxqUeTbFir69K306JuRImBICq+RdNefpF9sYqFKnJ502lXNQLojIKro6Rju4fWTgIfeHSVFDx
#TS7CW0Cpuj6ZtxD5PfA6YJXZKTd026pF4otalFpNJ2kktBC1D5q2Ixe02gMHJ/i/+4VBwbff/BqNyvI196UwWrVgscUF+uc/M+RQTPKh4PTaOF
#KrOc/bf/kbA0+BE5QKdJHAeDnDjrhSmafhZKblPbd1sw8mF2SVHp6J5e2SRg0/efIlYRBDA+bFfYYS1irhFM82Q0qJ17maW1mYnrSipDKuKxse
#ocYZSGu5rrhV3reT8U/D12oCvRPwoQA1pLDB5gZIVo6XJhI47XYBFy7dDlzmJ+EMyTBt4Ca1ioN9eXnZuILy5z0gv3iyFw6AWIKvvFlo5qwIj8
#ML+F2pBPVfxJFCpdUsoeFxV71lSQrevQAVLEBcJbNeB12smL5mvmfqMkMeaRo6Wks6n/UfzbN4d7f47PMkKoPbwdPHowBIjndznMOmwJYLsbOw
#bGQmyFllhF8gRXj6cI876wiuELkMf0fZJDr6wf8H73P9NKSKAgA=
