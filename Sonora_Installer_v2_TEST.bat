@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); $m='#PS'+'BEGIN'; $c=$t.Substring($t.IndexOf($m)+$m.Length); & ([scriptblock]::Create($c)) $f '%~1'"
exit /b
::SONORA_VERSION=2
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
#H4sIAGt502oC/8S925LjRpYg+J5fAUUqk4QSRODCO5ORnUqpWuqRSipllqZrs7K7QBAkoQAJJgAyIsSkWT+t7dg+rNnO7Nq2WZvN7sN0t3pt1/
#Zp56H3qfNP9AMzn7DnHHcA7riRkVLblCqDJODX48fP3Y8//eizb168+sO3nyurZB1cPXiKH0rgbJbTi0V0gQ88Zw4fay9xFHflRLGXTC92yaIz
#vEgfb5y1N73Y+97NNoySC8UNN4m3gWI3/jxZTefe3ne9Dv3QFH/jJ74TdGLXCbypWWgk8hZeFHmR0EicRL6bdMLIX/qbzs3K23TcKIxj/gQbSP
#wk8K5ehpswcp5esl8PnsbJHX7+mb/GYSm7KGi3VkmyjceXlwtoPdaXYbgMPGfrx7obri/dOLaeLZy1H9xNX0JT45vlKvmzrmFMevCvD/8G8G9o
#GI/nfrwNnLtpfONsW+rkwZ9to3DrRcmd0ukA7A7x3SZxbsetp/ADxtCapLPeO8HOGxtzbwmPVl7kJ/F44QSxd3wwjsIwOXQ6s+X4odEzuoYz6X
#SWwThazpy21etp6T/d6KnwKvA3XsVLE9/5m+vxw8Vg0Vss4Nd6l3jjh87Asdwu/HTg1cKeD034PoPnw15vMYDv7vihZc1tz8N+x9i8E3WWkTP3
#YR3apoWj1nhVxXik8ZpKrwffWU3FNIxHOICtVTXuoXp88MlhFt52Yv9Hf7Mcz8Jo7kUdeDLp3Hizaz/pJM62s/KXqwD+JR03DMJonETOJt46EY
#wDGhiP07IxIEIQzJzoQMg1No3t7WTlYU36fqwq20lWu/XsMHPc62UU7jbzKiB21QkfG85/F49H0DJ7Mra3t0ocBv5cEcY1ydvruIG/HXP8xbnB
#2o5jL/DcxA83Ysd7J2rDGqgTNk2A7eL4AHfggR7AmFfe2hvPneiaPR+PZ94ijLwDb318cTHZhrGPDY8X/q03B7SCHTo2Jj8CEsy92/FoBCV8KB
#11vD1UicebcONNwq3j+sndWDcGwtDHuEku5k7ijP21s/Qu4/3yye060B7ZL+CrAl838ZR2EWyim5sb/cbWw2h5aRmGgYVbCtvzLbNvtBS2FOzH
#I/tzaGThBzASxZ9PW5v0kfdqF812gbdxPWXmxN5vIu/tDn7dTVv6qKVsdutv3MTZe9Cx1bpklS5ZQ+xHBJCt7VdhJactnNojy96oWRswXvh2AU
#g5C+d3h7UTAT0B0JVXaJkuEfsN20udIAnpMGoxRmqhfYlA1uK7OPHWnZ2vdZztNvA67IF28dJbhp7y+y8vtBiwphPD5l/kyGrsV5Nw70WLILwZ
#r/z53NuwYZ295B3LeJStescWZ4E4DMQn28td45GC/5xEgUr4T6M9YPaH2hC2QHeg6d2eqgn4rQxgY2vFhuzeIwX/QUNDaMjs8YZwE/VNzbRGmm
#4Pz2ioC410WUPwXhmlI7K7mmWammUPNd2qaGjibABRCRbOLlIsK1Y8QCGAQifcJcBsFkh5PcVBHNg4iZcC1VnAg9MwhYWBjZ9B1SrjhhMlGu4o
#VXE9RIBLF5dxwrBuPAt2UXsEbahK7CS7CEbQNvWhqswiXPiNF8dtfQD0PNuPvd7xwZ9de3eLCBhirMCsDkl4oHkDGqwZLQywne4jrf9IVaIwwV
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
#Zv5mu0sOgiTNgGYU1aVcqwJxkcx09LTSgpCpXAXJKMMatDahwrL1g0Ai2KQJVAG4SqRtYOk28W+BgRSEshI/sSqhxJgKjpIz5QqV9Q/tjolYmu
#JtrgOTxvpAX67kKRLtqZpiE87VCDR8thXixHJ1TxHTTbJhppuacOf4YGVqK+tQVHPMXMshKmAcV+YhH5SNegtUE5SlbnEbNkgd0KtVxZZLGpDV
#vYesCVgZZrO0u2yrMpHmGqjfoVko7BUES7eEgrwLRYKEGzjrbbsL8NAG+xtt2EVswVVNSbuZwdGgEfUrdM4i9G0aNO8MOKFTYYNdytRVNOSiZD
#upfFhhnGbdbA+NODgQlV7Q6JnamviBF59jRYm8reckbeSDyAECDUgRkPC2hcK0Zi4iVRVwg9o9T4KV6E5uPjD4n6JcUMXKihy1eacWlcwCpa/U
#B3E6CkrVKcfK8bvXr1ZLhX1lZCBRZiklFykv0UKRtN+sAE6ES0jFbyJnW5KFaBbZQy8A/Ij9OO3G5+iNzihoIVo7Qar5CUO3+5V6UBWe3kMzwN
#1dEEBlgvyX7SGZp8hqqA/VCl6LkyirWRUuE1OdVJN8mwkmAhchvLK7BbWkq0rdAeQyWVZomdsj3RVAuWwiGgqyaueWy4oCqYa+USbLnUFsKYRG
#BW0trTjidqkTzPYDxKPCWomUDF2OBUbFBlin8y4zaatEl2oWxiotDDIyNNTVsvdVGeTWsM4sl3EPRquZZW/mL/nWtUR3nVVBYZAw3gPdh90GRZ
#jGMCiaTVHgztab5lfFj3Bzaj3gR32SsTnpJnQqMKdTrMhC+oLW693scFJMKVQumlf7xEMdt8JQSjjeYP6xRG6OVfmK9IUF6RtnU6SCkbduCXBU
#wq4XTW3dnnqOLZBmWZQuU5cHeZd1f3Y4y8hSYWUqL0hRUPRn9xEUJ+UxgpALjRTtkw4OPDrLgdJn/hMFCVv+J2ffFYsu2aQqrE1kPpK9QoWlyE
#0Uu62i92IF1MvVpGi/him6bQ4SzVA/sYbruIL8SeKSYKHYAeWNwvWhkV/9oY0zQN+WHp3DlAAnJhV6IZc+qvhhl2n7kQ4gOdzfZmz2q4zGfbUw
#jLKTNOtU0ddKShxgDw0cZ4ivrvRNBcUQBKhq7l+0v6eUCmm2RLoYcaYRYFd5M5llppdLrYRzDcDJLHHpF5XIjfHo0iZN6ZGyCTtMjNXOqEtIn9
#Ye3rc2kZ2seq8nVJc8PTNFH9U5eqq8MhmsznfMzA7ohRF0Cab+wbDQ4Y2fdo99ku0LjV8VxL1mnwtSK1ZU/PVSw4+S+bknUMZejfk5nP2ARsGF
#n4yZP/vDJVFR8C3bpodVQuBamfv7gzgh2hSys6okthdx/ZeI7mumJwp9WHqvkkd8cC8TeTpsa3XIT8T2YsFrclpbOKl0VhqjmWTJySnvU8t6R1
#6Vm5Szx/cymEiNlRgf8LjkroK2pXyLfN1GmdShLOlEB2KUjD+OzcuOOTmDjSIHNfUe/l1ETTwTlHPcbbTtyjC3uER7DweRhNOzgBH73P5qkRWJ
#v6ANzL+m2u5Q2Lq8d/ecMIiaMbEm3OTMGfTT4oooNfYEqZG+C1hHHci+iqx6UxBOwT3Q6VYLo0y4sAq6lSO68CPs1NSHnLTLdF2gzliOSSBFsU
#0fCeE5w6MUjZMKdt28iIF0O74+HycEz0eOCX2jAEmzhv5QEXjgO/C52a29yHfHiTPbBcAX4Tdu7lnU7DfONLYmM3yp6+MDMoi/Tu623hQgsvTe
#HFIjmrMF/grPXG77Lv7mppdU1yjr1rJqXS198VjULBCVUxyNAsyqYjrFEmrBOF8rAbMxKrqJ5pDSjDkhzGNMqsrkQaiApF4agVoHK44PXSEUqn
#tKFytrW9zKUpI0R2r1CNfhjx36wUfXOAr0eZwazvHBw30YlKQPk6uda2+zOxSC7jJXmiEQSov8HLgzspgBQ/RIFoVRNmNDMwea3Yf5WnWhXEbu
#MDvLe0UcQDAmnROX1VcL2hMxW5x7yt3vH4Fj1ETgFAgGBvmIPdXbjY4PMBgzXJYD4oaa2dNsC6BYGxBHJvqyHHA+WC0RrGRMYkAADGj3kB9qI2
#t/o1aYc0ZFaA+yqYzH6WhLk0pXpm5GfdIAWTPKyjoIlnrc3vzFCRM/c6oJVQl5JI1L76dtOZoOTA6wwznIPhO0Z2wOAk5kONBNnWNcbEwdvka1
#Bbx5OaoBZPfU+7ksJXpaEjABDuSu/YV+2iNuCyfyHIRMCkqKIoo8GgrgeOIDV0aZNrypthDX8j9BCOdOmdCJkyKZopAuJn8wqJPZq9Kc0OlhkH
#IDdeqd2Cti2CuZZquM0IWFSMlo36gwu3dPkigbl4sQ8lCMDMgQWjKsj/YrNrTqaHYsm7ZY6e7DPT5E82qFu6/Sglq0swqt/2v791g/23THBn4z
#HWCaqbzvh1kzoeDRT4Nf2R9bCIy1mAJUoJrGSefDCdQC6XftAQVq54s8xEVWD3QaQuavfPC0lFK0N2NbwusCn6I/Nmk1FLJdoFeo6lLYssDfrR
#4Vl+J+xns/9meBdySdr2o/EumLsqM/E5EiVg7PStlorY6YbSTLqIheO6LqxU8EHUURm3wJhXgh2F1umXof0aFyWmGjEtBGlBwF94kp6l1mQfHq
#EwgLcQoUe8DWguvNpVlTKEPZwJyr8IIx4PggdcNlOoI0w9TjQ161ki+t7Mqodm5VCPJ9teAPFMmcEIBTtvnyXnS0cPAv5R5JluYGWIxtkxpjki
#131t/TP98r++fL4Qypxz43QXBgZsbbfp3NrmB2yoyFZ5rIyW5YcK/3BbJe0a9RgrzsCxJ87fUBSDhE2YpGtsJ0O2V0WzgkSASVuMfYmggF8Ewo
#MnRBCIhXXrA4CIzdZlgZf3AsNZ5RwwFQIwUJsRhv0K859HBkVbOwHYl2PNCdIDjtHyyCNMWYLg/slpeKOnWy6KxydDSqG3PPDSMuCQDli/g0QZ
#CyypJUv8LXnoGiI8U+WkXXeyfeONsOaqDjW2Ubhbf+GogKbk8nmpd1xmG3cALovk6sXix1zNQqRlJZn2d5k0Z1IQ7ca+T660M5MlUOsD1n51b7
#9kVJjuL/inHd6EU9313e5fHpPlka7x2ZW3YRCADPoITuQgnCStZhhQe3T0DcVowlEo7wEF/P9cSuYKLodv81wmgK8ZEnPJQUI1BEvnKURSkUQS
#3CadsY/5IkIlErHb46SWPv5w9xk7iZIFmCwksj6pbk3u6vQtLLpxLqxNhGJm0y4/+RMVshgOx4KsLsyGiUIIRhID1iW5j7N5g97tQ2NgT/l2ij
#Q1x4cPmJMsX/Ka9W7/9x7Sm/3fmJsnn/U7hR9hZ/9cmlnDZgYDimW58bAHl9mg5g5DiGO8jTAYwclg5gOOu5i/7JFAAjR0wB0MfvfbvfX5gsBQ
#A/Ut1wBnlkMIMZ/nUSPDqsdNLjw6ORZhoWqPxm+dRvH6272bHswhnpzExvH8Vjvtljq3d8EO+XsvYC6H3j7L1KrcLglMdI6U4VORz0QN3Nzgib
#1Qc2qk+cGpppkyGgPvS/eHjYPnUQoKJCSQ+sjFVLD1uceXoiH7ytFp+YFp2Tyw8Y+hva4DXUtnh21Uq1Fe5yokOoglg1qBCrTNE+0U+tJakQzM
#+Upibk1KtHepx4YHQg6FRlOYMaaj5rSSqtcNjStkqHLc8Pwu02RB5WM6j5cO6ShrLxFcT01IYuRNqRXP5wswrXnh5uTge5PBy4tuPNtYcj27Y9
#R8xWUWI5TVKKaXW13lCzbJZdoHSMsiADB/5sdRJkzVK7rOunBx5lI1/TEdUquAbJ2et4hMKNi0BzvPfhSD4it+sOPW9y5gYTuzpLyZaSkoi1xR
#mJAZxMnAycmRQ1UXdetIg4vLPhbLiYDTOtmKsyeahizHQDwC2F6xuZ2ahrPZoUjomx05uiCWQokISKeHaqQNaBbVADJRGLLXZ49B7h6CW3UaUs
#iMG2vF0R2kLb/MzAdlN1HKngOYKmNk3RMw3LgVv8w8VG7Dden6PLkl3G21eU45uVmDGtuCi3H6mWACJTiI/g65k4S1FQlm2AKW7l50gYfzErQC
#ILs1avrNf3SHp0lswGzUHoDIazhcMOEAq4JKUOynyqBX5OKnAds5dC1GkmZLzrV0aHCYf+cjl50DUK2JobnYaksTOHQ63QMqiTLEx7pI1QgEsl
#m6J3x0wxXhL12Ck8a1j5siecXLzSU7v7Q6/nDZBC5W+aSS6doysQzSZCPpTAYnWLUcUnuadnmvORq3HBugSLnD9a5kAbGEBZmAZAIxVxW9j+XC
#yK+WkFPKY+8/B8YMn4wHVkYV90h6d05A84yXNCmz7S8JoXZjOv0PtTJs2k8F4eLWMKwDDPiI4gBaeofOHO5+/Q6LZ3Eic6j7sbElYw+dLZ1wVE
#lQd3lvWhOo+K0Yx1pt0TlLRUK1PLsVJp4rdajVR0vNLmYwBqQElZNDlK7gHpKPRQPIBA/oF77MhRwRbIqFQDQ0Op7v7ndKp3QYHq4Nib9+gHeQ
#rsnuwp6AueAmZL7QqegtKmPzeYLx3qSKb9zOFYdfjWMiqsldJ5j5NANIfqGejLaEtipqp+YqmVZ8iq8yDRIbJ7JapoMFSYXebI5IaKEeY5Mx5V
#BJhZ5yQ6M60scoXnOkPlURPnUJnnrNqmkPgVq1+K9z5HJm3aHpZ12lwqrA3BlPN4owIDSLpN/GbJNrmtm9kJWTe5bZJ1+xWC3S8QcKEzJuDWxn
#LL/iDpRKY+7CFRjWrN3XwDZp7yvOboqEuEuEIRE85t1vsssnxxhtlwKp95uQQWNJQNK9WuLCmgzWo0qxTZdQ1nwh3P33Ef2T24RrfEnrCFZtrt
#3sqHENwTtJ58jXrkKsxEXD66kXstmPaaNU5pRmqc/lJEhdyLv64MBkD2Ibud8pRGnHIIjSTJobBDRMeCUemd5cH3hWQCslREu7opAL/PA/BP6x
#B2gfh3hlIkk6gnmD3UIqqjMZnVKQ27P6ECC1H5/eao/L6ACf3qM+jHBw9ngX/t5e4BLnT6s3NNpFC0ecdjGD8dyLVY7AeM0RdOki2OD+PVbqE9
#BKlDY/6Kgo6a1ql3Y5QXhh0LxsMAp1SA8sGB8nHT02LtfNTtewtRrJVohF0ZNthHjpP1LkKxK2fHoFh5paxc0sNG9aXWCUWuhUwZ2K+O57ilMi
#VD9k8NLGmDmfk5XqnCodoxijxDI3tIOVKpFBRF5Ad54Rj/HKWUQZ2ZA9yPe4HTAKh4W2i2QAwFWmew7QQcTNpTwu8aRepYQXR4MsOSu2xvK2PF
#deaRp+w2/tudpynJDiGvLJz3/xBulG3ortCCoynQKJSaewqmaN7B18y5dqYTy0qdWNYjIE1cmhuMSJunTIJWwYdlgWT40OgbQ3NY58Ey+9UuLP
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
#0W3ub9PyXkJIoVoBXO+v0/ws8YxbaH8TxINUHMWTOwKGdNF3PWZEa38qk1qvY63HqbN+ckcBMC3Yf9/QoZYvJLb4OSDKkWD48/YsPiqWbqypnV
#JNsWs8tSEywVTOFY8BnXktTl5Ma+K3JyM61keFY+lGIsYDnK/Dw7jmg/wGHVHKU+0ssCNxSTCnATMTQiZdrI7rYRznETSK2aC/xoGJ1Slpt740
#EaNCBfVWPcx5NBJ3fZYMaBA1/omrtDlliAv9NdnhGsOeFFDHsrcVfiLQYxSAf3OMOAGSWozonwLFvGlrokn7JxqyfEhlDgDo3PvcctiZmTTYCL
#Qm1k8dzwQynn10uDPwy5lUjMlkq2HSEujkwRxSC0D0skiIPCxEvZVblCirYju+IYX8sn8clHWB+aXoj9E8IXC4Ex6WHN+IbfxFMfzpkf0a45vJ
#5NoJA0QHLGQj8Nfdz3MoAsbYlERqCPs9wNKbKSf9POLKnFMKAzsgRWjgHhOXZXnnvtzZ/4H6rOHyvaSmdXmR7L4pdrZdXYjU482Q8MJM0pJoSt
#0xF89rgTLha4GKkjOokrWGkWxJLHyFDZ+wf6D1ND0LAyw8YZ90H0K+LwxZNApQxyRdZVsXj52dViGG3DuQO2l7D2WYcBLVrahHhaRTYcd3tdEe
#zIUhBtr/luLW93W/JL1mVzrUzFWOGjmZSoTrQ8jQ887/nSlTMU9T9wdU+kXz99xQCMpE6soGHey85VUI+lNQPgjFdO3NZjz1UP9ZcnIx/13F9J
#0mRpjkqJKTIajVpssqkWNfGeLn2+zCMThwvHa0irb7M4H1brhLMHy5JuXDKLDwxmFueC1j1lF2Yw5mxdDKer5O5axl8FrsUFAtGE/DzVlWMFBp
#obkP9sG4E+ESV3Ci3+Ib7bJM7tuPWUoHPVmvDEjTGQ4B0yMsA7JwCeH+y81OJ8LLRi3bMVZqmWWwmu79lIGh0rNnJz3/kwy3ihkftOh1nUC43Y
#950OWeKP3MAv7HhaJoVfL60RuIVfwbXw4wbK6Vb+05J/2vlPbmsAMQWtJJK55dBgTJFSYcfeeZdx9NllHELdve/dAAKfVdso1UZVvak2LAFFtY
#P42GY7UxEatOkBu9z3L9sdC02F2eVWo0JXaEI4c6D8DnfejlVoiGx0wRkNUTbQ0pSpenLWODp2t7r67Kzqg3Ln82D5QTDoFtpZOPPyuhUQ40f2
#Og0AeYSJ1PkPxqRWhUZnnpPQhRkVPvjBfV1H3BkiGXtlfAj35+Fd1xDQ7A9tSoiSQWZQROjb5DzMqNhK8Qp3bHiochV0QAV8pBRAPNsepOT0Wf
#vcvjW/TeWB+Z2aDdmUU9dLdGB7APBndsxBr2rwlONWo0S3vElDPVJGlMY5l6uNjCIAQAaIV4euhAKl/ZCfYSpi5c3erMzo/wfaxUp87d38JQ62
#nNH/DwzHeJGOqffppvBC61ZN65TJjNcFskxVq/oAmpQPorj0G69u7auWfh4m25q9Uj5+bxX8YlJL29p7EMxT1yDYtZiEMaF0wYLZE4fI72E3GX
#Rto+Jdx+zSy25lRXaBe7+yImt0UFXPLq9mAlzrOvBqYGj10g3fNodYOYfEQG5nBeJ4sg1p45QukrDVY69X1T4G7NCWKcO8MEzMR30WyWb7S9wh
#+nBYaA2zw59J/zvDJh4IE07bKU06B13HNiTYGdy4Hm5A1/P3IIaQPX0ZhDc1ybjYjdtiRursXKuQnrpDoTHk2WBfKxTh5nRdp4MumwMICrGShd
#MfvUcqzCEIOu4K5f48WyIX3RawW8NFohAkZH8ZA04hUxK56ypXDf0ReNZYE1wt8R3ezqYbuKAUwEFOv62TrDTm+aPveXuYhG+MYh2l68sfh5GP
#wO7xI8xiQ+NNsuqEC8rvCSgstlt4Jfj9gForpll9A5fiYFDsxkm82m6s+m4suRtLGZ7uRVoIAUTycwFesgPzWK5/KMaCUpFk5a3pWhwqkjfCeJ
#8iwwPVdn9bd2uG1TO4cVJKxVq2sBjnh2EW829/4GbhTj5TVYz0ezlOhh10F2/u2YJWY4Notpv5bmfm/eh7EcgrPU3H3EsatAbQvAE5PiY6AgOL
#QqQgXP/BX8z5KYCVhHW66U1u1dL0IW8Up8NbFVtazYvtwMICJqHedd+20GlaaIxdP6fbvfu3htnxFJ7FTriVcccz+VIKVoAPozZrhPTcU/Y7D2
#Glu4lONhphPEyHo5se64ZyzCsqdNRBE36Tqzdvjil1ij6oaA6vPtSAv0pzKzQtzGkD3GZMzGZSN9FCZSIE5IySqA2/s9LQDSM+1lexKqv0mqrY
#VVXMxl66lVUae+lVVbEae+lXVmnsZVBVxW7sZVhZRe6FzlicWJfCXApVKtfFGjRVqVwXu9tUpXJdumZTlcp16Q6bqlSuS68RYpXr0reaqlSuS3
#8UZ1H+WyFipUYGJGFStFjz8rS1yRIl5H0eNhKPrE8dGEtTnmNWEArxoI+crDADjqL3zyMrTffVunRhba+3jlW5SznoMO8b1S3F0rt194XqEd4A
#V3WSkWZR9xLvjaODIRr7kiTplxi/6HQ5rJ9/neVfMSIUf63ucWmtGOFAkZrVEWq9ymNXWAeUK1UI1SpGOpKiSkZsgdetQIolrs4GlwGteNY2BU
#aSJW0VfAXD7PK/VFgZkKWdweogJgZLT5IXK/ADMikkKzpB4ZkuZNT6dIlPsT/BjYFOEmEhKgZgVnhn+4U2HtD6VeVPsURRzRpW3/1VuIZAMO5i
#u5Uxe6IBGCQEfkD+Eo2jCXwZw+q4sE6OH4cb5YkSeYvAIyWNyIvGtmSjeTa1xnKp71YjFTA3n/Hnd/x5TRJ5U7i+UWMn5BTkXVqOcvx3hkT0uy
#4PTrMdudOTzEq58n/2NORLBc7ut/8BEKs7mvZrrkrx/GbTqc1RdlwEjxNyV+etZlqP0tjB9V1NOOyvf5IT2eChGqW6RbaBDAMz3SGDErAmb0K+
#yd3KzRoDMielPTpRTY/22T06NeESfX7NxFbsoUJlkBou3ClQfaCNH5uuHrjV1IG8BeOjeI1PjdWWZiEryERO5EcF2sJ4AhCpte9GYYeYp+MyLy
#gSJH82dgjHNXa5bPqDhpO98YMg+4HBD+n35Sr7usobQrMl/1F1KyxLL3wfmPVqYJadC6lc9h5fdsyQW9tb3ogilKy53h41xrRwvd7YZQQ0PW9y
#UrA47ygK/T2zrNogU/wK97nJcsnGU7olsaSEqCk0CvaeBx8uK6YHc4SlzeIPGpVwidvZyPzyWAi6xi9tmodV3fjJioL3sjN/PHNUlmlWUNqZPR
#wG3q8dOCDC+Vc4G+fcy4JncfIxbJuubs4zylabJK1HLOksR3N5dqk/AtWU44OHS49n06veXf2GrXykykInZSeFZXD+4NRt3xMUnOVdzZjDvood
#5dyox3tbgZpBIdXe/HDGNZB2T21MI0IHJ4XhF3FPoGh4gSQ7acQTYCBRTXNh5IuQukoU1HZLSG7qfU3vMm0xy9ol4AYagU5BrnDzeJZsSsIEzC
#1RvzsfzjbhDdp5t5SlKv955Yu6aLg/Yd86Cg3N/b24024TBgHdPM/0xy8lFVpgTqE6OHYzONKdy6XtksASsBjhvEnmGapiY9iinbU4q7VG25RC
#j/ljuqk3pvp6piqbsrBCgCCD0jBMAo1dMgKD2r7Ds7XeLiKxQLousi6pFeUVu2Jnr/f+j+qhOUsTFCnHBQt6cErwagNMs/tmMUisJydNlPJ8Go
#NKc8swrs6SJKM7DjPPLGKxgQOrL9y9/qh8x4mS3jjYwPKTUAHEqQs1FIzJP3Kxf66ecLoIFhqcAya/TLzx1tnFmDSnNDdJaBEqRLvNBsoUGTdC
#Q/abAbYUjvKw+5j5oRyBg2OUjILiUO0GN3vqUawt3D+dt8OiZIhopYc/dPzNYwtFz0fsNXL+88xa12TVMrhVS4g0v4dGNEyZEEXDi/S/QPAppP
#qX6w8FIQaF4zxIuVqfsNIYcoxPFrFC5DDNDIYOGQmDx8ywzSL8UTwB1DgujC3+NfSqPDK4qbs8SvTrcO4pW3K9vP/JhYJ5oOjDRVwk2ynNSulc
#V86Z/tB0Lbsr3QtSTAyYG4/JV+gH+CPNn1xWOrvVluT+vSzJWt6VYsRYVBMlf8KhjLkfcd66eIWtONLUwVm4WfbXHuOp8TEmBDqnmp6i4erFIp
#bjIgridccsJM0p2GX6IBNjbidM8QRf0fXKiMQChBp7Zi8GTkXW8fyYa68KEjh0gdSzIYJ8edq9LsYOsonVRK5ZjzT7kWCMoxAWAIZbl3EQBQpK
#vD14JNhx+wbZcbv7lTa08GRm4VLO5gC1ikxVTXd24tFjWw66wtQjLOu7lKeHbjyhoPhSJnsL5PHiiQaJBzJkVggW4hrAoDCzfJ1AK0GeyhZink
#oAMEX4m1a6ACRIn3s3aOHCPRy7u1oqWTviBEiYHjW5j6Q5NAZuZvrRUJ2UUjWyiSR1mGQL143SUZVccUaUoqyvWrcH2MTaaTifaFVdz1m6P+iX
#XtKJYyDbRO1xx8JFGfmVHWVjLGak+gWDEVY4ufqkqO4MztJ0xDYKRhcu7AA9YBO/rbk7xsovj7GEK2OL1+E0ZLsuZlCtxzJ9KB/n6TaJDzjoWR
#MNSxHPkPxRDOnsIZKwQpahehpmkd/2jEPmTWdWC/MusESQjTXp0t+G3YvLCgxOoWWrdf0KpWaVpQqTNBhMr88/hSsespFvrKvdE2edkoWRn5cy
#BPHtRIYQ9D2JGUKkxGO8ozPThRhicrOsgz4DG+aOPwdwPOcvVSiml8+fNmVKh0Fzy1A5BQ20sD0vWWTVwdb0dL1p3ue2kjr+a/fqnJFWs80JJ1
#ES1KXkgVig1qtgsQKNSeprT6khNyMKwr3N7OB+z5CY18DY3xxpW3ErMFCTtGwpm/q3ThSiTzi+27irKNz48fuf4GdbVCzUXLMgaUQAGw6mkZlr
#3Mw9OkUxgjsm6rDpScJdl5z0XQOEO7ubsuOgibjy68Rg3iyiOIXUoOp+oybFpsp01aQyFPSVfpy5MdZOfN0B7rb0yqaWXCzXULakpK70ZdAvZO
#j6VVpJFSUO86BZYSqAgGJPq41WBAKyFktgYMsFkurpJOJstaq3ZVmm6DEUwm1ZF2+NPSt5uvX6g6p0M3kbKZhm6aP9jYa3/6mnLom0Ki+JrOUv
#dlHkL4db04YSk5rKLkkRNtyEUuTMWfxEL5ZFYmauIIBIR5ArmIaVSdOZdgq19K1TW8XK2i7cLlLQt8Xc+SRbivm8+pUsjN0Mydr2hCy1+qDnrY
#sL0K+knyNGP0t0JlUmzZ5Ibyi6QTOH+xXR6oCVHQA1YXg64HTFNh4d8yYT2fwoHeiNEj9mATcgka28CP5pysKnDyeYgVghkNjUX1gyUqMha7c8
#bxeRmRBlH+UJMUBVMNyXb3wZamYPaKumjwY16fEt62R6fFak8RrJinsN5GsPTt7s0O+p8qXAEkXnlwIDlBQ9Xq7kFJ8Wz+ogCIPm/a4vlg72I/
#LmyL3bbmFZycoDPUuyluA5aLoUXBBXpYQUVvWNboWL0UrZEmpMuSazTfMD8xp8K2QcqFKKqAa7xQU+9e3KOBQvoSvmYa06a1A0GpTcw8vTF43S
#SCQluCmplnC5F1WULoXqVmbg+CUKOg7t9H3Ilpxc2+IJpd3r+15bm94YyW9HmUgZLj4of8ngxP49dc/z6Xwm2H9NAowyPmylBN3icVoWY6Q7q3
#IqCdva1njjChdLsAhRJzdzWeLl7FbN7ew54legL+fcl4TfyibssPxzMmEjVWRQImzqeZfGEqxJjpXSfeA0BJ1iKMyEZ7ByVsrKPBQlHuS5Wk8H
#UVkbYPhZilQMp9j97qLMU7q5tigAUYot5nJJ4uqsMcXLp1jhjFgPEH17H4K+wxPoe1b2lvRSMLyBENCyjKYl3iBbcVm1VENEUjH33JDHXMHAvQ
#gHg5P2XOmiA55MPEmlp/lo3ve8gsg56E1KefqlFN8SAdtGXof3Nkt0N7cBZIw8vM2YOnVEWIEppPMCKJpi8A/MJ/FBrijnOsTGg3mZ6uGbOHIr
#sKD6FnPpYkKrClGwOcU5QV+Jrhchz6LzWf06AtS0Wusw8tL7DvjlLMhUlsI9kLRv73cTMF2CItwAMxTjvDs8Nx70oa9+lKFYzMCY5qUXk7NDTb
#9osi6wbSkhYZ2oUaWzpDQdlIyiJMLAyjOmFHgwm4qCA+PyziAd6VlXbozUSf1tp9QMP1bBvsSHgmMCnusYdpoPOb19kV6wWztKRB8jKktZ7+DR
#h+CRF0WzjNR1mRpa3jhUTFBc+XXNTXn9V2ckLxIuHU3vKz2KHJAZSFJiM2DpjUDlECRu2ypmvH8Rvf9p7iegaID+j5qnt1wK6owbwYiTwy8wTw
#uHH3JbXi7u2F3OqyiXWymyp7TWp6WYAk8jx80uxieUAjFVitnMzruImlk2SFEzMwOVKbjVzrlCQzTxZIE5Gs/sJAToZPd5aA8ta257nmxEEnIb
#pJNQROZwpvhZyLZWTBqWXwvKe1hFyaEq5eNEzoRusptChqYYZbSa4X2y1T7P1KZACimTstq4YYZCFoy8Udm9uJodjEdaXWoGs1uVzMFWj9awsn
#zXqkwuoR4HdakfMuA4Px6KklWBz1fqqQUtFBgC00KLNLsp5bop55Q7C5/KpStCuXv/OqHczo+x0iufL/uQGBwZpmi6zJUEFiYnYQv0XJu0pceT
#tggrWuslwGt+CsvJ78bL6uqAyNdimHn1rLV4da2wQH4pvcx1BVoT1bKqYwH+kh+KSoOMeVKWusJi2W5Fjhax3a7YLsvMMqwrLJZNk7hkQAFJwj
#8UjDdiAMs5G0Qw0zwExEruFrenIqVGRuOdbkaNP6B5y/W4f9AwhgZ+Dl2DPr0+fhqG1x/08XNmLBbaw3nPMBajtHx5p9lo57Mp761/C0QVlN3O
#Opx7YwyNBLlejv3dzpaKpffqjkIQWJQMOgKE5ZQws2XdXsiGQ6tXhjDdC0knHjMYV2dpyRebpzbhrm4hMHuBoXw8AFWzY7W02TGSuC+HEYtZwb
#B+TWySPedxlreaoWpAJvcr+JKiJz9Cp9l9frIxA9QIp72dOZuNF1XmuUmtzpb1qDaP3KPcYDuy6oFTyS64LwM1+z7o9X2CWUlPl22IqeP0rFu8
#hmaOq5whPHSGvd5ioP4qtL6SofervLh9KRYZga50qxJ2mOhvlKLJKwx9+bJVphUXPA/WsOx5sGWzXl8OO0nBQiBfkLMqf1nMbC7vM2dzqCfaeX
#o1XTixOCzkYTKtMxoQT5lYUgNmE9sQGsiqG4zG5/ULrKi+AekgIfktxGxSAoGiM26a+CA/Y8gfyMlFxtsf/CWFrtwjeBHrFPNeZZnLdDEBpVnI
#AZeeDpIL4R3MkvL0HWiJCp7gDZWxEm5mIWU9EPUneCiaiSzxrmh2s0M3vVW4fHP6GXcASoly8TZz0+aRKmZ/qA1B8+6CuGSa/KHdpUsALXtIBr
#dmi9uRhs/zLBzk++PYbb7welthzhH03m7pwoe0Vfm6YObS5VZdeo+2mdyYMkxf+JWeNXwBTV7XBJqRPT3KroCcnJ2Ru8nJwW68aDL0kmdIjF6T
#gk75dRyKfCtsnjCKT0uPMSWS4F9AG5X8zl9nqdjtwkJKGlkhMbudwnRxXlhWV6aRZrfKxofNiTeg1Svq/GjjGPp2ZngOLuPB3UkWXY0cDvWieY
#MrOj3eyem+QOnRxXw6y3fRYCDwAuL4hLT5pv8NHiSft5wEFWVPiNt/O0s2VdhJLwqO9ZIT1x5pI7you0/BTTCltzNnvvRqEJoEgPxibsFOZw5E
#G1DZDi9TlQyphaUxCsZ1FE9OOTfyI1IFlGftJneY7gbWzgkKbmKer1/eAzj7bZXcaebT5uZOZi8lQyePtuyJomnXOCeysrQYXaClmtXH60VrHO
#os4a6T4HFsyhF5yr1eUeE+zvZ+pYN9UOVgr2TUYkQBcWYxVvZEnJR4FnZYe8pK1TL9ieX2eEvBJIVtmwcrVUQmYaXVWbSoX7wPh+ID+pyVUjuy
#u3hQtsGwaJ/sSheooReDDgrcy0qbxtjKutti2evmC4jfzmrvFbKyS13r7xV6G9wn4/+/bsREZtvtCtd24xj9D7jDY1B5dQdjowWTWHHviBpIff
#TEpEp4gKGe5b6gTBxQmMVS4Bf9rXs4K1sjzbIUQtHojb6HQ9lkTtu3yUG8cDzH7KbDDzVXmfySQIq3lQcdKqO4RQz74C4loYRBwpHCuVhwtHQp
#k7DqilgcS1ADymwHvGVTc9d9hah4MmpE9LyxQJ6slzL65SEUFTeNwNB12A/3SCaWaQf9Cu3A6GeKQNVVHVgvj32cewtnFyT5KBSGXxnPHzjOEN
#96b1P61xPoX1e6Q6rTcas8Bw3z4inhUvO2q6oUPW88urQpb8KjPG5DO6MuUfm09vC+tU1LrI4H+PKgkVxz9d6y7KGV3g+OukymIUGTbqmkc4b8
#LJmqEDAbz1/TYswjZ5kL0XaPPw4T+bRBhwXQlOGeli+cTmgqPg/Tq4MEXepMVYpcE6nhSSCF8skI0Q+UlycEW2+Tu5NaRoWZLHM9ZmxWjtLoNz
#hq32IW/y1j2dwfmIuk+Wkgfq8ik077aYR/ejykt19VO8JFKY2ukcNbu6rkKLrbM6oLVKxx5kENlkaBFBK1LtecqOt86kR4r+ZOWcGMlIXz/h/C
#jfJyG2LzStvZbgNf+bcgaoc3sXDOgMw4Mcw3jNFzONeTWZU0bxRDX1P4DAUJvl8lwZPCyXnEGX5nIcuykibga7StDHPqCYoAqANoLxl1Oe3sa0
#MgnBpmbK9TD4yCtG+fUg8qKtzjgsehWkzQWPJ4Z/2XXeEVy3VW6qDC6vGBdkyB3H+wX1xMWFHj/+71qvNswPAV+BfwVBqKqTQk+yjoFHK8C2uI
#X/sIaKP0aSufLdZWtRbVDqu4a7PIx3PHW7GOLBY965HIUppmnNqfOSBApSnJb4XLXaVw4Hz79Fi0BvadXdBW129dYithmdAAdCje4Fe2E2HReF
#vMrJ/MNjVaWMPdenXS9LmHTA2JWdW4rau81v3qjBq50hyzKZ115V9fndQcX8MWmo6vUR96uFgI2WeGlRsJCzarsclsdTg7gPykOpMB9eylGN3v
#EGDlCvRiLc1mwhLqzVZN5wNPnEBmK7A6uQKrpguIu6ZlzaidpqOabFdgrrQaFfRIBVh6stySzizwN5X34QJXWGRX5IkW0CGvJCtFPZEYnthX7s
#KdecPSOYfCVeYNmnu6SkxzyoZy1m4pXK6YVdZvy9VLsoAle069RRf+V7q1xxyKp59StalHtkzoT9hGwjrS99pcUXQB5MPYS3Zbpg+AEuyB1sEp
#7NiP28jmNGRRGiW60x4iOoCQTGuuHkonIo8Pnl6SMfYKvqw8Zw6f2BV8wAgVN3DieHqBl11c0F1xn4a30wsmMXUNpW8YF8o28kCA2HvPKUXHd6
#iRTC9w0BcKnrvusI6mF3jV3sXVU1AX46unDKh/zmGq+HPoxLxQbk1oHT6s6YUJZWPMdcZ8E/ScRjq9wMcdUcy/MdWLy0JxAHVDBatcwWwoblPx
#S3nU1bOwzphF2vz04qHV69verHowQjGm5VQO4pJBFG81UWAAX8OOtowXFiyPPYTv+K9nKAMLPgfGSxOUD3pBC2gbxvewiF8Y/92Fgl7s6cUuCt
#oPETwK5wYAya6FHQsd9AzoANrpWfxfH0+lwmcXO7CpJ9CFoduuAU9s7MnmXVo1XZpSl0OaKqDg1YMHT+f+nmCLiWeqkeoSilzlBXmwS1NZVpjj
#N20pBXfTBdWn3xdXDxRFLIUeakTg/Akou/DAhzb94gf18jLchJHDe4TGVubVK0dZ72L/7c7TnoL29RTtYld4lhBpZuDHSazDvPEh7EeTam2vfr
#/xlNjbBR5IUT4eO3R+CEHeVhIHRvL+J+UP4e7VbuYpQKOSHRBbXWE9K3HLA44d7mDrbuaRA01vqckwQOS9+ma3B2XuqaOsIm8xvVglyTYeX16C
#vAkCvae7Qbib68swXOKPcH15AT1GS8TPv54Fzub6Qom8ADc7JlHzoouruppPL50rxUsUN3r/k6fsNkA0wh+8REdsppE8J/ao/Mv/mc3lM6BYyv
#Nvv1T2tvIv/5yX/BLWEqRiTOgQKz//9/8zxSt7kTIHGPqldwgdaIRXv4R54/RJJsCFvl7g+uHFrumS+huGAtfe3YVC3GsVBsCRphcvMDdnBnLf
#9ZX28y9/dHRdB8xFeRnmuQ28BAgI7GJol7GUtGEUbC+uXoTrtbdxvejpJXsNg8LRIPkt4yWo0wJWwq8STuJ9OfQQHgsEO66g2LDX8d+vR7DjEs
#VW7tivu1+Dfvf/m9Dv+F+JgA9c2/HmZxJwc2C86CO9hH9ARM0RWz2QPL63y6QzLpLrArUGgvwCiDSQZOQFrFngBJZNHbGWuzUty1R5kFNlwjgB
#EUH6UTbOnuPir0w4qUF5O218JeRbdbMK14iofraHL5Q5UI+O7wJNY+8ukcS4O88Pso1XNVB/trpgNDl7lNS1jGTcZU1/6s8CP0xW7/8R6HpKvt
#lfPmoa58YD9pX4CeLob4Eoe0hQUrpf18022MUXHDQpyRAb9dfbrNEvyWQHxHC3yRtOrXN1Hey2QejMi12kPEhcARFSzuzi6tVz5dMvP/3qy29e
#ffH+f/jd7z+vLb0NYrZU+KW+0cRZXtQwSJjtbgMcIorLIxO/FjFyy/GOOr8Rftwl6UDEvw+E1optrZ2UN+A3eHJR7nOFcMy4y6IO5DHsf3fFQc
#7YD5Z/W+A4v9t5yt7b3XaSHaZuQZYfKc/OZzY1nYN0dB3wTfGCZS8Q2JHIXHZLUSjaLXOQEc+SNkqMoL6UkD4FHmb+vva8LWsH9ZIMY7/NM7rW
#jZfKV2+A6g7wp7DPUCBw2f3rdV1QDdbFLCMwtCVmtZ0ylUrolj3IOgZOv028AjVBAvkyhVLlUPAugHnzdPMlQUZOeJzt2sqd4CasuJtImw8QNU
#SMSktRXD4vyb5L2OAGfDJXa2fuKWjEE0ldNroI6v38t/9JIoOzuww1MlD8yMH2Ywayn//u7y+unB+9KAkZ5AnXhCHgkYELzhyUf/nPoEtY/Rwj
#cTKNO3iGiFSmE4E8zzXHok14Qzzq57/9J1oN6mZ29R0wbQX+j+byXeTRQGlqL1Ygm4N0DtItzCfyJELF/8oL6c94V5hhq5aBYVLcZoTwZyL248
#nWDKTPf2BU4/3/LvGEWp6GdYucoJq6upWs3k2Ci7ppxqvdIh8YCNFOEvpR7cSx+CLwTk2dM5bI29dyUHzHfi6YQNfQIEIo5VXOXT1TxlJnNpmO
#cePd1gKe3t23wcjLWf9373/avv8pQSWsugfmha5f3IJecZ1SLiIHO2jWGBtGRrqIZ+FtrdAwJmlK9WYPdELYpSQmrx3QPEzUOPZOsPO46Oxt4Y
#tuis3Pi82f5u2109xjAJ8nsdbSMKFMwyiHRi0Go5c0gziL+vz5b/42jfts/06tGxVIMzuvyGFYPKfAYdmDZraTrT1oD2G++vhLGQNdclfO+/8b
#jzyAAuiSUkzEKEaX7fr9P609piTVYgk1exb2LWIRGt+Kmavbv6mFhHcLKzyvQ8PUkJPqwg7qtxm8OIXDz0pFNcePtyhcza6KS0SAlWezXPFG3S
#Dn3d95CRCmSEkwMsP1lLc7X4l3fqKgAQDBiQwA5LEIJIrvMYfjKVi9vc3RxovW0HQDstxWQkeaXoaPuURGoBKtZYu4EkwFvsjSOQtyQWEGi/hW
#yVc8n8bvABzIWNrv/x2g3PbsyZS6d9O2UZfCrCfsF3y7wEMc0wtxbFLNIK1ZYOAsO132Er6WZHypNBLFGS+d8N2X0aZF7FyUtCG5/qxCqFjIBB
#RmdyYJZTlCP4CILuImMiqDvIFJs3Sfv0gYSRv61XgyNJW1+Wsz5UX8C9hyHdliV0swljgPlmWrXYL0aWVdCerP00v4XSc5uUEYewUScj/yURqB
#M+M6OftaUwx9QbwYfRWKiQi8AELLivnrLQh5jut6WzTi/RCHG42igpgKdokPLiRN5qqmJWcvNEQ5Mi8/KdQkiCOoC0DPYA4gbbSJENCZjd1Ule
#8doPJR2R4OPAuagOL6BtStUzZwqTQavjVgFZsNqAteFijlJQorRgblbFTAVV68/F5Hu4elKi9W2BHyHEwt6MMUfNfXlHAH7aHlCCeE1chsznMS
#Kh3lFTGof/lnpU0zBh0VXbmemhn/K+3dPt7VXbA//DZc49XjgSPoDZUNlJCAfc2wwI33mp7c8uoYf+dEnlMaQkK7TRrCZ84iUb7dba5hYt/AdL
#4GBQVmuPYePzSNyfM7R/mtc+2sd6APdpTPfnDmPxC5Trso4nNErK5aAgAM3bgeUMbnm80uqOfpZFthNUIg8il+FfebiJqxG/nb5OoBukcS5eMp
#VL6ah+4OL3fXAZc+D+ie90/vvpy3/bk64QW/nR4eoP1y3MrNubZiGnpPMS3FDkbKQO99bxkOxQ6hU7YD31ad3r7T/2K073/RFd90zB8vLq9a2g
#MyXIptjhRz+H0vMK2OtTdttPG6fuQChrnAe/qw5+6A9g0B0acXxbf4mF73s9fQA9osxQ5gtL292f0ax70yu6wQszsWipm977tfD5RR0Ov0FPgP
#qlhGVgWNI0KFNQ5c6XfoPypB1hOxRF8ZKX38jxd44ESAA2KnfExfm7bSD6igwosSsxOLWoY+VLp63+nBCuA/Ch7sDOCp8RXOUR8ECGfdrCgB/w
#JYDSxnmQH8gqd9XBe5LCudrhStE55NUgDWowsFIG1dKBQ3QCvDwgYA/PA0uuXLk8MT4GPsTWegDFIk6CrGvmMSpId7DlVMICTCDEeo2Lqp9HWA
#iQ6NwFp08VO34PcQp2DilHrwD+YCjzvwuNPrYCGokGHaLAwkAAKMoWXF7K5GAChlCMPrAPQ7I15+uwtiCdstC1en0w06tjL6agQ4j1++sPjAtx
#EI6GL5AWGL8bWJfmYXgIr562Bofb2r2B14MQI4j/SuC2sEg8d/FkzKgona+qBjKXq3Y0ONLkxl2NGhCsxN70Mr+HXUseE5Fod3CBKAJq4crNfX
#ZhcBloHaQCxQsJ9RB77YUB9Wu0vNdNk+Zc3C5wAaxe8D3ezgO4SixSES7zYwP3HDWXzDWbThZF8Prtzeog8DPrEh+BdQlzqg+EAf4MoNsicEXg
#sQm33SIo90XNJuJ6sBaJA+YIPCyB4BL23CSzvDy0GOlwOGlqbew3GmFWA737MG6wLr3bOPM6oglMkeXwC0yQFtEqAHIqDXlgmI38HlhH8pMpJZ
#vUDPEHIjwBHY97gZgw58BciP2B4KCKnwbQ9fwhd88CNt3H7AkPMr3AOwXeArbj1ADSvoAALiK7OPryzE0ZRk0PWWTRhTJBGICT3HRMzQOe4qhJ
#bDQEdKhsQAI11N6BEHNITeTfi/XAXGjftFKTyE78CgxEaIAFXUxpn3lFKbgHqd8jDwX1AxCoX217DUTK9jfmHnTcCz7qpUl4rR6oiVWYvpnPMm
#8lFUNATD/mJUfIrj+F4cBYKiXFkpwUFhsA0qhpCuRwmgbAW/H5XnqJhfiAuCJ/JXVQsCBTlK3Uo4PSR+ag6/ho8AsZgTY2bYEYsOFfuLHu8J20
#TiZK+hAeN76XEHKLy9xoi5lZ0/V1Aa6dgo8PT30nPFWvE9RxfGCj32laGDo+OAhBquAQQZWAb++8KObRiE3RkBfwAAWThp5Goj3rKNBJ3vZmZ8
#lmbeV+xVb9/7ugvUFSor9tfwBwbXA4nraxPg1UP5AV53A2DonKNFksSCOxsqQ6dWALyPNq0kioy+ZxVR8RR5MnAboBDKsIN/fixyeRSuUsnLuZ
#Mh0g2A6Q+R86ckgo4ICfS7T5QyJ5RdQa7oc0pZQVpPVoCumNFZEi6ARcNcgMEqXVxbE8QRp4t7gdYMnqMwNiAqR4U6XQKzvReK4fMvOA4wg68E
#YxMkxz6KCfv+CteiWwAYCltDveeghMm6BSwhODomnh3LHqZQRbdINVHtEU1lnLGB6DYUGAkFEGJogG0k4HIwntkHgQSEMQHvAUOAdaOAhi/FFx
#18gQwexYLSXPVcAJDfdfAdDu+Yaia+O21vtIU6vWpR2JEUaGTBBummcSStJ+3Fs5a7i/CsxgsMhmmNWxhs1FKftNCUFYXXHnkYsgLp0w5HLyt7
#gJEzrrNFPW63mUuPfwjRYMaeX0Gn377evHn3roW9sIiVVj52+Ji2VUEFe7vzoruXdAImjJ4HQbv1mptT3rRUfRFGnzvuqu1Nrw6e7mNCoS9eff
#3V1Hfbno7lYi/RfVfLfyzUY6bEvXoxPaBJbT5+3eJ591pa62FvZpmzfuuN1vrO2SqLyNm8/wfHj1tYynO7w9EIS43m5qA7h1Lfhlt8w7Iz4Rtz
#3vXmQ3jzXehe46vFrAuN46vZyHRNF159jhOKQrljkEnnox51/PhT6s40ZqOhie+MxaDf9/DdV5jXlt52nbk3NKjL3tCwcTDfecul42GsNbx3bK
#9v96jl+cA1FvD+BSrKGMHBxjVbWF0aV7dnG6PWmwyL/vzL6eEVSfAoUbZKoGiB/tOiqbdQR2mxubZQq2hlk2uR0tDi02mR0tYShtgCEbqVTajF
#dIaWMMYW6cMt7ZW3maMFIObDyYaZuGEwbV9raCEBrDmwp+701YvX128m/qLtqpGX7KKN0up0EnPceuK+Nt48aU3gl0W/zDd4yF6Jp9jEu3fX2u
#0UE3xFbd7USgkXSqzeTtu3n9jmE3eluysnehHOvedJ21DVR3bfmEh9rGJA0ie3T1p0RrU3fKSy3tjzdvv2SbdH1VRexO4/UoUpzZbT7fQKZ9be
#6v58Op22CElbz/jnGB9rW50mDXM5nXiIhdol2UGtxFLVbNMt1sk0nl758W/olGs7Vh8/jq+MZ18DHdMXQQiwiC9ptACwlwle9t4W3z2Cd6q+de
#YvMdtt29JaRksdt9DanfUx91zsg69PMs22txsBE/K4kaXdSo1DLXWSCNs5TiGc6GRqz4DlxdQuH1U8nW52QfCs1RrHqg4MDs1V7cvXj59eXby5
#XGru9Kp9aD2GeTx21tsJoN5T/B4k+PUKvy7p6wV+fbsL4cfxtftGBYKBOPJvPv/DtNXSXk4PWUDw+PUbzQUC5I0Px6OGpHZ6gD2DlqHWUcMiUy
#hBLkb64k87poa1vYiGqsFc53fThQP7RNsClrOnKOLwh5RC2Junv/avMjwB1EhgQonuPGm9az1J9ETVk/ArzEv6AkhdOyNzhDVEVV/qeSjzwt/M
#24BoMo5llfz4q2tsnx63oeUIsCzWY5hZ+xbQ05+3b1Woh18ShBCeQ+1k/1Oi9z8tA2eJ0dNOpMzf/7TAQ6lCgU8ueU+fff4bANrKQ0lh44VAEV
#zYqDzZKfyAfZrRyNkSyqA409IwjDYeo+NMA3THy9fxKx68Zt9gC4ztvhbfYJJE7YGiYNIyXoHSWfGvYRCPe7CI0fxmbA67GmbH0GLP/c7DQzGs
#EPsZZj++IqaR/vrav82+vwJWyd9Al5G3xNgmoLW/+Q7w6vcv4c+ffwp/Pvsc/nyKzz5/CVQZBKXx0NAweIy3BAjt8s5xm48B71gQE35bgNi/dm
#7hUcTYcjxm6BHcQTU+sd12/vsowOLw7XnacrZzvv3u8+kBwT0+ACH+7fufmgF/g/yCM0bgF/OZNRgM8NtiNLBNZJYBkH86eDNyAPVh8qHrOaz1
#b9z3Pzlp80Z/1p93efN9u99fmLx507OdoUPMbjgyZxZ+s7tzG/gtb57zWGoeg9n9gNp/SV95+3xArP10nNT+YGHOTeRlDz0H+CUxZM4C0+HPRp
#btsvYx0XRCzf8mjN7/U8Kbtyy31/N48wY05I1480a/69kz4sZ9x+7SRGbewupnzXN+Tc1Hu5kfU/Pf4bcU9nRgibfODpbw1rlsgLB3rb7VZ4On
#4aaDHw7MgclapzR31Pq3+K11zNb9+VdfwYZ7OX39upVxVXRu/CbCr9AqYOobTXzp7G6V9/8O75jo/H6DI0U8LhZRvgvvHCDpWIQhuVwCegDhzV
#s7y43H8L/UwqdAMmJcRtwYpdqfx1te9/OX5bdfJk7g48svX5UbfuFsnDkux4vn5Zd/4WwR81t/8W353dfeLYoh8Pbrv2y9eZOC8LvP//y308Nv
#vgPM4ED7/ctxSwLRn38K6ypC5LPPxy0BAJ9C5Wy+n0PtbHpfvhq30tm8eD5upYP/i2/HLT7Wr/9y3EqHdiwR3jgBSQwIb4HWLnYbSqOlxEA32+
#ohie4OQeg6wUuQq6G4DsLxl4m3brdiiuH7axSYoduX3/xWj4m9+ou79ktVPbpOghK3ejiCFuRE6PEBsa0NrEmdwJ8pNJQ+Q56zwAOK7dYla++w
#9pJVOAe8/OblK6DneHSu1MdR1VknWP9wVLWugXeSOnhzopJNBF0UqBCoByTuMB3kz9KUloUpXXt3LRU1D2EOUBfExI+gLoMJW+Jo6tw4PshGfP
#BUE+XJSA+vVeyozQpEOoosbRUZpL9ui9DhTWctN0IbO9CwaKEBlDuYUDDhs6weIEE3H2EmaMmjxPeJOp8SxIEvg5SQqMcyNOZsxFLBRsiy7itm
#P3/8eJ4LHerL6XzyUieJaco/3707HCe8Xy5sqKKcstvEK3+RtA9o2GZCCmeJr1j0FDyDjdTSmIQCEhkqeIryEmGcAE7F028ol5OOWsVy0z4cYT
#f+Rsvf4wjUdAgv9XWI6PUlyMLqQfw1NRF8a5zh15RwpNXeRt4C6Gsn8uY718NM0DxdFf5UQT+l0h7MO+tMRwmFSXPHB0d5W/4b764Na4fodT05
#D2WuRZiL2Fq5066LO0sYQBI6cdJep6gzr5XR5/4eMG2uk8/1t7AS0xbVbcEzRLMXLCXCdD3JWqDb1p0tCrgvVn4wb8+BVMhkYg7y+jpE0qRZQ9
#ruBbqWHj6TyVqBJtwlbTS/aFsiCmwmu+nGu1F+/91X7VYaNXBzc8NPwDlbP6bzc3cwEGj+cm9ftp5gG+pkpzPnQ1r/Jf2iuJC4fdB1fasBpMew
#XAx9qnbmTtV+yDYhBli0M0yjjZqsovBGwQ4+jyLQpto/4H0kYfT4Mf+ir704huUHuhXR5U27mFrgCtEPOh3gfvfuNbCnI2dQnz7/bHr5MF6FUR
#I/++Ps3R9n7Dt8haUkSLEv8TNY9ncJCIeR7wTvVjCUJKSIgncgK8No39FxZ9Rr3u2DcPlu5q1AbVBAWldiEI+9+B0edvADCiB5twAyxS5ZfLcN
#5y7gxDvYlCB2R++uAWrhtfcuwKOEz/DYurN+Z3X/eDmA0f1x/kR51l5h0N6zdyv4o/5xdumn7Bak6lhQHtfTy29ftZ+N21BL/UJ9ln79Ov/6Un
#12qXu3ntuOyc6Uao/rZ+0na9D4370z1E9AATee4G+L/e6zXzb9GhuZwLQH9Qg2/xUGUoQLxU+4vsQYVusZPRjTXx3KeuGX80kRLcNNcPc1mjLa
#tFqEnIgC9EsPvM0S8I0NEtcxRaU5xxzA6hY1DVTusCXPd7zxYTslGs8/8pmXAJxjjSGIloRb3+XPWhoNDztaO9s2tKPqaJFrg1ijioi7Jjz/Gs
#rMWcnp1es9Whr2pAFnKMfaYglx2ggZvjD76Rr5AvYAj1ViNh/tU/sLUbwJgOmv/xpUWyAo3yzaezzrT0s8xUVu73V5Ovp8x671oe6zAex1Pnuk
#Zd4yjO6+pBUxjdbjx22B1DItCl5R5+/eteOr6ch4/Dh+Oh1Yhqo+fpw3hYj5aQQiBaJtSsKgUbKHUkECre6tZ958jjlwP+LtNvf5EWxGIItAWv
#O+KFYMu/9IfOgsaRurTMcGuF7+1cNnfBN/fOmzRgCuuGbpTsc0rVNhDWL4kbaoJatprNMN5huEJt8Fh2Q8x53BR6E5/Cfe6Lvxglfs6X58D3zX
#/HE7WemYhgu2/jv4yhPPqfouClD3KOwHYNthsEfhg++ERM8QBb7mOHk9ZfYNpcq+wUUuTk+5OPH6+g0IL/p+mv8WjEfHrGU/lY3yvZlvNkb3i5
#sNRAyAyZhtxZZGHy8yDBwj/rGHn2c4Mm6h0t3S3o6vNdDYv/NigEo8Hh7VjA0AJCUCoGTCnjQJWNjXxhuRyGBlWAUV/vGXGSpla87XBJdhwgT/
#iQjm44MbygemhxvOXr+kbOzPv/3yOzJMkZiA+iQ3WQGB+MMr/Vv61W7dAUh4powWJkJraTxXBv/Fan0P4uOYTGYxu4tobGqRFwCJ1XgajQPt7n
#BDfY6pT2YXQ+BNWCu4w74nf1L7ycdADsMAxCsyBhKhQdFCRY2AfSMlGJt8iZn3XrDLqtFJAEWZLwBQ2lDxZ+SBsJD14V2/CtuGmnaKHxhFHoJk
#78F+VjYkRx9hBPgKhpAbKbN2zWeATC1y5bU0Ux3TLyyNt2dDTRYq+wF1ZXmK5K+vQEaGXbEEUYYVxD2q5c3lkCD5ggEX7eJb1d2ihMFgzKd1JN
#oyeSDpWECmD5lpkjQMXBuVQwhLEIQoQg4oOoGJyu9LMlzkgbiwdkDFpjN/BVkOdR3ysf2OWzthUNAOzIj/hqVi31Le7GxQMOBcvkAcMvOv0lGI
#H378bu/tw4/fhYuF74K4c7nUqBYnItmcOXO6FUTI5bTdvtVFrvr4sfyb/eDUwAeJn5Fy5KM7EG5h3nPv9999iScPgaGAGA3C5TbwgdZcwhi24R
#ZVyGzIf41jU0ChStnsZnr10eVfkTfkY5ChFh6dFHlHWXug/w1ixbvECzzMIoOSmB+s38UY/fhu6awBgiDbzWZ376434U3gzZfeuzh0fS+5S/nK
#RmWDhY42tYBk/V8i2AS5ARnXFMBTZmTYIKxPLDeYTYpeMdr31OoB3wt86MbQzJ4gbhyWGjaoBbCFx0IvnMM83wG+fAXvdiAjv3tXep+/wrVOe7
#AKyHLMOSpoTc6L6aHMs/AFbgVGtqnYa5CMUtGS/76X8FYS0/ZHUdBK25zOgbg/42iJ39XxYYmeBwQMfhJsWi2aRdFIApxs0060fWYlSYU9Njo+
#q0nKbl/C8sWJl36Carwcg8Ls4J8A/2xINEaScq1vnjyZgMyXgdXOHbLL6dW1vny9fDNts0+Uqp8ADbvWndfA0uk5+8bekG6t40zUaz14zb5Sqe
#wHL8j4mGi0KM0afRsv/TXoJVH78FZbe2gpB0qpAYHfaJupaRyF3b2d/np8XuTyXSM1bKw9NrMtbCbYo2g0TBFzyt9NBMkE5OszhJOtqmouCKnM
#fCIJ57jxBKlwMWVyt5YACweJEcVz7vU0JvyE4QLWUVi8Axv1EniUG+zmXtxeqmr8ZGof1bQG/CI3IJCXdl9b0L5Pt/bt9Apq05OsgVvY+VzSSZ
#uAThY0+8eP2SewrBRW0LwllGML+PixA9gc6Q66nuArewoj60zttHAq5kZaPI6f0BAjYDkhUPlPTL0HPI4KCkP9CNFCxwxe5NYClqCqKIZHSbvt
#aDNgmTM97jh6XKp5SPcNjAXrwcAmsCYor7XZJ0davjzs2dOpdcyJ0YYRSmiNep6IVqG33+AyaImArTdTWpeclKWC5E0K3Rt9u4tXbV3X0zUQpt
#okT0tLlXdQ20OC081x74brlcC4nqQoj5rDImo9a0nBAxj6wbhJq4JmxWzn/uEV0C3cq8Lk96ktJVMgJC1TVJ7XnkziaO+TBPsSlNTXAB1yy2rw
#BXSHiLx9XP9K+ZChvqGlAayQNGCZvIyzRcoJzRhAw4kNU9cKU2SSTTvlJpmgA/oijYoD+t070XC4S8JUr+TzneQSEolxEol35ikL4gAFyZYaf/
#3Wf4OTYxsG99Z8nq5sZl5mwyBxbML91yLIoMqbiVBmGk3efuctYF1WIEwxW2Lr57/7e0C0vHVY9MoTryxn1vufYjwLHzh0ntNrqWRDlmzTBYGw
#CnfQXU5HbtsC2iTTbOJMbQIVkYZ48RXSYrwgBpMb0rEdnuHkItWUsF8+H3aU18MUWe9/ApZBUuzPf/P3LfU05JNUrGFbSQQ5b/35zk3zE/B6Pn
#xLonC3f/9TSxxOOq2309dJvhh8IQgR2Iq9nbz1gcKDykGvQADKdQao026FG2h3C/Jj0uZj42P5r//x3/+zwqYLu9jFzGBjacWgAzzaRGQElvVf
#/hmWS1wt3g4oHd4ugrqtJ15myUSGXVAMeMaGZuMuahw4dmAAmq/F1/52ymgD4ASqpDAHNu8kwom3/SdAkDmQH2VfJ2WUSLf/9PUBd24C4g7u3z
#383Ws+/PWPFWQiJ6osGOKjLBjiTU48YZdxvRvGCcI3UiwB4DnOVFC2DFn2pKjihJ/2UoFTBMZb/4lJ8EABS0QTrr5NyDXCwnNQFKzGiFSLRBfj
#Rx8Je5torEiWOm99YGFqSsQmAkpuOFjbOCb1kViLtt7m8eOPNvr+8WPxzZWpptPeFBwU2PbxbKzKUIX02Tmovwg4iaSmlJPLWlMMtSmO5hmN/o
#kQ5CRLETIwTBAWpImOoTalV2ULxGimL/paGCIg6sJKYDYTyRgAfNV/9ic6cB1H7vTi44MXu/hQPWbnrv80buX5T4Cd/inNgZIWTtRjflo6zQy1
#4WdRQW/OWnWwVX569fvQj5AA46FGj84Xthg/8y6uhPLSIeY/Tfg00DcnzQNtFzzmD6OJKEyIzB/3LlmNpFlRFCPjbzbqIv79do4p2ROqPjuvdm
#ZVYUDgBO0/8zyNrQnfoLNptlaTmdAmd1u14htnC6/2oT9XZjrLNfdv0TYmlSayy4tK7nNoGNZsQh9FF3p9d9oIXWWyXYgINIoN30bh1ouSu3ar
#0yHYEl5h9riPD0jT1D+l4b4TeP18uw3uiOwIiMpJ1aEhHFePhDjcaHoVVcDb3UUtLaO3jx+jZ/f1kyiP0H0Dgk32HtYklyWOD3JbWwjyqe9eT1
#Mj1kfMEsV3NBIp/6nBWi/YVLPNiO+03L63BCjRN7ITtlWywKW2PzTCcePfuMIeOMGRIaEpjgyT9v/W2UuWNcRHPHBwuizQE9Z0SqHT8rlow157
#22JjaB8DmGwn2etq1EeTJ+uDMhIJzXhCjOYvEJlSIdLTefD4KzqXjeD+FONUQYJ7EWCA6neAR8BAYFd87W12wJyQSy/wAxM0WrbBx4lUujhbCp
#L8CP9O8hLVE8aXaUued00t0UnpKbcJM0TKXN85dnzGPVAsdmKuyoZiVK9oYmSIvjQN45O5hkupHllvzExd2VnZrC23pk6y35U7eotmXrHCk9aj
#Fk4S4wTIa+sEbXmnvHuHG0TmgK4w2Rd8sYD0tFWtGgzadjp/5l7OP4HJshzg7vUrWJO2q81Vzgpwu6tSLMBinbRdIsrzyndzesfXhmXT2ApP6g
#CwpTlz9ZRYwIHYRtMAKBlH7RBYjg95ENmz5mEcjxSnxPYVZz3ivkqFKCJxh/tuEYbOGHgqtILsQvyJwacgkhKuEn8TaOpsF8HuZfsLSC+5bS4t
#ttPgN/PcXFqEuUJQSNZrko45mPIwnUyGCtLoYFSMv8SbYCpDhHFQV0DesuJoAQcx2UffBrkNsjdZ0A+I3ckxk6Exj84MlG6MDmGdr2CRMDYArV
#krOXKfBe6vpu0VBe43xO2vMme/G+6npZjoZ63TEfY8iaz2cGE4s4WrtsZ/Ol0JTwR8fIAptHkw/1EZ9tiRAf6uLbx80mPHBlihrvVIVf8kLNXK
#i1Dn5WAhQ8dnxNMQpb7A2ArYvMvp6mn/WetTTHqhbEDNbo1XT02LnoAOHtHPIf1UHNBy/zHurP05Hs74FNNH+1ErN7Bsg6kYp5WqPENmzgIo/q
#mQnSGhzBPs9M4cBVAE87GQhtHdZ7mCP4bJ7NvAqlD4LC7Jz3/7n2BUIAC3MnE0FX5TYJL8C0Ly//r/SklX/pTGP7REm86fpFyhAEs5cdE17OKL
#q5ff/Pab757zjEUrE/pbHlmGQSkz+NPt1e92LS9OOpSgClhQmiNUeYaZPqTEqhiVThMMjmIqpD8dCypyBunawM50c3C9YhvEkpAtLlbNCm186O
#bjA8b76BT9sA0w9gF/EvRxEZ61FGCp6G6431oms2W6lr5bOtnCpP/swE/hUMKxKpvldnNRs+Z0tTDhDCcnTBg8MuNK6TkofC2ySmI3VLWqO8xf
#wQffwu/CqGowC8VDOglSJ5YwOH/E4EyCd7ZsZYFsNs3YPaUcQkVYp3pAV2fqMmzjyRN4gI6kWS5az4+qSNGBLnwbtBFYPGBy+jrjRtspBVluW0
#+QcujIXNR6LXg0Gqma0NBxImIYGYi3Zcqd0twtTRbzLhflutSQsI0wTWu7lae62RQTMytjNv3N48cb7sjN58Jnmj6fyBDaMsiIoFmjCHqr3Wl5
#kFaT3oPFBdVnPb1aZzGMUlhVcyDlWgykpDbhEZM0kFXnPpZbjfYy6ZQdy8IDWdvbvDCw8bzsHSv7BTH1jtVPC6OkxMK3+KjbrwNt8UYVsKxutA
#zHSfkVRacAfkvLlwNhskDFZy0Ffs54yFl9aOiaNkL2HlSDzzFKBDcPJnGCzYd9gfDLJduKXcFW5vHjinfs8KgzvYB2L95oOiZnbanqB6/zUYwc
#yNUYxCL03Qk2aObWk09gkQGRyxsf5eQuJc+vW//l//sfldYTRty0TJjfSqexfmSi1o+CqKXmJI72YZ0YlRrqnzP7O5rf0954vAsv8Nn7n36Al3
#NnEwsl3mSeIZorw6xUdHvd+vl/+r+Ur3zKyMgs+jQDnP9vUdFNVDxw8fP/9v8oQiZcMj7JmSFZNZJkn89xerxb6o2m95o8DaW07WiZ106QlEZK
#IlMQ7TUD45sMbN+mlfHujPc/kcuCDa5ASiZlize7wjHLOlbD0914/114E7fjTGGAX0CxyXsb4ZHCBR5JfMv9ISj94hu0+vtPU/428Z88UbOjsf
#FrptG/Jduoi1z2osUMzK/9J+ab9MHiCX5iXYYJvA/2A1667JvQxltmxZAea9BSxFZpAQQBBitX++Om9e4d+xa18hHBj8eP8/FAKRUGMslbQjiw
#HxH8QIjkbdPgUCHEkOnUyVJd9ci5ET6TzF5R7LHsYe3kVvS+EvzTVcFX2mqKz14bb1gMduZy8qcrWR+6pB2p0DljEkTe/RV+z0I7b1O8UzWnXJ
#nZYbOymVM2QZXq8WOHNCthNlweNzM/BZrmXidofaOPtDOiNREejE3G4gvNGbej147/hkfOULDS5euJ9uZSxVhDftxF8osCPNKCf4ye/XFzyVoP
#pldB1h0fzadhGHjOJiuQhaUEWQvxk9edn//m3//8N//hDXy/zKO4c7Ht4IzXMBgtGa/z+XIndEeB7TiGErA/knHAQttI5oCtV5Q54DFl2csU/1
#YLNX9Ke1d8hvSp8GweLBFGq/Dm63DuBKlxkKetK3SWlSem1GYGg7TVELMEb5belPm+PCGGI2NmWBQRjuxyi9ScUxouP4YgHP35qDhNtTTvBZH2
#PObrj/ofb56wkK9yeBqfZXhdBGe+C6KpuJeKY8z4R+6oq/KGVvlAZSmvOA+OboC7GY1mBBeptEZRFiSfywvBus7Gkrur07ogmVeKkRQ0WSDw+5
#1Xq6pFRD0iENK+DbLDADkM2CxboppI9ydfsAz3eL/RFpR1TD+5DklsYTpjS9yLEW0tkEV8FRU9MdNiqrihWuYfMx2t0/HHHx8yGdLXzK5aVOk2
#pAI9MTPdR8rOf0WOhRO+K/JKog//InB+vCu6so7/zRxZ8j0AqZxIKXfTfmHqzGv0rJXqwFfCs9Qm8X+gJlnIUCnKnVcg1mUFoD5gwbNWsWC0Lu
#a8vrj6+e/+l6we9MTvsWGTaHHzgaSECjwttQ3mm9NN0KXlJpkFVdL71YPg1t1OS6kDKF6JtHRuH2AkZpsyIb5PWCoE7iOmhAipaMrdxmKeBwlN
#tyvZBDPzlx9gGkrzcxduT5ldXH371fM/fPXly1eiOUc2JaApp1jrg6wKFXfZyMlPHbr/o/a6g+0Fs2KduGghzjCGi92w4/KrHP7rf/wPf/P/t/
#e2PY4j15rgd/8KZrk6SZYopaTMrK6Wipmorhd32dXVdbOy3deblbeboiiJJUpUkpRSWUoB/jSDiwVmr2c8M+tZA3cW2Lnr9sUMFgvsnQ/exQCu
#f9LzA8Y/Yc9LRDBIUZnVtufifphGV4ov8caIEyfOiTjnORrVFXWOnP42ojdoZDjFEGlEh//i1sb0Vb7X89kM2DFm/MPf/ttf6BQsOyfvEALQB/
#aIPU1skk7s+ExFO3DmHa7yOq6d/O3ubpz5qWxpxVmifmjIR0skzFadLGmmM4Uqtu6U6GXTloMw7KAzQdA+xe9t2yCg3nhzA8YAlBUJ/7Khs/Bz
#Vz6o2n9hPlBqR1+0o1/RN9CUQZhMLFONJNv+cF1k/mMcQ/6VxiSqNF1kGUBy+a5QkUdwi5R+kHMj3kRbbfILfIEXbINSkZOZvszLn85wzJafbc
#2EHoylPPiokGV1C/ciiBERsYcuxdS/u4I2pZ9GsT+GMUAUbOY6XD1OGBBaFAoBbTIi+Hh5alBysZAep+MgIoXE7uRThu0Ei3NGwzfYgHRyzFfx
#DJ/GuLtiCgwnAd4EfyVqE+IoSIAmBd50nm8oDUngWAlj3O+xq6Rtg2GPmfCoYCHyo+dkRi62iBE8jNe9GnbfkMHE6EFpRyo8Zotpa6iMTp2h3U
#HasejMj8YHyL5qnwpFTWWvpa2mQLkLm0bBXVRMri55ZnDxIiQZKgh+EkfRaTxzm6yJiN1h2Vq8ZaihdBREiwA1fUdcPsrcpuPPk9f5m0m4fCxQ
#hPqPBUaAQO96+vLk6Wv37PsNMQ/ltqFW8BcCf9H1YJQ9sgr1zrWdB0/ZRXXDo2Y3rNfl3sNbd7tFFVqL2d0z7yw8d7yzt+fn7hn+OPjgXGrpnr
#5b60WR6AtdponniLikXAJzt0wJ6EPemroZn+DLkFHsldEkRDwPXxilJu+/9QOMDZopkAFZxNreVlUs+Aed9/vxV6CL7e7uUL64rdU2DhGZE2cw
#FM41v9KsS1F2xRC0Jc8p3Npa5xaCotjdXXHREERjl+7VLAVOrJog9hJkD746lXgJpEmlFixAA3S21C0el43pkdsu28hP615jen3dawDRZHCNP7
#ZuCykN3ZHrL8nOctnwnBD+hs4C/i7Wdv5Rr06lJOUebA7PaR4+J6IQvfNUHLLpYBCvTteFj4ujvltCtBIflXtLxK784jPeTlUOpDvx9XV+MlKP
#6QOP2q17Tx79TBsNqES1/JAtEGGCXl/Dn8YU1r/8vY0TdzXt5E+crCPmFxZT6Lx1d6MTQDFA1dgLI+yD3/9nIhXGw4CZ0ItCvS+w+mxNZrq5Ah
#2NS/2BAkU0VkJUka4J9+rmsSiCcURj3cN8FscRMQzpaF6QESIv+5z3vaUkzfQCIyMGwsnObVuSpV09yz8PlyD6QUVqCO7zECC3vL7GvzQIWhKb
#GCkMg/ZMGwd8WtX5UBOr4SBfqw+m8kUvC6rBjPD9vpeVmkpYYcdianbOzosrTC7baJ5KMNDA+s1TwkmEjmRGr6jkY+GwYE2F1l+UzXGhA3UT8f
#HoEFee4A5Jsz3GdXRqK62WVtyptuKKo26WV6a3Hn/+ea0EtIPkD0RGLG9dZOGf7+w5W/6jnj1jcEQ+eaYYCZVHz3mXE7priTJ4V8dbYtfXZ4ry
#ldPnDaMwlFssU3tjGKbbe9labWKGcgcTaqi4FtCgfLe2id42yO62AZiKvv+Tey4duZqIpUsYXdq6sNKRtvkhmBTBB4mb4hkAnm26uqQOEgCUwH
#1PUjtI7OmIp2zqpDhn0wZKBMf4BysfWKnd+eYhcAs+DxI7Efjm7kpgOCCxVkorx6aR+GKbqrCRIUIcce9JJIh1VZgjDwOqEBnQ9lcaQlGPBrSt
#JmKwlSwitgZGg95v41ik6vBSkKbGFMV5QNWmJQI0lluybRvTx33MsPTRfvhH70/iBxZ4oCpzJqlL+uiXthT1+pel9mTZneIm50aOLC3tVrICee
#uwlyfzqKdtUubWO2J75sdvTC+cBPJLSnb4+ZB+U97L0vi9ei4I9UOMrEjtMkY+7anhwlbRBZp1VF7X3RVyuHLdd1fxtMcLJqTAqbf+psJBjNU+
#XFIFOmu3iNrqiNEXaJm5asfChhSkpXykiYNKUXt4v4n/CfUw3+DY1A4n3lUvQGXB0o82NpLlPuXBIHUFgqMUXPsI66pmkEAczV05+2etc90cJQ
#mkb/GrJJ6EadBANgfZIxACsXyagdRp1hlRiJOgfYgQe6ScY233T652dscAQHQ/idMMVoB5hKjRlb7V/A1oqtlJdH/q/ebalitWnEzw8JE+TCrL
#SVDYaRKIPeSBOo+QZGA5R9wGeUKkLcOaC644mMrV7nyI5WlVkQikehuIBsjlIa8+CVCfInRddPa0q9yYksBL46nmzWQYW8knCRYBnjIW6KfCF5
#K3PS5Yr7RXkuDFWrdwVQXSpZwlW7kLdQJ8BTrey1KWc2nP74K9/bZOkyripdMtakP/nfRfFwfaQCYXThROwqyDTvmNbBRM8ThaelK6FnuJlF3u
#QAHtfT3wUJJv2ppUiR3sqdlJH+i66cJepYsGbry5nrYBWuFrRqh7tNT/Y6ID6VR+yFSuMBWaOsV/oCcc046UOoRxiPpu3Hpib4p03oOedxk9H9
#1TCHuLgDNg5DCQ3+v5EHeP58OXtVrRYQmenUoT8As8SLooHb52L+TG24XcbeMDYz8rGTjmuzdDd5vJVjw85+kTD23k9D9y46EycoyHXXiEO/G8
#DabNlOJ5cdzbXsG0J2voySkNikAtzm0pIQm9n/ZeBxHhBaBjuLjtB1GQBRQjjraUxWPIB8+cFfwj1EqtOLwHqot7FeahaRCZxZ2LMfYxFIqn7d
#SKsR2PG/0wRUrqu7K68F3wcF/5dnAWn3P4tl8w3dOywKRO338b8eI9ff+tWbO0t0pJ0TuUkJTKXflD0UB5CAi37Fcm+UB1liUeHmCF6NNL5y6D
#OPGDL6a9Eu1uDGjPqzKLRdN7YRjryabgs5feQl9OvWQrNTB3EgThJep7ZsFUnB/UvNx/TaCLaE/4cCavKdpOeHTcIGuKeoWq6NihBk/zqvCRoz
#/x40WQFJ4wr9VMUOOtlaP/l6h7ErPEcjaJVUn02t2pfLx9UC7SrfVdiMouUvmdkkekqvQLrenRtGp8oymXEk03B+bTKzxDgFd5l021AkeVdtSj
#Hhc46uWGcqOelgDVD9N2Mk0/PKv5qor0XMgT+sPwvFvwn+nqHkC7u7inlfvn5MabwktcuvBk0nUngOag98hfOvLqZ/b2MfBHVd+JMjcPhGSnvp
#Jfhq4/Um0fyj3P4U2nJ2uNwKuqA9FS0rWtEAr1HvQirQtZx5b6YXeLdCK0n0qZY9tpy2bv9Ct7hwaZeqVf3V6/v729ZVdT+cLRc4Van2WVfZaR
#IRghNUe0c5nlfTQsTRr9VT48hQzdojmGMFvSkpAZfO6NttGehBuzk5Q953X/XZgY5NMbnjtV80ud8glhsFftlxvqHNPVeJ7I58ltORMFoNLM+o
#DJ8r3mXy4uGYY8I6YGeH0gEmmO60MzP8Cr1Sdb/nqr3cTrXgzdMakdbJad4LkzmQvovnHbz/Ar7M78eB6BTJhKA+fYH4F2V4bWWHgJLH/ZK5i3
#dIII16cgYjTx4ifBFdo1alvR7aU1clIH6DHdc1vNZjfiH4l+NAX9cFob7YGw+lGr7Xhuek+ZkUVOqx7ZzgATRXXvntqJrLcclWhsTe36fn7/SR
#2fOAitoILr/NCsnQ2sJhRlPcA/B2KzG7QBPkzEMbCW99qHhwhsJGLCtO5vxKbRti2040QMpTGZzVGEm2hb7i/d/bbjbz2/9r3pwkOzQJ89Kl1f
#eFK6L0XvLOER+tai0LWEHO2+vj3+lRtOQFiAL/Qi8uxwPtOesP+GoP6v9j47ajXau7tw8bDVODi0l41+4l0+x/jb0Gin6Xx2r9FqHzpf4cXHh/
#Cg6bx0XgqBdCO1eKkh1i0J2B1TgNLrWTIJTUTnU/dRknhXjUEST6yVgLpotddkYm+tLjtNZwT/UviH4J6smxct0vu5Rbp7UDAwS9w+MI89GDtn
#iJe1Ft/06KbNN5Olq6gncYZOz3Ym09zpRTyKXGuyrE2m9l7b6UfuZFmfTNXZXPSw0bq+jo4an+xfX/fhrvnARtDhcMrwSWon2O1He1arToV7vd
#Rq34sQ6YMM70eqOGiR6yboZGoN6z17rx/ZH91XFvD0dohve/UEX9ba/A6eJPUhPTnokofq/WYNI0KRV6rWjEuYSRWtcGL30zP13a2Wg1Pvummf
#d+PGZc29hJ9RzR3dw4u0BmXgRVRzI7goHP+lSeZ+KtXq2D2C7EdNeaw7cy7Q8aJxWZ81LvPNjyRT6FRwjbbglw9b7TJ6rYg24nISZ9RyHzVGe4
#8al07ayofsk3Z+MnH4wHnUSDEJ+pbXHsBnRlrS+wda0jYkjWRSpjQamDb0ZavWfkAd6aRtN205UduNWpIWhTJFvsHwIdJoXPLzeORC1+1BNzj9
#fl636v94VB+1bAcKr5ee5ce//f6Re9Dc3cW+dLGJjba9gpbFoy40qPrTDx0YKKxWfno3am/59CYkjWRSSNgDhjRe5+eNK7/VIYbdcvDjobV+mx
#+0oUOgN2wMFyNSQCPuAzO97JyJFB83Heg9R7z++IFzcKDuHjxwgETP14VjSg05ZKVCKOSYZTJAkRQe5G7Q9TVhF6943anVuvm6oy1Lkvd7WMNr
#USgvyQwJiFlg4W6Eu7ucTatHCFmwqtVqXI0TMsY580CQBybAzuM0/SIJh+EUVvZpPL2axPOUHeUmoPDjFoqyg4OydlyXy5IV4YaRaHFxCcn3ar
#QPWos2Q4u75Y9SdRLu/42V6l2kdVx1gXjOgfX9oOxRjLu/BLmGnt+VobnY3/nrnz49QSxGnGEYSyody3hkGyCp8PokuLBmdmWYklllUAr9VJyD
#Vgk4X+FhIolAxk9YV1T6eBT4Y2viTedeVAj9cHPhkhznJGiL7GJrDehW+qER0EmEV/0kSFM0KE+LvVfeGSkWBfLgKEiEJTrmk9kUdhx27VuiJR
#ktQvSkuTcnSKM9H7/Q1KjqhlrQXSFNwx6030KiCBWIW4oOfPA4DZIFbhxSgBHj2C63f+ctRZEp1/G2MUmHpaQv55MeLB5vG4sgsY9yisntn3a4
#jN1dSTySjBUxSfBCwcXdOXWFCrxhze3GKE6zYqAaKluZpn6udavRD9NZPKUO6BjQLsRENswatRH0JCsE4gDdlGHtzFre6BqQxpvpayjD51ejmv
#lm+mb6AgZfZAoSA3XMLJh608w4FjBRxsIz0PUsSNA6djYPU7xNAuz4IGmA0Ikfm2+FKbPT4hiKwkBpUt9i5e0vtNOs2vLPK1nlsIWn77+FT8Xj
#lyFJrUIzqCTEHJBuGyESlxE6IVGJdDjRKUTU/Jy7jC3ZciDBvMuSoP/+24mXJAE3oQpD8P1fI+1XNNokzLcSSgJGZ3n/G7JF2uJ8U2KTObc4dX
#Nm4ZzkIr+8EEI/+1s7M/fVydOz0wZFLjy/voa7BsbTk9PZb7mzht+C1Rd/284l/FzC0gs/0VgwHpGbPC4oThvwzZZ7Ctm6kA1+291L9wwyYzkY
#qXTs+q21zKsWV7X4YW6+FEXIGyxHXF9iKeI6GmNhZ2cIEOa3MAYduuTiTRtj0PFNNDah2Xx9ibH6QJ4Td228a8m7fbxri7vE65vOKQIIkuc5P8
#Rgi/gUf8UTjLtIj/BCS5rS01Q80uyLz8YYkMQ9OikA8cBD/ZTz0+2jp/baMfWnasO9N6zHeEAIlfYItZbu7G4hBZ2MywR4o7+fxnWMSWk6O6cN
#Ck5ZeomBn+glXujvBst6Gg+o5MGSQm3gXSk3xbik7HRVekvn5PSWrkpv2cAZ39KVvsuycKtd33HzbqE2bLwFSDGLwuEBfAbFo0RjMguIkcPnmq
#/V2koesXwffzmbqaCk3kIAFuT4OCSPaSUiRJ1Zk/fI69D0gD32+BmWStYLqmKUvLKA4ITJgDrzejBEs5nppNmTEEikGDkgiS9dK3L6ju/4UQrS
#U9neJM3qGJnp7gpel81nskgYH0Vkd3R31T/+Rhl+9ZUll24wUchOJg9+0ZZChXUdYjxjaBk0CBpAbfzmYeT1gkgVcAnVE6KYgUeOBE3ij3vxUh
#jEjNGsZbyGPzk/OxufH5sGJUQ7OWgYQuMwLg4VTnZQom9kExxQPvBo0plzBymo0kK53dzrWLRWN5FJFuwEkSy+pkah78L67mquDGX0D0nQ9bX0
#FXw3x7s53E1CcvmDH7zxlnTjLeGGHVjvYPmaLdCsc3dlLeqQ3t6DxXZJV6g6rT+6A9+8zqNMRfKr40LXpzQjlHvTtNQ8tDtho6WzhTM9JzKKZ7
#TQ6A0qjQV6zcF4cNlyQO6uptArnLlkXMMJtTHqZVPX8qC5vmsOR2aFsSdSmPSS9DO896i1kWbRoyN9eb2ytam+HkrzF5xWLk8szdscpWXedUSX
#gVEcpiD/oPvu6P1vJoERzwkhIUDJMwuDacN0inPtki2dhN05sBcMoWHBiirswc7QqvO84iMh591VvopWoBNhlPq7K8YmCiVZaNBc+C5ff49N+P
#TQz5G6cLPL+KRJEF8c3NYREWYdEQrWERFtHRErV6ZDCLAtuF9oBQrrOP+21/Y32DiYing/XVfZ00o3HgfaF5kMQ1/TO54jvmKk0rgfDkKQQRGY
#UewFGxjzbcHdzyPy+783KDCs8fvflQfDn43L7AWFjJzs/ZY211BWyU3JZGNat5TQLpbQ3iyhfUcZmfHHZkM04RQCD1JZ9TY3urGgokZazwz3yc
#k9YNumeH8uXMyDKaaBBFYSTMjNPe8tB5ZJEECxQzPgUGnIjhkxxnhsyMGAGYoiAgbQjacYZPjlHIRn0EDQPA+KmKJH8gzleRDFsRTjixdPn9g4
#NwYR/Ck1TLYHRgfEMxHymsok+YhFFfOlKJSekXBivpIdcX6u9RzJI/D2p95wTt0BvQjNwkdP0GsiwQp7HvcP9B+30cDgo6QxevAShHS4gK9JPF
#i9Ta10IZuYPxK/z0LsKhAWENI7nQtD0bzcQmYWi8xH8MO+LRjFF22Hkjks6JB5+P7bKVXaMGDQZwGXloaskdNAY8wq7El8iD7x8wUrOtCRw/e/
#nQbFURossetC8qYk/V5WjdPHW4KCgtZz4dQLU3LASY1sjlKVY4y8KDYu5iEh1BNSPYxRCC/QEij055RoEaag0YGeMk8axpN4jgXmdIN64VyIoj
#S2FMgb66VBZEHQxGz5CCZDQoPFXkoSoK6QGjXDeG3eHHM3DdeApRMpvZ/EYYZk03QODhzTAOlZKwWlavMFKoKoJQcVAwvvTad90HT2HzRF9jLv
#HwwU78cBFLKneUqdpOHUAfUMg2lCL1/AmyG6e6nezIkQaW+E0eEF8Xm+Pw/CqEAlQoQF0oo4gECglQ16JHw9LjDwuAfUQd0cz4lwE7kt0tA7gj
#UR1WYvMaKQw0u/RpLDlhqSWJ19576elVUW85TcbngoxKRLqfda0HvYg+XOR/oSMWuxQtFmynIf7bw0rv6aLXHSUpcgBbDxNVL7xEsRhh8Ue/wR
#xZXZeTKkpRUITbnAQSmVdsNEf+y8Rl6AwuPs/be5m4tI8oLD8FY4/ogEn4dE1LqHjHhDTi+UVQbaxr6YeVcpanm82o+lIFUUewNf+BoISWnT2v
#/DJePTmwRiYcEt5eJtq3BpXoCElstEQ8b+BY5L4L4YTVzsdICqQ0OO8UWQRj7SyTy6SkKfHDW9JEbKxO2dEcz5MJUzZRYF4VTQpkYPgowpE5Fy
#TtQO1p5cZaOJtuBZqdzkenHy+MXzT+2GcQorGpT0QoKLpILCEgflBQe9vGFKw2UDLykRfJPv4ZYY0GnTOTRS4NEckUwRxhTIF3RGaA5Rs2hjcQ
#mAGYv+qIh98/4/Tak4lV+FwsBu+Ys5TkyY1chhcBsTWHwCEj18o9hUolAigV5AMdZIoWIO1qnYigSyNtRzmCfA2eEBheF0DIwSCj8qKi4xuUUI
#3RCnCFMzo1UbvfBgftJ9FE9xyW0UhLZXQO7cRM0d+0vamgJ6f/TquZoUDePzOJyKnoNMLqxu4v5iHmfelulekqQxYr0UpX05uYqSdDL0URbbsB
#/37Q2ROhkK7ULMw1vFVc0DgD7/ZYwr/msgFFp/wymsjF4kRQXoBtLx6dN4MlcoX6j2kwLIZ5HunfbBHYMEt1Ec9YPEvXMac6CWaTzRxE30pjhV
#DmLfFEZlFGcx9XQSD4jZAg/0+qS5oDwGk/f9t44xBP5Pe+nQWh+GHwbNS2i9Kg4FqGg0FvCL2xbzmdKNWDgPcdeD3BnUzgclTSbeguom0BfTzn
#cRCq197YGUg21BdiJRjohExySqwF2cEDUjVNz7b4cRVEccZD4lXJwwSG5scrDEFj9dIvQRtmMtniN8FohoE/W8onGfFw5HgAuKPewbNt6Bc4jj
#C+wcBfUpd78RG1A7gfHDeh8jVM9pBkba9rz4QrQuNqysLJDkHZEiU0JFF2YyrFwgyTv0efNZn0eeW8NjVdx21r/00dYjIRBMEK2pD6PoZwaFHq
#evQRFV9L9gWl8/l0cLjZ6XUWydbA5yfS8KkXPcNA34TKtE+TLM+Xc//7u9qhruGCnwmYgWP/cO7YttzBDtsEybJ8g08YyBGfZPQWRkZbO8vOG+
#bJxu7NhjOjoRIek8xVGLjCsCqqFuthLsMVwx8AREEQsfWxFn8EFX6dtFbvoYkyDTFDFsaXmlsRwHVzTpcFuJ8KD8CGHECpQKIyagoVJiFwP4KH
#JhlhsZdVpaqfWw1uLqVOGQD6snjFgAwr43T1NSEBYJkrIsHAiET4UEKJUkt3ja0/jCRGtNsZ2fFebzMH7/uwzb+HQwQF0VFuUqkU4s2VFFe0X1
#fpSoUvBqODL6w2LNJ3LK0LSYBHimPk+lwKFOW5CTx3SQrr4tQf8OzC84PFCCXkcFPJU6lqHoH9peVErhV1I8MDZt58pNe7l9p8ByQzmsiHgNQi
#/tAJuPiEUD3bGiDAoMPBMiNT5B0Q11FApCRU9mhIvxihYCUoPJLD7QhFQ06K/ckoJm3F0JobBqQwpeyB2pbesneTXp8Cdqd66rf7h7JUMfcG+l
#VYFiwqmMSpMWw9KkG3FpKCk8rgDB5e1wDQbXSshHM6kOijA24W0xJBNaaKvhzdiy1aZuyrqlwSe0JwlYmDJGH2a381sda5E2/GMs/FRuj56c5J
#H+SO/SlZ9cx9FUGaW0KB3lnJEZBc1VABETU2YgYkWnQbTV9H0sLK53gqhoSjt2g9wcd+yUt13x6xaYhFQaF9FxWKkxj+Gh0GA62nvaRTePa/CI
#mHpHXkgfjHJSe4WOHluCW1iLOrzl/XO88JbynmyVKACHODdY4BxNFl+btTF9abKwk+Kp0aJmad865+UFWoXqmLsQ7RvTR7bM62u+aitz28+2Hu
#t1P9skZiCuaVaOs8R0Ynf5txxp6bPKCSQK4vAecrdZ7Bh3b4KOTi8zbcr0ipGcdCR4zXdjpJ0GS0sn6gehlNjyPEsaTQjr4NKxtt6X+b5ppcEV
#gl+JEGhkCq1MurTIIgR5VTA7Khkb6S1FzXd3txh2bVUM2g6DrR5so7wFh1Xhgk9OyOFqbIt4BBowmDL//8FaTFnBMoouZpr3EeRVyaTKnudTuK
#x5+MhtcxrYF6wW4qBBXiVDeeX52bnzw5QyicmfbVioVRyzZAKCQua8qYmUXFGP17N57Sk8U0d0FXx2vVEGDJYkcv1pdwuhUcpny23+KVUVb1aa
#DHPHG/2pE7q6UtoPll+gI5uKJbMiSwiZQIUTzB9pdvRsc5O/IjQXKKswocRH3tBu6Z+QNxOGWfdQQMVJfk0vooXo0yjuWWc/Bn2nkZJdeji4sl
#47ZHrfts+dFfuO0m62TxLaHhq7mWs0Z95me+4BSUWNURIM3C9PXoi3rPmj0VQvwtf9+JKNGM2UNIF6qvRGsqczIQ1NE5QtiswQC02CRTzWCuX6
#bKeNDu7SzCdXRY1gKVF2N50bCHf5LimQDKjItW74V6CqbNNR/03JSE22le6MjGwLgVYNYqEoVPlsZUVIs6KcBDUJ4mGlCUiR1qDf8oZulI4Sfl
#VW5eJIdCe9H9lKoeDNKjwxaRmDfJXoXANGIZFLzcA90vxPBw32QO3QBbmhDoT3qd3NPbkKrUbFwC6APwolgZRtbXehz8c6tOtWrWtIbEgZZBUD
#rnKUefo8xijTr9vyBj9OXnvAEldrOcYV+JBqGRBUqWtM2HTU/NabHjcED6l/J+k4BDst1Zx800BTcuRXSdYtUdMQL284tVZr58nTZ85KMJsOwl
#7BA8l8ztfVfOc22r3pw9fkDpQTWlXoDFxOVCAJ0QBcMXQTmRx8UENBaFbVLGhHLLtiXn8vCPNiCDshjeSg5gWLxL5LDJQAxa0iujmvrf0caMrO
#Rmi+08yD6OrjS7slfCxJm7Cp0u/wqHweRPJQyKfD2Jxl0qDnbTOM124faNOHORe44hdnIjVHAKvZOv6VCmyGgXYYYYonpDwZKgGonZ1LYLnbKC
#1/T6xgG0FtGdyyb5mWQwBlbvL6HFFds9tcKrvNZ2KPK5zC2ELxpgyKyHxdkcmfRCDCGbFg1+/MK9fDgV1h1S9ljtv8u5xJ7o4BRZCvlwMX7OxV
#4f7Vaj/objp+FV2wVEn1CTorWao8vp847KUFReG/DTqQK58PqgT6a+FHmrSrvPd2FgxNp/Hg0O5WreJz+4PXygqvBGncizUZYQSEjZbWJvlToL
#PBnId5GHhlUOPCHoC94bqoDuLTSm+EwfKLKRWjdwFkKaAUDhBhmI/RdesmIaMunattBk5IVsI2syyhbzP1dchYt2TCe4wmMR1p+lv5uo2v2119
#0+DmGFG0+it03ATBcXlpfwQLVdhDjxNzFs8QCMB0TDYpN4XIJNQrP01PgQzxmHKQdczaEg1rYVLP4PqKruv1pAU3fqtm4nUbr9s3x2oKIpss9b
#GWUXz5iptgSS+Fr9lQ/zbdXTPJ/Yx1d+wzGBSxEVaUSrEyFWHqM6WlqyxrPH9vFjcX2SdYDj4xEKAlyy6FQkVoxQUwQbR5tqEj+drz23jzw8Fg
#YJ5v+jS2DvT4OsHWkcRDZeAjnhvutQ7u3W+0H+zXiiC4jUOn7+7fLz09bPO8D3QS6CEFfI+R7S/hhsr149Ty7Ht9+eJKvkiBs6kXmoEcUEF6Fn
#60fw5kQcwKnliHpUZ+TPHFusy9ticw+VNuIKgNJSRQg+08wFjX+rAKiKGVhnZC0Qz8il0cSit3Qv3CRqhf3jqSaQsbR/QQQ3SLi/LW0Q2VOq2P
#kSIlbBNvWGIYZ233m19J8rTYBEqgqX3RI3+dxIS11LgELTi+tK+vd0pssOhiF8Z2GCM8jI+xPskfHV/EvFBWFG6BUHCkQQQHUxYSg2kjTPMMU1
#DU4ZHaDil03CJEV2iodz6NuVhLpUUxEcThOM46OkyDA4JakOLJVafRvF8KDre5pfZDPzMIzXigbaylIyHPjjaM2NMcjAbknXJ7Z0nA7ZWtTUc2
#xwkSpw5jtAqGwT2DVVhs/MOdWYnHWImxqG7HeE8Ai1uQEc2aWcY7hPorMAyrgAKz6scKdV7Eh8EQPsCUrI8JLb2I2Gfqxw/55yOuvMsfTUUUW5
#lwE0sRYqpjw0jzGhHfRQV1OaqKwlJs7wPVXpPdELMwgtVDYJ7n3k9TfG7x2QKlsFfki4L7+vBzRT8Tvptcaaj1M4yhhxkET+UJrPYjZ6BgaFWu
#1wrGalPHQv9Ryq1OBratN8FW/A+H3GE60zizgIJtMw/2hW1A6Ar8BUEHFmD50aWjBdHcQHPGTvAQYQtYhbN08w28OkeJtvdEmGjnKn/5szpFjM
#Z3I4VOsO34AHvcspb1xqF9r9VGT5Bn4RJ0ojaMZz8YsmRTnXOJORuH9attOW+oFkfYWpJ/tMrYsvmoYmsebOpVdR65r3zTiMNSgUPOowHJFagO
#SsIRHp0RdMBw6eZRPEHGH1657WbTyZbucOmABj7EI71biQqSq8HqQi41OGsEpQO1cBEwMB92k6XmRxTHM54dO4rFjsJ+P5jaq+Gy5lrZsj5cgi
#DS6g6v8PaqPrziWxlkFO1YYdJMXJMuI5Bw9oGR1oYkdThwQSKH07TNdRIAN04zZdn7LCFgJmgEMFkg2PUPKGx3Nhb7DgX0ns0+4GPPfPciy32w
#x7yHUl0hpVeV8LBcudVQQd2bnf7KRJMC0VzZ3a0uVKN+Zexfrg5V/6ujB9AXG6OmyTiT8U/Dd0rGWdyiKCx0IXERvjM35dXD+7q8uj0yR0hBOU
#oiJgiMKN01DsryXeOT4hxNQbYkSbG9IQkiUAXMq67S9ur9IPKuOnVIXUxamvepCd9XCtKxVVogFDjUP2e4hkz71sLeiMGpm1KWNE7sr0EK+iZR
#jTNIT/EfIuRo680gpWO1ImBMj6b8IJUHW3IPS0P1+GPgZNoHN+HJVGC7tA/g/wKEYCW+CyejowwRVLTpDOFfD/5dumL/7EYUF4Exp2GzIJSLwy
#AuDsO3FIFaqt6P3UbrsGYRWouNaC/dpEaYMPfG3WFNQMLAda8mEGHg+rLmjtkTPNlzL7tD/NPDP9pHb2LGMJTMBm4MPa7EjmGf9Hwrsc+4XBOC
#Giriv8CDDQwYkSrHgeFEZSwY8XQTD2atw9J4mduPjquxaRB8x88/C9I6jf37dEzPbe8NNadLIl3XHKXoazlSEw3npmHWUr/w5COj3f7INlUxJT
#44QL+XLSXl7fFrraZzqK2vXPL+/Y+EhJP791e19Ictv71/0DS7W+r/4X5vf/CxZxZ1xEH6JfmtC3wSmpq4jOtWCcCZu/TC23gBk+LqRewhMJgG
#sC9neHdQofT5o6HUMwcFPXNQVj84ZQmqhNiMM3H3FuGbPevsr/bOa/abvb1GsAwIqJxsJpxR6E6OTWnoFzausnAyBOV+Atn2zNrkrAX6+h4QPS
#hXfUZ0bbydDc0OIYEodEXaB00T3xn0ZHBpuLtpc/UW0JTtsCn0XbJkVFCLuFcPQQza3R0oZDgswYJbHhj4OOSnie/Cv67Gd9dapVW4KeVaoURV
#Mtk0lIqnDtbrQHk/j5U2kW2gB1TSKHQIfwb+QH2j8BguOpSrIurzrNqsfxObLbr6PJi4q7UD5BdOQTWno+Lo6nl/6dbbcMFobdHVF4MB/eJWRC
#JTsWEHXHw6T0uOz9HVSxTfQNe3UgGFEr+IL6V7dh7k9eyvvPq7Zv2T9/++/v6/nNdEyFcFnJILlVePMZKvmF/IKz0X8eq58DyQbHqvDv9AdQj9
#u3thMaDsIljEGw8htRWjd0PoRdd8AerNm17jnkyag7iQyzdWm21We/bGenP2X3/+N+dnf/XGfnP+X3/+i3N4Jq7kZxUy/Lf/79fX51gN1kIDr7
#+vWQNYs980jq8H/DdAMsaNkTdp3jY9g4pjfFz5Tdfs9XF8LajjGoT5maHeevN+GF+P+tcH4y1fL2Mnp9tjJwtYmtxCQizbL1wmCAvjKNvOI3nr
#5XhWO4+ur+FP7hLwwt7d3XmR3z+ybdtzJ3lUaM6autVBmSWwT45Y5TlpB4hRjF4RXyq6ekXnfcUw3HmYrxzUK5oiqpeA/cPkpVjUBby5iRtNQS
#bA5WbvryzruPPm7E2/1oF/cH3W6JzDlX385twG5gtj1rhn391jFXtSiReHqwZ0QbvYBXnjshQbh2yZa8XNrL03ZxZW06G/ol66xpr3hrLF+bKT
#pWf758cCccdsNswaPYGVXw9P1BEJ4F3r3EZRIn8AolZtAN2N7c1jQWFmHfNt1sjqF41MmcHge0E57WO46fDGywb8THT1oyCztIHCoV27OYsAMU
#8SGIsZkjKJ352NzxX7F/caOuEceDtIy/0rDu0ZJCjMPplznDT7ePOZhf2i8v9YnEfPURtUZ8pFgKq5BjYVj4/5lcSdoo/ORRQN746XBwmFHrtH
#JfebWPreLBm6BHRl16wFUz/uB1+ePEfoCli9QP5fKGzKXVjje8CRXbXGRwmwhV5jGmR73gzWeIUz4+ohZ4bie35sYe6aCd1xbNYurBVblX9NZ8
#0eny7zTbpWseSHu7sgWkEnBf0XxJJsn2lqqJCy/FLQg6RUHwPTcpV6JU6h/jUf2DOeZJjSr5XYtu8mxQgOelvWf0QTLjqK0LSI9X961SWwQ1QK
#5slRE5ok5hGeNQlcUpTQLVDQBFVeg/pbhxs7l9+tq8231Mo8hY/cNU9E+fHP0cGh3ph1Ic6H5J2UufBBotGQyJYzDaNX6I5aeFfgw68z2j2iQx
#E6D1h4kSUED7urSyClbIi8ems+kJILL/2x02o3+T2bVWll8iO5typEpOvrHWIP8Iua+8Ypru/mLOLxPElgwmHVll0jKarWaB/KORW6JGk9bB7X
#Wx26lKcqRy5IqaJCUE4b2ZFvh26d8CUvR2EUYCTLhyKBikOhMoAO28geupCnVpNFgm5IVWgNZjlPE9RfscYRoYU+gvhEfWi+vrfzFvTTtw9fSc
#38Le7wvDp7e77F3vgt+ibY3S0pZh6keBgWrB1fneG3H4edpoy759lam7ZvD/7MEjog4/NyHjaXgxFghNt7jYO65Qll6TSe1eQ1v95r23R8aJuV
#a47Qz1ab+pkzRqzFUGpvJXBKFrvsFQnTMB6SxLu6zN2V0nSlrkdIaAU4vDEhUlKm3V1LkSaL4nZhjLFcSN7VtT9qS1cI7tLCe1vDSPbvSqWgqw
#1H7jlimjkVvRCcUi7TWvgTobDwKQNpTtSSQnt1ZYI784Wca6sP6BzZ+BddqYeX2/qCl8lIRP+aFeN73V1FjZRjF4pDpeAOoebgY3Rag19bxX2f
#lf1pPpBYm7zLsaGr08coboZ0qChZtzOXBiObBzszYQA+gz4rcSzZy4I/pUEwPo0tLWSf5B+1mRZcAGQ0IgGbo6MrOigEyfWzZ6naPa7et6DP8/
#wNTwlQnSFhuuEjUTXUlN3Zb9IJvbb38sUsmOqQQpmrfAqENbywFrvzAt0Cjb7JYJvkc8nO2Hd0GqItWQ4Qku/rdOV+a1WIdrUXWzCW8ZLQq/PR
#h+mYRNOQVvSWoO7PviodlWw1W8HwnuTzbpnpso7V2Z991ZjFafY5h+ThNui2p7JZ4sjiGUy/1E8C9nGqfmNthCuSx9SffeWyVUADNxUmwe5u4b
#ZxGfTQcrOwc/1Z2Mc4aBprkUxQm+Y571Nb4RWdLYmAAFSYkD6k1yn2UZFcHrNp9Eo2r5sPw59vFOQQqBIHqotFmbZ6FSzDG0Zg/QNuH1RTcWTH
#lfKBHYapZcU0oBlsU1SytNM0d3eJgcovxmFVtW8WmjeVjSfz07Cd7Z+jqhDdK04zB2kvm2rsi2crD92y8JzyiTy3nXnTHMoJYDNthigTaUZoRZ
#R488iSMvsl28G7Isii5hFA6cTDm5NSyinovKWUK2h38tJbME+Zki3xmlNjOKzbU9dbMj3HpSgsBvC8Jx7LhuSBNnwhgvIysS2GRDFkBcW4yL2y
#RKwLPq2vicP6vbZDJ/Q1eUAP0tNa9BWuLNRGcl10BWXyGqSMrKsUaWxH3y6uT0XL3L1Ws3mvz0vRWr3a5tpVzMt+Xt0fbBILiEfowKKbUuw9f/
#nqy9Pr06d/efro5Omj69dPXzx9fLrXyAIK+yHKzbwhHoLau7v5o6tZsJP7PBaspYIGy23m09T3ZoFZnjK698lm2gucOPbFKYvPxCYLOfIsF+b1
#tbr5CxM30oASsiQicXEHY7hlnrz2oowvWcSqiNAmqywsLXltA722Zx9UW2U1WP+x6ouOXNb1SjEJ9rWozDArC9qYmJtF5K2P9Na/+MDWb4j37q
#bEL22fWfLYeH2swHcINo+8vjvqGUHi0DM7Xx71WWoLhSR/sPmRQp7Tv9bRvxbxoleslbraw+PGYafeOMwlfqkJS+N82UizZlHuo+axWaPAbazj
#FixbjJJIUhpChBq7PCHgOZsZY/emlC+CgUwIPJFNZsqnHww11p8z2hfZQ0+nCAuAeCACqfwrklxSu3QmIgQBZcuiC5WjvnujBQZJmqO+NuNH/b
#KsmPX0k7h04c7IzG8xpEiKn8ZL907TaBqtNvx/hyNs35nG0wCRRpN4jFBTzM8fM9QhP63zIf6dVuNQPUJMSOAbaPYH/L7wGNUV+fzIrM3Q6A2a
#cKSpcJ8/+svnbrqwzIeEKgLNguZc0V9R14M7hjAZwMtkibXfv7N3BPL5ydPXlZn3IYHMfr9xkBdAN1zEIRTxcAYqCawQdz4/aLQNyPXT/Uetxo
#GB/6h3jMPGfbi7/9knpeetJlzuL/YbB6UXnxgfNx6M6qKF2mEGrLi+M8pdNPq3WL70NcsXH+5yrXKEhwpyX7e/1tXhyRhHHpF+yuHPe1OGrc16
#E4VNicGcCEVU4rDIANS+ewcj4t0R8GEyBPZGkXimI4vtqWJfIV7H+29BKM62lY7RtRWmLYLbo73MMAn7XaXEdpI4Q3Wo9QDBSu3v1ZaBasvreb
#jwbmlHsWR90B6LDvWrOnQkaxup2gQEx7ba0PHohtpORG1oYP0VXV9WVDxVtZ1AH89DHCazRpNAUXPbuD96QASIM666y3IyeETogGGC5eB03J5n
#qfI8o7gAFTXDfIF/0f3GAwP+ff4JTAy4f4HP4brcJnPDCAG+PZ25wM82DJ9nnPhxwWJqYHdPxANLueg4KKcGGKrP0QC2na9swSqlBdUL57FzQt
#w0ndnwXC8YnnSLZv0hIitlnwZAnIE16jvFt4MQJFfKSrXs7SF+EJ2YEm7NnuGJXkZwoH4870VBHWSGizkGXUDkLYlcyU3copLksiPJbdyLsGQ1
#SWaojlLnkGzs4JxyPKeRzocVimQ/8dDVRPbQZvX9XkQijqr9T6sPQUJFdV9tDPW0pKZsZA5F6L3NrJPbsnrLbVmXt2SVoAeQ+Xb9WPL4opJMWo
#fy+sfGdEzUnJt29ZfkPJ/QEzB9yzzGVa+DE3UtSW3qLcIhB6WY5cwXiC5l9pfPsct+4XQN7r8Y646DCxcencE/sfFebyk49J2dBch3CxKCEe4b
#xIjra3G/u8u/mi/tJqwF27bcRRbXKyuiSFCUHkspeTHNE6qsCxcNlHT75EmO7qddbCijHswTu6si4uYVDaoqoq8uG6/Tl8OI094RVrDIK8Ng3R
#y+c3FTZPBt0Trz5oxKzRGuqPL1pHLz9cOV6wlGZ2TtGXRmEZXxAYLyfvfvfmW8ysGteJul6L2IKFF/+Ntf/sKQ8GIThhdDJDJOv4kNgHm+++e/
#NSR4Hu1zSudg4/UszsLBlco8JcCEQt7/7R+MV7rRqvWs1bI5Q9VeF+X59b82/mIeZpmCm6tOL+br+TmTg34eR5SgCLHiRAkBtTR67Cpa2pZWkl
#RXDXP1OVV5Tqyd9iH59tnWpjmvgnGzngTBO/jcGmgT43AG0zv0HAaRwxGyK71L++8ek53b5x6RNGJ+vXvuNp3+u0eujHTZf/cXxA/k3Y9iniV8
#8gcpHx7s7kIidUINj2q1Lj5ht29str4/339noSzgEJBa6q7WmlqD2hW+rJmgxJWgQzi93KmGpjM4TqBOmIxXSYzIew2gwDhaBJQG5gGn0c558Z
#NFWgvPg50keGvzZouB38v8wlKP1GlqzzW//rr/DlTNWg16CsSUr83aExBBGxhAVYvAuX8fPbJlKCdlz+DNwkafxonMFkHdgW8VdjOGUbKgWDUa
#Df5mJ55nsF52TDTKmJmO70URMrKO39PwL1SUmHmDzQFoMqeEhqFCxWhmtdstsoEvhbNMeG9ksTMIp/kZmGZbDbqg4piQRjJLTE67hYWjlSwGaY
#nixQt3vjO/d95N/dyxFQinXu8ihVnSxhHjOZXPYlZYL/HWtxb28FM0gbRMQf/AXGB5m8XTPqLv4oqCmMPkHMsF5pXDiqkKQ4oCMm6QPaVdLFo8
#bYjVG1QreI5g4lwlovqRWSWSW8rk5vSxfanVV2aUwF38or3mjZ/BWJCe7wep8DS39YLI5TwnN00OHQVeSUr1xadLUAXuYLI91s5TpoNJhuFqha
#tk1GD7qWcgonlAEoOk/uzEdFZT1LhgFndMIOAZHnxgsJRwMp88Szya30/CYZilnRZTJmYmAw/JQK4S7HarzzaLbCvXdA7Ue6SZ6SPdVvPPbk5Z
#NiYUqtWpu6JA8x2TQtCbThoivHzHfE2/ILTNOubTVzD94MtDfPGYLhhGXwVVGZGhqViXR2yaPohiGNt0b/8+EKKEVWDbgBTN3Zt795vKDGt0DO
#zPGCFULI/uZCOaL8a9BgG3MxEXIiJyL4xBg5iNQkSazZcB49kJR2d7+jJn/dMYiEvv5ikOVhS+g1Xo5bMnei+evZk395vNOv7cH5D56HYT2jdW
#497xG1sk2rCs3TSqFXs8X7529/B8J7tOkHrn/HON1vDwQ1G+r7Hj4zTECAnXb3pPfvymdz1L4v7cF096oD3BMxy3IOECkuv+PL6GuuJr4J3Dyw
#RyJ9c0ztfoKMwlg3x0LVbSvXAjwOMl9KQVgcBDqCWFUIuKs5s1TFAzG5h4FkCvN+JkuHdJLH82msFyJlaD1xpvtlY8ZzomifamwzOGGb3pMOpO
#x7xnOkNUIDwQ+/PQ8DSZh2nC9x1sW42aSdvgCaygCtubOpbiSlB3ojkBfzeIU9xbBvYdKMBQXhROQmjCfdOBzgWSD5Zo1Jal1+F0EJuoutHjeR
#LBlFiGsFrFHbOF1zDWIXnoiHtREkV7SAIGBU7x3VrT6WXMPatolGgLC0Rn6hKpWtT3Gj4FYhO5RVwo6y2rSLu74qJBqWzGiWIjNc9Bq3+PNax6
#j3/tolUtGiJzBQX72Uy0ZMZxuIRpQ0P0z/W1uhSi0MMHTQz5WrKdxdMKlO6AK1pTaWG6D2pTllsXT6HJ0/w2s+G/3V2YI3zik1ck+SfyFQFgqy
#yMaSDypDzfHBg2eIjnpXOEOrZuo+BjUCvCvguiCnVm2LcdTLeWMZULVoEbhkqohYSxpeZNboTaE8NOkwvJlScX9qnyh+gVg19iZhkcV8uLB+uM
#bV5IXWoY8kdNB9aDIyqdcKWhnyjJXtr9zHCACwhUzK2VekYa4axKI5z9MRphRW+iMvaI2NSnV7jpayXepdboqcuLJz0m4tQNAqvisv7+72GVmc
#Ii8vvfVUTDlEamILALprPHTBLkgIvO1OHpDQu947mgUuL2BX4zRsHLDem9AjZSYBC/mC88jFNKANNaGwqmU4b2uZaHIG6egLCviJcpBDLEVw+k
#nEY+UVt70BKocPqg464FbSPQPkVpH0ElW7grYGqyJyS4nAjJZzroIAMslQ72HSyIpsowthZ2hVukp/UxFwkTMewLUW1BX+zyh3cXDRB84Ab+Im
#bz10uYv/ldLxzqtxOYwbDG4THAojEANRBL6X0NV3A/7ZGIw49oMVQDRgTrugsNYZTWGZ7IYggQ4GeK2K6rRQOEDrd3fc36QVUB64JD5hmIbw5U
#CQtCdC4+XuptoNbgXkMU9K2zUofUzD3ICITHRNc+BKrbTEKfkqpUGPGuKhmGqMUIdCpde22fqy6Helz4B5qnl81TWkznEZ5+QY5jC9/QcpPTO1
#nwLUGSArpY8trgeB1r2eBad3flFXcejhJeOCGlwSYD9xdXoBcugkSNXuGpDVmJBta23Tk713s1DYKpQn9WX8Ld4cLPlo/BN+WP0W25rSuQ4ICn
#pMHXaHfGgiLFTw5Q9vWSANq9kcLWjMpXEu7ZEj1T4X9VM6/N2pJQEJP+12iyQPvt8EkC/lbyWgHVhy/wAHOsRGY2olF9ssA2uQnBHlR9diLBof
#PP1vKKCexup+ii32Y5xwLVRVexoeo5sYU14YAhZ6LxdljM+GMZFCsxUBgV01G9z4V36O+fyrGwjiLD4sMfj3/RNx+rgXuma2ZZfE0MSySAhGOQ
#xNyT0zNPJwQMp8ramKJpmklQoJxcnj65ujLB835VkrAPCa5gKXOvEssrUC7iCKC7jac8DuABRUOCR/QrW8AxuFwQJcUlVsBXvIWfM4WhezRsKM
#GV7ewzUP+9BkMdYk6+ynPmS2eWCPHw+lpdPrSIZ3Mm1KttcuyhQiuGBdkmJS3yRFsQfpZoMpPuc52N1JBJViTu8yGTA07lu9DC78sG5VgREYad
#bLS27X/sSYhiId7Pc80YkcO9pA98E0o4gj/0Yd5m1INhaCR9GW6UyRIjjjYwzAE/pdVbhBfxVACeDXQjzFRct4+/eRhOhgZu86jsxRRQkOFFUO
#MdQ375nch7d3Xn6JtO6OMBmK/C1GzgJhVbtAVFCVv19deXo6tjjAkhJEaQrygnvbA7JgtTgVmzpHgBaufv/zOKdINJph7ijgUKIWSXo4IAVwWB
#EGMQ9SrGYKmBVy43VkrF0OSqsDlecrBI+IGOXWpjxYxK9PZS41dLnV/5toppwafcMj3z6urR9TeH0791/FA/3zqCxrbaSw+2Di3wv+LKjaGOik
#/EQGIYj7srYMzLasa8MZrriuFMsvRTkBv4RItUK3wkzv/wUrA3jCldghkLfGUFMvGSYTitI8xf62C2rAQfOxIUmW4BHhsmfWP0jqhbzHNLNSKn
#TAkQhuGs82jJ/qmblUNmi1rvrrK1VqMeZTgdzQeDKHgGQq7FKBqROivBd7xXjhDGcLPFoh/Py/CRFTnahmIROUaViqDI5SAzQunxdZchIUuIk0
#zoVbn8CA0d+LpbNi3Bh3eOvvtnf2OcBBmob7mZhtCTifHaKz/TTqYxU63QbZCmBx03O8JTQd7hRu7ij/DwkgwdOMJfx2CC5lLJxeXuirWi4/L0
#noF4J+bmhZwZC8V0H8vQVqmKkpeTrBZuTNNAxRZu4PXdQuO9UZHyPJjbikaxecCpj7/JsTzqhE/boQjvslmQxF6bNtVM8cEpk2lW8u4inc+h5x
#6dnD5/ffpUJBm1jvTPhalJ2jwSZKsUht3j6c8q4Q45VR0Xg5djGorSg/yb09lrYt4Cs+4b5ghKi9ySX71fG8RvtSdHrWOTloK1XuQmFt43iqYE
#i9zd3SFCraIvHKciUB8FzzRrEtHP0gD1NA8tArrJSyiOtI9mYSUyg6nIZl3eLFKM+AUZWX33b/5hm11U2BOZ0lEhEwUCi95/62UxFfGHv/3lz7
#eVMRT2ZN4gxh4O02dxFMWXksqPze9+/a8wJlc6D7F7/9v/+z8brykml5lHXNJ6dm9POzEQXdFDiE7R6ajZuy4QcIAhwPo23pvF0HlG1MephbOW
#bJhEeF1VKtChwjDMrW6paGl8j8EiXXpCMDRqR/SBBPCBWksB++6uMBMRA7xFw2wMaxqZcjLxVJAlVq2CPViKKTA8lLPBSLCbiY2ggSOk5SqYpl
#V90rIOKqVhxMDI8zDTu5qp2jMoWsUdvVnACnD9F4FZ7nzdi7zp+I6BWuudaYyaIBrOvZbRSrWjHEs0olHY6H92As14+tJc2w/3PDnEys5527g9
#mvtoi6GdGtHWHBom084cBXrk1bShjeKo5n7oKt1u4yp9d4VLp2V+qiriwIphvNZWWkGRIoDpLJ7NOQKqtr2JOxq4OXqMS5YglI7CWmo1He25fV
#NTVZNOy7Uh18SewmmWANPApPhrUdFyu31qO+zxIEgLCCmv+ajVrCApA4mpVyAs/himK/Fh5k8xujmFO4URpZtZNE83iGqj23irB8256LAy7zUv
#ci25E8SKqe7xr0l0FIaEJDoUeUsvxJEnWl4OP7C8HVUean6lF6o8DcUBjxksEPWdsZPZLPTfJBTKMczEiOXyHQl3QoGwFhj0GMrqYHly/FptOx
#+6vKKjVvvDRo4CKuO4UUTlwpidYqB2jwMUJ4Zl1vLia6Z9w0B2TDm7sCcsL3Kg+yJYLzFuH+9r2jV6lQ7p1espIoDx4TTF+Xz6SoGm7niRcsTf
#SYf5tVpK7Vvnhqy00L3BZJZdCdbBRCeZRmNDdhZtsWg7jmlFzM3b65ZmTVok5I1x3pDjsZ4KGZ5oTJcXRsKaDhbwkrGdNo2Pc5kb/jhNuyPOGv
#jbOaI02qXHUxEKQBSali34CgoAlKVSDuKy6aFEPuAIN91XjYH7iuPcqLh53liu92qnCJIgjMxKmNfwrfSPAXlgGpBIQKwENPNFfo7CK8SKc7gY
#oGOhwuVwsrUIQ0N/qSF0RbHrcD9N1KJJHqoG0Pk7JG7jlnKIvkUYktJ7/5+AYoRFs4hvSkEpRYNUMCqxSVMRMZO3SW/SZcT22D8VdYYZYZU2s0
#3rQD8v94w3K/VlTV/6oH+JCtHzSV9+hHCNQZQd2tQ8Hk0suqBHltzC5CnJurpjAG8XG57nkqV/Gsd4oMh7mdBwBWmF+wL2xrTa7JdZSVPqhUVF
#iTZWdFWpqCTxqQeoSYZPp6V79AA4pZaB4xUMbalGcZGImCBAEbYrUVyNxVvPaj8DDye+RMsRPpxQ/ERTsuRW+jYtCwqXXxlhMJ2kDlqOj1vsjf
#3ZsjsA6q+n4btA7GLQ+k8Mr6RKeVGIYmFpgzHf4q7aZpRvbU0Slk+EtnV3hdSlbe8IjQ6fVmlhHBe3rIXRFDv+ZkPhAhauFC6pVHf+aWlVuTpQ
#KeYVZbtv5JoqFwyKa3bj0sFgXfra0f2whUHuSKfz4TBIOSpM31Q2vn205pVOIMhgEnWYr3avISvFeUSXCrLfhKtTB/68dJv48zwLJhgJCa9fg7
#6BMD6KvY7CfvB6PrTsFbwtb0SNKJ5RV+XTAZu9ZMz5MOQX5q0KDAotytHnrR4hnmwLDooIQVyTrcMlYMQVrCjEryD2rz6JHuWtI/sHeqY229TX
#adwW26oBxxSoGfRAbTeRIwFwiQTZ4gnIFkGRJCrf4Zs7eRl3ioAuhb3+dOLR9svWrX5KkO8U00TSGcRs1KSNAG3PiPdT1iLKQG9jqx8DEGCp8s
#uwPR+4cY+lU1YVvGBLFOcC7UikDEE++moOn0lkE8q9AM+Vw3kmwFI8acGSDx7Scq2GM+pCRVYVFhLiWS+a4wHRVvsRkWxrdGNp+V2wX8Z5JLEM
#Lly9dg3+EJ2i5Uldm2YRNrWK8KROW6thItFtBdwZOh9mIPcPM8kRBjkYUATaMeUZ9HJ3t6Kt8O7ClpNJt90paHNMAjvofKQbV+UOCd3tXVmBYl
#Ckixy5hCljA7tsqohBInyVcAvIB/sJVlLpeC9YgcW/tZb90bSrGNW6CtyACvxy9iHF1Vu16e0FPqVYOLu7nIdit1aULKeB4HfrG3AX7JyUbu7+
#QezPUy3qYbEnK2kix0m9aQJjrfj+Vu9DaeZXEe4DVwI29LupO2p5gOiQ4y3eABJzq+PhDwdAYqr3qjz1AwzPmRjBcAiCOvldBsbh+39Lesrv/9
#7w3gVJFhu//51hxXMDYSyNn8TAUEK7Akbfe4fLrffuFL1csqtTbY2lB7qt4QcFCRPwTNqsoXIK00YEEhMvtFBrExfdtv7FX5sO/vwD/Hz369/Q
#zb/8NT/7f/DZf/wbuvntt/zqv/Cr/5N+fvkfquKAfdzkuAqa5cBtwcC6hZhe/mCJQb10/PFgchZ+FEjU3nMZCKw67lfpCAwjmdTMxWW3Xk/xba
#scWKz9gAIxcBgwCtXQOCgnadzfDOuAocSsYmUU4KXdbOYFJlsSfSIS9YPhRgCIzU/YqP5PCyB2X/q+5ItO7xZYgZ4+QrOeh+KR2e3pctLTfK6I
#7R9jR8gVnz89efzcePLdz3/15enzF89fPz0xXn/x8ouTRyhdPPqfnp6cfiHlCPPmSHu9je/q5d91cCC+Sy6MKGG/A5a2zfFRI16MaDF+eNAdA+
#2WnYskpGyxWRzVgqCHHk2vPgR9yBnf2z8ULdTFCOYHwOXot+zblMf2E7PYuX9YGdgPW1EM7EiR/H44GOz3H7Q4dF8AY49X7XZ/PwjwyntweDj4
#GK+azeD+x/dvCPHXbn/vEH/t9vYQf4fN0tNPmn9yiD/yBUHviQFOlu67Otnydz7Z/7ME//PlYlkIAlhmKA/KQQCrE/xpc/gTEQRQkvjW5U8Jrk
#KaFhm6XsVyno48ROnioA1eIWiDV1b9ZNoyMcMCB4W/2yBjXv5aGLwQXr9UuK/43HX3bbFp+Fg4Rnz3878z/vC3v/i52r6GdEfuob2icrpixZRb
#jbiS4V6jlyreEwVonZGg/yrwHbFS71BUjDws1U9gfkgJzylfkRhZcU0QP44ODHTDC9yq92AyEY8JKXrKLYLx98b22pCSxwyWJGgVerd1zA8KJr
#YdetaFRo0hyU/OxuH58TistToW3zfPj1udpuz+MWrfP1F6M33KxiD89lvjcS4ESdwo6nVECSTpyi3/Z3z+xenTL0+MJ0+Nk6ePv/j880cvnzw6
#ff7Fy9cVadWexpNHP3Mf3D8IDpU90ZhcFckbR/g8TG3N28xg9zOZnEKqcxBduuSf6+uV11mtnQz/DPDPtNNUbnz9wPeuENfcihtkaHmP5vUsvr
#SAoVm5028dEnjZ9XX+xLb3rP3mPWi1rZogz+qx3Ts7xQj2Z94Ymq+5WJ+6wNspOskH21IOesKK8vublJvkjiWEYQPDa3vzpdE3ZYD7joG7OPMk
#MDimtWGBLuUY8jUe5UXvf5PJ5+k4nBmJN6OU9RYIQIYmGPszjtchUQWFW7G2uE1mj6zM6dsr7cAD2BA7tIyLgAzyoMSJ3VcN72x8fn1t8YW7Sj
#tNPscQBIJlOF7WyccJPhvG1qWRtmK71u/iSLp5gu6rxrRW05Ze+OJp9grktgL0smpF2BfAy9Se7Czsc4PoCo2yYR7DMEJL0Ny1EToL+LtAsnOA
#32ZAfTQDY6y1i0f8aaE1CFPcWNhxY+HCL9+GcBtiBJeu7LmWJhWNlYcczP4UW0KljOXSdoRCFNwVbP6xvcvzxvReK2jt18QdtgVIHe+uCu+uxL
#vcl5fCCcptvrF7pE6lMjykop0OPuLRhRraTmYXV+haoJJVVhwsB1Z76Kf+PIG/NA5Bv8OByoIk4at1uUBCivORmCSY/UyfqHV/BgOOUXiaRWhE
#/wjeQIU2/7g+Y0HCHZqI91VggFlDtGR3l1Me5aGo2sAlOMP19SeffAJy0IGNXyazCBd5RVHwJiuH+u3TG631JdgT158BjS9cMZu6YnZ1S7OLv0
#lWTCaIPjYMWs2Nprt7GDp9xWTkN4iQeKDW+o4EVLe7u+PjCdburt6V0JNH2JOiUOhVvTBiBLK8PEaQMQPpIwVmm+ZIFh2jF/aiMM5G73+DOnhN
#sprUsPrBJKwvwsDYbxpvbXilciGMTZhKVpP77pJglur69iSHvHDUSWsuNPX7LvkrOpcwn23NgwW5tHRR3BlfX+9Yl0fNEkJM7E4YcQJ9TscF/k
#N5nUug3rCP60zcuKy5lxQVqo+TuO+G/e5EoDXE7O2PQKp9xJVgHwE5qTKQsEAsQz6yzybzsKIJRJVUj++KIz3DohFaEssyywS0WndnFcVvMF8f
#earlE4sFXZa21/HuofvAlm1pYVhHao71Gg0+QOwRe4qb7QZqoJRFB17g3XnqmFPH7CwluXR1Nl5IVdYBZx1w1gfOAPqggACCxxQTmd0+L/gG9x
#qXda9xaVc4YMqDNyaQMVD+VE5OvhHF040uoxVpRyZrbpytY0EY8JqeyGTywL3snWnd5J5ZoDreGN7PHT+K3mODCJa9pRSollWClO7/g0FDpn3c
#IsaMIGZQJUBjdDtGmcJKQKQEEYSe4LXwG1QuzXlScVV6ledBz2eZRtoGHuPrjsLvN1QXud4xbvV3ml1lRlDowoLvqByFtQLBiMLe63AojvMKU0
#+euO+ZNX2uJUF/Dv0ElDNDtac2K6Z3cNsHsuiLcEH0Uzvbkh9SO5K5QMoBvvb+WxD93/+GrNQQPFQB/XSMYeJl8zBzjKZxMY8zz/hZPD+d94KC
#wIWGVzm6uYO3XwHVyKWhROC9OSijJ5DGgqnkB5K4ZSFFR7xNAejEpYkft52vXMV5xfrzVX4uUi6FALewvt3dk8KicoLL8+E9RMgI9nd3QRyrWy
#cNwhN52GpD6gaMGIaeoHGz7I2S1dfLsBIlZ7aJt/zK/Qpp7bLkTtlP5fzSvFPhI6SU84CtIrj/LhXHhNnMuRSruGQmdIksSJJj2D9GdB9cYdYc
#YsnOvSaV1YVy7tfiklHLShF5NGgeGQcnSjdday3Oi61OQSrTvWLTRqVfbBsEUnb1peOg/JAoR4SHO7vAHoj1KVfUr6g66J7LBkx2B1vwHHpWvi
#60KCUm7fjetK+BUrFNEKVTR8cpnbziV2I4GvXYc97K4w6uh9xHPSo2F+/0kLRYF63XlAgVQif1YYUeQK91zs7XXb+R+jXXShuXGFfyK/ue1aq/
#3bNk1YIrtG0MXouZGDkqFfZZVHwqind8e13sKhgTFxciSlZei1gYv4L660v4Y0ObgnTkQh5JJz5oktTb/Jkg6DY8yTILYdri2RcDEC5KY77hU/
#3gQwa7SGa4xKvBLC36knr3mzxTMhrdESxUfZUFv57zOHBVYrkyU7FSPGMqezqL7/TGARuQDnrO1InHufAmQuflCB9LRPgQ5heYxSahWAv55k7t
#XhJ4YxmoxgWtnJVyZyyj60AObI1wUgaBMB7jkqbgPuilcFRWoepAxs8DzCFuD37A3h6CVvnz2ftvE0+eEsFQv/9NFOjrtDd55fJcyIGT5PShYb
#bEJIIOeuUSxZQZli9TIrVIqUidDAR+uYJ9EceN55zOTtT8Y3L0gBw3553GxKQbJVdPr5nesgQ3OjBAG7JBu0Rj0St3k4mVSt3Cz0pwAIc6O7OW
#JQd+L8JWABl6kfP1116HJzEx5hvY3SAutW+LZKpZHlNtg1KLSUItxyYqVnUGw+9MLx0YJARPeBQ5UHkFhIJ1pt8gzYCeoz1B2ig+wWG3scxXWO
#QrnHD6YjgKokWQulJmBGJt2cbn4RJRzd/GBLvR2ttHeySoLIzCIHGMNj+YxvNF4M2LNHwKwsekgTIdsngYfiItnL54TQOMdEXL5j5Mt6Md5hES
#DaDQK/A1p+70cmtxNAmwOE8vkNhQZXmTcIlfKhrbdiWTwHbDvMofYMUiJ0MhDtrKXXvaVpunqDKrOyicuQA8EuCIbKtxa4rBZopBnmIt5QN8KT
#nYfVuMnIiRCWKxCe9NgQdgaiNocnDEtIP5NcYtoTtgyNs2goP6gYEqeTbPdfLvfv53RQ7y2oU/zDQIboo5h7US1VaXAnO2MO6iPVyAGtyhGNch
#rBHO8KYhVV/Rxq8omrUURHTsJ+FoBE1XwgS6GsuUasjlA9UvaMMAuTCM7GZf95omrmoigdaV+7bxkudF9v5b3PwwMn3/w3potA7QnyC1tY6NRE
#hqlI713efWwT2x19zI4uevv5CIgNp2nO3057PqNVPgZDyKqIutsjNH7gzMPhz5/RHI3JPyw4d5C29ojV2ScPQSbgQXUQBXVfgiywYwbUISuQFp
#hLbx5rNKWBF8XoUqkjf9IB91RBAR83Fz4KETTAdtigUIR6qm3A3DbjpkWtiBkjVSObCN0wJt8DaXXVDeXWDaZeVBtXRwQ0Mhn2oo1ZC39LSiaQ
#O9ZYe2oZw03v97RDKHmbxIwkRrGgLslaSQ1oESQ2ixBSnEISyBDgvQNFPy1mMJaqIeVHwCJtj2DdXtk1+DObXvuW8bMDCoZv/+7zVO9/vf5bxB
#BXZWGseSWFvF1AcqDPE0BL5wSd+TK3Ai8VYVTmjQ7qq4/T3tgPbrgKLbkcquI4pal/Y6pKq7EbaX98jxpD+cwrKPYGr63kC+DZIENGi4D0B7Id
#qugIjzo1n+XvUCeqV2qbXgMmng47vi5vqO+MLdXbVFoIYYHu6ozYaV2qygTxIQHkUMNonkYRjlRrKk548Uj7h0ZXnd0i4IOin5sGxf2puI5DmK
#lR4HrVjAuniWgdT4GsYGpHHZKSnD20CpaByvwOPwxpIxu83cZclEDLWa/qBbLkcSu63ALsr+VNiCaogEtglOc5CID0VKALmaDK/X23y9tPYJ77
#F/hOaJVv0PiJA/L0QIp4JVlRbSNZpvVeKG3ID/UU0nou9Ns6sdBCXwgTGHI8gCZMUx2skhC+5In2DNE2JGgDQK9dx2aC0dxu9/l6VGL45TWmLF
#Nmhpj7P/7jU5FSZW5ky1c6HNrTt17Kz24nWHMpSdrEr0vi1bacXNd8GUxmqvK+eGYs/s7LIxdi4bl+e2jnsaokSK8odQp1FzTjsFo6OadTmWm0
#JyS+i48XGHReHS/hJuL+VCzscKzW6JH58fiyUZaIAr6RuonamvcZGjVmmfBTp+1Q4kIb2Idhf6zGts345KlKOMbqheqZVXgOHhFhOFJcNmbtmi
#AqH0XNuj4t0ix59meDymWcYlbrObINx9vlH0cNpNajW7aDuHX68srQtpy9ayS0QaRK3nLGF/h2W+fSR6MhFbT9h3Uj1Sm1BA+WOPDukSMVzMhn
#PsvOtrCz7kbOzRwR2ssHkFOpCeSOPqiWstbdsqsTVQVXhccTrGvrrJaYwTy4VOXW2BE9XnH3618r929+V6kVSCuYoafnbKWTX2EU97MSxRwCPR
#eHsEylPIUC+KZWhnIpCYYPPIEgVufuSS2zbBL/vBF9OeOCyBV6/H4Sy/I2EJ+JbYVYTXwAO0vWp+/sXLT3/krrDETtN5hWBF+23nxIPf1n3nJP
#bHndZh23n/12hWk8TwdN8xT3Y/NTut+4d6oARk+tAY/ex66GJzsc9ka1x3KMUr+WioBW8Jp27Ee+J6Bu1T4M1wx6VitXIYVfBGkYtsd2EOo5Mr
#TmH86rPhOW67STlczOT9pjaVoUXbpjG+OiNmpwlT0Bg0OdY7YTpwbz9QY1HTkiMK02BHDOfu7nTwcH9T+nx4YEuVUA8gvon/I+WUJ2Fan8bz1M
#j3M7xwUkSemslMUPkMoVKQMoEq5wwYYOzrdg8cqsRIv/v5rwIg9iDJGIgDFkTE3I7hCZ0JTsIlOfzj9VRTKdFTAeqfJ4jXMSuu6aNwRqu63nM4
#ZAqosCwKYY67K8QYQdo4NmEkGGCFZZt4KEWLIYk0wrNUPLjBQ2xdxPaRxObSbLRXiui7N0qOSBf4OTg6VQAFOSaNgqDRpBARt35HVF5Sxv64Gr
#e4fmssqGF8mYURrIXow5m7btIQp4TTY8yljQEWQpj9qYDCamzKadCgwZ1tGEHwcnnniGOwlT1fK8Wx7/nVAmdD9qDabjuwb4RLxPJCygasMz8n
#APJKg6hAX8CFPwxNUXeIJG/+X/8rSX7/NIEWt0+KW0eXMc7E+MbjO6on0Z384T50Yz9MEVu7T3159FOy2ExuA5RiYnmF8BAZrKJ5cupbkcIX4y
#2rWxvp+28jppnp+28L7zYQvioor8jkH81mUcEtqgCCsdqEoUBDSa5QbscAzRGSRS71MqSFpyAtPB3SopCO6MzWCiU7d4wDXBAJulIkoB0JuVVD
#NnfSqFEhrX/367+jzTuhlaSIeYG4C0OYLwmwa9OWFgr5HocCN9X2VUjMqbamfvb8xVPjifno9PTpy9OnRs14/OL5Y+PJyRfPT6vtqV+xLOxq4R
#j3jfuj1j78tNri98Howeetj43WweLj6LC+3zh8hzEZpXRzoQNNozRFkaCFjHTxJPGGRZ/yC0w5mNpKCqQWNEjfcy5cJZ+fdwdT68LuXvArN+ly
#Uy+6Fye8H2XpnuBog/MSI+9mauOJC5ZnMBfhQ5BAlSP+Ge42Zutzp7npheu7/JI+x8vcixBEXz7U8bKHerG7uxcsWHOkYy8DccXL2L+BPvTCPb
#qg/Rwf8zpNxwd55oLFbF9Zz3/3v/xHxr3PGhkh3+Ni7xnRHAiEUcSKQhDV9ghN5/6MH5u3l8PjVTb0f/2/jEdvYxQvcBeVcBlxgUMviwzd9TZc
#unFY4sv/Tg0VHYvjI7pWlcQ6Hr4pdd2P55MZepireNXhuV3KFeqEBdRGDjKcBT0hLsLr6x2VVwjJslEr1aoQLWYxy8OL0L4I6/V1odjPsVDc4n
#aymIrG64dUeBbzLz45cvUO26iNuuZsee6qaqnIFs4b8SCLj/DZcRbXW50sho5a2sWmPGbeRl2C47H1k6g714oanpXG3liE/fffolOw5A2wliJE
#atYINxdWcuPdvpaahYX8Alab7371W7F6mN3C+AhuoEe+uAiP3OYxG197SxBE9F6sw2i0bFDGeuS33/P6Q+HN1Cu4nk6PPvnk2Pzkk5rZmXarkC
#nIBdrZmSpff2R9NrRIQlIX6Yifai56c8H9MES6M5+JVnNT07zHBRg9Q1Oacu8X41cScJYmJFxEUvR+St4JSVpcb/WkITVAx6O4YEAKHDUqvSDg
#XRBIi5BgMK5mJuEjckkfH3t2aY1XcY0vggsZylhJ/Ns/4P3PhRAsSxP1zGcS+khdacBH6lkB9qjYIllxoSS193Mo7JOszBnbJXRf6DPoL1jShi
#hTuXdwjS52YK1VYyg4sS5kIMpqPdCP841YyUdnHuJehdw1Al6ZhiC7YQCyqu7PNjtfz+/l4iOj4nrwBfGsDJRDCw6i7PzfG2KiypbkoaBPggzy
#JShn/+sNxYIBc5RYS/tRnQKqyoVQl05CUHFhSRGKDylBwF0mMflHPuwlR49hhKDz45ChwhTm2nf/7F/i4qm3HlZQHaFSRJrjya5H1enKJzoW3E
#Yq96o4kU959se8WcziDoVUVtCoxzv0tBNPBbTbxWxreE/mGV2ZKA2yR1mWhNCRAW6Ihl4duEwfgxqJw3Mum+OGXvSy6W0lb2VNeX4dhEh+Hpe/
#3PJWHPxhEj9KtES8mDASRe8m39RAd00FebcCFwKmmyk23LOio0Lo1sIsh4NwqmAlzgS1nis30h4tcTmMBFCy65rJxLTzRZ5CN4rVORTyQy6J4H
#K+gxKALeUIxt0AaXwImjxIbXWM4U07M0TCINjHST9G8sr9Fy8+95Jx6ooQt9RNFfhIceY0Ynyn2aAsKxx3Y3Q1xYT2Tb2OXCtFfyodjeP2br++
#DrNKkBZg9TnYBIv5hSHpcjCV08SbpoMgaQSDAXzbI/R5DPquiU03u7gZXEoHmZ/AvWXiQrxHEeQU5VM1Cnpmaa/WhcaRa3IelfzmvsDzOeVzSw
#Xngk8FCAkPmSUBf27qOEEm2e7uzk19t7tb6C+kKvo8pReF24M2b3w2es3j+589LCMPHCN9dIg+1rf1Cp62fHCP3N4RHC22IL9+aOd8SC84JSYA
#Uql7Qz+EHZjLuTaBIjH3eFcpqWqQi8J5V3HN28kKEgq3+81Sb5jrTLW3zXROZUv3XAzdjcA0laui7vRGVmqfY6DvzFk6Vw6FAHTPzjVRNBq7Yf
#pibDEYKQUFx5RntGKfmd/9m3/gBXZCER2n3lTAYuX63bkj04Iyqy/GWkLWz/OUUpsE5rhFm6S8mror80bjY/O7X/0HQ0gftPUdhWPcRkGkx/9d
#lYu+y+IFjwuvkC9CNAclLqck8N1dPENTt+jBxJbdNprc5M9zLFL1JQitrn2JHtIcQSGpZiAYbQxQdMx74g9/+4v/wyDc4Ag/XgRRURHXC0H+UM
#oTGUEfprE81047Jzk0R4HQgMpwWBWDmuRzbLKd0eBhHAeFP2IZiaZT/YE9EbAcGB1NqVkPHD2RnHx1gXkhICv8rFosiClUKLVRCgfEQfhYTtKs
#DvFSwXmSzjTOrEY6tk3b8atS+F7S1xKJ3khkbwBTSXSeQrG0BPpcfvaFaI+iRRxdPqdDJGM59oLkGCtc2xUQe4ObUSDX5+e6c62PzrOyMemODr
#6/ksbYLjDM12z5dVbTUp9D29PR7m46UsGl1KWeMDyXpx/ZDdxeZyGSyf6luvoZD48GQtb74DH+8wiAmSs3ZLqFT8HO/P5fwzLeceXYIosSbEkJ
#jefnHfKFEV/fA37xYd8vvUkUc+n+iQNRRyg+bMbtQCMbWHLVfIMXKGYdaoGauEcThUezpT7Wn7TqeHh3d7WBFitc1TNNJODKZaf88c1kptstA7
#2BxD7xEly8S8htMJTjAek26bw3QRKFT9kqCo1Rv4QuLcNAog+vvcIp/5PgCm0rejFwHwoEDxmSAAi4DPuNUz+eDsJkYpmPRx4FZM48WOvff2s8
#evXcOEYJSZaI/rhoJo1LPZpixV5flb6dEnMlTAgAVfMvmvL0i+yNVShSk8+bSrmoF0RlFFwdIx3dP7JwEPrCpamg4ptchLeAUnV9Mm8h8nvgdc
#Aqs1Nu6LZVi8QXtSi1mk7SSGghah80bUcuaLUHDk7wf/crg4Jvv/8NGpXla+5rYbRqwWKLC/Qvf2HIoZjkQ8HptXGkVnOe7/75bw08BU5QKtBF
#AuP1DDviSmWehpOZlvfc1s0+mFyQVXp4Jpa3Sxo1/OTpzwiDGBowL+4zlLBWCad4thlSSrzO1dzKwvSkFSWVcV3Z8Ag1zkBay3XFrfK+nYx/Gr
#5TE+iDgA8FqCGFDTY3QLJyvDSRwGm3C7hw6XbgMj8JZ0iGaQM3qVUc7MvLy8YVlD/vAfnFk71wAMQSfO3NQjNnRXgcXsDvSiWo/yKOFCqtZgkN
#j7vqLUtS8O4VqGAB4iqZ9TroYsX0NfMjU5cZ8kjT0NFa0vms/2iexbu7xWdfJlEZ3A6ePh4FQHK8m+McSmzAUjp1gPlLaZKyaBsdA834UNp9Kz
#Y65mkaBgj4hHiwDFIXYq9jI5ErIYuWoYKBpuHpwz3u9SO4Qgg0/B1lk+joB/8/mLpPukqCAgA=
