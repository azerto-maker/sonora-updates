@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); $m='#PS'+'BEGIN'; $c=$t.Substring($t.IndexOf($m)+$m.Length); & ([scriptblock]::Create($c)) $f '%~1'"
exit /b
::SONORA_VERSION=5
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
#H4sIAN2x02oC/8S925LjRpYg+J5fAUVUJkkliMCFAC8hhlpKqUrqkUpqZZamarM13SAJklCQBBMAGRFi0qxfdm3ncXbN1rbNxqz3ZbtbPWb7Og
#+9T51/Ul8wn7DnHHcA7oADZKTUtkpFBAn49fjxc/fjH33w2TcvXv3p28+1Zbpe3Tz5CP9oK3+zGF/M4wt8EPgz+LMOUl+bLv04CdLxxS6ddwcX
#2eONvw7GF/swuNtGcXqhTaNNGmyg2F04S5fjWbAPp0GXvuhauAnT0F91k6m/CsZWqZE4mAdxHMRCI0kah9O0G8XhItx075bBpjuNoyThT7CBNE
#xXwc3LaBPF/kdX7NuTj5L0Af/+RbjGYWm7eNVuLdN0m4yurubQemIsomixCvxtmBjTaH01TRL747m/DlcP45fQ1OhusUz/omea1y78ePDTh5+B
#aT6bhcl25T+Mkzt/2+pcP/mLbRxtgzh90LpdgN0hedik/v2o9RF8gTG0rrNZ7/3VLhiZs2ABj5ZBHKbJaO6vkuD4ZBRHUXrodieL0aXpmj3Tv+
#52F6tRvJj4bdt19ezHMN0OvFqFm0Dx0sJ34eZ2dDnvz935HL6td2kwuvT7vj3twVcfXs2d2cCCzxN4PnDdeR8+T0eXtj1zggD7HWHzftxdxP4s
#hHVoWzaOWudVNfOpzmtqrgufWU3NMs2nOICtrRr3oHN88uFhEt13k/CncLMYTaJ4FsRdeHLdvQsmt2HaTf1tdxkuliv4SbvTaBXFozT2N8nWj2
#Ec0MBolJVNABFWq4kfHwi5Rpa5vb9eBliTPh9VZbvpcreeHCb+9HYRR7vNTAXEXueajw3nv0tGQ2iZPRk523stiVbhTBPGdV20152uwu2I4y/O
#DdZ2lASrYJqG0UbseO/HbViDzjWbJsB2fnyCO/BAD2DMy2AdjGZ+fMuej0aTYB7FwYG3Prq4uN5GSYgNj+bhfTADtIIdOjKvfwIkmAX3o+EQSo
#RQOu4Ge6iSjDbRJriOtv40TB9GhtkXhj7CTXIx81N/FK79RXCV7BfP79cr/anzAj5q8HGTjGkXwSa6u7sz7hwjihdXtmmaWLilsT3fsjyzpbGl
#YF+eOp9DI/NwBSPRwtm4tckeBa928WS3CjbTQJv4SfDbOHizg28P45YxbGmb3fqbaervA+jYbl2xSlesIfYlBsjW9quxkuMWTu2p7Ww6eRswXv
#h0AUg5iWYPh7UfAz0B0FVXaJEtEfsO26tzjSSky6jFCKmF/iUCWU8ekjRYd3eh3vW321XQZQ/0i5fBIgq0P3x5oSeANd0ENv+8QFZzv7yO9kE8
#X0V3o2U4mwUbNqyzl7xrm0/zVe864iwQh4H45Hu5Zz7V8MdPNaiEPzrtAcsb6APYAr2+bvTcji7gt9aHja2XG3Lcpxr+QEMDaMhyeUO4iTxLt+
#yhbjiDMxrqQSM91hC814bZiJyebluWbjsD3bAVDV37G0BUgoW/izXbTrQAUAig0I12KTCbOVLeQPMRBzZ+GmRA9efw4DRMYWFg4+dQtau44cep
#jjuqo00DRICrKS7jNcO60WS1i9tDaKOjJX66i2EEbcsYdLRJjAu/CZKkbfSBnuf70XWPT/7iNniYx8AQEw1mdUijA80b0GDNaOEK2+k91b2nHS
#2OUvw2AOoMnSBXhR6szhFmuktTIDiIqCPOba6nuzgBPOYkISNpJkfvrJQwS5zb8YkBKBkcONujZx8wtuojSTYA0/OXizicXeOvLqD9FkeKVHy3
#3iQjB6GpWfO49D6O7pIRPNaGtkjAcU8s/O3IwqdbfzZDloFfoMdEHM98Fdxf46/uLIwZmR2xPov6a0AJ3rIJ9YEsV1iA1QOM1W1Ph0XoEAxmwN
#a74lLaXmkpgVFkHObsCjJnsXsFa7Fy1sKQC5kwlgeGufRnQBlM2KxQxsVfNGZTx3+G4wIVMzb+/pDBicpZPf6LoDOyJChcnwYftLmKFpEMaB9Y
#86YLu2qdjBjOF1AmonjHOgBBiX0HZh+MbHy9ClJkRAkiO4yxawxwZTjd1QY42AEt7wxEIalT7AEYr9Q5DTnYzDKMQVizulrIJQK3wKdBDuYM8t
#heZT8vRJoSvPE12ExqopJ1Ndqky+50Ga5mbbtzyCt3ZwGOvmv0kmOloKMqOEg4ddpEadvAuQOQOhqfUFEe33QT3PWjrb9LgplEMWDMByCfKIkd
#+NT7ABe3+IoYd0R0CXMYT1bR9PY6k6KAkaTBfdolYI9WwTwttp+VYZQMS3ok8kgUOjsSPngSPlAFImaM7Bp2UtDgGCCShvuABjlaIkU9VBhwZe
#m2Nm2C0ACi11S6LNoOSbKtMC67U+WKIMLmfTRyZn8C+xhAcI3Qg72WRlvYAk8BakCT1/SRQds5Fy1xLy7lTfHjLknD+UM3GwDuq6A7CdK7INio
#9infakQbBuznxKL15UWzqpvYMnCTEb4UXGq3BXVo6qNeA6PWOCfiMxakdPosTx8QVeyxX0GTY9EiRw0VJlQFtmJ0nGXSuiNct6vkkAlf3QeQJN
#KIE0x6eT75y3YJUTKTqNF0f6CmSOpmAOgJXI4+l7YSPpK4KXyCdZW6FCDk5YuICoTMLTwciKdmFtucV5DeVNl8VXkU6pyH9JkSkjOjyiQZ1yvW
#DZoLp8WWnMfRmvNAUKFluc8kjZO/7OiZEsU/TKXCBXde+8ltZedfgtoC7ZkdTVDX9NpSUmOw69Y082B0H+HWkh4F99PVblboWaaIxPyhZniJwG
#ySbbjReonGus/ZjEp9Y3wiYxGauC5Zh5bEFLBtlCMJnCPHQ8wHFnC5vTv4yRZ4PqwLDAKQ6WpYRkfErxIqiCuH0FEgTyYzW9SLFtJADvWoIvCe
#QgB8Cji39mHo5d1Z7U+SbBqIvTWQqX1hnfAyel+IgR3NGaDwjgLwrBg8UN3p7QPR9ELRdq8rAossuOI2tAcy2rMOTX2g22aD2IlS0QlBkxXJDS
#rEZZTiJM1FQzp4yIRC/77LxSXPFGgPzaPRTmL2O6dEV8mIMhTgwYiTSRJfLVE1y9TfTYrxj+bRdJfA0NMloAjvSiT7k5LsjP96GTEU2Tqwenpn
#Kl+6HGbhZrtLD4IkzYBmltWlQqsCcZHMdPRUaUHIVa6SZJRjDVqbUGHZhquVRLBJE1ABWCXSNrB0h/i3wEBKQlmFn9hKKDGmgqPkTFmhsv6p3b
#UQSzO8LXRg0lifGIulPEWiPaopNuFcjUDDZ6sQJxbLR4qY0zQfZrapCXeOT5aWvrQPZTXHKrQcogLmcWkdikE5qLdANUFZ6pW3YYPUAb3aKrZc
#0YDs3iNkTcDKKJ+l02NblYk0t0D9Ds1CoVsSLKcVFORdaBIkpit/vW33AB56f3+nD3qILbiqGWm3cjiaNCJPoXOWoe/QoHlnwAl9hQ12IVNX0Z
#CLku218qHCOM262R4acbAvKr2g0TO1NQ1XQXKOFSUOtoGftpEPIgdY6UCKgIS3bRSmdWsedzoCblC750mwEt0pzAcm/1WWC1SsrMxRm3dqWcks
#UXqlPojT0VCqzjhWgd+up1ZLhX1l5iDRJhklFykv0UKRtN8tAU6ES0jF72J/W5GFaBb5w2AF+JGESdZNyNEbnVHQQrz2V5nmJwzd8ZR6kApPH6
#EZ4O4uCaAyQf5je0DmKbIaGoOOgtfiJKpqlsJlYnWu1STfYYKJwEUIr5xeSS3pdaTuAHK5LCu0zO2R0yVAuWoiGgiyaveey4oCqYa+USYrnEFs
#KYRGBW0tqzjkdqkTzPY9xKPSWomUDF2OJUbFBlin8y5yaatCl2oWxq4sDDIyNNTVsvdlFeT2oM4sl3MPRquZZW8SLvjWtUV3na2gMEgYH4Hug1
#6DIkxj6JfNpihw5+tN81PxI9ycugv8yCMZm5NuQqcSczrFimykL2i93k0OJ8WUUuWyedUjHupPFYZSwvEG848tcnOsylfEExbEM8+mSCUjb90S
#4KiEXS+a2npu5xxbIM2yLF1mLg/yLhvh5HCWkUVhZaouSFlQDCePERSvq2MEIRcaKdsnfRx4fJYDxWP+Ew0JW/GrYN+KRZdsUgprE5mPZK9QaS
#kKE8VuqxluooF6ubwu269hitM2B4ludj60B+tEQf4kcUmwUOyA8sbR+tDIr/7Uxhmgb8uIz2FKgBPXCr2QSx8qfthj2n5sAEgOj7cZW57KaOx1
#SsOoOknzTjVjrWXEAfZQ3/cH+OrG2CgohiBAqbl/2f6eUSqk2RLpYsSZRoBdFc3klhm3kFoJ5xqAk1visg8dIjfm0yuHNKWn2ibqMjFWP6MuIX
#1We/DY2kR28uquK1SXPD0TzRjWOXpUXpkcVuc7ZiYH9MIIugRT/2BY6PDGv47L/pLtC41fCuJes88FqRUrauF6oeOfivnZFSijW2N+jiY/olFw
#HqYj5s9+f0lUFHyrtumBSghca7NwfxAnRJtCdlZVxPYyrv8S0X3N9EShD9twlTzivXu5lqfDtlaX/ERsL5a8Jqe1hZNKp9IYzSRLTk55n3reO/
#KqwqScP36UwURqrML4gMelDwralvEt8nWbVVKHsqQfH4hRMv44sq661vUZbBQ5qGW4+HseN/FMUM5xt9G2q8Lc5hLtIxxEEk5PVozYF/ZXm6xI
#/AVtYP4x03YHwtblvU/PCYOoGRNrYpqeOQMvK66JUqMrSI30WcA66kD2VeTVm4JwSu6Bbk8tjDLhwi7pVr7owo+xU8sYcNIu03WBOmM5JoGUxT
#ZjKITnDI5SNE4m2PWKIibS7eT2fJwQPB8FJnhmCZJWDf2hIvAg9OHvZrcO4nA6Sv3JbgV8Eb7j5p7EzX7jXGNrMsNXuj4+IYP46/RhG4wBIovg
#h0NmRPO3wF/h2ZTbvsvfuekl0zWqurWsWqulLx6LmgeicoqjU4CZKqZTLNEpGedrJWA2Rs2w0BxSmTEnhEWMiapMEYQKSBpkEah1sOL40BNCoX
#qndLGqtsWtLBVJc9hRj3Ad/dSlL3x0jaNAn8ep4RyfXO6jVUX6sLjauQ42u0Mp6C53pZkCobTJz4E7I48ZMEWPZFkYZTM2dauvOx7M164L5TIL
#h9lZ3iviAIIx6Zy4LK9T0p6I2eLcM+7++AgcsyYCp0QwMMhH7KnebnR8gsGY0aIaEDfQLVd3bIBibUAcmeircsD5YLVFsJIxiQEBMKDtIj/Uh/
#b+rqMw5wzL0O7nUxmNstFWJpWtTN2MPNIAWTPa0j4Ilnrc3vzFCRM/c6oJVQl5JI3L8LK2fN0AJgfY4R9knwnaMzYHASdyHOhlzjEuNmYOX1Nt
#AW9eDjWAHLfzOJelRE8rAibAgdy1v9BPe8Rt4ceBj5DJQElRRHFAQwEcT0PgyijTRndqC3Et/xOEcO6UifwkLZMpCuli8geDOpm9lOaErotByg
#3UyT2xV8SwVzLNqozQpYXIyKhnKszuvZMkysHlIoQ8lCMDcoSWDOvD/ZINTR3NjmWzFpXuPtzjAzSvKtx9Sgtq2c4qtP7v7d9j/WyzHbsKm+kA
#00zlfT/Im4kEj34W/Mp+OUJgrM0UoBLVNE86H06gFki/6wAoULtY5AEucudApyFk/soHT0spRXsztiW8LvEp+uWQVkMh2yV6haouhS0L/N12qb
#gU9zPah0k4WQVH0vlU+5FIX5wf/bkWKaJyeHbGRmt1xHwj2aYieu2Iqhc/EXQURWzyJZTihWB3TavU+4gOldMKG5WANuL0KLhPLFHvskqKl0cg
#LMUpUOwBWwuuN1dmTaEMVQNzocILxoDjk8wNl+sI0gwzjw951Sq+tKorQ+3cUgjyXqfkDxTJnBCAU7X58l4MtHDwD9UeSZbmBliMbZMaY5Itd9
#Y/0j/vVv3z1XCGzGNfmCA4MHPjrVdnsyuZnXJj4ZkmcrIbltzrnkDWFf2aFcjLviDB114fgIRDlK1oZCvMtlNOt4VDgkRQiXuM7GuhAJ4JRYYu
#CAHJMljNDwJjdxhWJu8dS41n1HAA1EhJQizHG3g1hx6OrGoetiPRjieGv1qd9g+WQZphTI8HdstLRZ36eXRWNToa1Y1ZMI1iLgkA5Yv5NEGQsq
#uSlKfwteeg6Eqxj3bZ9d5NNv62ixro6F7bxtF9uAaigtvTj2dVnXHQK50AeqwTy02kjplaxUgq6/Msb9KwLsSBe42m4fpQjUyVA2zP2blq374o
#yVH8XzmuG72o57vLezw+PSRL46Mjc6suAgHgOZTQXShBWMs7VHhwPQLiVjGWWDjCQ3y90BN7gomi1/v3CKMpxUee8FBSjEAZ+apRFpVQhE4ZTt
#vG+Jc0FYla5fDVSRr7OH/INE2aCZItKLw0ol5F7u39KiS9eiqhToxtZNIWM/4fGbMVAsiOpyLMjoxGCUIYBtIjtkWFf4PZ405tY1Pwf4k2OsSF
#J1cfamP8T3u1fPfP60D7/S5Mtc27n6ONtrf5qw+v5LQBfdO3pvW5AZDXZ+kAhr5vTvtFOoChz9IBDCbudO6dTAEw9MUUAB5+9hzPm1ssBQA/Ut
#1wBnloMoMZ/vZTPDqsdbPjw8Ohbpk2qPxW9dSvh9bd/Fh26Yx0bqZ3juIx3/yx7R6fJPuFrL0Aet/5+0CpVZic8pgZ3VGRw74L6m5+RthSH9hQ
#nzg1dcshQ0B96H/58LBz6iCAokJFD1TGqmWHLc48PVEM3umUn1g2nZMrDhiGG9rgNdS2fHbVzrQV7nKiQ6iCWNVXiFWWaJ/wMmtJJgTzM6WZCT
#nz6pEeJx4Y7Qs6VVXOoIaaz1qSSisctnTsymHL84Nwew2Rh2oGNRvMpqShbEINMT2zoQuRdiSXX26W0Towos3pIJfL/tTxg5l+OXQcJ/DFbBUV
#ltMkpVh2T3cHuu2w7AKVY5QlGXgVTpYnQdYstcu6fnbgUTbyNR1RVcF1lZ69jkco3LgINMdHH47kI5r2poMguD5zg4ldnaVkS0lJxNrijMQATi
#ZOrvyJFDVRd160jDi8s8FkMJ8Mcq2YqzJFqGLCdAPALY3rG7nZqGc/vS4dE2OnN0UTyEAgCYp4dqpA1oHtqgZKIhbb7PDoI8LRK24jpSyIwba8
#XRHaQtv8zMB2ozqOVPIcQVObpuiZhuXALf7+YiP2m6zP0WXJLhPsFeX4ZiVmTCsuyu1HqiWAyBLiI/h6pv5CFJRlG2CGW8U5EsZfLAVIZGHWdq
#t6vUvSo79gNmgOQr8/mMx9doBQwCUpdVDuUy3xc1KB65i9FKJOMyHjnaeMDhMO/RVycr9nlrC1MDoNSGNnDodaoaVfJ1lYzlAfogCXSTZl746V
#Ybwk6rFTePZA+dIVTi7eGJnd/TJwgz5SqOJNM8mlc3QlotlEyAcSWOxeOar4JPcMLGs2nOpcsK7AouCPttXX+yZQFqYB0EhF3Ba2PxeLEn5aAY
#+pTwI8H1gxPnAdWdgXvcEpHfk9TvKc0KaPNLzmhdnMFHp/xqSZFO4W0TKWAAzrjOgIUnDKyhfufP4OjW57P/Xj87i7KWEFky/9fV1AVHVwZ1kf
#1HlUzGassxxXUNIyraxTjZXKEr/VaqSi45U2HwNQA0rKoslRcg9IR6EH4gEE8g88YkcOS7ZARqUaGBpKdY8/p6PeBSWqg2Nv3qPv5SlwXNlT4A
#meAmZL7QmegsqmPzeYLxvqUKb9zOGoOnxrmwprpXTe4yQQrUHnDPRltCW1MlU/tTvKM2TqPEh0iOxRiSoaDBVWjzkyuaFiiHnOzKeKADP7nERn
#lp1HrvBcZ6g86uIclHnO1DaFNFSsfiXe+xyZtGl72PZpc6mwNgRTzuNNBQaQdJuGzZJtel83sxOybnrfJOt6CsHuFwi40BkTcGtjuWV/kHQi0x
#i4SFTjWnM334C5p7yoOTwaEiFWKGLCuc16n0WeL860Gk7lMy+XwIIGsmFF7cqSAtrsRrNKmV3XcCbc8fwd95E9gmv0KuwJW2im3dN7+RDC9ASt
#J1+jEU81ZiKuHt0ovBZMe80bpzQjNU5/KaJC7iVcK4MBkH3IbqcipRGnHEIjaXoo7RDRsWAqvbM8+L6UTECWimhXNwXgezwA/7QO4ZSIf3cgRT
#KJeoLlohahjsZkVqcs7P6ECixE5XvNUfmegAme+gz68cnlZBXeBoV7gAud4eRcEykUbd7xGMZPB3JtFvsBYwyFk2Tz42Wy3M31S5A6dOavKOmo
#WZ16N0Z1YdixYDwMcEoFqB4cqB43PS3WzoY9L5iLYq1EIxxl2KCHHCfvXYRiT86OQbHyWlW5pIeN6kutE4pcC7kysF8ez3FL5UqG7J/q29IGs4
#pzvFKFg9oxijxDJ3tINVKpEhRF5Ad54Qh/HaWUQd2JD9yPe4GzAKhkW2q2RAwFWmey7QQcTNpTwvcaReqoIDo8mWHFXbZ3tJE29WdxoO024Ztd
#oGvpDiGvzf13/xRttG00XaIFR9egUSg1CzRM0byDj7lz7Uwnlp05seynQJq4NNcfkjZPmQTtkg/LBsnw0vTMgTWo82BZntqFZR2lRNBFHmfH5Y
#lYM86smZIjoS7nKkm2WUbVk0ngCNGq6tRAtywKFPfqwu1PZ7AaKOPx1WEYJcbDUjvA9q+G5SMgPFN1yhAnfFN2y8n5mypxZY820JXjpRoTpfEh
#bbZFSFHuBRPPcZe1MlsV4q206TerwY6cDQFHI+WWq3aLpWTnaTnx5Rn+096gSFxt1mg6zDEpA5OWm/3Ko/R4r7X46XQqpli5QK0ftnc6BVuvKQ
#Wb2h0vuTydPK2XIF0r7La2eAxQFeGXz6Y/qDXRAmEC1RYY5IBiwM800brMRusoZS8CLhkiT0UmH9Hch/IluW0ZjvBETaWgVeqpV1iKEtlLzEPu
#BHhJ4aaUPs3uvVemIvXAayNIuchgTayJ4x+zlyQ08FfMj3qeTcjNbEFmjR1oUA4YzWw5tvoIiCA2DEpw806IXqbZYJI5TXV6FZNMsdmb7C5Ete
#m4WMZb1WYXhdVFbYoXizlZrImre5R70WaZfdk4zziYWsyBY6+grHdZvBWTwrwibM52nzZfxmAP5MTxRE/qQTQN4+kqQOhgWgOnZEdyMesC5vYX
#523bCqMUM2jkDQ1duaEeteQM5JZ6FOYDANPRWFNwMbRoiDwtl0dPxBKTv65kFxLonD0olF8pnLeXR9OKKfVMlUIuBcNzt59WOpfdM0uaSFVhPj
#dc1O1U4/bOUN57yvBuue69yu/LpyccX5K1fIWhq17xN0vVk7K+LJStZBMxSBhdTqQQRWFPCPPtme/hjhoI0Qnk2TllnqwcR1tOGpYQ4/DcHpKW
#a3WeIaje7HVWGEea+bR9Hi21z7oNgNk5Kuf0S8kDzlG3A7Nnzga1zstCDLCGtu4M6LIOA8N4L5MguM313rNPc6PHivV56jS3I5/m5j3WHLXm6+
#SI26ysKXB9uoIEeGCaTjJnJ6JFpZSbDA7l0K1unB1sZyYFbm/hCrCgmDPylZdgSWaiTecgBcQo7AuWPTgd5cqFCackTBwb7BWoQdYc4WK6Hz/I
#VU2Fca0626WQ2+3BeeoK6HnHx8fw9u0TRpDzDmbVH51i+s6jbB2ieeLbIE6izcZfhQkdtKhG8vpTa8SjBjA8d2oLQbmrWyFa9w7KuRPbmuCbOy
#g2m9j9Psb03jlQbNh3LHwDYGcZY7oIOSCv+AGGecfPVXS7yR0/VN8Q9ctTa0xz+Q8G1slS/p4OIlRXVwZDsLuv1uF9OwTxGfBCqAy0TpJCOo+K
#ZCx61us7sTtaH280m8/nndpjF43Ve255jE1RZY1NgbhWbqoUYNRY3csmIuiR0nG25tolWKt1xObxl0BRKI+N1ZzKKpecTNVrmKZ2R+kwKl6zGJ
#NKzdVtRxkYkr9loR3n+qyrKF5K91XOp9XNqVHuSq0cXlTObnAKioq9Qk4IHSUz6WzkLfHPzDtwOBM3MswS3Abn4rVT3SKFuPL+oFZIJ83UpDKM
#SmoUnUky70fgHpmSplmIUUkrIpIKMmcpy6AoP7KLBI1N1EU+ppF/QpcfKThcXglmHdaFbGdlMJ2A9qEuf83qVB4zXbtIQSBfLiZK7uVrx6ilya
#IbrYKZVjbV49HdY6WEPAr5DRuIYkpQzI9TTWmOd4/VIhXT/KCADckzGhNrclCQXUszltNS75mQlosTAw/z5x+eaMzQr5SKGEokdx2SjaCoQlxj
#ZeBLh8h48fWoNrQK5cWq2HpV0xESgWKxDzHJBZfRThRES5EmHq/iiVBQWOlUpKzCkX58ooAVCMjWuQIy7weko05VVAbRbR5s3v1LSk6iRANa4a
#/f/TN8TVBsu0xmq0wTxJw1fZty1vQwZ01udKueWqNqr6NtsPnhnARuQqD7wNsvkSGmv/Q2KMmQavPw+CM2LJ5qpq78SU2ybTG7LDXBUsGUjgWf
#cS1JXU5u7FuRk5tpJYOz8qGUYwGrUebn2XFE+wEOq+Yo9ZFelrihmFSAm4ihESnTRn63jXCOm0Bq11zgR8PoVrLcPBoPsqAB+aoa8zGeDDq5yw
#YzWvnwga65O+SJBfg7Y8ozgjUnvEhgb6XTpXiLQQLSwSPOMGBGCapzIjzLkbGlLsmnbNxyhdgQCtyh8U0fcUti7mQT4KJRG3k8N3zRqvn1suAP
#U24lFrOlkm1HiIsjU0Q5CO39EgnioDDxUn5VrpCi7ciuOMbX8kl88hHWh6aXYv+E8MVSYEx2WDO54zfx1IdzFke0aw6v5xMoJQ2QnLHQT0Mfj7
#0MIE9bIpER6OMsd0OGrOTfdHJLajkM6IwsgcoxIDxH02UwvQ1mz8P3VeePiray2SnTY9n8cq28GrvRiSf7gYFkOcWEsHU6gs8ed6P5HBcjc0Sn
#iYKV5kEsRYwMlX18oP8gMwQNlBk2zrgPwlPE4YsngSoZ5MqsS7F4xdnVchhtw7kDtpew9lmHAW1a2pR4miIbznR7qwh2ZCmItrd8t1a3uyP5Je
#uyuSpTMSp8NNcVqhMvTuMDz3u+mMoZirz3XN0T6ddPXzEAI6kTK2iYj7JzldRjac0AOKOln7SNJJh2DvWXJyMfDaa/kqTJ0hxVElPkNBq12HSj
#FjXxni5jtigiEwdzP2hIq++wOB9W64SzB8uSblwxi/dNZhbngtYjZRdmMOZsXQynU3J3PeevAtfiAoFoQv4k05UTDQZaGJD/YhuDPhGnDxot/i
#F52KT+/aj1EUHnpnXNEzcmQIJ3yMgA7/wV8PzVLsgszsdSK/YjW2GWarmV1e0jG8miY8VG7h47H2YZLzXy2Okwi3qpEeex0yFL/JEb+IUdT8uk
#8euldQK38G11K3y5g3KGXXy15a9O8ZXbGkBMQSuJZG45NBhTpFTYSXDeZRweu4xDqLsPgztA4LNqm5XaqKo31YYloKh2EB/bbGdqQoMOPWCX+/
#6x3bXRVJhfbjUsdYUmhDMHyu9w5+3YpYbIRrc6oyHKBlqZMlVPzxpH1+mpq0/Oqt6vdj5bLd4LBr1SO3N/Vl23EmL8xF5nASBPMZE6/8KY1LLU
#6CTwU7owQ+GD7z/WdcSdIZKxV8aHaH8e3vVMAc3+1KaEKDlk+mWEvk/PwwzFVkqWuGOjg8pV0AUV8KlWAvFke5CS0+ftc/vW7D6TB2YPnXzIlp
#y6XqID2wOAP7dj9l3V4CnHrU6JbnmTZudIGVEa51ytNjTLAAAZIFkeehIKVPZDcYapjJV3e0uZ0f9PtIu15Da4+yMOtprR/08Mx3iRrmV4dFN4
#qXW7pnXKZMbrAlmmqqo+gCYVgygv/SaoW3vV0s+idFuzV6rH7+2SX0xqaVt7D4J16hoEpxaTMCaULliwXHGI/B52i0HXMRXvulaPXvaUFdkF7p
#6yImu0r6rnVFczBa51uwpqYGi72YZvWwOsXECiL7ezBHE83Ua0cSoXSTido+uq2seAHdoyVZiXhon5qM8i2Wx/iTvEGAxKrWF2+DPpf3fQxANh
#wlk7lUkXoOs6pgQ7kxvXow3oeuEexBCypy9W0V1NMi5247aYkTo/1yqkp+5SaAx5NthHhSLcnK7rdNBlcwBBKVaydPrDfdqBOaxW3ekS5f4iWy
#IX3eawW6N5qhEkZH8ZA04pUxK565Srhv4IPGusC66W5AFvZzNMXFAK4CCn39ZPlzrz/NHnoj1MwjdCsY7S9RWPozhEYLv8CLPY0GiTLrvRnPJ7
#AgqL7ZZeCX4/oNaaZalv4NJ8DIrd+GlQ241d340td2Nrg9O9SAshgEh+LsBLdmAeq/UP5VhQKpIugzVdi0NFikYY79NkeKDaHm7rbs2wXZMbJ6
#VUrFULi3l+GGY5//Z7bhbu5LM6mpl9rsbJsIPu4s09W9BqHBDNdpNw2p0EP4VBDPKKqxuYe0mH1gCadyDHJ0RHYGBxhBSE6z/4jTk/BbCSsE43
#vcmt2rox4I3idHirYkvLWbkdWFjAJNS7HtsWOk1LjbHr5wzHfXxrmB1P41nshFsZdzyTL6VgBfgwarNGSM8Cbb8LEFbGNDXIRiOMh+lwdNNj3V
#CORUWNjjrowndy9RbNMaVOM/qK5vDqQx34qzS3UtPCnDbAbUbEbK7rJlqqTISAnFESteF3VpqGaSbH+iq2sorbVMVRVbEae+kpqzT24qqq2I29
#eMoqjb30VVWcxl4GyipyL3TG4sS6lOZSqqJcF7vfVEW5Lk6vqYpyXXpWUxXluvQGTVWU6+I2Qky5Lp7dVEW5Lt4wyaP8t0LESo0MSMKkaLHm5W
#lrkyVKyPs8aCQeeZ8GMJamPMesIBTiQR8FWWEGHM3wziMrTffVTunCWtddJx25SznosOgb1S3NNnp194UaMd4ApzrJSLOoe4n3xtHBEJ19SNPs
#Q4IfDLocNiw+ToqPGBGK35aPuLRWjHCgSE11hJqrPHaFdUC56gihWuVIR1JUyYgt8LolSLHE1dngcqCVz9pmwEjzpK2Cr2CQX/6XCSt9srQzWB
#3ExGDZSfJyBX5AJoOkohMUnulCRt2jS3zK/QluDHSSCAuhGICl8M56pTae0Pqp8qfYoqhmD9R3f5WuIRCMu9iuMmZPNACDhMAPyF+hcTSFDyNY
#nSmskx8m0UZ7rsXBfBWQkkbkRWdbstE8m1ljudR3r5MKWJjP+PMH/rwmibwlXN+osxNyGvIuvUA5/j1HIvpelwen2Y7cdSWzUqH8nz0N+VKBs/
#v13gNidUfTfs1VKZ/fbDq1OcyPi+BxQu7qvNct+2kWO7h+qAmH/fVPciIbPKhRqldmG8gwMNMdMigBa4om5Jvc7cKs0SdzUtajH9f06Jzdo18T
#LuHxaya2Yg8KlUFquHSngPpAGz82rR643dSBvAWTo3iNT43VlmYhK8hETuRHJdrCeAIQqXU4jaMuMU9/yrygSJDCycgnHNfZ5bLZFxpO/iZcrf
#IvGPyQfV4s84/LoiE0W/IvqlthWXrhx8DMrYFZfi5EuewuX3bMkFvbW9GIJpSsud4eNcascL3e2GMENDtvclKwOO8oCv0+s2ynQab4Fe5zk+WS
#TaD1KmJJBVEzaJTsPU/eX1bMDuYIS5vHHzQq4RK3c5D5FbEQdI1f1jQPq7oL0yUF7+Vn/njmqDzTrKC0M3s4DNyrHTggwvlXOJvn3MuCZ3GKMW
#ybrm4uMsqqTZL2U5Z0lqO5PLvMH4FqyvHJ5SLg2fTUu8tr2MpHqix0UnVS2CbnD37d9j1BwVne1Zw57FXsqOBGLu9tCWoGhVQHs8MZ10A6bqcx
#jQgdnBSGX8Y9gaLhBZLspBFPgIFENcuFUSxC5irRUNutILlleLrRY9pinrVLwA00Ap2CXOnm8TzZlIQJmFuifndeTjbRHdp5t5Slqvh6E4q6aL
#Q/Yd86Cg3Nwr240+5TBgHDOs/0xy8lFVpgTqE6OPZyONKdy5XtksISsBjhoknmGVKxMWzRyVuc1FqjHUqhx/wxvcwbo76eSWVTFlYIEKRfGYZF
#oHEqRmBQ23d4tjbYxSQWSNdF1iW1orxiN+zs9T78qXNoztIERapxwYIenBG82gDT/L5ZDBJz5aSJUp5Ps680twwSdZYkGd1xmEVmEZsNHFh96e
#71p9U7TrTsxsEGlp9GGiBOXaihYEz+iYv9s84Jp4tgocE5YPLLNBht/V2CSXMqc5OEFqFCvNtsoEyZcSM0ZL8ZYEvpKA+7j5kfyhE4OEbJaCgO
#1W5wy+0cxdrC/dNFOyxKhohWdvjDwO88tlD0fCRBI+c/z6x1S1Ytk1u1hEjzR2hEg4wJUTS8SP9LBJ9Cqn+5/lASYlA4LoKU1fqEncWQY3yyiB
#Uih2lmMHTISBg8ZoZtFuGP4gmgxnFhbPGvoVcVkcFN3RVRol9Hs0Dbkuvl3c9TKFgEil7OkzLZzmhWRud6cs70S2tqOz3pXpByYsDCeEy+wnCF
#X7L8yVWls6e2JHuPsiTrRVeamWBRXZT8CYdy5n7EeRviFbbiSDMHZ+lm2V97jKfGx5gQ6Jyd7BQNVy/miRwXURKvu1YpaU7JLuOBTIy5nTDFE3
#xE1ysjEnMQapyJM+/7iqzjxTFXVwUJHLpA6tkQQb487V4XYwfZxGoi1+ynuvNUMMZRCAsAY1qXcRAFCkq83X8q2HE9k+y4vf1SH9h4MrN0KWdz
#gJoiU1XTnZ149NiRg64w9QjL+i7l6aEbTygovpLJ3gZ5vHyiQeKBDJk1goW4BjAozCxfJ9BKkKeypZinCgAsEf6WnS0ACdLn3g1aunAPxz5dLr
#S8HXECJEwPm9xH0hwaAzdz/WjQua6kamQTSeswyRGuG6WjKoXijChFWV/1ngvYxNppOJ9oq67nrNwf9Esv6cQxkG2i9rhj6aKM4sqOqjEWM1L9
#gsEIK5zefFhWd/pnaTpiGyWjCxd2gB6wid/X3B1jF5fH2MKVseXrcBqyXZczqNZjmTGQj/P0msQHHPSkiYZliGdK/iiGdM4ASVgpy1A9DbPJb3
#vGIfOmM6uleZdYIsjGunTpb8PuxWUFBqfRstW6foVSE2Wp0iRNBtPb80/hiods5BvravfEWadkYeTnpQxBfDuRIQR9T2KGECnxGO/ozHQhppjc
#LO/AY2DD3PHnAI7n/KUK5fTyxdOmTOkwaG4ZqqaggRa25yWLVB1szU7XW9Zjbiup47+OW+eMtJttTjiJiqAuJQ/EArVeBZsVaExSX3tKDbkZUR
#DubWYH911TYl59c393pG3FrcBATbKylWzq3/pxhD7h5GEzXcbRJkze/Qxf26Ji0Sk0C5JGBLDhYBqZuc7N3MNTFGP1wEQdNj1JuOuRk75ngnDn
#9DJ2vGoirvw6MZg3iyjOINVX3W/UpNioTFdNKkNJX/GS3I2x9pPbLnC3RVA1tRRiuY6yJSV1pQ99r5Sh61dpJVOUOMxXzQpTCQQUe6o2WhEIyF
#osgYEtF0iqp5OIs9VSb8uqTOEyFMJtWRdvjT1rRbr1+oOqdDN5GymYbhvD/Z2Ot/91Tl0SaSsviazlL05Z5K+GW9OGEpOayi5JETbchFLmzHn8
#hJvIIjEzVxBApCPICqZh59J0rp1CLWPr11ax87ZLt4uU9G0xdz7JlmI+L0/JwtjNkKztQMhSa/TdYF1eAE9JP4eMflboTKZMWq5Ibyi6QbcG+y
#XR6hUr2wdqwvC0z+mKYz49Fk2msvlRIrL8KgqNLDb+wyoEgXcdzcJ56MMWE8jrJFwY2+l+orBQlzCnknAor1t22rX+xz/8H/+vhvYi6C+IWw0u
#vLOuLay/aau0FtU0/VnmardzQt6k3Af5hAhby6m5LOnIdJwCTCmkCWTeZRDDj67NQ/rjryYguAlQzjyyFSCjqXC3OI9OkSEWpUvtOYkYHcE1Ur
#1TZ6BbLnAv3Rj2ay4gsO2TFxCwIo0XdSpujpAvljh5d4bnduRrlyWeya9dBihpRrJYyklUbZ43Q0AT63EXREupE5A8FORjt93CspIdDXqWpFnB
#N9N07bqgEEgpP2z1nXmlq+cq+ShqjOUWs/7zlAQ6fCrldFCpnVSD3ZMDf43t0jyUr/krZ7pVneYom2UqDvjF6atcaSSSmaEpbZlwfRpVlK7d6i
#lznPwSEwgO7fSN07acvtzmKbunt4+9GDi7k5PfP3Mt5RB5rwwx/RP799RN2qczxmD/NSlGqviwlVKgiweWWRSX4S+ryToce1vj7yxd3cFicP3C
#kGg7Ypyroz6TVCC+An25bHRF+K1toi7L8CcTNlL2+hXC1nkEfyNNQUqogtMQtLaBMBOeI8xfakvrUJYpUarRXQOUEb2PAX4ZUjGcIlyVpMrK3c
#BlEZOSmDGnVpqo8/KUr/dihXNi3Uf0dd8HfQcn0Pes/DjZtWt4xyOgZRVNK7xBtpOzapkOjqRiFkwjHtUGAw9iHAxOOphKV0nwdO1pJp/OhjMv
#CEpCfd+9rtyEICVRlwjYNg66vLdJakwLK0vOyKP7nKlTR4QVmKS7KIDCP0pqMJ80BLlCJdylxmpWpXr4JomnCixQ3xMvXf1oqxAFm9P8E/SV6H
#oZ8uz8A6tfR4CaVmsdxUF2owS//gaZykK4aZP27ePuWqZrZoQ7dgZiJH2XZx+EPozlTzIUyzkus8z/Yvp7qBmWnQIlti2lfKwTNVRaYUbTQY0r
#SyIMrDwnTYkHs6loODAu7/SzkZ51qcmwc11/nyw1ww+usA/JoeT6gecGBvYWQ87ut6QX7F6UCtHHmNVKXkF49D54FMTxJCd1PaboVzcOFRNMA/
#xC7KabE5ZnpIcSrnXNboQ9ihyQmaAyYtNnCaRA5RAkbscu3ynwIn738yxMQdEI/AR1+2CxENSZaQwjTg+/wAEgHC8prKWFuOP0OK+ibHkVzbSy
#1qelmBJPI9fYLsEnlGQyMzuwmZ131TezHZGiZuUmQEtwXJ5zSYloRMtDn3SeO0sIgcpvTNEvbXvmBIFsphOyR2ST0ETmcKb4WcpnV07LVly8yn
#tYxulBlVTzWs41b7G7WAaWGMe1nOCNvWqvcma1IYWUSVlt3DADIc9I0ajswF1ODuZTvS75hdVTpctwOkd7oCzfs5XpOzrHfl1yjRw4/k+HsmRV
#4vNKPbWkhQJDYFpomWY3JbW35Kx9Z+FTtbQiWN799wmW939KNLd6gu99opxkmKJxuFASWCCihC3Qc21aHJenxRFWtNYPgxcplZaT3z6Y1zUAkW
#/FQH71rPVkeauxoxJSAp9bBVoT1bLV0RZ/5MfOsjBunvamrrBYtqfIgiO22xPbZblvBnWFxbJZmpwcKCBJhIeS8UYMETpngwhmmktArPRhfn8q
#Fm1oNt6aZ9Z4XJq3nMs9sKY5MPHvYGrS38DDv6YZeH0P/07M+Vy/nLmmOR9m5as7zUE7n0OZhcN7IKqg7HbX0SwYYfApyPVydPV2stBsw607bE
#Jg0XLoCBCWk+5MFnV7IR8OrV4VwnTzJp0pzWGszoNTLDZPHsODCYTQ9zkGS/IQX91JOpXNjrHanhyoLeZdw/o10V/OjEey3utmRwcyuV/Chww9
#+SFF3fH42dEcUEOc9nbibzZBrMwklNn1bftpbaa+p4XBdmjXA0fJLri3CDV7D/R6j2BW0dNlG2Lmmj7rnrSBVeAqZwiX/sB15/3Or0LrlQzdU/
#nJPSnaG4Gu9VQpUSz06Erx+gpDX7FsysTtgm/HHlR9O45s1vPkwJ4MLATyObkDi5fl3PHyPvM3h3qiXSSwM4QzoYNSpivLPqMB8RyPLTVgNbEN
#oYG8uslofFG/xIrqG5COapLfQszXJRAoOkWoiw+KU5z8gZy+ZbT9MVxQcNAjwkOxTjmzWJ4bzhBTfFqlLHvZ+Su5EN5yLSlP34GWqOEZ6Ugbad
#FmElFeCVF/goeimcgWb+Nmd2f0snubq3fTn3HLopSKGO+LtxweC2R5A30AmncPxCXL4g+dHl2zaDsDMrg1W9yONHyeyeIg39DH7kuG11uFOUfQ
#e3uVKzWyVuULmZnTnFt16T3aZgpjyiB7ESo9a/gCmrytCeUje3qcX7J5fXbO8yYnB7tTpNGR2SvFB0phvfzCE02+d7dIycWnZSSYdErwL6CNSn
#4XrvNk905pISWNrJT63slgOj8v8K0n00irp7LxYXPiHXP1ijo/PDqCvtFTPSuEld51Hr+OHA71olmDsz87QMvpvkDp0Yl/Oo962WAg8ALi+IS0
#xab/LR7Vn7X8FBVlwcF++WaSblTYSS9KoQsVJ64z1Id4FbpH4WMwpTcTf7YIahCaBIDi6nPBTmf1RRtQ1Q4vU5UcqYWlMUvGdRRPTjk3ikNoJZ
#Rn7aYPmFAI1s5fldzE/EYEeQ/g7LcqudMqps3NncxeSoZOHs/qiqJpzzwndrWyGD2gpbrt4QWuNQ51ltLYT/HAO2XhPOVeV1R4jLPdUzrY+yoH
#u5JRixEFxJnFKIkTkWjiaeNB7Tm2jl5EWJCb+g2F65S2bREOpoj9wkrLs2iRV75xiOIDPM5KqR3ZXdyv2mBYPFV+aQ7UMMpBByXuZWdNY/Rq3X
#287HXzFc9vJrU3N9n5tbn1Nze9WT3mToV/34iJ3LbbEy5GxzGG73FLSl95OQpjoyWTWHnviBpIffTEtUp4gKGe5b6gXCdQmMVS4AfjzfRwVj5M
#mmUlhKLRG/2YgCnmtH2THsQr3QvMbjpeUnNZzC8JpHijPEqijJMXMey9u5SEEgYJXwqYY+Hn0rVXwqprYnEsQQ1okx3wluw6DXvQmEMLRcWTUS
#Oi540F8uS9VNGvCKFQ3OUCQzdgPzwiXVuuHXgK7cD0ckVAdRkK1iuiS2fB3N+t0mIUGsOvnOf3fX+Ab4M3Gf1zBfrXk27p6nanKs9Bw7x40r3M
#vD3tdOh8gvn0yqHMFE+LuA39jLpE5bPag8fWtmyxOh6RLIJGCs01eMPysyq9Hxx1mUxDgibdA0onOflpvY5GwGw84U6LMYv9RSFEOy5/HKXyeY
#4uC6Cpwj0rXzr/0VR8FmWXMwm61JmqFLkmMsOTQArlsyeiH6goTwi23qYPJ7UMhZksdz3mbFaO0vAaHLVv8J6ELWPZ3B9YiKTFeSt+cyWTTr3s
#DEV2AMfdL9WOcFFKo4v68F40lRxFt6fGdYGKNc48qMESVZBC0qnL5ifqOp/6Md5cutOWMCNt7r/7p2ijvdxG2LzW9rfbVaj9RxC1o7tEOMlBZp
#wE5hsl6DmcGelEJc2b5dDXDD4DQYL3VBI8KZycR5zhdxbyWGtZisNG28qgoJ6gCIA6gPaSYY/TTk8fAOHUMSd+nXpglqR955R6oKjwiCs0B51y
#CsyKxzvvv+oKVyzXWcmZSqvHB9q1BHL/3n5xMSVIjf/bddWZTGD4GvyseLISzdIa0qmUdAo53oU1xC/WBLTRPNrKZ4u1qtbi2mGVd20e+XjueB
#XryGLR8x6JLGWJ3Kn9iQ8CVJb0/V64PlcKBy62j8uiNbDv/Aq8un7rUocJy4QGoEP5jsSqnQiLJtvy3QXpZFOjhTXcXlgnTZ97jNeUmFWN21rl
#tfbUOUvkYwkwpbMuVfQ61zUHBLGFpgOC1IcRzedCfp+BciNhwWY1Np0sD2cHkJ9UZ3Kgnr0Uw8cds1SugJvoWb4YlrJwsmw6gXnijDdbgeXJFV
#g2XfHcs2x7Qu00HYZluwKz0dWooEcqwBLAFZZ0ZoG/U944DFxhnl9CKFpAB7ySrBS5IjE8sa+m8+kkGFTOOZQui2/Q3LNVYppTPpSzdkvp+sq8
#snFfrV6RBWzZcxrMe/Bf5V4kayCeL8vUJpdsmdCfsI2EdaTPtdm46IrNyyRId1umD4ASHIDWwSnsKEzayOZ0ZFE6pRLULxEdQEimNe8cKmdORd
#HuJRplEzw2tmoxQS6X36BMt9vVfhvv0nABCvInQRzREy7bvZ5B+8yqO77w4eXFDwfi2qNLuz9x53NBFiUWPrp07cDpBdLz1e3ocjKYO6Xid9CK
#OenPZ5b8GBqxhxOvXNrBeyODYenxok6muxz6c3M+1/D8qj2BbuZab4hnWacDbzbQXAs+9+YzLIJyeOea2WMVWIUHzZjKMbqceTiNa1TYVecXbS
#w5WcAE/OE88I51QNToTvfTgumlDRMOBjQJjw22h5+ng7kFn/s2fJ54QTB02SQ0JnMTW53763D1MLp4GSyiQPvDlxf6RbbO8PFlFPsXevKQwBbu
#7kI9ge0IZCEO56UTlSiO2oXx2TMB4U3uumiaXR5vmQXqyLlQpTOcJ++GwYxElvdUs3uqLPMumgZK18S4hoO5EmpbQxOApWzNGWBz8t1M2uBEcx
#4MzlOmwHewtZ7cWu9Ea/bgKa2tAsM8ZgaR27NMZYPMbBZk6ZyUw/NK107ZT0+uK1MYikuESNPKdTrHBp1XXNwi4MYtLtSym9YcEIxFJNKyD9hn
#/bI/nE1dG6HplcDZV0xeamSAjVi4W5z5ZOD4iC92CWGcppnj8wyj9ZpCyuT59U3SZU567Vu6NercpoBH1be09sPN4UwlWMKNno1XMSm1UI3yRW
#QmxoFumSBwDRDdbYW7S5EkRb5wkJBJY8TGVBQfdvSsCHeIKW+h0NlRKM0RvO19IFg9IXVtRSO3yg4794QKr6jQsDTLmQh70XmRXbTVWJnpdY1S
#jz04C+QDNcgzd1qJvtsuQtPka6Iiaw3DJmXvDO72WBZ95izVgRhn4Fg1VmMI4OhjErbGNcYtes58UagZ9mi+MK+p47H5gig1sGZsvv1J4LuT8+
#c7fNw+olX1+MFTXoCtuH1ylhSn1TBLFWNW3xZzHomQhfnGYYGSpZ8qcIYGIC3TqTUq4ZngVDkxYLr57NenkQNc2gF3jGf4O4DFdc0T25UuUThp
#hjhjxCfwp7h35BQ9a2hlE5Y06vdFQ+9cNDw1mMfy/fgsINhN/caP9AoWK6QERa1X8DwoxMw7uNakTF/15SnD+KNWsKdewg6IgoUU0iNqDQyMEc
#WzVpYrwF+HqJxgRpWgVv3Fcw2F+jtX6b4TF/9VdN+5QvG1bbui9TqOU1F5e71eSd+9nNv4r15fRWtZjYJqeoUqO/DxH9dXTR//HetmXdFXeQVJ
#0/wSrRu6oG+qtMvmLupFbKkQ00BObDdeo0bMzt6eJWZnhYEaS0CwTPxXxbVLa4b/Kq6asjgpuWuUL6vBJQ3DKwv6l+YM/zXUkIVTXr7WH3Vp+f
#hPOY3GTipC7KXl4T8F5Owe/qtCToLDQLZBn+5bdlDIzNp13eq1crUNlkXbbDfyxkzMiH1q7E3NlyRJ0VysaLuhpbK0ptA8RLD7+E8BZt73ZDI5
#0ZdSBCsVqDK+6vxOy1FZo0yOEpGqh/9U23GO/04sDAuHFTOLSY548Ra8xiGdKw5IdaqAsSb4r7GeVB4Yyi/CvLIQWMUXCVDvARy1/MdJQUO9TX
#h4zEQqAiInW6eqPHbd4keNKlbN3MV/16orv9VtlKW+S6uP/0q7hu3lU+2cIa/lfKUkr8kbTaQWj+QMk3DRQDP2h/OpHZ4yOpRDGythwORj5iLf
#74MV3le5CrTPwimGWAFI2pOVv9gFnVoZcEOVRClwZjsKQRAPW1szhSBYKY6yoOsD6TMr4uDEQW5ckQgVjSxqnVmsDZ1XUjg5LFP3HGYdywTDoD
#8dkGAoiZC8oEUuDsycg0jTm3m5w8N0TfdYDzK99o32YZazYxev2hdYZETZSa+S/eL5/Xp1vUvnA/0j+KbBt00ybi3TdDu6urq7uzPuHCOKF1c2
#QBDLtzTyvo1bjt3SmIxAn28+QreG9jBu2V5Ly+MO6OvN//iH//JfPrrCAjcfYSM3Fx0N9H6dharXDzzcbHdpw8SwRaCgfjY//N7UXkXKZlCVpO
#zfBTDd0NcvXoV48u33wZ32XbT2NyBu18jXUvMlt0zXw1xZNa4Yim/EbDXTaBNOC+TCg3Ya4lfmWZAv/80wxUJXhVe+iRMfaBYdXGzwgMit2tDq
#UCc/q+yucN2n4sFSmGkcpZrVMxWnpoXjgqzcQXUQkJ8TPp6GY7MbpCJNFOchhIA31XkM5QrUnvLFbc1t4tluZwZyTFnfaZpFjWJUvD9LNSqKK3
#0QxevHeCGG/JBLPzNX9PgD4SCjXYh3DAqKe5NLrntTczLLWNbDMLNyyz4FjsJkLSVLaeUmvDpvgncy/6Z3al3ey2OQV19aDauwtJuWaLVsfJuz
#2EzfXwNKp/rFJzFsYu3TFYz5ouJHVh0kKR9MUQpOwoQKKYXWWfRP44I6ZBDlXLQRsjSF+sZs7urOGyvnzomjuy4Gw53upRJW+ef/83/WPvvyxa
#tPXn3+h++0d3+nff/l5xo8vBCj84prBkrEngG0iJYbVo/32NJxPGTM4tSIsmQ37dn8pj3zBBqqfU/5XnTP3os9eS+eJCU1WnvdZi4JMo1No/7e
#hOWnXDmYUMHu+/pl4PkD08ydAD2GMCqA0GJUTgQDkvV918bkm3X7pHQ28+S8DhWoN1YpWwgkwqgy+GeLK++g6lI3T6g4J/M4OlBvZagUUdoZxK
#FLq9WV5tM4hLLJoeas/uXANyfmRL90Zii/PWafnOz+XDW1VItBJONDFMm9CZIE816d2DFpeFDsZpXvgm9Bu7k9ZmhQ0Idag322tasxmZ5wkvhE
#lzVOF3R9WvQ/3XLS0MhGBYdzUF2Vqs49sdIVI0ZVvB7U79DTTedYVN0jjZXjR9KYismiYR6P2IcqC8bJShUzBtudj2Ji59k3hM1Dt/CKnTIZva
#ChyE0eM4THSGAKrJMZkSeLTqD84gRu4MMy8GfwF1Ud+IOq93TlJ8n4ApWCC20fBnefRvfjC3bKpgdNmeaFto0D6HkffEIX532HWhlAA4B0oeFt
#SF0WnDq+SONdcHHz0SyYJzcfMSL6O05DtXAGnVgX2r0FrcMfe3xhQdkEbyBm+SzoOQc1Pu6KR8PurM7FVam44boNFexqBauhuEPFr+RRq2dhnz
#GLrPnxxaXtek4wUQ9GKMZOxikHccUguvXTpQYD+BpEDdt8YcPyOAP4jD+uqfVt+Ns3X1qWx17QAjqm+T0s4hfm/3ShYeaj8QWaYy4RPBpXXgGS
#PRs7FjpwTejAw3g6/uPhXTHwt4cdONQT6PvQbc+EJw725PAu7ZouLanLAU0VzTJPnnw0C/cEW7wOUo1UV1DkpijIE6Q1lWWFOX5TGLaGEdgXVJ
#++X9w80TSxFMr4iMDFk1mUwoMQ2gzLf6iXl9Emin3eIzS2tG5e+dp6l4RvdoH+0SSGVd/6mxu8fyK73iMxYN74EPajRbW2N3/YBFoS7FYBiMgh
#XlXh/xjt0kBLfRjJu5+1P0W7V7tJoIFMku7CNDA01rOWtIINUJcdbN3NLPah6S01Ga0QeW++2e3jQPvI15ZxMB9foIUtGV1dgQIDFCkwpqtoNz
#MWUbTAL9H66gJ6jBeIn38zWfmb2wstDla42fFq4yC+uKmr+dGVf6MFqTaN3/0caLsNEI3oxyA1EJtpJJ/QkQrt3/5bPpfPgLZqn3z7pbZ3tH/7
#16Lkl7CWKd5/skkT7c//y/9GOW6DWJsBDMPKO4QONMKrX8G8cfp0jgQX+naO64cWvWxJww1Dgdvg4UKjEw/LaAXkeHzxIlqtCpCH01Brf/LlT7
#5hGIC5aAyCeW6B+gIBgV0M7bJjCFnDKKxf3LyI1sCSpkH80RV7DYPC0SD5reKlvxWxEr5VcDLBt/gQHgsEO1FQbNjr+PPrEeykQrG1B/bt4deg
#397/L/Q7+Xci4P2p4wezMwm41TdfeEgvTYy51awhWz2QW793qqQzKZPrErUGgvwCiDSQZOQFrFngBLZDHbGWezUty1S5X1BlwjgBEUHE0Db+nu
#Pir0w4qUF5O21CLeJbdbOM1oioYb6HLzSSzMIp0DT27gpJzHQXhKt846kGGk6WF4wm54/SupaRjE9Z05+Gk1UYpct3/wx0PSPf7DcfNY1zEwD7
#SsMUcfT3QJQDJCgZ3a/rZrvaJRccNBnJEBsN19u80S/JPwTEcLcR7oviJ7rrOthtV5E/K3eR8SBxBURI+ZOLm1efaJ9++elXX37z6ot3/+tf/e
#Hz2tLbVcKWCj/UN5r6i4saBgmz3W2AQ8RJdWTixzJGbjneUed3wpeHNBuI+PuJ0Fq5LTRms1ngJ3hyUe1ziXDMucu8DuQJ7P/pkoOcsR8s/6bE
#cf5qF2j7YHffTXd4oSKy/Fj7+HxmU9M5SEe3K74pXrAbrwR2JDKX3UIUinaLAmTEs6SNkiCorySkz4AHeK7dBsGWtYNn2XKM/daP/fW7f06BJd
#WNl8qrN4C6A/wq7DMUCKbkK6rtgmqwLiY5gaEtMantlB3DE7plD/KOgdNv06BETZBAvsygpBwKLMZ+1jzdYkmQkRMe57tWuROmKSs+TaXNB4ga
#IUZlpSiXMy/JPkvYMF3xydys/VmgoYVWJHX56GKo9+e//78lMjh5yFEjB8VPHGw/5SD783/9x4sb/6cgTiMGecI1YQjk+efMQfu3/w66hO0VGI
#mTadzBE0SkKp1YyfNccyzaRHfEo/789/9Cq0HdTG6+A6atBRhEME13cUADpam9WIJsDtI5SLcwnziQCBX/LS9kOOFd4b23tQwM0D9tRohwImI/
#3oaSg/STHxnVePd/STyhlqdh3TInUFPXqZLVT9PVRd00k+VuXgwMhGg/jcK4duJYfL4KTk2dM5Y42NdyUHzHvs6ZQNfQIEIo41X+Qz1TxlJnNp
#mNcRPc1wKe3j22wTgoWP93737evvs5RSVM3QPzK9cvbkmvuM0oF5GDHTRrjkwzJ13Es9KHLfQc49Wpmd4cgE4Iu5TE5LUPmoeFGsfeX+0CLjoH
#W/hgWGLzs3Lzp3l77TT3mPQxkFhrZZhQpmGUA7MWgzGzTg5xlin0z3/391mu0PZfdepGBdLMLihzGJYDVOCw7EEz28nXHrSHqFh9/KaNgC5Nl/
#67/wfTZIMCOCWlmIhRgml+1u/+ZR0wJakWS6jZs7BvnojQ+Fa49llr/7YWEsE9rPCsDg0zQ06mC/uo3+bw4hQO/yoV1QI/3qBwNbkpLxEBVp7N
#Yskbna4K3v1dkAJhirUUs3lNA+3NLtSSXZhi5BiBExkAyGMxSBTf483qp2D15r5AmyBeQ9MNyHKvhI40vRwfC4mMQCVay+aJEkwlvjhPyKomLI
#E8g3lyrxUrXkzjrwAcyFja7/4zoNz27MlUup9mbaMuhTflsW/w6QITf48vxLFJNVdZzRIDZ3dG5y/hY0XGl0ojUZzw0inffTltmif+RUUbkutP
#FELFXCagMLszSeg8eU8iOk+ayKgM8gYmjQD7hcJI1tCvxpOhqbzNX5spz5NfwJbryBZGuEUMk5PZalG12qVIn5b2jaD+fHQF3+skp+kqSoISCX
#kc+aiMwJ9wnZx9rCmGviBejD4KxUQEngOhZcXC9RaEPH86DbZoxPsxiTY6JSBhKtgVPriQNJmbmpb8vdAQiw398Lya29XJmrRWuEil5cpXCxaj
#0ZpCy8Ws81ZH+94H/hBXLenA7aAJKG5sQFE7ZT2XSqPJXAcms9mAohHkafmCVGPFyBSdjwr40YuX3xtoMbE72osldoTcCi+yDmEK4TTUtWgH7a
#HNCSfEDr7923/LbsDWutorYm3/9q9am2YM2i0mDgo6udtAaSkPNz4IXLLl4vfRmnLP+ILGoWyggj7sY44/02SvG+k9r57F1laGkNI+lYbwmT9P
#tW93m1uY2Dcwna9BtdEwfvbZpWVef/Lga7/3b/31DjTJrvbZj/7sRyL0WRflnRATk1TLDoDbm2kANPWTzWa3qpcGyCrDakTAHjL8Ku9UETWTaR
#xu05sn6FhJtd+MofLNLJqCiLtJDcClz1cBfvz04ctZO5x1rnnBb8eHJ2j5HLUKQ7CDKUNczbI1ZzXU+ob7vW36lKkO3bld+LTsuvuu98Vw733R
#E990rZ8urm5a+hMyeYptDjVr8L27suyuvbcctA7zcN4pcC0P9twDUM0BIPr4ovwWH9NrL38NPaC1U+wARuvurd7XOO6l1WOFmMWyVMxyv+993d
#eGK7fravAPqthmXgXNKkKFNQ5c87r0j0qQ3UUs4WlDzcN/vMATPwYcEDvlY/racjRvRQU1XpTYpFjUNo2B1jM834UVwB+KZuv24an5Fc7R6K8Q
#zoalKAE/K1gNLGdbK/gGTz1cF7ksK52tFK0TZsLXANbDCw0gbV/wOHlcGR4mf2HB0/ieL08BT4CPubf8vtbPkKCnmfuuRZAe7DlU8bpKEWY4Qs
#0xLM0zACYGNAJr0cO/hg3fBzgFC6fkwg/MBR534XHX7WIhqJBj2iRaSQAEGEPLmtVbDgFQ2gCG1wXod4e8/Ha3SiRst21cnW5v1XW04VdDwHn8
#8IXNB76NQbQXy/cJW8yvLfRQTwGoeFsyDM0zeprThRdDgPPQ6E1hjWDw+GPDpGyYqGP0u7Zm9LoO1OjBVAZdA6rA3AwPWsGPw64Dz7E4vEOQ9D
#AbDXbw09dWDwGWg9pELNCwn2EXPjhQH1a7R8302D5lzcLfPjSKn/uG1cV3CEWbQyTZbWB+4oaz+YazacPJXiJcub1Nf0z4iw3Bz4q6NADF+0Yf
#V66fPyHw2oDY7C8t8tDAJe118xqABtkDNijMIyfgpUN46eR42S/wss/Q0jJcHGdWAbbzI2uwLrDeI/s4owpCmSz5JUBbHNAWAbovAnptW4D4XV
#xO+MmQkQzyJXqGkBsCjsC+x8246sJHgPyQ7aEVIRW+xSxgK/iAD36ijeutGHJ+hXsAtgt8xK0HqGGvuoCA+Mry8JWNOJqRDLSzN2JMmUQgJri+
#hZhhcNzVCC0HKwMpGRIDzKtqQY84oAH0bsH/chUYN+4XrfQQPgODEhshAqSojTN3tUqbgHrd6jDwZ6UYhUb7a1Bpxu1aXzhFE/Cst6zUpWK0Om
#Jl1mI256KJYhSKhmDYXwzLT3Ec34ujQFBUK2sVOGgMtivFELL1qACUreD3w+ocNesLcUHwAMVStSBQkKPUvYTTA+Kn1uBr+LNCLObEmJmExKID
#zfnC5T1hm0icnDU0YH4vPe4ChXfWeFxj6RTPNZRGug4KPN5eeq7ZS77n0OMj9uhpAx9HxwEJNaYmEGRgGfjzhZM4MAinO/wa067BDvYt4mpD3r
#KDBJ3vZma2lmbuac7S3btf94C6QmXN+Rp+weBckLi+tgBeLsoP8Lq3AobOOVosSSy4s6EydGqvgPfRppVEkeH3rCKqrCJPBm4DFEIbdPHXT2Uu
#j8JVJnn5DzJEeitg+gPk/BmJoIT0Av32iFIWhLInyBUep5QK0nqyAnTFzNWScAEsGuYCDFbr4dpaII74PdwLtGbwHIWxPlE5KtTtEZidvVAMn3
#/BcYCZiiUYWyA5eigm7L0lrkWvBDAUtgaG66OEyboFLCE4+ham6MsfZlBFh4qaqLpEUxlnbCC6DQWGQgGEGJpuGwm4HMZneSCQgDAm4D1gCLBu
#FNDwpfiiiy+QwaNYUJmrUQgA8rsuvsPhHTPNJJyO2xt93hnftChgSQpRsmGD9LIIlNbz9vzj1nQX4zGoFxhG0xq1MEyp1XneQiNYHN0G5JvIC2
#RPuxy97PwBxtxM/S3qcbvNTHr8Y4SmNvb8Bjr99vXmh7dvW9gLi3VpFWOHP+N2R1DB3uyC+OEl5VuP4k9Wq3brNTfE/NDqGPMo/tyfLtvB+OYQ
#GCFeX/nFq6+/GofTdmBguSRIjXCqF1/mnWOuxL16MT6gMW42et3itzy39NalO7Gtidf6QW9952+1eexv3v2THyYtLBVMe4PhEEsNZ1a/N4NS30
#ZbfMPuAsU31qwXzAbw5rtoeouv5pMeNI6vJkNrak3h1ec4oTiSOwaZdDZ0qeNnn1J3ljkZDix8Z877nhfgu6+i7jyktz1/FgxM6tIdmA4O5rtg
#sfADzOwL730n8ByXWp71p+Yc3r9ARRljP9i4JnO7R+PquY45bP2QY9HvvhwfXpEEjxJlqwKKFug/LZp6C3WUFptrC7WKVj65FikNLT6dFiltLW
#GILRChW/mEWkxnaAljbJE+3NJfBZsZWgASPpx8mOk0Wo3btzpaSABrDuzpdPzqxevbH67DeXvaiYN0F2+0VrebWqPW8+lr84fnrWv4ZtM36wcM
#6NaSMTbx9u2tfj/G62TjNm9qqUVzLencj9v3HzrW8+nSmC79+EU0Cz5J22an89TxzGupj2UCSPr8/nmL0qG6A8qCC72x5+32/fOeS9U6vIjjPe
#0IU5osxtvxDc6svTXC2Xg8bhGStj7mf0f4WN8aNGmYy+mjMyxIL82vBUjtTiffdPN1Ok7GN2HyWzrT2046z54lN+bHXwMdM+arCGCRXNFoAWAv
#0zjcLNriu6fwrmNs/dlLQIS0bests9UZtdBOnvcxC6bYB1+fdJxv72kMTCjgRpZ2KzMOtTrXqbCdkwzCqUFG+hxYQULt8lEl4/Fmt1p93GqNko
#4BDA7NVe2r188+urn44WqhT8c37UPrGczjmb/eXgPqfYSfVyl+vMGPC/p4gR/f7CL4cnw9/aEDBANx5D98/qdxq6W/HB/yUOLR6x/0KRCgYHQ4
#HnUkteMD7Bm0DLWOOhYZQwlyTtKHcNy1dKwdxDRUHeY6exjPfdgn+hawnD1FEYc/xN2VBrPs2/5VjieAGilMKDX85623reepkXaMNPoqugviF0
#Dq2jmZI6whqvrSKIKg5+Fm1gZEk3EsrxQmX91i+/S4DS3HgGWJkcDM2veAnuGsfd+BevghRQjxFBD8Py1+9/Ni5S8w7tqPtdm7n+d4BYpQ4MMr
#3tNnn/8WgLYMUFLYBBFQhClsVMr2MIS9P4V9mtPIyQLKoDjT0jEANxmhy00HdA837CMeW2efYAuMHE9P7vBKbv2JpuGJLV6BLk/lH6NVMnJ1PM
#x0N7IGPR3vYtOTYPpdgCnYWSH2Ncq/fEVMI/v2dXiff34FrJK/gS7jYIFRUUBrf/sd4NUfXsKv330Kvz77HH59is8+fwlUGQSl0cCkzAi8JUDo
#Ke8ct/kI8I6FP+GnOYj9a/++pbObIVtk/UQ6CahCbDoZMXRZPUAzfKK77ewP8Qqrw6dPsp7ynfTtd5+PDwj+0QEI8+/f/dy8EHfIPzijBP4xm9
#j9fh8/zYd9x0LmuQJ2QGnfhz5sBQBGNA181vo303c/+1nzpjfxZj3evOd43tzizVuB4w98Yn6DoTWx8ZPTmznAf3nznOdS8xgWH66o/Zf0kbfP
#B8Taz8ZJ7ffnmE8EWw184J/EoDlLzIY/GdrOlLWPB7tSav63UfzuX1LevG1PXTfgzZvQUDDkzZteL3AmxJ093+nRRCbB3Pby5jn/pubj3SRMqP
#nv8FMGe0qXz1tnR1R461xWQNhPbc/22OBpuNngB5jHhrVOlyxT69/ip9YxX/dPvvoKNuDL8evXrZzLorPjtzF+hFYBc3/QxZf+7l57959TP026
#f9jgSBGvy0W076IHH0g8FmFIL5eAHkCYC9b+YhOw/VBp4VMgIQkuI26USu3Pky2v+/nL6tsvU38V4ssvX1UbfuFv/Bkux4tPqi//0t8i5rf+8t
#vqu6+DexRL4O3Xf2z98EMGwu8+/93vx4fffgeYwYH2h5ejlgSi330K6ypC5LPPRy0BAJ9C5Xy+n0PtfHpfvhq1stm8+GTUygb/l9+OWnysX/9x
#1MqGdqwQ4iQFyQwIcYn2zncbusRVS4COtjuHNH44rKKpv3oJcjYUN0BY/jIN1u1WQtGAf4MCNHT78pvfGwmx23D+0H7Z6RynfooSeOdwBK3Ij9
#EDBGJcG1hV5xp+jaGh7BnyoDlej9FuXbH2DusgXUYzwMtvXr4C+o5JQCp9HDsG6wTrH44dvWeaneMTP3nYTLV8IuiyQAWhc0BiD9NBfi1NaVGa
#0m3w0OqgJiLMAeqC2PgB1GUwYUscj/07PwRZiQ+eaqJ8GRvRbQc7arMCsYEiTLuDDDNct0Xo8KbzlhuhjR3oWLTUAMohTEi45rNUD5CgW4wwF7
#zkUeL7tDMbE8SBT4PUkHaOVWjM2Iilgo2QZd0rZj979mxWCCGdl+PZ9UuDJKgx//v27eF4zfvlwkdHlFt2m2QZztP2AQ3dTGjhLPIVi8OCZ7CR
#WjqTWEBCQ4VP014ijDHtSzL+hm4SNZBpLjbtwxF242/14j2OoJMN4aWxjhC9vgTZuHMQv40tBN8aZ/g1XXfXam/jYA70tRsHs900mHVZ4RH72g
#F9lUoHMO+8MwMlFibdHZ8c5W35H4KHNqwdotft9XkocyvCXMRW5U67Le8sYQB0yLa9zlBnViuzz8I9YNrMICnk97AS4xbVbcEzRLMXLFvHeH2d
#t4CdG/4WBd4Xy3A1a8+AVMhkYgby+zpC0qTbA9ruJbqWHWOTyVqJJjykbTTH6FsiCmwmu/EmuNP+8N1X7VYWRYApr9hZOn8bJnQS7wEGAs1f7Z
#2r1nNso3O9M5gzIqv/kr5RhEnSPhiGsdUB0iNYLoY+qp256+g/5psQQzXaOabRRk2XcXSnYQefxzFoV+0fjQA/PHvGPxjrIElg+YFuxQbeYrlL
#qAWuIP1o0PVBb9++BvZ05Azq008+G19dJssoTpOP/3ry9q8n7DN8hKUkSLEPycew7G9TEA7x7PPbJQwljSjC4C3IzjDat5RZCfWct/tVtHg7CZ
#agRmggvWsJiMtB8haPTYQrCkV5OwcypfmryW79dhvNpoATb2FTghgev70FqEW3wdsVHkr8GC9N8tdv7d5fX/VhdH89e6593F5i+N/Hb5fwq/PX
#k6swY7cgZSeCMrkeX337qv3xqA21Ol90Ps4+fl18fNn5+MoI7oNpOyG7U6ZNrj9uP1+/tn54+9bsfAgKufkcv9vsu8e+OfRtZOYC0x7UJdj8Nx
#hYEc21MOX6E2NYrY/pwYh+G1A2iL6cXZfRMtqsHr5G00abVouQE1GAvhmrYLMAfGODxHXMUGnGMQewukVNA5U7bMkTnmxC2E6pzlPjfBakAOdE
#Zwiip9E2nPJnLZ2Ghx2t/W0b2ukYaKFrg1jTERF3TXj+NZSZsZLjm9d7tDzsSSPOUY61xc7utxEyfGH24zXyBewBHneI2Xywz+wxRPGuAUx/8z
#eg6gJB+Wbe3mPiF1riMS5ye2/I0zFmeDkEAJC6zwewN/jskZYFiyh++JJWxDJbz561BVLLtCp4RZ2/fdtObsZD89mz5KNx3zY7nWfPiqYQMT+N
#QaRAtM1IGDRK9lEqSKA1gvUkmM38ySr4gLfb3OcHsBmBLAJpLfqiqDPs/gPxob+gbdxhOjfA9eo/XX7MN/FvrkLWCMAV1yzb6cAI1mNhDRL4kr
#Wop8txYqTL3XqyQWjyXXBIRzPcGXwUus+/Tpf+ZhOsXrGn+9Ej8F0PR+10aeAlsLD138JHfu1xx9jFK9Q9SvsB2Ha02qPwwXdCauSIAh8LnLwd
#M3uHprJ3cJGL01MuTry+/QGEF2M/Lr4LxqRj3nKYyUbF3iw2G6P75c0GIgbAZMS2YkunPy9yDBwh/rGHn+c4Mmqh0t3S34xuddDgvwsSgEoyGh
#w7ORsASEoEQMuFPWkSsLCvzR9EIoOVYRU68MNf5qiUrzlfE1yGayb4X4tgPj65o9tojWjD2euXlNzvk2+//I4MVSQmoD7JTVhAIP70yviWvrVb
#DwASfk9bC7NutXSet49/Y7W+B/FxRCa0JNxQ4kxLj4MVkFidZ+w70O6ONtTniPpkdjIE3jVrBXfY9+Rfaj//DZDDaAXiFRkHidCgaNFBjYB9Ii
#UYm3yJ+QhfLDEceIROAyjKfAOA0mYHv8YBCAt5H8Htq6htdrJO8Q/Go0cg2Qewn7UNydFHGAG+giEURsu8XetjQKYWufZautUZ0TcsDV+uoSYL
#un2PurI8RfLXVyAjw65YgCjDCuIe1YvmCkiQfMGAi3bybWe6RQmDwZhP60i05fqJpGMBmT7kpkrSMHBtOhxCWIIgRBFzQNEJTFR+X5Hh4gDEhb
#UPKjadHizJcqjrkM/tr7j1EwYF7cCM+HdYKvYp483+BgUDzuVLxCE3B2tdjfjhb97ug330m7fRfB5OQdy5WuhUixORfM6cOd0LIuRi3G7fGyJX
#ffZM/s6+cGoQgsTPSDny0R0ItzDvWfCH777EM4zAUECMBuFyuwqB1lzBGLbRFlXIfMh/g2PTQKHK2OxmfPPB1X8i78hvQIaaB2QJfEt3RkL/G8
#SKt2mwCvAOQ5TEwtX6bYLRkG8X/hogCLLdZPLw9nYT3a2C2SJ4m0TTMEgfMr6y6bDBQkebWkCy/q8QbILcgIxrDOCpMjJsENYnkRvMJ0WvGO37
#yHaB761C6AbvWhHEjcNCxwb1FWzhkdAL5zCf7ABfvoJ3O5CR376tvC9e4VpnPdglZDkWHBW0Jv/F+FDlWfgCtwIj21TsNUhGmWjJvz9KeKuIaf
#ujKGhlbY5nQNw/5miJnzujwwI9EQgY/EuwabVoFmUjCXCyTTvV97mVJBP22Oj4rK4zdvsSli9Jg+wvqMaLESjMPv5a4a8NicZIUm6NzfPn1yDz
#5WB1CgftYnxzayxeL34Yt9lflKqfAw27NfzXwNLpOfvE3pBubeBMOrfG6jX7SKXyL7wg42Oi0aIya/R1vAzXoJfE7cMbfR2gpRwopQ4EfqNvxp
#Z5FHb3dvzr8XmRy/fMzLCxDtjMtrCZYI+i0TBDzDF/dy1IJiBfnyGcbDsdfQpCKjOfSMI5bjxBKpyPmdytp8DCQWJE8Zx7Qc1rflZxDusoLN6B
#jXoBPGq62s2CpL3odJLnY+fYyWrAN3ILAnlpe/qc9n22te/HN1CbnuQN3MPO55JO1gR0MqfZP3vG/gLLymAFzdtCObaAz575gM2x4aMrCj6ypz
#Cy7tjJCmdibqwno+Q5DTEGlhMBlf/QMlzgcVRQGOoHiBYG3h9Lbi5gCZ0OiuFx2m77+gRY5sRIur6RVGoesn0DY8F6MLBrWBOU19rsL0davjzs
#2Udj+1gQow0jlNAa9XwtWoXefIPLoKcCtt6NaV0KUpYJkncZdO+M7S5Ztg3DyNZAmGqTPC0tVdFBbQ8pTrfAvTuuVwLjep6hPGoO87j1cUsKJs
#BQEMZNWgqalbCd+6dXQLdwrwqT32e2lFyBkLRMUXleBzKJo71PEuxLUFJfA3TITavDB9AdYvL+cf0r40Nm5wdaGsAKSQOWycsoX6SC0IwANJzY
#MHWtNEUm2bQzbpILOqAv0qg4oN++FQ2HuzTK9Eo+3+tCQiIxTiLx/ixjQRygINlS46/fhD/g5NiGwb01m2Urm5uX2TBIHLvm/mwRZFDlh2uhzD
#i+fvNdMId1WYIwxWyJrT//138ERCtah0VXnp1l2bfe/ZzgqfqVTydDg1aHbMiSbbokEKpwB93ndHi3LaBNOs4nztQmUBFpiBdfIS3WZi0fcwTS
#MR6eK+Ui05SwXz4fdig4wGRb734GlkFS7J//7h9bndOQTzOxhm0lEeS89U920yzTAa8Xwqc0jnb7dz+3xOFk03ozfp0Wi8EXghCBrdib6zchUH
#hQOegVCECFzgB12q1oA+1uQX5M23xsfCz/4x/+93/V2HRhF08xx9hIWjHoAI86ERmBZf23f4XlEleLtwNKB14JMYKCQW7JRIZdUgx47odm4y5q
#HDh2YAB6qCe34XbMaAPgBKqkMAc27zTGibfD50CQOZCf5h+vqyiRbf/x6wPu3BTEHdy/e/i910P4HR4VZKIgqiw44oM8OOKHgnjCLuN6N4wThG
#+kWALAC5xRULYcWfakqOKEP3IzgVMExpvwuUXwQAFLRBOuvl2Ta4SF66AoqMaITItEF+MHHwh7m2isSJa6b0JgYZ2MiF0LKLnhYG3jmDpPxVq0
#9TbPnn2wMfbPnolvbqxONu1NyUGBbR/PxqocVUifnYH6i4CTSGpGObmsNcbQm/JoPqbRPxeCnmQpQgaGBcKCNNER1J5d5wvEaGYo+loYIiDqwk
#pgXhTJGAB8Nfz4b+nodhJPxxe/OQTJFB92jvkJ7r8dtYpMKsBO/zbLppIVTjvH4tx1lmNqw0+1gt6ct+pjq/wc7PdRGCMBxkOOAb/rnh1mvLgR
#ykvHof/2mk8DfXPSPNB2wWMAMbqIwobI/PHokmokzYuiGJl8s+nMkz9sZ3j/RErVJ+fVzq0qDAicoP13nvGxdc036GScr9X1RGiTu61ayZ2/hV
#f7KJxpE4NlrfuPaBuTShPZ5UUl9zk0DGt2TX/KLvT67vQhuspkuxARaBQbvo2jbRCnD+1Wt0uwJbzCPHS/OSBN6/xtFv57Da8/2W5XDwg5lnf3
#s2AaB4wMCYjLSdehIVzXiIU43f+PvXdrchzJzgTf+1cgo7ICQBLBIBkRWVlkIsLyVl3ZyltHRnWpNzJUCYIgiSRIMAGQwUgGzepp12RjplGvWp
#rp3TaT9kHarpZpbB5mNA+ttTHr/Cc5P0D6CXsu7g4HCEZkdfdo9bBllUFcHH734+ccP+c7iXuYVPS/P0tMR9Hf7W086T2tJbkF7xkwOuo9jFHO
#W6x+kOveYuBXQ3/kSqXWDdZMiRWORCu82+DcSzpWtTjxnZPr+wbQa3RFekPLJo2c1AWiUk4oA9sV+sEO1gwJT7lm8FnyzJsXNG04P9Eh4fq0QF
#84a0mxZfqc1eHXwbScGerLoE+mHfW6eimgCpTLIKwjLZtAs+H8PVgoyVQGdWFcfkJ+29jd99GOFTi6BxEasB7DPIINBVbJ02Ayg80Kd+0+/iD0
#Y2uvIeqJVLvcWjKivIF/O3mK6gbjS5lTEIwoJ/KkdoWOmCeSOgrPZ8dDcSLFthQ9u6g4RnGLGkaK6d1mo3Gr5+BQ2isujdXWlYWtq7mLudkddV
#+5wqeo9tU/qJmfmthItBugU1wvsoor5fISF0hxR/S1xj4QgwWkyLKd6m5wpm7vyN/t3YLGthvMaZzAmFi+07PF1oDL3S7YBvTHmeUTke5VvuvR
#OzE2jNMx1Z5s6oAptVmIq7QlLGkbuaoCBPOxsQqMHlKshHp2dTVWK7Jb4nUltiJ9XUmmikjc8vsuEZ7OaJiq5YLbh36LxqnAotJcpf1Oo6ndWQ
#Krl9cXkF46xtlt8UqDez7J2W3RzNWMRFSpmaxz5AqzHcVTRdJ6GAXlxximqdKEGCt1CORNJUeNOLDNIZ510DGCeqOMgIANz1aKp0aEni4I4Wgt
#woUPYZDQVgC1W8OiZT8b9g9da0iG/VfY9Q/V4f8UmDCXjKZ9DHxwZGq297iRmjXxpmbahk/q+F26BxZvhz2uUN0hs4NXem6YuzW122Wz/4+Ijc
#Hot84n/YbX7fu22X59/UfokHBzCT1kCV+ClXHngD0WxDtLe1k7YK8FTrTf+tS2X2szYRgkKGKLXie9ykPaMnHGfommHEAbBu7w7u0j8z5ibhgT
#kOrN9vBus0VPQORP6PYO3RoeCNW/SnfGYQ99Q+4j7nWYmLk+Zxq5ulmYlLDusPYMevV1CRwiI+ALdh7qIb+L3bwq4Uf6cwVyfBMaM4fhWCGvqw
#bcbK95ZXz4xd9CDYH3NnNWWDLesmeJ9wYG/a/+sQAd81raXpi6Pul1AfEU43sX4JdGQDG2Dl8+f/b8+J7AXRo2obzBinESC/jmd6eHP56ZQZrt
#EMwWbHcS6dQ4QtSRAjwsWshTa6OVDuj0elUSz1W3bzQqlQtRyDTTKC0w+PrIbRiuSQjF3FyirVGdLC+mEdpd4C11P47CkWnA9o1HHd9vYLMurr
#OVNqwdWLli9WFuxREP/bUxZ+lEOSiVnChWVbid08nWhnmRjr0ooiIFeWPmdMXKn7XnIJCapDXFYujTquIQbwPbgbIUXmu12jD7kF0lz5VNbBKP
#xQ0eCxIE1NCuM4hdV7EfBK6EgnqdvgM637UHsYWeMvAAD7q6OavfW9n6DgOE5EVkYWcJg073VO2OU5eMQKdmDUlNHTc7e7OU/vnnn9uOltGqo8
#9CUmBP13cSuQdMqbGIMF3mM6WiY5ogIK1l5tA8kzIEtdHm5k+2tyfioDlvi2ipfN4p9tCUe0bvGgy9Yi2cCyc3IrtKDsPkmig2dg/HysayYPZ1
#taHnWDf0pDzhEXM+yDrkZ0ALh9Y7ybw7rRY6kE0XeWJgK/K0F5z2S2Iydlq3ZWLk3Ni8TNTaOo2c/pmtzbJNteU5TsK5zspFcF8YvrwTOn0UxM
#YFw9SuMInbbLo6poWg3oOo8gitWHDxIOgULD4sC5hxwWlXrAoeme3tinfs7Oq5W5Dv1plTRxha07Z/53Fe6ZYNuViFswjPFjUdOR87Fj3GSMEp
#fMZu5OROkvBT85//6d8ZyAPRMlPCxbTgPfaOWb93Gutn5ySO1uEmtk4eJNzj8wE8HpClCXsckeDh++/ewMueN0m1FGfq5IrayjNLspKn5od//w
#/Gk5CwJ/nEgVqA7X+Ggndmo0PIh//4nw0N85eUY0UMTP6MOOt7PWyeKJZKo+ad0knIGkA9nhw415CUKylJkYI4p9yNZ6rbXsiPMUrI++/oSIUr
#VyIlnXWNPEdGVihpG/Z9P50fx+eplSoBBu6AYtPpcoIukH10oXwrzmuQG8c3eCoR3pX7Wyes1WzlypuesobhLelufdxlt0xWgJ+GteaZfNCv4S
#9+yzNBlME38NLnKy2Pt6xVKTx2IKeER6kPBAEqW/zs1cS8vOSrxMxrBDfb23l9IJUNFenkOWE/8E0CN9gjed5UORRQ0aRbHgJVf7oSuxE+K6jh
#kjRgtDMrW+inw9T/clTwlTN08dlp44xtxNWRWOgOi/LZLq1Ig/yiiRG5/BO8VqanCznvbMdb/5j1xCqtOjTOUMTb3vZI0tNaIxj4pjpHQVXhaY
#baQPqRhRGtSdCRN2vrLxyvbSWnXngmLHvImGr3tOOc7dpoCynccQrnttAfMuGr5OjVZJdzj9zDSBUnanM/jqPAm6gEymwmUjmktdOdD9/+xYdv
#f34G17u5lXnOti299hgq42Ttcd5ecUi+Y8BybEMKWB9ZO2LTO+I5YOmVeQ54TKiAShEBMiU+y1jdWHiG9Kn0rBcNsI+G8fnTuOdFUlkpYPZKha
#n0tClZrMCQucaIhzwZBC6fzQWajYnazDApTjjSE/alemmtusJNQnNNulFupr3W7j6R9twm7VX91XmNTdLWzedEK+NRuTvzVZC4+loq11HtH/lB
#YtVpbdUZbZHLK7dDTDeYu4pGM8FFKu2QFQjx58WB4KJVXfLjdPktcOaVbCQZdZYI/HwWbBTnEqIeCTBpLyLlrJD3AbfS1EXJAPatiy3G8sdITl
#OQ7hEucxwT28JypamvxYSWFvAioY3CoI4MKYU7FN3ClZLjdnbC9s2l4iFDp7lvl8W+CYlAtaaSfQpxCA7p4OOaszU6NUUbg63Ie3dRPmpb/X92
#0FaMeCD5RAIXluVC0/lU68iUcvKh9kwqLv4vlCRLiJo633kIbJ1KAN/DLDgyywmTcRnde+vwwy//Un0HJYmIPdwIU6gYCkKotqdJXWW+OP0Mj9
#z8TGl0C7oBe6kdO0/dNagDsqciKV3oEJjETOUmJNYJQzeIM2wCcJCsqTjW1nEpCtN0OiyqabrhwJj6cz10xNTv5uFLiG7SqE9jGHVgHn9f1ZNE
#MS/FmOluHb54cu+nTx6/PNHVRUU1BKqKyl/9ThqJiog/RaBXj6KkbAwKMd1iLdk14ShS1ZGCZYfVmge8+Je//vm3HxXMY+pfOSCQ0V/9kzb1i4
#JPvgjWgmVoa2GCEeloMfzZta3qqe9ezqZT2BPww3/56//wM30ZyV7Oe5biFQCNxiEjWk3HmHzQpJ3KsyquzExox6Hb22sHoeqztOKAVT9J5fM2
#4qirjts0+6JCERvVNXrepPcQ1i90UAoisPi9ThcDMpY3M2AMQGKSmDlrghM/d+WDKiUQEyNZD0Fl/LGm8Pr4sxqSttRJZjeGgR3X7jinpyZON4
#Pj3DAqNoFr54Ih0BPOm0+ephF3Mp6vgXh7hv5yvpdZpeV5RDn/2X81Xoh5jfZ2TQy/gKtZiLn+/AvotBP8DijP2VkbbZpUfkyCTlFy/UvjOBhD
#LkmgLxUd5kXliJaVU+TFODt7lU8nXxs66Edqjd8tPdTHvCfGvFcxD6Ga/TAZW6ZaNWyMxuNK9mjGEXy/1HaFKtUG7hGwvHM1YHFT4NFXAmG+/b
#DWdLm+QeALvGCjqIoveZeX3/I0Y7xwy882foQutaVv8FHhk+U12xVh4IhgVHQp6PXNJdQpvR/FNKcQpp23Ci4eiRNwqQoWg/YdxNUvkyFKLjin
#o3QURCSB2u2cPLHhapE+aYAba5hjjvkinuLTGNVppgAZE+hi8FfCiiGwh0QQU+hiZ7kGcUAc5lJYh38PNaKm98QeM+FRwWTph4/Jr0GcCSC6HT
#M6Ney+AaPd0YOSCjI8YhN+a6CsoJ2B3ca5Y9GhM40PTPsqxSTKFsqAUGOfYObObRoFd15ByDp0NsnZi2h7KBH6SRxFJ/HUbbDoKY4DZG3xlrGw
#0mEQzQNU7Tji8l7mNhygfy/zN+Nw8UDAXPUeCNAKAS/36Nnxo5fu6fcbYh7KTUOt8FgEQKjrwSh7ZKbsnWmqJk8Z6nXCw0Yn3NmRyqY37mYTPz
#RftDun3ml45ninb87O3FP8cfDBmVTLeLp63osi0Rc6ExvPEBJM+ajmfsIScYrch3W7UrEHwodCOUqLEAFmfGElnbz/zg8w7G2mUC9kFit7U1Gx
#oB9kcOLHX4Pwvb19g76LW1ppoxChY3EFQ+Zc8gvN3BmFFYyuXHLlwy1rlZusimy3t8VFXUwau3SvVilQYlUFoTySPfjiRAJ4kOicWrDZ99H7Vz
#fBXdQnh26r7LQx2fHqk8vLbh0mTQbX+GPrxrnS8wKp/oIMfxd1zwnhb+jM4e98ZeeNenEi2V93f314TvLIUBFFn56l4uRVRyd5cbIqNC6Oem4J
#ck00KnffiV3Z4lPWnyuP5hvx5WV+FLYTUwMPW81bD+/9VBsNKETV/IBNYmGBXl7Cn/oE9r/8vY0Ldzlp50+crC3WF2ZT6LxVZ60TQBJEXYgXRt
#gHv/1vNFUYoAVWQjcK9b7A4rMV2Y3nGpNoVOoPZN6ikWJYi/OagNmuHosiOkw00iEPpnEcEcGQyAcFHiHysqd80CH5K54vMDJiIJwMmBw5Le3q
#Vf40XACbDQWpIbjNQ4DU8vIS/9IgaElsIqQwDNozbRzwaVXnQ0msdwGhSDWY8he9LGYNfigYvWJVCczuSCxNZOAKO0zO22iuczDQQPrNEwLyhI
#5kQq9myWfCg8aaCDVPUQ7Cje7mMkRRl0725bH+gFQZR7iPTtQBPe+4E23HFfYPzK9Mrj3v/sPakWjWBR8J3VnWVWXhVi7tv87zE4YJq63X2PT/
#GaYJ2eJf1TQBo4SyYQKF/Ki0TMgHiMCKS/OIlX7eAgdqZ6rWifJZvmLMBlIDN7HXBm1SNSZcVWu5DoHLHUwguOJaIN3y3cqm2bk2Sa8bgIno+9
#+759KhqzFkOj/SIc2WlQ413ZggaYR+JW6KR0R49O3qfD3wC5CDkDGRQwD+Ph3yAk+dFFd4Wkf+4Qj/YOF9K7Xbr+8CbeHjQqFswjc3lwKCBCdr
#JW9zZBqJL7SYBV2ViPXFvSeBTFZV8b48jA9E04C0o2kIWd3rk9ZVBCMsGcxsjBAIvd/CsUjV2baYmhoJFcdFVTptxBst12STlttHNXdYarQf/s
#7qa2xggWKqPKdydkmIiZLGWS9/UapPlm0VdeBrX2RpSZnN4ua1w15ezMOupsPODcCE4uxHr0wvHAeyJSU3knxIX5fVldruoJ6LifoxdnokpBlD
#n9SmuA1WdIFmYJeXdXOJFK5c9s1lPOny9gopcOmtXlf4N7KQiBuwABvuFEGIHTH6Auw1FwSZNZFst+SmNOZRiXV3bzfwPyFM5uqQdVly7F10Ax
#QtLP3kay1ZDokQ9FNXAJBKNreHKMVqBQkA3dwTuXfaPNOtlZJAusa/SOJxmAZ1JHPweQQsI+ZPK5A6zTqlGeIkaD4kmCTJFVmb3eursRownhXd
#j+M0gx1gFiEIeiU0ALcBLYvbiQ4HsNdY2XLHipMxnk1Tw6RonQQFvZQAnCIH6lmEUwa2c4QdkQeI2jaseZCLc8tcSM+HWB5mFieBFIYDUQG5Pe
#TFJwFKXwQWjb7KdpUXXhJ4aTzRnPEMY+P0SYJ5gIfQhflT4crLSpK3LIXaSznhxV43d1UBEhGB+WCpszoGugId72Upc8WkIXzLzqobl0nV5KXD
#T6pD752EXxD2DjBN3jpROA6zNmJK1LNhMEFrBekI7Frs1FT2GAVxtftN30O+v2FrPCh2sKdWJzXQddO5vUzndVTTuZ6mmq5wlSTQSNrq/zXBrf
#RZfsCzXEGCNPQZ/5GOnDx3JNchbIdUu1FRxc4/6awLPe9yMAj0piLoOMJ9gZHDuJQvZwPU688Gz2q1or8dPDuRHgtv8ZzxbelsvvNWquneSt0c
#2xP4Wcn+Ndf1DNxNFn3x4IyXTzywkdL/0I0HygY2HnTgEZ6RsNJMWylFc4K4u7mASVeW0JVLGgSBWpyb2kISej/pvgwigrtAXANx2wuiIAso5C
#EpoMVj+A6eOUv4R6CrWnZ4D7Mu7lZYD6dBZBb1HCPsY8gUjTGoFiM7HtV7YYozqefK4sJ3wd095YrEn/j8hW/7BctO7RNY1On77yLevCfvvzNr
#lvZWCSl6hxIQWLkrPxEVlGfEcMtukZIOVH+ywKMGLBBd0ulErB8nfvB80i3N3bUB7XpVVtPoyiHspj1ZFXz2zJvr26mXbJwNTJ3EhPAS1Z5pMB
#GnDTUvd7cU4DjaEz42y0uKNk88OpyQJUXdQlF0SFGDp3lR+MjRn5BoW3jCtFazUI43Fo7uiqLsccwcy+k4VjnRa/dG5ePNg/I23VjeW1HY21S2
#U9KIVOX+Vqt6NKka32jCuUST9YG5f4EnDvAq77KJluGw0sx+2OUMh93cjnLY1RKg+GHaTqbJh6c1XxWRngl+Qn8YnnUK7l4d3WFtexs1YLk7WW
#7bK0AOpMdZJj3NAjy3hHX7x468+qm9eQz8YVU7kefmgZDk1Ff8y8D1h6ruA6khHVx11rLSJnhVccBaynltK4BNvQe9SOtClrGlfNjZwJ0I6aeS
#59h0NrPeO73K3qFBpl7pVdfX722ub9kzWr5w9K9Crc+yyj7LyE6QgMYj0nNmeR8NSotGf5UPT+GDTtFaR1i1aUnISyI/kF+rT8KVuZGUgR90d3
#NYGOSCHp45VetLnQkKZrBb7UYe6hTT1Wie+M6TajkTGaDSyvqIxfK91l/OLhmGPFGmCng9mCTShMGHan6EE7ZPtgs7zVYDr4UBw/563gmeUpMh
#h+7Kudm6osIs0Y9nEfCEqbR/l+YGRUvFuZfA9pe9gHVL541wfQIsRgMv/ii4QLNXTXHdWlhDJ3VgPqa7brPR6ET8I8G7JiAfTmrDXWBWP222HM
#9Nbykrw8hp7kS208dE0Y53S2kid5qOSjSyJvbOXn7/+Q4+cRAZRMWK+sSsnfatBmRl3cE/+0I1DtIAHz3iGFiLW62DA8TlEiGOmrfXQi1pagvt
#8BEjwYynM2ThxpqC/pm713L8jafdvjeZe2g16rMDsOsLx1/3meidBTxCV3BkuhbwRaunK9O/dsMxMAvQQi8ixx/nS+0Ju/eI2f/17peHzXprex
#su7jbr+wf2ot5LvPPHaPEClXYazpe36s3WgfM1Xnx2AA8azjPnmWBI11KLlxrg4oLiEmAKEHo9Syahhejcd+8liXdR7yfx2FoKpJZma0W2K9by
#vN1whvAvhX+ITcuyedFhoZc7LLj7BfvDxO0B8diFsXMGeFlr8k2Xblp8M164avYkzsDp2s54kvtEiUeRa40XtfHE3m05vcgdL3bGE3WSF92tNy
#8vo8P653uXlz24a9yxETM7nDD6l9IEu71o12ruUOZeN7VatyIEqiG/jKHKDmrkugn6RFuDna6924vsT28rBwl6O8C33Z0EX9Za/A6eJDsDerLf
#IYfq240aBjgjJ2qtGuewkipq4cTu/VPV7mbTwaV32bDPOnH9vOaew8+w5g5v4UVagzzwIqq5EVwUDgvTJHPvS7E6dg/h88OGPASeOm/RL6d+vj
#Otn+fKjyRT4Gpwja4C53ebrTL4sgiW43ISZ9h079WHu/fq507azIfs81Z+MnFwx7lXTzEJQiHU7kAzIy3p7X0taQuSRjIpzzQamBb0ZbPWukMd
#6aQtN206UcuNmnIuCmGKXNmhIdKnQNLzeOhC1+1CNzi9Xl626v94uDNs2g5kvlN6lh8W93qH7n5jexv70sUq1lv2EmoWDztQoeqmHzgwUFisbH
#onam1oegOSRjIpJOwCQRqt8tPJpd9sE8FuOth4qK3f4gct6BDoDRujHYkUUInbQEzP26cixWcNB3rPEa8/u+Ps76u7O3ccmKJnq8KhpgZ8s1QR
#QHLIPRlfSzIPUht0eUnQ20ved2q1Tr7vaNuSpP0elvBSZMpbMiNa4iewcdfD7W3+TCtHMFmwq9VqXIwTMkQ/00DgB8ZAzuM0fZ6Eg3ACO/sknl
#yM41nKfpRjEPhRhaKs5iCvG67LecmCUGEkalzcQnJdjdaglagz1LhTbpQqk8JWXFmo3kVax1VniOccWN4PVmuBjhCI7hmhFVUGmnv26Mk3D91T
#dA6EbS8zJr/9z02jbfjolQDiuTczAlwzBAeNjnm4JeJYsTcHGThy7nXTMUU5Hto8+iH8IQi8bGZM0BMQo96h3YfRS+IQFd14nwYJFkYnp5jFE8
#TFnk0xFSbC9nqzXpjUjado0BVMPNig86IyyDjuQibzoG48jgw85TCCST9EGA7kiN//JmOeGcQQjKmVN3O/Be1E7gkhi6iVFMejFwIj9WaWvp1B
#1u//RvgrG3HS4wo+CCT8YJB4Rhd5wff/JaMWR14CTe6//zXkMCGTHy8SjaKIfzHae8BGZLz/Dh01516EfSSiAWLw3Hgc4ou8Q4/Rui2Ceqqeze
#IZgkKkRuKFItGJ5gHpibxTeBuy/WmE7cC4W6zhxZ0wef9fCJ4QKgCJMY/H4ym2Ip2RqbfAJoJym8aHX/wt+nTOgyRl78614YauIeyKHs4Z7EJs
#CyYx8sGMu++/CzPRf/gR9ndxGkGqH86A/TVezqYJoijW0XoNSf4kiJ54IIYVGNYSAteyZFOC8x6N0jmZibSoKNyMhCyAEsMICIwoRCaSZY7wfc
#Hs7W5978BWEJA/+5lh1mgRnW60k6PX8iThzC6vUTyhIVRPHNjKRcqwFt/85NGxe8BdguEK05EMgbmGww2vj4O31tSujIQ1rYx7pHcfx0UUiPHC
#SVASahmiZ1VR6INh4I+ssTeZeVEhutDVmcstY0bDKD4XXQx7i3QlJuwsnM4erEWgHDDj0mLvlbWXxaxAZhsGiXAmwu/kZwqeFLv2DdF7GZBI9K
#S5OyPUvF0fW2hqlP+KUtDjLE3DLtTfQkIWKpzQFH2wI6Ihc1TuUwwr48gu1//GGwpUVi7jTX2cDkpJn83GXWDw3tRhpdqH+YzJLRpvcB7b23Ly
#yLmuJpPExxWcljujrlCxnayZXR/GaVaMhUZ5K2Pzp1q3Gr0wncYT6oA2URCcJmaN6lgzDSuEyeFFESOnmrW80jWYGq8mLyEPn18Na+aryavJEx
#h88RGQmbHaEYwjgUQIRNVA7+EgQXv36SxM8TYJsOODpA6CITY2V1crQ/LiGIrMkEjJtlh5/Qv1NKuO5fJCljky7sn776CpeEQ64G2UpffKiZhj
#nm6aiMQJCL0NzRLpM6jPEFHyY+4ytk3NsWrzLksC2IjGXpIEXIUqmNr3f4pzv6LSJsGKlsBwMADY+1+RdeEG/8kSK5NTixM3JxbOcS6WywshmD
#ONd6bui+NHpyd1CpZ7dnkJd3UM2SqXs990p3W/CRwy/racc/g5B/YYfqKRIDzia3Kao1CgQDeb7gl81oHP4LfVOXdP4WPMB4Njj1y/uZLfKgZY
#Maj4NV+KLOQN5iOuzzEXcR2NMLPTU8Sg9JsY5hRRFfCmhWFO+SYamVBtvj7HcLAgc4m7Ft415d0e3rXEXeL1TOcEMWoJPIQfYnxffIq/4gmG+q
#VHeKElTelpKh5pHgOnI4x55R4eF7Dd4KFuiXB/8+ip8zBMfV8dinUHOzEe4kOhXQJGpzu7U0hB1isyAd7IQ8qXT2G02EYI3oBcFZrOy3v6My9I
#YlPLbRLvYNBk07lxUqfoyZeXL5/Cv3t2MRFGJKREeKG/6y920rhP9ekvKAYU3mEupRwoIDNlQVcbyiFrGEpFV6W37PSAb+lK16XO3Wr8E1TRz5
#Va1puDrDIvHBFCkyiIMvlSwnTmmO/mS7U7EywC38dfAT8qI2l7c4Fak6OqkdSl5cjwb/IeqSUaGLHbNj/DXMlGSRWM8lUWmAWAmfLkUQp6GlYx
#vPCtDPqc9wvwXvrwC3awcw0sUBQPYg0uJtK86CKyHyd/E+UyN4l7wcnFFEvYsyeF3oXyj0z4A3uG2Rb7iqkcEPhI3RYn6+SZP4yjXpDwd88FZ5
#0pltwx/DCLLwJCVG+bPwYmHRiIxQ7IWALBLDGOis3j7qX8jt9/N0UDc+Tte1IszKuFGxn5sWReF1bKdIrBtB+GsK6LEYWS+Ny1Iqfn+I4fpcCW
#lw350mwHIzbeXMLrsl1iFgmrzogMOm8ue0evlUVtT5nI6pZohc/JlswvGqmp8O8DFygQ1AwqBBWgOr6+G3ldkKFkBudQPCGLGmjLQZBg/qgbL4
#Sl4QjtBUcr+JNvQqejsyPToIRoroz2xncRrw7/UeZkYCr6RlbBAeqDNh/OjDtIQZgX8u3kaB+itrrtYTJnX7Rk/g1VCl3IVjeXM2WBqDckQU/d
#Uiv4boZ3M7iDKuEl/OCNt6AbbwE3DByxhflrRpbT9s2lNd+B9PYucEgLukKd1OrTLWjzKo8+GclWx4WuT2lVKY/eSal6aNDH1qCnc2dyRtMonh
#J3oFeoNBborQ7jwXnLAbm5nECv8Mclq0VOqI1RN5u4lgfV9V1zMDQrbO5xhkl0Aj/De49qG2mmkjrip9ctG/3rTIy0K8Rl5fLCyg/5gNxQf4No
#/JKUNchgoYyDAoPuy+UYXySzLERv7HuwiRFDmgQGMNczo5uEwN5NMtsxnsKmBysIYRIMa4IQCrCiu8j0OSx2BH2QAlPbiGdSqwCFPgx9BHNGPp
#e0BEk4gI03setUVjFXyE98SAIOcrJ4GmWAMD9NUOcQ4WEUyPrA0EiCXPBJA8aCtmHHLLSIXvCebWrl0WNBt5XOoVBllMKBN+HAMzWcfbCJ8AkZ
#Fkyew6mBSCTD978aB9hyBHsKMJcsDFCXUSRf52yVKzyqoIEYrcwCzlLYLp+iv8JZxbyBL28uc26yAowxG5IpM0ExhnKlabCk+C7nQ49MmE2hn6
#OU4sGM8XmD4E37/b3e5x78fv7ZXvO280mr5R8cBM4njdvd271955M73QO/f1umQ/jTDZin5DzRXPFva2W/xsoBdcP7yarKU0Q6qDpQv8is6HiD
#6w8DGffCfhiw47Y4tzQwvO6cu59H5Ld/b7zAD4zf/qY8GP50VKbYyGznlMRvauQLefbc7FlWpnlNDq1iDq31HFpbyiCaG5sN0N1AMP44y6qPZF
#H5JxczLJBg0iPHt00HuL2ZUC4GE0wDCawkGBNfkPeWA8weCGLYoRkQ/TRkl8MYw2nX5WAQYekOcI3Fkx4unFmYEbFA+BzHIMowxfWOGlGkC8+f
#PHpIVKEfwZ9SxWR9eFVP8MhS5EnLk1l285nIlJc4Mumm9K7P1yf2HHHa8PYn3mBG3QG9iJpQoaGNEyyw66WSGHIdkfIQeh3UrIvCKlxAaxLSsm
#q5C07b/KH4/SLErgKmDKOnpDPh1JDnW/iYGX3zHtIf8tpE7ShqNZPZlKjN4P13Eyq0bsCgTwPOLQ1zqm1geFDsSXyIStHZnAV+6MjB+19PguIo
#9RfYdSFhMpCeSxaNy8dbgKCOlt7hhBS+pPPKZigbOMbQi2Lj7SykYEAUFAjGKIQXaLUa+jNKNA9TVPSmUPe68TCeYYb5vEH9yExw1TS2sM1zuT
#SILNqY+JlGYQcEtI+9lCQwu0Kq1BRD43oz/LphuAZwIzjTSdeP06bh7O87pgFSpJYLSpfmE1SIoLYoqBhYeG86rf2Gs3enIT4vb6f9vtpOcQCF
#BGWeUCdpsLwwewbBJKGXqJEfoIJW9WY+CXHuDb1ZpnZi358FYVSYJUIQg6kVcaymQMvbM5AXww0GHndhdlA3xzOauIlUD9b1jmCJXNUZ1eHhYE
#JMAU45rKkhJ6uz59zWP2XR3Twhh1IeCrHoUuq9JvQe9mC583F+nbADKBYo6kyf3EabZI2qv2Sr0bTUJTgD2FEIZ/vYS1Gw8Ice/ojsyuQ8GdDW
#ChNNOXdDLpU+LjT/2C2b/NuFLzUeF0gHTpGEPFyxNWsurSLB05Amte77Kd6QOyd9KiAWqC+m3kWK2g7e7UeSNy1KEoEv/OIE87numfbxwsbJVT
#KG8DaSosamXbi0LoDpVesChxvDKgDFpbgJBpIa1viBwE5DjqHccI58qk/z6CIJfYIgEKdXqOYcwpoPU7lSplEQTsTc1OZDpB150VTOJ7WDpScX
#2XCsbXhWKpW9T44fPHl8HzjPE9jRIKcnEictFTMscZBfcBC/BJY0XNbxkhLhKZyHqmGYpw3nwEiBRnPwVzUx8CgSz+CmvLuIOha3AFixiLSAMH
#7v/9OEslPfq6hj2C0/nuHChFXNnDFirQYJsLDQRqFcpahtgZ5BMaxboWCOi67IijqHU89hnQBlhwcU8dwxMCA7/NDBJdpSEpGb46linCLi3pR2
#bfQvh/VJ91E8wS23XmDaXsB05ypqQCNfkYoW5vu9F4/VoqgbT+NwInoOPnJhdxP3b2dx5m1Y7iVO+vjRD59JVtqXi6vISScDH3mxNV8n315jqZ
#OBENjEOryWXdW81aj5z2Lc8V/CRKH9F0SPLPQiySpAN5CmiprGi7lCnkXlFcnUfMznbrX2twxdobN1EnNMvEk81thN9Pw7Ua7PrwujMoyzmHo6
#iftEbIEGej2SXJAfg8X7/jvHGAD9pzMlPNwN6FTVS2i/Kg4FSL00FvCLyrfZVMlGGqoSud4p/R0lTcbenMom/DrTzhUzhdq+9IDLwbogOZGAjT
#RFR8SqwF2c0GxG1Nv33w0iKI4oyGxCEH9hkFxZ5WCBNX60QBRHrMdKPEckUDrAls8rKve0cEgIVFCc5VxxAAWUQxzjYeco1HJ5CoQwx9pJpB/u
#wOykPT5g1lIeU4kWoieMYWVlhiTviBSJEuoOYCXDzgWcvEPNm017PPJcGx6r4vGL3tJ7G49GgTFB4MkejKKfGcMsm6bUGmRRRf8LovXNY3nEVu
#96mbThIM0hUo6rlgGf7ZZmPpXV3t398O3f7VaVsGWkQGci2vzcLVI1rq0Q7dBYWydINPGsjQn2T4BlZGGzvL3h+UScrp1cYTo6GSTuPMVRi4wL
#ws2jbrYS7DHcMdg8REwW1qMQZfBBVunZRWr6AJMg0fxpPDuZdXl7pbEcBRe06BSmnh8hImphpsKICZTLlMhFHxpF4BxSkbFDWyvVHvZa3J0qoG
#Zg95yh7cUCmpimJCDME5zKMnOYIHw6KvA15XSLJ12NLoy12hTr+WVhPZOdDdbxUb+PsipsylUsndiyo4r6iuL9KFG54NVgaPQGxZKP5ZKhZTEO
#0P5rlkqGQ506IiWPyehLtS1BX0T8XlB4mAl6GRVIm+p4kgKraeq9lCLdpWg4YdrOhZt2c18EAUuLfFgxwAcwvaRUN+8RiYZ5x4IyCDDwTLDU+A
#RZN5RRKN4nPZmSuuwFbQQkBpMLV6Axqeh8VqmSgmrcXAqmsEohBS+kRmrT/kkeuDqwl1J4dvSGuxcyqhT3VloVky+cyACAaTECYLoWApCSwuOK
#Axo+YdCOaKyE8ASS6nhTIxPeFqNfojeRGl62H8ps6qasUxp8woyU2Mspww3j53Z+q8NG0xlKjJmfSI3z8XEeVJnkLl34yWUcTZRRQouSUc4YZF
#rMuYqYCkSUOaaCmqdBtNFNayS8g24EUdkyKshdR0ZOWZONrZtjkoxPvEwp1JhH8FBIMG3tPR1MmEc1eEREvS0vpL9gOam9RKfEDXHDrPkOvOUj
#CbzwFvKe7Goptpk4ipnjGk3m35i1EbU0mdtJ8exzXrO0ts54e4FaoTjmzkX9RtTIpnl5yVct5Rry5cbj7c6X65MZJtckK4e05Hlid/i3HNTyy8
#oFJDLiyGlS2yw0xp2rjjXT80xbMt1i0Ew9qI3mZzjUrCKkVS71gxBKbHlEKI2HhCdLybyjU/gSzzu2t+faiWzBou4+bLswt/GUUqj7Kk8u1WFo
#3Szkn+tlK42PETZSRLMltyBl3qwFhSOwyIIJbsnwVu8JlKy3t4sRdJcqkCEzMvOOerBpZs85Ih5nfHxMzscjW4R30iA1lSvcD1aCJAiSVHS31j
#xx4VuVTKoE8u8UhH0eCXwTzQDyCLuROMiQV8lAXnl+duZ8ktJHgrhka9baFSdjmYBjkl9eVUVKrman17V5bys8U6eqFXR8tZYHDJZcRPrTzoaJ
#TCm/WGzy1awqeL3QZJA7oepPndDVhd5esHiOTt0qDOCSLI5kAhUZOn+k+ZSxbVv+inDQIK/CghWNvKLe0lcvryYMs+6th4KZbE03oo3ufhR3rd
#MfgTxVT8lHK+xfWC8dckNr2WfOknEUSFvuEwe4i0al5gpdezb5YXkwpaL6MAn67lfHT8Rb1iygcWI3wte9+JwN+s2UJI2dVMmlZLdqQhqBDdwp
#EVvMNAnm8UjLlMuznRaCvUhzulzUNYKFDEiw7uhHISpukoCqIRJ31nwNURS3ySDmqmQkhttKNkdCtmGCVg1iISsUKW1lrUuropwEJRWiYaUFSE
#Fyod80hOXypyhBVH2q3P1p3kkkADYsKSA7CFQC2ibhu0pcyz4jcsmtrO8ealgM/TqjMbTpgiAZ+gKJwe7kXs2FWqPgYRdgk4UQQsK8pr3o8bER
#afWqZRmJqsxgo4jG8hKIEnBp3DxG99SvW/IGGyevPSCJy5Uc4wpkZbUNiFmpS2RYdZQsV+vepwSsrLdTAVcrMSpXSmhClGyVJN0SbxRP9QcTa7
#lyHj76wlkKYtNGwEh4IInP2aqa7lw3d69q+IpcY/OJVhVlDLcTFXNLVAB3DN2qKYft1RCBGlUli7kjtl2xrr9XtJdi9GHBjeTxXwqWvz2XCCjF
#XrGKgWB4b+3lEI12NkSLq4byULuhjy9pY/jYk5S8qZIf8Sh+FkTy0Mmnw96cZNKg53UzjJduD+amD2sucMUvrkSqjoAktXXkSBWTFmMSMtoiL0
#h58lSCHj09k5Cs1820/D2Rgk0TasPglv2stS8ExPQ6rc+Dz2j20QtlH/2F0KGFE3LsoUBi7KyRA9Sz52Qeoorx5dFVN1046YWTnjvpMOcMvr9H
#cuvgdmfdF7noFawVRR7C8A3+U0yAD6IA+gbj/meSVnj3zTQYmE79zoHuTq2w7GdJZEv8TRduNjuzi16FNEfKMsAYk4kI9ms7f6gh5yM9AqYOWC
#yzVLwOzq/FK1LRSWR8JemKWDCR5+hEgWZ8obwVdO/t38efMF/LH+UDTraXF24DBsb9slPpDr6E9+wB3sFE6AK+klG3lC/p1ziJOmp4tFlmfb0z
#Rp/p9KJmpUO+Hjtjex11Sg1EOPF8P2A3FlOg/ZdcGK/+pFP0T1QRGhTd/L4UU0azUcuKaSiM8bSEX1EYOmdWyTb27YqBW+tSeE8rzYELXmobOl
#gm5L61VHKtrztVjObMvqJnqQVGGAFNLfbpjDdA5hx/5w4tbEF/mK67nnY51/TuGmlrtu5cS9qu736ieJAV/lvbaSRvfSUF3DB8H82N/+7DPAi8
#cnCXghbTXgMKUaZEaaVfYX/xfELZ6F0AnxQQxPsY/YMNgXSTVyEFL5yLTVavOK2Ev0RZB7DJaccht5uSM84RGvW1pRNP5esWvm51dLXn1QF7Sb
#5QkSsSDFzBwsM9YIXDLvp3m9N4ijua6ZjsHGYKoUwocPw0PYFpiIYW/axt1hboIgMb3BSuL+h6Zydpwo3frJl43cLr1tWBcwMQYnHXwFKG8fkL
#roIl6fM37HJ3nfZRc675krWP2GcwKEKVX5R7sTAV7vdLpWdUn6zQgqhRPB5hBB45+ERAYC5ZdpGK+Ah7PgcOAL2XbOhIvvb8Ft580u/3zbN1BJ
#Hmvh7sNNg4kmgWA3TEc8Pd5v6t2/XWnb1a0fG2fuD03L3bpacHLV73gT4FujgDvsfI9hZwQ/n6cWp59q2efHEhX6RA2dQLzcQXZkF6Gn66dwbT
#gogVPLEOSpX8jII9d5h6bU5gclOumFBrao5ADbZzB4a1cCgiAD2XGrYghZbzK/TQlFae5fiFoxy/rPyWaQuqb3pYzwSMKMhZpYpeUajT/AxnpA
#RJ5SOXMO7o53f8Sk5Pi404BXbxc4YMSEzgVYzzELr03Ab+oUQGi4AWYWyHMYIx+uiTQ+hP+CLmjbIicwvEjkMtfEcwYTE0mNTDNP9gMrCX8Egp
#XAsdNw+RzYdyZxMBc2CptCiIgsAdx1lbB0VzQBQMUjx7b9cbt0uRutcPBT7xM4MijfS1owHgLVliHq45k6U59COwoOX6TpOA6ytrC5woB20V56
#YjdBWBwT2FXVgcXcKdWYl+Xolorm5HeE9w5htwyM2aWUYXh/IrEMOrYLmz6scqIpQI1onxVIEoWZ9RJKMiPrapH6DmzceYTy43mrIo1jLhKpbC
#dVYH6pQGgiLYpoqweVgVErNY3zuqvibLqFkYwe5RFlBnE3xu8ekopbCX5FWKJ5Pwc0E/Y74bX2gRpaYY0Bw/EDSVF7A68ZgCG6wVuVop0Nh1LQ
#5KV/S1OtvctN8EG9H2HHJsbU/izIIZbJt55GWsAwLF4S8wOrABy0aXDkdFdQMN+ijBY9AN0HDOws2PCHY4sJ29mwhG9yJ/+VN4CXsLvhsqLLBN
#B6DY45a12Kkf2LeaLfTI/CJcBD2rBePZCwbM2VR/ucAv6wc7F5u+vKJYHGFrQWhE6sOmzYetG7/Bql5UfyNPrq4acdgqcMh5NCC5grBETjjCw3
#8SmAcLl+wSaOcBHn9w4bYaDSdbuIOFk124AzRKuHZSQXI1WB34Sg3OCiGgQZSdBwyDjd1kqfURxfGUV8cNRWKHYa8XTOzlYFFzrWyxM1gAI9Ls
#DC7w9mJncMG3otPIEh8Wzdg16TICDmcPCGltQFyHAxfEcjgN21wlAVDjNFO+CV8kBIMKlQAiCxN29YMlreWR0GwWsDLX+4ANN3L9aJYjHo1YS1
#tdIOs2ZCE8LBduNTBn52r3/fKkSWHSXNidja7Mw14hgKaCUqbiULl4cXgH+mJt1DQeZzz6SfhO8TjzawSFuc4kzsN35jq/enBb51c3R80LKWBe
#icUEhhG5u/p+mb+rf15coynwlsQpttY4QYSFg3XVUdLeTi+IvIv2DqQuJi2t+9SE9pUC6G3kFghzGeXPKe4hk541h8Rl2AfNGLwkcWJ/9VOQN2
#nWOP30BP8hHqW23/RTOrgvwjN2acn3U3l0LrXkGobe76Qq3b8KvbECSbG1D/8XALsr0RQ5GR2WEoFK3IYzgH9d+HfuCg39lZiJQvukISEicKLD
#kIkOgyUWYRGr3o/cevOgZhE2oo3Yip2kRgiMt0adQU0AMMJ1tybwF+H6vOaOGNMl2XXPOwP808U/WqPXERoZuHENpZEeVyI1MrpMfljRYxTcMQ
#F7FtEW4cEa4qJIlaMucqIy8qJ4uo6+uNJBIL3M7UVH1UiQCHXp582CtE597zYZGnHduwMN/ICmrmsOU8Q8GKqFhmvTMGupX3jyqdFqfWqbKpsS
#Heyj596GnPL6+LVmwznQ9lfOee/2p4LDydW6VTX9pOm39vYbZmdD+Z/sdff6n3lmUUbsp18RAo1AA6Slidu4blcFlLlDL7y1F7AoLp7EHkFv5e
#Gs5Arv9CuEPn84kHJmvyBn9sviB6csAQMSmXHG7u48fLVrnf7J7lnNfrW7Ww8WAYUFIqsvZxi64yNTmiqH9YssHA9AuB/DZ7tmbXzaBHl9FyY9
#CFc9jp9QfzMdmG3Sayssc9KDponv9LtiV70Bd1cpV685UtgMUkjtkjmjgFo8YbgLbND2dl/hMGMOFtzywEDjkJ4mvgv/OhrdXWmFVqEUlkuFHF
#XOZDVVyp46WC8D+f08dvVY1oEeUE7D0CG0R/gD5Q3DI7ho01coR64DDVU5Jq0jIUcXT4Oxu1w5MP3CCYjmZIwSXTzuLdydFlwwNnJ08bzfp19U
#RSQyFZuOwcX9WVpCw4guniH7BrK+lQpQs/hJfC5hUlDiwuNXa/f0T7ydd42dz9//zc77/35W2x04sJpzCLScqbx4ALzvRKwvpJWei9GhOHOV3a
#v01g78A9Eh9G/uhk7h5TyYx2sPIbXFSI5edCkhHe1X3fotmTSHY6OzKCw2Wy/29JX16vR/fPvnZ6d/8sp+dfY/vv3ZGTwTV7JZhQ/++f/55eUZ
#FoOl0MDr72tWH/bsV/Wjyz7/DXAao2LkVZrXTf/gdOfDt3/x4dufnx1VtumS/daOLsXsuARmfqpALC8RUDK+HPYu90cbWi/Pf9ieKiuWCde7Un
#4c5zZYYtt+4vKEsManDdiF78lbL0ePvXHv8hL+5E5NT+zt7RtP8vt7tm17Lmag1cmA8RgrNFuhWjB28imk4cN6TtqGyShGr4jmGl28IIuCbJFV
#huDNIXSjCWLoCpBtTK56Izl6Ndm1C+jOYzeaAE+A283un1jWUfvV6aterQ3/4Pq03j6DK/vo1ZkNxBfGrH7LvrnLIva4Ep0Zdw3oglaxC/LKZS
#lWDskyl4rKrN1XpxYW06a/oly6xpJ3B7LG+baTpad7Z0cCO89s1M0aPYGdXw8d2hYJ4F3zzEZWIn8ArFatD92N9c3jtOLHOsLytJ7tvK1n6owd
#34uZ0zqCmzYrXtaA5KKLHwaZpQ0UDu3KzUkEsHlygjGbIWcm0bvT0Zki/+JewwKfAW0Hbrl3sb2NFhtBgszswxnHMLaP1p9Z2C/q+x8Ji5dZ4a
#S7CDU502Aj49ERv5IIktTonEXR0KV5e5CBh2L3sORAGEvvwQWDkIGs7Jq1YOLHveCr48cIIQW7F/D/c4UEvw17fBcosqv2+CgBstCtT4Js15vC
#Hq8Q41w9wONAtOdHFn5dM6E7jszaW2vJfjHfkDWLx/YrfJMKXHQYhMH2NrBW0ElB7wmRJNvnOTVQmJd+KcRYUiqPw0BwkXohTqH8FZsEMXp7mN
#Kvldi27ybFeGl6XVa/QxXettVEU8igf4iiS9DiKBTMksMGVEmsIzxrElEAkEO3QEATs/ISxN8duLFz/t26WH9rKyRXSuEjdc0T0ff453D/QK/M
#qhBVT9JO+rjQIFFpSGTLlYax4nRXU7wr0OGXGWmP6FCEzgPmXmQJxsPu6BxI6TOMc3Dtd8AlF176I6fZavB7NtzU8uRHUrcqWKTLyxtEHuAXJf
#e1U1zfzUnEg1mSwILDoi27RlxUrd46kGsqdInTuts42mm26VKeqhy6wKWKAkE4rWeHvh26O4Tmfj4MowCjzN8VCVTUN/UByLD17K4L39RqMkuQ
#DakIrcLM52mM+guWOCL0MUIwvagH1dd1O29APn1z94WUzN+ghufF6ZuzDR4Tb9C7yu5sSDH1IMXdsGBP/eIU234UthsyJrZna3XarB78qSVkQI
#6Gwd+wQS6MANsS3arv71ieEJZO4mlNXvPr3ZZNx4e2WbnnCPlsuS6fOSNENg+l9FaCgme2y14SMw3jIad4R+e5O5KbrpT1CNO0AGw7Ivx3+mh7
#21JTk1lxuzDGmC8k7+jSH9WlIxh36aOyqWLE+3ekUNDRhiP3fTM1dMEnglLKbVoLNigEFj5lIMmJalKory5McGc+kWtt+RGdIyv/pCPl8HJdn/
#A2GYlYu9NiNN2by6ieclxxcagUbBGUGj5Gt1v4tdvmh1/8Gj2+p2WPwI+crA3WcqzJ6tQYRc2EaRjPZN2TRRqMrB/sTIWLyRT6rESxZC8L+pQG
#wegktrQA2ZJ+1KZaKC/g0WgK2A57/Ml5sNKEM8/PvkiV9rhab0HN8/w1Xy8QnSFhuublVTXU9Lmz16ATek338nwaTKyCsaPyWhL+NsKCb+sJOj
#YbPZNhs8lrnOEktvQ5RCpZDseX63U6Ut9aahPFd1K62IKxjJeE3g4ffZiOSXMa0oreErP7y69LRyUbzVbqKBEgaodlposdLM7+8uv6NE6zpxwA
#k+ugW7fLaokjiy9g+aWIDT+xN76x1oKDymPqL7922SqgjkqFcbC9XbitnwddtA0vaK6/DHsYdVgjLZIIass8p31KFV7R2XISEAQUT6SP6XWKNF
#qcLg/Y+WIpq9fJh+EPNwpyCFSOfdXFIk9bvQoW4RUjsPoB1w+KqTiy40L5wA7h/lkwDWgF2xQDOG03zO1tIqCyxTisqvT1TPOqsvFkfhp2Y3Nz
#VBGie8VpZj/tZhONfPFq5aFbFJ7Td+Kb6868aQ3lE2A9bYY4OWlGeGuUeP3Ikj72S7aDN0VIc83niNKJh1cnpZQTkHlLKZdQ7+SZN2eaMiFvhR
#WnxuCz16feacr0HAWusBnA8654LCuSh7XzBQvK28SmiG3FAHEUUS73+xSR5fi0viYO63dbDp3Q1+QBPXBPK9FXuLNQHcn52hUzk/cg5cZRJUhj
#PXp2cX8qWubuNhuNWz3eilbq1Sbn0eK37Ena+cH6ZAH2CF3kdFOK3cfPXnx1cnny6I9P7h0/unf58tGTRw9OdutZQEH2RL6ZN8BDUHt7O390Ma
#UYG8Jru2AtFdSZbzMfpb43DczyktH929bTvsWFY789YfaZyGThi/yTt+blpbr5sYmKNJgJWRIRu3gDIyZnnrz2oowvmcWqiIcsiyxsLXlpfb20
#Lz6qtMpisPwj1Rdtua3rhWIS7GtRmGFWZrS2MNezyGsf6bV/8pG1X2Pv3XWOX9o+M+ex9vpIwYcR8CfhVrTVMwL1omd2vj3qq9QWAkn+YL2Rgp
#/TW+vorcXID0uWSl3t4VH9oL1TP8g5fikJS/cfWUmzZtHXh40js0ZhklnGLVi2GCWWpDSECJZ4fkzQmTYTxs5VKZ8ACRIJgSayyUz59IPBEnsz
#xiske+jJBIFNENFIxBz5mjiX1C6diQhGQNmy6EzlsOdeaYFBnOawp634Ya/MK2Zd/SQunbtTMvObDyhu+f144W41jIbRbMH/W0Y/jCJ3axJPAo
#SfTuIRguUxPX/AYK38dIcP8bea9QP1CFFtgW6g2R/Q+8JjFFfk80OzNkWjN6jCoSbCPb33x4/ddG6ZdwkXCaoF1bmgv6KsO1uGMBnAy2SBpd/e
#2j0E/vz40cvKj/cggfz8dn0/z4BuOIsDyOLuFEQS2CG2nu7XWwZ89ZO9e836voH/qHeMg/ptuLv95eel580GXO7N9+r7pRefG5/V7wx3RA21ww
#zYcX1nmLto9K6xfOlpli8+3OVS5RAPFaRet7fSxeHxCEcescpKMDRZd8JY5ll3rNB1MXQq4SBLJCmBSRP67hbGn94SAIgCkWY9SzzTkdl2VbYv
#EHHo/XfAFGebcveHwVwBnaPjF9rLDJKw11FCbDuJEV/aat5BuGX7e9Wlr+rychbOvWvqUcxZH7QHokP9qg4dytKGqjQBIrSpNHRtvKK0Y1EaGl
#h/TdfnFQVPVGnH0MezEIfJrNEiULO5Zdwe3qEJiCuuusvyaXCP8E3DBPPB5bj5m4X65guK8FNRMqwX+Bfdrt8x4N/Tz2FhwP0TfA7X5TqZa0YI
#0PZ06gI9WzN8nnLiBwWLqb7dORYPLOWi4yCfGmBgbEcLdOF8bQtSKS2onjgPnGOipunUhud6xvCkUzTrDxEbLrsfwOQMrGHPKb7th4kIS0Gl7O
#6i+ySdmBLy1q7hiV5GeLNePOtGwY6PgCoYPknEfaPthKu4QSTJeUfi27gXYctqEM9QHRPaId7YwTXleE49nQ0qBMle4qGrieyh9eJ73YhYHFX6
#71cewhyL4r5eG+pJSUxZ+zgUga7XPx1f96m32PTp4ppPJawKfHy9fCxpfFFIJqlD4YpgZdomSs4Nu7olOc0nfBZM3zSPcNdr40Jdyak28ebhgM
#NLTXPiC5MuZfKXr7HzXuF0De6fj3THwbkLj07hn1C87zRVjIwbN+bA382JCcYYEMBGXF6K++1t/tW89deBc9i25SaSuG5ZEMUJRekxl5IX0yyh
#wjpwUUdOt0dYFejg3sGKMq7KLLHJyQekWUsrqF9VELW6bLxOLYcRJ90RFjDPC7u8hE7DOrjzKq9q4bbTqTbBdRt5dYal6ghnd/l6XKl8/Xjheo
#yx0Fl6BplZxEC/g7DiH/6PXxgvcng+VrMUvRcR5+5f/vrnPzMkQOKYARIRS5HTr6OP4Dcf/rdfGxL+k/ScKhrmy2mchf0L9fGEIFkK3/6f/2i8
#0I1WrS+aTZs/qNJ10Te//Evjx7MwyxRgZnV6sV7Pzng66OdxNBPURKw4UUJIQG0+dtRc2pRWTqmOGubqc6rymlg5rQPy7bOtdXNeBURpPQyCd9
#DcGkgTo3AKyzv0RDgRHCG70ru09+4B2bk99WhKI2rhu8duw+m9u+fKuPK9dz8meiDvfhjzKuGTP0h5d397GxKpE2p4VKt18AkDS2C1df18752F
#vIBDUJCpu1xpYg1KV/iyZoIQVwIn4vRSUw1VZ/itQJ0wGS+SGLFD6zAD42geUBpYB5xGO+fFJou0Fp4HO0nwxmZli4HtZXphqUfqNLXrmt9803
#sHomatBj0FbMo3Zu0hsKD1SXxuafHu926jR7YMyqjsGbxpWO/ROJHZIog70FZhN2MYJQuKZb1e5zY78SyD/bJtolHG1HR8L4qQkLX9roawo+K9
#zepsDkCLOSW8HRX0TTOr3WyRDXQpnGbCeyOLnX44yc/ANNtqkAUVxYQ0klhictIWFo5Wshi4Jdi7skC485363bNO6ueOrTBxdnY6OMMsaeOIkR
#nLZzFLLJdo6xsLe/gRmkBappj/QFxge5vGkx7ih+OOgqjp5BzLGeaFw46pMsMZBdO4TvaUdjFr8bQudm8QreA5hkPgIhGXlMwqcbqlPN2cHtYv
#tXrKjBKoi1+017yyGYxmq4M02HpG5HKeTzeNDx0GXolL9UXTJWwLdzDZHmvnKZP+OHMn7qFwlYzqbD/1BbBoHkyJfrLzxbHpLCcoccEqbpswga
#d48IERtMLxbPxF4tH6fhgOwixtN3lm4sdk4CEJyEWC3W712GaRbeUazr56j3Nmck+31fyDm1OWjQmFaHXiLr2oOxu3zXv4YzppiAEy2uZL+gWm
#bdo2H72A5QctD/HFA7rgQCAq0taQDE3Fvjx0tZDD6e7ebZiIElaBbQNSNHdv7N5uKDOs4RGQP2OIYNc8umMb6ECPT2FbjtlA8QgDhZntsbhYMa
#xAN4xBgpgOQ8TKzrcB44tjjrP66FlO+icxTC69myc4WFH4DnahZ1881Hvx9NWssddo7ODP7T6Zj242oX1l1W8dvbJFojXL2nWjWqHj+eqlu4vn
#O9llgrN3xj+XaA0PPxQf/BI7Pk5DjPFy+ar78EevupfTJO7NfPGkC9ITPMNxCxLOILnszeJLKCu+BNo5OE/g6+SSxvkSHYU5Z+CPLsVOuhuuhW
#o+h560ImB4CBepEDRZUXazhglqZh0TTwPo9XqcDHbPieRPh1PYzsRu8FKjzdaS10zbJNbedHjFMKE3Hcb1apu3TGeAAoQHbH9b2HqZDi3mQZrw
#fRvrVqNqkho8gR1URSegjqXIONSdaE7A7QZ2invLwL4DARjyi8JxCFW4bToYLqxtBgs0asvSy3DSj00U3ejxLIlgSSxC2K3ittnEaxjrkDx0xL
#3IieLVJAHDmqf4bqXJ9DJ6rlU0SrSFBaIzcWmqWtT3Gj4Fop+5ReQ56w2LSNvb4qJOqWxGomMjNc9Bq3+PJaydLv/aRataNETmAgr2s5moyZQD
#NgrThrron8tLdSlYobt3GhTUvGg7i6cVyN0BVbQm0sJ0D8SmLLcunkCVJ/ltZsN/29uwRvjEJy9I0k+kKwKCW1kY00DkSXm9IRIUPMTz0hmCtV
#vXzeAjECvCngusCnVm2LMdTEeb0UpjqaqNY1EKCWNLrZvcCLUrhp0WF05XXlzYp8ofolsMY40fizf6t3iwztEZCqlLFUP6qMnAephjJRMuNfQT
#xdlLu58pDnAB446ptRLPSCKcVkmE099FIqzoTRTG7hGZun+BSl8r8c61Sk9c3jzpMU1O3SCwKsL6b/8edpkJbCK//U1FXGtpZAoMuyA6u0wkgQ
#942544vLxho3c8F0RKVF9gmzEabW5I7xXQ1xB5CujFbO5hxHGCyNfqUDCdMrTmWh7CRHoiCEdF5GvBkGGEiEDyaeQTtbEHLYE7qQ86ai1IjUB6
#ipIeQSWbu0sgarInJHylCI1rOuggAySVDvYdzIiWyiC25naFW6Sn9TFnCQsx7AlWbU4tdrnhnXkdGB+4gb+IOv/NAtZvftcNB/rtGFYw7HF4DD
#Cv90EMxFy638AV3E+6xOLwI9oM1YDRhHXduYZhTPsML2QxBAjwM0F06uW8DkyH2728ZPmgKoNVwSHzFNg3B4qEDSE6E42XchuINahriIKedVrq
#kJq5Cx/CxONJ1zqAWbeehJqSqlQYBrUqGQabx7CkKl1rZZ+pLodyXPgHkqeXzVLaTGcRnn7BF0cWvqHtJp/vZMG3AE4K5sWC9wbHa1uLOpe6vS
#2vuPNwlPDCCSkNVhmov7hiiD41eoWnNnxKc2Bl2+3TM71X0yCYKPx61RLuDhd+NjQG35Qbo9tyWxfAwQFNSYNv0O6MGcUoxgBOyPt6SQD1Xkth
#a0blSwlYb4meqfC/qpmXZm1BOKtJ7xs0WSB9OzRJAGxLWivAQPEFHmCOFMvMRjSqT+ZYJzch2IOqZicS3j5vtvatWMDu5hld9NssfzFHcdFVZK
#h6TWwgTThgSJlovB1mM35XAsVCDGRG2bRV73Pmbfr7+1IsLKNIsPjwx+Nf9M0nyElPzGsmWXxNBEskgIQj4MTc45NTT58IGNacpTE1p2klQYZy
#cXn64urIBI97VUnCHiS4gK3MvUgsrzBzEUcA3W085XEADyieGzyiX1kDjiLoAispLrEAvmIVfk4UBu7hoK4YV7azz0D89wT6JX7JV/mX+daZJY
#I9vLxUl3ctotn8EcrVNjn2UKYVw4Jkk5IWaaItJn6WaDyT7nOdDdWQSVIk7vMhkwNO+btQw+9LBuVY0SQM29lwZdv/2osQ2UK8n+WSMcYm8JIe
#0E3I4RD+UMO89bgtg9BIejIGNU9LDENdx0At/JR2bxEgyVMhxNbQjfCj4r599PpuOB4YqOZRnxdTQEaGF0GJW4Zs+VbkvbvYOnzdDn08APNVoK
#013KRijTagKGGtvvnmfHhxhFFtBMcI/BV9SS/stsnMVGDWLMlegNj52/+GLF1/nKmHqLFAJoTsclRk+KowNmIMom7FGCw08MrF2k6pCJrcFdbH
#Sw4WMT/QsQttrJhQid5eaPRqodMr31ZRefiUW6ZnWl09uv76cPrXjh/K5xtH0NhUeunBxqEF+lfcuTFYW/GJGEgMRHRzCYR5UU2Y10ZzVTGcSZ
#beB76BT7RItMJH4vwPLwV5O3q9BjMW+MoKZOwlg3CygzB/zf3pohJ87FDMyHQD8Ngg6RnDdzS7xTq3VCXymSkBwl630ZdE8lj+iZshGago9eYy
#W2kl6qHn0+Gs348Cwp9lFI1InZXgO9aVI0g63Gyw6MfzMnxkRY6mUCwix6hcEXa9HCZLCD2+7jIkeAlxkgm9KrcfIaEDXXfLpiX4cOvww//658
#ZxkIH4lptpCDmZCK+99DPtZBo/qhW6DdJ0oeOmh3gqyBpupC7+EA8vydCBY5S2DZ7QnCu5uNxcslR0VF7eU2DvxNp8K1fGXBHdBzI4X6rifOZT
#VguYqEmgQoUbeD23UHlvWJx5HqxtNUexekCpj17nWB47hE/bniWRZcpqQRJ7ZdpU8tah/Mg0K2l3cZ7PoOfuHZ88fnnySCQZNg/15sLSJGkeJ2
#Sz+C2wwykXh9T4BjlV4ZrTI+JCGoozhvSb09krIt4Cs+41UwQlRW74Xr1fGURvtSeHzSOTtoKVnuU6Ft5rNacEidzevkETtWp+4TgVgfoo/K9Z
#k4h+lgaop3loEdBNnkNxpH00CytNM1iKbNblTSNFiJ+QkdWHv/rHTXZRYVd8lA4LH1Eow+j9d14WUxb/8tc//3ZTHgNhT+b1Y+zhMP0ijqL4XM
#7yI/PDL/8CowqmsxC795//6d8ZLymqoJnHjNN6dndXOzEQXdFFiE7R6SjZuy5M4ACDGPZsvDeLwT+NqIdLC1ct2TCJAOEqV5iHCsMwt7qlrKXx
#PYa7dekJwdAojegdCeADpZZCjt5c4kc0GeAtGmZjYObIlIuJl4LMsWoX7MJWjCkxnzVCgt1MZAQNHCEtF8FzWpUnLeugUBpGDO0+CzO9q3lWew
#bFw9nSq4Vw/LD/i9BPW990I28y2jJQat2axCgJouHcSxlvWTvKsUQl6gVF/xfHUI1Hz8yVfXfXk0Os7Jw3jZtA19dOjUg1h4bJpJmjULW8m9a1
#URzW3I/dpVst3KVvLnHrtMz7qiAODRvGK22nFTNShGCextMZx3DW1Juo0UDl6BFuWWKitBXWUrPhaM/tq6qqqnRSLg2pJvYULrMEiAYmxV+Lsp
#bq9ontsMeDmFowkfKSD5uNiill4GTqFiYWN4bnlWiY+ZMYY3piwGYYUbqZRrN0bVKtdRuretCciw4r817zIteSmiAWTHWPf42jo0BHxNEhy1t6
#IY480fJy8JH53VD5oeRXeqHy01Ac8JjBAlbfGTmZzUz/VUyhHMNMjFjO3xFzJwQIa45h2yGvNuYnx6/ZsvOhyws6bLY+buQoJDyOG8WEL4zZST
#zLKOwrMRuWWcuzr5n2FQPZNuXqwp6wvMiB7otgv8TIo6zXtGv0Kh3Qq5cTRADjw2mKVPzohQJNveFFyhH/RjrIr9VWal+7NmShhe4NxtPsQpAO
#nnSSaNTXeGdRF4vUcTxXxNq8vmxp1qTFcl8b5zU+Hsup4OFpjun8wlBY08EGXjK205bxUc5zwx+nYbf1oCRMp9YCkmCmadmCryAAQF4qZT8umx
#5K5AOOodV5Ue+7LziSlor86Y3kfq80RZAEYWSWwryGb6V/DPADk4BYAiIlIJnP83MU3iGW/IWLIYDmKiAXJ1uJQFf0lypCVxR9E/VpohSN81Al
#gMzfJnYbVcoh+hZhUF3v/X+CGSMsmkWEZgqrKyqkwt0JJU1FzF9Wk14lywj12L8VcYYJYZU0s0nqQD8v95SVlfq2pm990L80C9HzSd9+BHONYe
#AdUmoeDccWXdAjS6oweUmyrO4YQNuFwvNMkvT7cYwHiqzLhIorSCvUC9hry2q9X6YlSakbFgUlUqzoolJRSOJTDxCTDJ9OS3fpAVBK7QOOVzCw
#pRjFWSJiggBF2CxEcTEWq56VPgMPJ75CyxE+nFD0RBOypCp9k5QFmctWRhhuJ9kBKcdHFXt9b7ro9GH276Thu0BoMWj/J4JXEqW8KES2sKRgzF
#XcVWpG+dbWOGH5REhbN5c4uzT1jpDo8GmVFMaRvctSGC2xo9drAheQcCVwSaG6/W9LqsrFgUo2r8jbvZZ7qtwwKHLilVsHg3Xpe0fn4zYGqZFO
#Z4NBkHJUmJ6pbHxlqF3hUxhgWENxmK+01/ApRZJFlwoOVzUbnDjw5xlGrZoNHmfBGGOt4fVLkDcQxkeR12HYC17OBpa9hLdlRdSQIqZ11Hc6YL
#OXjPg7DCqI31aFNoYa5ejzVpcQTzaFN0aEIC7J1uESMOIKFhRiK4j8qybRo7x2ZP9Az5SyTbVOo7ZYVw04pjCbQQ7UtIkcCYBzJMgWT0C2iBlJ
#rPIW32zleWwVAV0Kuv507JH6ZaOqnxLkmmJaSDqBmA4bpAjQdEasT1mJKAPdNVU/BiDAXGXLsD4fqbjH3OlTFbxgQxz6wtyRSBli+ui7OTSTpk
#0odQGeK4fzVICleNKCJR88nMu1Gq6otyp2s7CQEM+60QwPiDbaj4hkG+OzS8vvgv0yriOJZfDW1UvX4A/RKVqe1LVoFWFVqyaelGlrNUwkuq2A
#O0Pnw6UgdVea5AiDHAwoAvWY8Ap6tr1dUVd499aWi0m33SlIczwFbqDzkW5clTskdDZ3ZQWKQXFe5MglPDPWsMsmajJIhK8SbgH5YD/EQiod7w
#UpsPi31rQ/nXQUoVpVgRtQhl9NPya7nWZtcn2GjygWzvY2f0PRoStylstA0LvVFbgLdj6Vru7+fuzPUi2uarEnK+dEjpN61QLGUvH9td6H0syv
#ItwH7gRs6HdVd9TyEPchR3S9AiTmWsfDT/owxVTvVXnqBxgAODGCwQAYdZ8D2R+8/w8kp/z27w3vXZBksfHb3xhWPDMQxtL4oxgISmhXwOh773
#C79d6doJdLdnGiRxTFB7qt4UcFCRPwTNqqoXwKy0YEEhMvtFBrYxfdtv7sT00Hf/4Rfj788ld087//kp/9V3z2D39ON7/+jl/9d371f9PPz/+2
#Kg7YZw2Oq6BZDlwXDKxTiOnl9xcY1EvHHw/Gp+GngUTtPZOBwKrjfpWOwDCSSc2cn3d2dlJ82ywHFmvdoUAMHAaMQjXU98tJ6rfXwzpgKDGrWB
#gFeGk1GnmGyYZEn4tEvWCwFgBivQlrxf9+AcRuS9+XfNPpXgMr0NVHaNr1kD0yO12dT3qUrxWh/jFuCL7i6aPjB4+Nhx++/cVXJ4+fPH756Nh4
#+fzZ8+N7yF3c+18eHZ88l3yEeXWkve5au7p5u/b3Rbvkxogc9jsgaZscH7XJixEtRnf3OyOYu2XnIgkpW6wWR7Ug6KF7k4uPQR9yRrf2DkQNdT
#aC6QFQOfot+zblsf3EKnZuH1QG9sNaFAM7UiS/T/r9vd6dJofuC2Ds8arV6u0FAV55dw4O+p/hVaMR3P7s9hUh/lqt7x3ir9XaHOLvoFF6+nnj
#9w7xR74g6D3Rx8XSebdDtvztz/f+IMH/fLlZFoIAlgnKnXIQwOoEv98a/lwEAZRTfOP2pxhXwU2LDzpexXaeDj1E6eKgDV4haINXFv1k2vJkhg
#0OMn+3No15+2ti8EJ4/UzhvuJz192zhdLwgXCM+PDt3xn/8tc/+1apryHdoXtgLymfjtgxpaoRdzLUNXqpoj1RgNYZCfqvAt0RO/UNioqRh6X6
#I1gfksNzylfERlZcE8SPowMDXfECVfUeLCaiMSFFT7mGMf7e2F5rXPKIwZLEXIXebR7xg4KJbZuedaBSI0jyR6ej8OxoFNaabYvvG2dHzXZDdv
#8Ipe8/UnIzNWVtEH79nfEgZ4IkbhT1OqIEEnfllv8znj4/efTVsfHwkXH86MHzp0/vPXt47+Tx82cvK9IqncbDez9179zeDw6UPdGIXBXJG0f4
#PExszdvMYPczmRy16SKILl3yz+Xl0msvV06Gf/r4Z9JuKDe+XuB7F4hrbsV1MrS8Ret6Gp9bQNCs3Ol3BxJ42eVl/sS2d629xi2ota2qIM/qsd
#43blis32fNvn3qjaD6mov1iQu0naKTfLQtZb8rrCi/v0m5Se5Yghk20nAw8WYLo2e+/86H9Yznz6jFmSWBAdICMNCGBbKUY8jXeJQXvf9VJp+n
#o3BqJN6UUu40gQEyNMbYn3K8DokqKNyKtc1tPL1nZU7PXmoHHkCG2KFlVARkkAclTuy+qHuno7PLS4sv3GXabvA5hpggmIfjZe18nKDZMLYujb
#QV27VeB0fSzRN0XtQntZq29UKLJ9kL4NsK0MuqFmFPAC9TfbLTsMcVois0yoZ1DMMINUFz13rozOHvHKedA/Q2g9lHKzDGUjt4xJ8WaoMwxfW5
#HdfnLvzybQi3IQVulz3X1LiikfKQg9WfYk0ol5Hc2g6RiYK7gs0/1ndxVp/cagbNvZq4w7rAVMe7i8K7C/Eu9+WlcIJSzTdyD9WpVIaHVKTp4C
#MenakhdTK7uELXwixZZsXBcmC3h37qzRL4S+MQ9NocqCxIEr5alTMkpDgfJ5MEs5/qC3XHn8KAYxSeRhEa0T+EN1CgzT+uz1iQcIcm4j0VGGBa
#FzXZ3uaUh3koqhZQCf7g8vLzzz8HPmjfxpbJT4SLvJpR8CYrh/rt0Rut9iXYE9efwhyfu2I1dcTq6pRWF7dJFkwmiD5WDGrNlaa7Wxg6fcnTyK
#/TROKBWukaCShue/uGjydY29t6V0JPHmJPikyhV/XMiBDI/PIYQcYUuI8UiG2aI1m0jW7YjcI4G77/FcrgNUlqUsPqBeNwZx4Gxl7DeGPDK/UV
#wtiEqSQ1ue8uMWapLm+Pc8gLR5205kxTr+eSv6JzDuvZ1jxYkEpLF8Ubo8vLG9b5YaOEEBO7Y0acQJ/TUYH+0LfOOczesIf7TFw/r7nnFBWqh4
#u454a9zligNcTs7Y9Aqj3ElWAfAbmoMuCwgC1DOrLHJvOwowlElVSP74ojPcWsEVoS8zLLE2i56kwrsl8jvj7SVMsnEguyLKnX8e6ue8eWdWli
#WEeqjvUSDT6A7RE6xfV6w2yglEUHXqDdeeqYU8fsLCWpdPVnvJGqT/v8aZ8/veP0oQ8KCCB4TDGWn9tnBd/gbv18x6uf2xUOmPLgjSfICGb+RC
#5OvhHZ043OoxXnjkzWWDtbx4ww4DU9kcnkgXvZO9O6yj2zMOtYMbyXO34Uvcf6EWx7C8lQLaoYKd3/B4OGTHqoIsYPgc2gQmCO0e0IeQorAZYS
#WBB6gtfCb1C5NOdJxVXpVf4Nej7LNNI28AhftxV+v6G6yPWOUNXfbnSUGUGhCwu+o3IUVgoEIwq7L8OBOM4rLD154r5r1vS1lgS9GfQTzJwpij
#21aTG9g2of+ETfhAusn9JsS3pI9UhmAikH6Nr774D1f/8rslJD8FAF9NM2BomXzcLMMRrG21mcecZP49nJrBsUGC40vMrRzR28/RpmjdwaShO8
#OwNh9BjSWLCU/EBObplJ0RFvnQE6dmnhxy3na1dRXrH/fJ2fi5RzIcAtLG97+7iwqRzj9nxwCxEygr3tbWDHdqzjOuGJ3G22IHUdRgxDT9C4Wf
#Zazqr1MqxEyZlt7C2+dr/GuXZecqfspXJ9ad6p0AjJ5dxhqwjuv3NFMWE181eKVJwzETpHEiSnY9g7QnQf3GFWHGLJzr0mldWFcu7X4pJRzUoR
#eTRoHhkHJ0rXXWst/hZrnQJXpnvFpvVKv9gWMKTs6kvHQfkhUY4ID3d2gTwQ6VOuqF9TcdA953VY7A7W4DH0rHxdqFFKRNrxvUlPA6VimyBKp4
#6OUzp5xVZiOBr12HPeyOMOLofcRz3KNmfv9JC0WBbt15QIBUIn9WGH7kOvtU/PVh2/nvo110rr5xhX8mv7ltXcebNryaIFVWjZGLwWP2LkqFTY
#Z1H2qcje8e1VsatgTFzciChZeS9iZvwCyt9ZwB8b6hSkQxe+kfPEB0mSepubCYxu3ZMksxCmLZ4+7wNzURrzNZ/qOx8z2MVphlu8GszSpi9n71
#6DV0pGozuEjaqnPsHW8zcOXJVIrvyoWCieMZU9nUU7vVHABqT9rjNx4lHOvInQeTnCxwIRPoT5BX5iE1OshXxzJ3Y3CbyRDFTjglTOQrkzktF1
#4AusjXBSBoYwHuGWpuA+6KVwVFah6oDHzwPMIW4PNmB3F0Gr/Nn0/XeJJ0+JYKjf/yoK9H3aG79weS3kwEly+dAwW2IRQQe9cGnGlAmWL1PibJ
#FckToZCPxyAXsijhuvOZ2cqPXH09GD6bi+7jQiJt0ouXh6zfMtS1DRgQHakAzapTkWvXDXiVgp1w30rAQHcKCTM2tRcuD3IqwFTEMvcr75xmvz
#IibCfAW568el+m3gTDXLYyqtX6oxcajl2ETFok5h+J3JuQODhOAJ9yIHCq+AULBO9RucMyDnaE9wbhSf4LDbmOcLzPIFLjh9MxwG0TxIXckzwm
#Rt2sbTcIGo5m9igt1o7u6hPRIUFkZhkDhGix9M4tk88GbFOXwCzMe4jjwdkngYfppauHzxmgYY5xVtm3uw3A5vMI2QaACFXoHWnLiT843Z0SLA
#7Dw9QyJDlfmNwwW2VFS25UoigfWGdZU/wILFlwyF2G8pd+1JSylPUWRWd5A5UwF4JMAR2Vbj2hT99RT9PMVK8gf4UlKw27YYOREjE9hiE96bAg
#/A1EbQ5OCIaRu/1wi3hO6AIW/ZCA7qBwaK5Nksl8k/fPt3RQry0oU/TDQIbooph7UUxVbnAmu2MO6iPpyBGtyBGNcB7BHO4KohVa1oYSuKZi0F
#Fh37STgaQdUVM4GuxjKlGnL5QPUL2jDAVxhGdr2vuw0TdzWRQOvKPdt4xusie/8dKj+MTNd/WHeN5j76E6S21rGRCEmN3LGufW7u3xK65noWP3
#75XCICauo42+nNptV7psDJuBdRF1tlZ47cGZh9OPL7Q+C5x+WHd/MaXlEbu8Th6DlcCS6iAK6q8EUWdSDahCRyBdIIqfFm00pYEXxehSqSV30/
#H3VEEBHrcX3goRNMB22KBQhHqpbcFcNuOmRa2IactamybxsnhbnBai67ILy7QLTLwoOqaf+KisJ3qqJUQl7Tk4qq9fWaHdiGctJ4/zeIZA4reZ
#6EiVY1BNgrcSHNfcWG0GYLXIhDWAJtZqBppeS1xxzUQt2vaAIm2NSG6vrJ1uCXWntu2wYMDIrZv/17jdL99jc5bVCBnZXEsSDSVrH0YRaGeBoC
#LVxQe3IBTiTeKMIJCdpdFtXfkzZIvw4Ium0p7Doiq1VJ1yFF3bWwvawjx5P+cALbPoKp6bqBXA2SBDRoqAcgXYimFRBxfjTL34tuQK+UlloLLp
#MGPr4rKtdviBZubysVgRpieHhDKRuWSllBTRIQHkUMNonkYRjlSjKn5w8VjTh3ZX6dkhYEnZR82LbP7XVE8hzFSo+DVsxgVTzLwNn4EsYGuHHZ
#KSnD20CuaByvwOPwxpIxu83cZclEDLWa/qBTzkdOdluBXZT9qbAG1RAJbBOc5iARH4uUAHw1GV6vNvl6afUT3mP/CtUTtfr/IUL+sBAhnAp2Vd
#pIV2i+VYkbcgX+R/U8EX1vmh3tICiBBsYcjiALkBTHaCeHJLgtfYI1T4gpAdIo1HPbob10EL//TZYa3ThOaYsVatCSjrP37iU5FSZW5ky0c6F1
#1Z06dla6eN2hDHknqxK9b4Mqrah8F0RppHRdOTUUOrPT8/rIOa+fn9k67mmIHCnyH0KcRsk5bReMjmrW+UgqhaRK6Kj+WZtZ4ZJ+CdVLOZPzmU
#KzW2Dj82OxJAMJcCl9A7Uz9RVuclQrrVkg41dpIAnpRdS70GdefbM6KlGOMrqheqVUXgGGhyomCkuG1dygogKm9EzTUbG2yPEnGR6PaZZxidvo
#JAh3nyuK7k46Sa1mF23nsPXK0rqQtmwtu0CkQZR6ThP2d1jk6iPRk4lQPWHfSfFIKaFg5o88OqRLxHAxGc6x8y4vLWjI6cijgzvYYfMCdCA9kc
#bVE9eamtoqsTVQVXhccTrGvrrJSYwLy4VOXW6AE9XXH7Za+V+7e3K/SCrBXEUJPz3hTzXyEU+6MWxRQCPReHsIwlPIUC+KZGhnIpCYYPPIEgVu
#fuiS2zbBL/vB80lXHJbAq5ejcJrfEbMEdEtoFeE10ABNV83Pnz+7/0N3iTm2G84LBCvaaznHHvw2bzvHsT9qNw9azvs/RbOaJIane455vH3fbD
#dvH+iBEpDoQ2X0s+uBi9XFPpO1cd2BZK/ko4EWvCWcuBHrxPUPtKbAm8ENl7LV8mFUwStZLrLdhTWMTq64hLHVp4MzVLtJPlys5L2GtpShRpuW
#Mb46JWKnMVNQGTQ51jth0nevP1BjVtOSIwrL4IYYzu3tSf/u3jr3eXffliKhHkB8Hf9H8ikPw3RnEs9SI9dneOG4iDw1lR9B4VOESsGZCbNyxo
#ABxp5u98ChSoz0w7e/CGCyB0nGQBywISLmdgxP6ExwHC7I4R+vJ5pIiZ4KUP4sQbyOaXFPH4ZT2tX1nsMhU0CFZVYIv7i5RIwRnBtHJowEA6ww
#bxMPJGsxIJZGeJaKB1d4iK2K2D5ysrm0Gu2lmvSdKzlHnBfYHBydKoCCHJNGQdBoXIiIW39DFF4Sxn63Eje4fmskqG58lYUR7IXow5m7btIQp4
#TTY8ykjQFmQpj9qYDCqq/zaVCh/tYmjCB4udg65BhsZc/XSnbse7Za4GzIHlTqtn37SrhEzC+kz4B05ucEML3SICrML6DCH4emqDtEkjf/L/9C
#Tr9/m0CLmxfFtaPLGGdifOPRlupJdCe/uwfd2AtTxNbuUV8e/oQsNpPrAKV4srxAeIgMdtE8OfWtSOGL8ZbFrYz0/XcRz5nJ++8K79YQvipmXp
#HI35tOo4JbVAEEY7kOQ4GGklygVMfAnCMki5zrZUgLT0FaeDqkRSEdzTNby5Ts3DEOcIEl6EiWgDQSUlVDNnfSqFEhrX/45d+R8k5IJSliXiDu
#wgDWSwLk2rSlhUKu41DgpppehdicamvqLx4/eWQ8NO+dnDx6dvLIqBkPnjx+YDw8fv74pNqe+gXzwq4WjnHPuD1s7sFPsyV+7wzvPG1+ZjT355
#9FBzt79YN3GJNRcjdvdaBp5KYoErTgkd4+TLxB0af8LabsT2zFBVIN6iTvOW9dxZ+fdfoT663decuv3KTDVX3beXvM+ihL9wRHG5xnGHk3U4on
#zliewbwN7wIHqhzxT1HbmK3OnMa6F67v8ktqjpe5b0NgfflQx8vu6tlub79lxpojHXsZsCtexv4N1NC37uFb0uf4+K3TcHzgZ94ym+0r6/kP//
#4fGPc+q2eEfI+bvWdEM5ggjCJWZIKotHtoOvcHbGxeXw6PV1nR//ifjXtvYmQvUItKuIy4waGXRYbuemsu3Tgs8fn/pIqKjsXxEV2rcmIZD9+U
#uu5Hs/EUPcxVvOrwzC59FeoTC2YbOcjwJ/9va1e320YRhe95CgcJr1dZp0lFpcbO2ooCSKitVLUFUUUWWsebZmSv194dtwlJJK7gugiQyg1CAo
#n2kgteIG+SJ+AROD/zu1474ecqzuzM7MyZM+dnds53MBJiLi4uNkxbZSTrQZ2bUQm8MYtN9uYinIt2+9Lr9hF2ikfckcypa/y9R53LnP9iSS92
#Cbb0NiLN4ekgNq+lLndw36gCmfewrC/z9k5H5kCo09AfygHLNiIJrsfKKRE5Lw03fFJZ+8ZLMbp6i0HBWjaALkWIVLkllhUrhfGu1qWBp8jnoG
#2u37xT2iPoeuujpIGb+WIuevF2ny9fJ6dgiLhUbMNq7ITgjA0pbn+YjF6oaKahF3o67e3u9oPd3c2gM+3WIVNQCHS0MTWx/ij6QhiRhqT2+YhL
#nRC9hZJ+mCI9WszUqHmopaW4AqNnaMpAn/1i/koCznKMhPlEm94fU3RCUfr61q0qaAAuHsWcASlw1ah3z8CbE0iLsmAwr6bU8BHW0sfiJKzoeJ
#PXeJ7OdSpjY/GvnsDV18oI1r2p9yxmGvrI/HKAj0yZB3vkj0i/2OvJnP3cU/eTWjIahxV0X6AZ0AtU2gu0qeL3UUf7BNzc2WQoOKUXJJiyDgVG
#uT2I1XJ0liDulWDSKHhlWgK5ZgFkHfnlMvHd9ok1HxkVN4EZ5LMqUA4pHETZ+WPJTDTNCpsK+kkqoV2BdvYPS44FA+YYs5bOozoeqspcuUtPBL
#i4oFKU40NOEEiXLKf4yL1h0TuAFQLi54Khwgzm2vU336HydEcPGtRFqFSZ5nizu1l1urrExYJbqhWf+Rv5Ge/+nA+L2dyhlMoGGrW/QaWdfKqg
#3eazlek9WWZ0daUylftSFgIImeKBqEjaIGVGmNRIfTznvjlv6Hwopzf1vFI02fYuCJGeHvd/uuKp+vCHVY4mhVOJlQkjUQzXxaambmgq2Ls1uB
#Cw3QJ14C79QAURbwpp4SCiOliJQ8WtAxNGOiQVZ2EkgJPjOCiyILRKnlI3Ku0slP1gLRFU5xtoAYTajmDcDbDGX4AnD1ZbG3N408kMsTAY9nkx
#ypG9bPzi/FFSjMtYpbglMtXgI+Uy2srxmXMH5bQmcDfHUFOsGK6jOkqtEuOpXDSOm8l+cSFkLUgLiHoLNsFmvrckXU6m8qxIpuVxWmylx8cwt3
#2MeUxHcYBDD7p4GFypB40/gv9bASriO5RBznA+vcZAz5yG55fe4Cg02WYlX08L/D5nYm6pY2v41ICQ8JK1NODPOsIpNpHN5sY62jWbHr2Qq2h6
#xi8Sq5M2L00bo+bx+fO9KvJAH/mjQ/xxeRNV8GvLrSlyMyE4W6xnv96WOLehQlQRAmCVxmvoIDqwl603gSYxU7xrnFSzyL5x3jVS82a2gooq7H
#651zV7nbn2pp3OtUIdnoupuxGYplYrukFvdEvtESb6ltFpdBZRCsD4cOCYopNxLMqH4xaDkVJScKx5SBr7MLj+8U9WsBlldJwmUwWLZf27QaTr
#gjPrKmOnIvvntqb2JkE4rvAmqa3j7uq2k3E/uH7zW0NZH3T0PRFjPEZBpMdfTL8Yu6we8Lqwhnwo8DooSTljgTeb+A3N/IsRTHyzO8QrN7bcYp
#GamSC0ujMTN6U5gkLSm4FhnDVA09FS4q+fX//aINzgCU5eJVExGde9JH9o5amG4A/TWg6cr52ZhebwGA24DJfVCKjM7rFstaDBj3GcFL7HNhJt
#p/b9MFOwHJgdzbhZ9yO3kt58bYV5oSArjmS9WZBTqlAaozYOSILwZznNsy7ES43kKTrTXLa2ynEYhNFRXY2jpBg5lRQ1Ck0NECqFK1Mol5ZCn7
#PfvhDtUY2Is8tbPkQ21muvWI6xwp1TAXU2uJwF8nIwcINrjzB4Vg+m3HDB98/1ZewYBOZTvvl1uOnUHsDYy5NmszwxyaXMT7eiGOivH3KNtHdF
#iBayX5hfz3l5HBCy4a3X+P8xAGWsD2S63lSQmP98Nmzj9WvXFkWUEkvGaBwMOhQLo2Y/BHlxu/nraBIjXLr/cSHaCMWHw7gZaGQJS65ebrCCYt
#FhFFQW9zKDR7Pifew/Oa/j5W02nYVWGq6uzDEJ+OWaKP9+mCx0u1WgN7DYs6RA5V1BboOlHB+Tb1MuhhmyKExlpSk0Rv8SSFqFgcQY3vAct/yD
#9AzvVgxzkD6UCB4aFCkwcBX2G7d+Pj0WRdYKDk4SSsgsE9D1V28b+48/bfTRQtI9YjwuXpNGVY9XsfJkZHpfzYnWCVMGQN3+m0x5+03CJS00MZ
#svmWq7aJhOqii4LkY6hn9IcSyOVEiT5+IH3EXyEnp1/Uk7QpT3IOtAVMpnPNBVWovMF6OUdrajYqsgRXT3w+0w0gpt836EG/ynNw1Kvn31O14q
#szr3qbq02gJliwr6+9cNvRSZXQqu76wjjZrbXH/7roFfgQu0ClyToPF0hoQ4M42nIps5bQehe+2D2QVFZYLfxOy49KWGBx8/JwxiGMDCP2eoYK
#0STvFsOaWUemzd3NrO3Ko1PVVxXfniEXqcqb4t11X/mujbbPy5+MpsoFsBHypQQ0obHCyBZFm8NFUhunvXw4UrVwOXHRVihmxYbuEhtcmD/erV
#q60z6H8xBPbLszviGJgl/TKZicCKIvwc7uF3lRrU/2U+Mai0zk1oKO6ap2xJwbPH4IKliKsUtNvgi/n1N4MPAtdmsJmmgdBO1cVstL+QebPpl3
#1WTKrgdlB6cJICy/FpTnRvW2HLCSQW9o3CBCWrzvALrAile3eYWD34hchl+PdEZpPee38DC1haFA68AgA=
