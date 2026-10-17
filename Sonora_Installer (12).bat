@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); $m='#PS'+'BEGIN'; $c=$t.Substring($t.IndexOf($m)+$m.Length); & ([scriptblock]::Create($c)) $f '%~1'"
exit /b
::SONORA_VERSION=4
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
#H4sIAIKv02oC/8S925LjRpYg+J5fAUUqk4QSRODCO5ORLaVULfUoSypllqZqs7K7QBAkoQAJJgAyIsSkWT+t7dg+rNnO2ti22ZjN7sP0tHpt1/
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
#ES84ShGcSZNQE0SNFUHGPruBMFMp2Nits0vXBozPyFHhpi5vfy8CTEN2nUZzGMOgiPf+zWk0QpL8WQ6d05evHs0ZfPnr481beLitsQuFVUzvUH
#7UhURPQpArl6FAVla9CH2R3eJbsl3ESqOlKI7DBb84AWv//Vz799p2AdM//GAYGC/u6/aaRfVHzySbARDEObC1OMOEeT4a9u/aq+yvdyPpvBmo
#AZf/+rf/szfRrJXs57luIRAI/GISNeTceYfNCkncLzVlxZmNCOQ3d3Nw5CVba04oBVP0nl8zaSqKuO2zR7okIVW7dr9LJp30NYu9BBKajA4ve2
#vRjQsby5AWMAGpPExNlQnPi5Kx9UbQIxM5LtEFzGn2gbXu9+VkPaljrJ5CDttQfO2ZmJ5GZwHBtGvSbw7FwxBH7CZfPJ0yziTsbzNVBvz9E/zv
#cyqzQ9j6nkv/ovxgtB12hf18LwCjibhZrrLz6GTjvFfMB5zs87aMOkymMWdIaa698aJ8EESkkCfaroMC6qRLSknKEsxsXZ65ycfG3ooB/pa/xe
#6aE+5n0x5v0KOoRmDsJkYplq1rDxGY8r2Z8Zx5B/pa0KVVsbuEbA9M63AYuLAo++Ugjz5Yd3TVebCwS+wAs2gqrIyau8zMtkxnjglp9tzYQutK
#U8+KiQZXXLckUYNyLYFF0Kfn13BW1KP4xioimEYeelgqtH5gRSqoLBoHUHcfPLbIiSC8npOB0HEWmgdidnT2yoWuRPGsDGBqaYY76IZ/g0xu00
#U4CICfQw+CthwxDIQyKEKfSw83wHcUgS5kpYg3+PbURt3xN7zIRHBROlHz0lPwZxJoDodSzo1LD7hoxmRw9KW5DhMZvsW0Nl9ewM7Q7SjkWHzj
#Q+QPZVG5OoWyiDQU18Aspd2DQK7qKCkXXpbJKLF9H0UCP0kziKTuOZ22TVUxwHyNbiLWNdpaMgWgS4teOIy0eZ23SA/73M30zC5WMBY9V/LEAq
#BHzck+cnT166Z99viHkotw21wl8RAKCuB6PskVmyd65tNXnKMK8bHjW7Yb0uN5u+cbeb9KG5ot09887Cc8c7++b83D3DHwcfnMttGU/fnveiSP
#SFLsTGc4T8Uj6puV+wRJQid2HdjlSsgZBRbI7SJERAGV9YRSdvvvMDDGubKZQLWcTa3lZVLPgHGZz48RegfO/u7lC+uK3VNg4RGhZnMBTONb/Q
#zJtRWcHoySXXPVyy1rmJqih2d1dcNATR2KV7NUuBE6smiM0j2YMvTiVgB6nOqQWL/QC9fXWT22VjeuS2y04a07rXmF5f9xpANBlc44+tG+NKTw
#vk+ksy9F02PCeEv6GzgL+LtZ1/1ItTKf66B5vDc5pHfooouvQ8FSevOhrJi9N14ePiqO+WINXER+XuOrErv/iM98+VB/NOfH2dH4XVY/rAo3br
#3kePvtRGAypRLT9kE1iYoNfX8KcxhfUvf2/jxF1NO/kTJ+uI+YXFFDpv3d3oBNAEcS/ECyPsg9/9VyIVBmSBmdCLQr0vsPpsTXbi+Y5JNC71Bw
#pv0VgJrEW6JuC1m8eiiAYTjXWIg1kcR8QwJNJBQUaIvOxTPuiQ8hXTC4yMGAgnAyFHkqVdPcs/DZcgZkNFagju8xAgt7y+xr80CFoSmxgpDIP2
#TBsHfFrV+VAT77uAUqQ+mMoXvSyoBjMKQa/YVAKrOxZTEwW4wgqTyzaaqxwMNLB+85SAOqEjmdErKnlfeMxYU7HNU9SDcKG7uwpR1aWTfXmsP6
#StjGNcR6fqgJ5X3Km24gr7B5ZXpreed/9p7Ug064J3hOYs71Vl4Z1c2/86L08YJqzvfI2f/r/CNCFb/pOaJmAUUDZMoJAelZYJ+QARGHGJjnjT
#z1viQNVnap4oH+Ubxmwod+Cm9sagTavGhJtqrTYhbrmDCeRWXAskW75b20SdG0R62wBMRd//0T2XjlxNINPlkS7tbFnpSNsbEyyN0K7ETfGICI
#++XV2uB3kBShA6JkoIIN+nI57gqZPiDE8bKD8c4x+sfGCldufrh8Bb+LhQbDbhm7srATmCxFop2xybRuKLXczCXpWI5cW9J4FL1lXxvDyM/0Nk
#QLujaQhFPRrQrqsINlgymNkaARB6v41jkaqzbUGaGgsVx0VVe9qIJ1puybZdbh+3ucPSR/vhH7x9jR9Y4JiqzJmkLgkpUdpx1utfltqTZXeKe+
#AbObK0tJnN6uatw16ezKOetoedG4CJjbMfvzK9cBLILym5jeRD+nV5u1JbHdRzQajvYqdHSpox8mnbFJfBii7QDOzyuu6ukMOV6767iqc9Xl4h
#BU699dcV/oysJOICLMCEu0WQYUeMvgB3zRVBFk2k2C2lKU14VGrdw/tN/E8ok/l2yKYuOfGuegGqFpZ+8rWRLIdACAapKwBHpZjbRxRiNYMEQG
#7uedw/a53r1kpJIF3hXyTxJEyDBrI5yB6ByIjl0wykTrPOiEKcBM2HhJAkpSJruzt9NTYDxqui+0mcZrACzCMEOa+EAuBvQMviTqK7/+8317Zc
#seJkgmfT9GFStU6Cwr6UAJgih+l5hCQDyznCjMgDRG0Z1jzGxbllrqTnQywPM4tEIJXhQDRALg959UmA2heBQaNvsl3ldZcEXhpPNec7w9hKPk
#mwCPAQukA/Fa67vElywVqovZIEL9a6hasqkAgILAfLPasT4CvQ8V6WslRMO4QX7Jy6dZpUES8dflIb+q8l3IKwdwAyuXCicBJmHcSQaGSjYIrW
#CtLx17XYqansIQrqau+rgYdyf9PWZFDsYE/NTvpA100X9ipdNHCbzvW0rekK10gCiaSl/p8SzEqn8kOmcgUB0tQp/h0dN5l2pNQhbIfUd+NGFT
#v/pPMe9LzLwR7Qm4qg4gjnBUYO406+nA9xX38+fF6rFf3r4Nmp9Fi4wHPGi9LZfPdCbtNdyL05tifws5L9a77XM3S3WfTFw3OePvHQRk7/Izce
#KhvYeNiFR3hGwptm2kwpmhPEve0VTHuyhp6c0qAI1OLc1BaS0Ptp72UQEbwF4hiI234QBVlAIQ1pA1o8hnzwzFnBPwJZ1YrDe6C6uFdhPZwGkV
#nc5xhjH0OhaIxBrRjb8bjRD1OkpL4rqwtfBw/3lSsSZ/E5h2/7BctOLQtM6vTNdxEv3tM335k1S3urlBS9Qwn4q9yVPxQNlGfEcMtukJIPVGdZ
#4lEDVogu6HQiNogTP/hs2ivR7saA9rwqq2l05RB2055sCj577i305dRLtlIDcydBEF6ivmcWTMVpQ83L3S0FGI72hI/N8pqi7YRHhxOypqhXqI
#oOKWrwNK8KHzn6E1JtC0+Y12oWyvHWytFdUdQ9iVliOZvEqiR67e5UPt4+KBfp1vouRGUXqfxOySNSVfqF1vRoWjW+0ZRLiaabA/PhFZ44wKu8
#y6ZagaNKM/tRjwsc9XI7ylFPS4Dqh2k7maYfntV8VUV6LuQJ/WF43i24e3V1h7XdXdwBy93JctteAWogPc4y6WkW4LklzNs/d+TVl/b2MfBHVd
#+JMjcPhGSnvpJfhq4/Um0fyh3S4U1nLWuNwKuqA9FS0rWtADX1HvQirQtZx5b6YXeLdCK0n0qZY9vZzGbv9Ct7hwaZeqVf3V6/v729Zc9o+cLR
#c4Van2WVfZaRnSABi0e0z5nlfTQsTRr9VT48hQzdorWOsGrTkpCXRH4gv9GehBuzk5SBHnR3c5gY5IIenjtV80udCQphsFftRh7qHNPVeJ7I58
#ltORMFoNLMeofJ8r3mXy4uGYY8UaYGeH0gEmnC4EMz38EJ2yfbhXqr3cRrYcBwsFl2gqfUZMihu3Jut66oMEv043kEMmEq7d+luUHRUnHhJbD8
#ZS9g3tJ5I1yfgojRxIufBFdo9qptXLeX1shJHaDHdM9tNZvdiH8kWNcU9MNpbbQHwup7rbbjuek9ZWUYOa16ZDsDTBTVvXtqJ7LeclSisTW16/
#v5/Qd1fOIgEoiKBfVDs3Y2sJpQlPUA/xyIrXHQBvjoEcfAWt5rHx4iDpcIYdS6vxFKSdu20A4fMfLLZDZHEW6ibdA/d/fbjr/1tNv3pgsPrUZ9
#dgB2feH46z4XvbOER+gKjkLXEnK0+/pm+hduOAFhAb7Qi8jxx/lEe8LuPYL6v9j75KjVaO/uwsXDVuPg0F42+ol3+RQtXqDRTtP55F6j1T50vs
#CL9w/hQdN57jwXAulGavFSA1hcUhwCTAFKr2fJJDQRnQ/dR0niXTUGSTyxVgKZpdVek+2KtbrsNJ0R/EvhH2LRsm5edFjo5w4L7kHB/jBx+8A8
#9mDsnCFe1lp806ObNt9Mlq6insQZOj3bmUxznyjxKHKtybI2mdp7bacfuZNlfTJVJ3nRw0br+jo6anywf33dh7vmAxsxssMpo32pnWC3H+1ZrT
#oV7vVSq30vQmAa8ssYqeKgRa6boE+0Naz37L1+ZL93XzlI0Nshvu3VE3xZa/M7eJLUh/TkoEsO1febNQxgRk7UWjMuYSZVtMKJ3Q/P1He3Wg5O
#veumfd6NG5c19xJ+RjV3dA8v0hqUgRdRzY3gonBYmCaZ+6FUq2P3CLIfNeUh8My5QL+cxmV91rjMNz+STIGpwTW6Clw+bLXLYMsiOI7LSZxRy3
#3UGO09alw6aSsfsg/a+cnE4QPnUSPFJAiFUHsAnxlpSe8faEnbkDSSSZnSaGDa0JetWvsBdaSTtt205URtN2pJWhTKFLmyw4dInwLJz+ORC123
#B93g9Pt53ar/41F91LIdKLxeepYfFvf7R+5Bc3cX+9LFJjba9gpaFo+60KDqTz90YKCwWvnp3ai95dObkDSSSSFhDxjSeJ2fTq78VocYdsvBj4
#fW+m1+0IYOgd6wMbqRSAGNuA/M9LJzJlK833Sg9xzx+v0HzsGBunvwwAESPV8XDjU1oJuViviRQ+zJeFpSeJC7QdfXBLW94nWnVuvm6462LEne
#72ENL0WhvCQzgiVmgYW7Ee7ucjatHiFkwapWq3E1TsiQ/MwDQR6YADuP0/SzJByGU1jZp/H0ahLPU/ajnIDCj1soymoOytpxXS5LVoQbRqLFxS
#Uk36vRPmgt2gwt7pY/StVJYSpurFTvIq3jqgvEcw6s7wdlp3Tc/SWEQEQSqIwkxy7zX/30yYl7wGZMGPosHcvweRuYvvD6JLiwZnZlVJ1ZZQwV
#/QydY6wJ9GnhgCSJQIb7WFdU+ngU+GNr4k3nXlSIVHJz4ZIc5yRoi+xiaw3oVropEi5PhFf9JEhT9DdIi71X3hkpFgXy4ChIhKMC5pPZFNQhdu
#03REsyuInoSXNvTghcez5+oalR1Q21oDdLmoY9aL+FRBEqzMEU/TvhcRokC9w4pHg4xrFdbv/ONxT0qFzHN41JOiwlfT6f9GDx+KaxCBL7KKeY
#3Fpqh8vY3ZXEI8lYEZPE2hRc3J1TV6g4MdbcboziNCvGVaKylSHrp1q3Gv0wncVT6oCOAe1CCG/DrFEbQU+yQiAO0E0ZhdGs5Y2uAWm8mr6EMn
#x+NaqZr6avps9g8EWmIDFQx8yCqTfNjGOBamYsPAM9E4MEbWln8zDF2yTAjg+SBgid+LH5VpgyUi2OoSgMlCb1LVbe/kI7zaot/7ySVY6yefrm
#O/hUPH4ZktQqNINKQszxE7cRInEZoRMSlUh/JJ1CRM1PucvY7i3Hvcy7LAn6b76beEkScBOqIC/f/CXSfkWjTYIoLAFtYDChN78my6UtvlklNp
#lzi1M3ZxbOSS7yywsh9LM7vjNzX5w8OTttUKDN8+truGtg+Ec5nf2WO2v4LVh98bftXMLPJSy98BONBeMRuckhh8IKAt9suaeQrQvZ4LfdvXTP
#IDOWg4F1x67fWsu8anFVix/m5ktRhLzBcsT1JZYirqMxFnZ2hnh2fgtDJqLHNt60MWQi30RjE5rN15cYWhLkOXHXxruWvNvHu7a4S7y+6Zwi3i
#UBE/BDjA2KT/FXPMEwofQIL7SkKT1NxSPNGvlsjPFz3KOTAm4UPNRPOT/cPnpqrx1Tf6g23HvDeowHhFBpj0CW6c7uFlLQybhMgDf6+2lcxxCq
#prNz2qBYqqWXGKeMXuKF/m6wrKfxgEoeLCkyDN6VclNIVspOV6W3dE5Ob+mq9JbNofEtXem7LAu3GhkBN+8WasPGW4AUsygcHsBnUPhU8rICYu
#Roz+ZLtbaSwzTfx5/PZiqGrrcQeBY53hLJY1qJDAwl75HXoekBO3TyMyyVrBdUxSh5ZQGhX5O5deb1YIhmM9NJs49CIJFioIskvnStyOk7vuNH
#KUhPZXuTNKtjILG7K3hdNp/JImF8FJHd0d1V//hrZfjVV5ZcusFEITuZPPhFWwoVhXiI4behZdAgaAC18euHkdcLIlXAJVRPAHgGHjkSco0/7s
#VLYRAzRrOW8Rr+5PzsbHx+bBqUEK3q0CzuIcIq4T8qnOygRN/IJjigfODRpDPnDlLIuoVyu7lTumitbiKTLNhlIll8RY1CT4f13dVcGcroH5Kg
#Q1npK/hujndzuIMm4SX84I23pBtvCTfs33wHy9dsgWaduytrUYf09h4stku6QtVp/d4d+OZ1HhQtkl8dF7o+pRmhHM+mpeah3QkbLZ0tnOk5kV
#E8o4VGb1BpLNCpEsaDy5YDcnc1hV7hzCXjGk6ojVEvm7qWB831XXM4MitMQ5HCpBOtn+G9R62NNIseHZjO65VtU/X1UJq/4LRyeWJpYAQoLfOu
#IzoYkDdWaqB39+jNryeBEc8JQCNAyTMLg2nDdIpz7ZItnYSVOrAXjPhiwYoq7MHO0Ab0vOIjIefdVb6KVgBcZSMyDyN4q1CShQb1hu/y9ffYhE
#8P/Rz5DTe7jA+aBBnHsZgdERDZEZGLHRGA2RGhnWU6hJTbgiNHBqmtNf+21/bX2DiYing/XVdZ30qnHwfaF5kcNaGmdzwHKMbAunE/HIQBO8OJ
#vWADQxQuuPt5RH73DwbFMTZ+99vyYPizcZm9oJCRk73f0uYayiq5KZlsTOuWEtrFEtqbJbTvKCMz/thsiCacQuBBKqve5kanF1TUSOuZ4T45OR
#Ns2xTvzwUCQTDFNJDASoIJoSDkveXAMgkCKHZoBhwqDdmNI8aQpA05GDBDUUTAeM/xFGNiP5+D8AwaCJrnQRFTdFifoTwPojiWYnz27MlHNs6N
#QQR/Sg2T7YHRAfFMRGinMkk+YlHFfC4KpWcknJjSYxFkJq3nSB6Btz/1hnPqDuhFaBY++gh9LBKssOdx/0D/cRsNjJVLGqMHLxPyX4SvSTxYvU
#2tdCGbmD8Svx+H2FUgLCACfToXhqJ5uYXMLBaZj+CHPWEw6DTaDiVzWNAh8/DNd1OqtGHAoM8CLi0NWSOngcYQa9iT+BAhE+YLVnSgI4dvfjMN
#iqM0WGLXheTnSvq9rBqnj7cEBQWt58KpF6bkrpMa2RylKscYeVFsXMxDCqhAgRVgjEJ4gZZAoT+nRIswBY0O9JR50jA+iudYYE43qBfOhShKY0
#tx57FeGkQWBE3Mlo9gMiTwYuylJAHqCqlRMwwv6M0xd9NwDVg6kdL7SRxmSDZN5+DAMQ2QnrVSUKo2n6EiiFpyUDGw8N502gdNZ/9BU2Qv8/7B
#QPF+HEAhe5qn1Eka1CFQzzCYJvTyGbwZonOY6s2cCJH2Rt48k8Tn+f48CKMClQgRFkgr4ngXgVY26JHw9bjAwOMeUAd1czwnwk3ktkhD7wjWRF
#SbvcSIQo6G/hJJDltqSGJ19p37elZWWcxTctLhoRCTLqXea0HvYQ+WOx/pS4RYxgpFmynLfbTz0rj6S7bESUtdghTAxtdI7RMvxagRoNjjjyiu
#zM6TIS2tQGjKYQ5KqbQbJvpjVzfyGRT+aW++y51iRJJnHDW6wk1IJPg0JKLW/WnEG3KRoawyLjz2xcy7SlHL49V+LAWpotgb+MLXQEhKm9b+7y
#4Zn94kEAsLbikXb1uFS/MCJLRcJhoyVDVwXMKiNpDV8E4HqDo05BgOB2nkPZ3Mo6sk9Mmt00tipEzc3hnBnA9TOVNmURBOBW1q9CDImDIRKedE
#7WDtyVU2mmgLnpXKTa5nJ4+fPf3QbhinsKJBSc8k9kwqKCxxUF5w0CccpjRcNvCSEsE3+R5uiQGdNp1DIwUezQH0FGFMgXxBZ4TmEDWLNhaXAJ
#ix6L2K0Ehv/tOUilP5VeQW7JY/m+PEhFmNHAa3MYHFJyDRwzeKTSWKfBPoBRRD4xQq5tiyiq1I3HVDPYd5ApwdHlDUWMfAoLbwo4I4E5NbhNAN
#cYooRjNatdFnD+Yn3UfxFJfcRkFoewHkzk3UnLc/p60poPdHL56qSdEwPo3Dqeg5yOTC6ibuL+Zx5m2Z7iVJ+uTJj55LUdqXk6soSSdDH2WxDf
#tx394QqZOh0C7EPLxVXNU8AOjzn8e44r8EQqH1N5zCyuhFUlSAbiAdnz6NJ3OF8oVqPymAfBbp3mkf3DFIcBvFUT9I3DunMccVmsYTTdxEb4pT
#5U72dWFURnEWU08n8YCYLfBAr0+aC8pjMHnffOcYQ+D/tJcOrfVh+GHQvITWq+JQgIpGYwG/uG0xnyndSEOqIHcGtfNBSZOJt6C6CRPItPNdhE
#JrX3og5WBbkJ1IECwi0TGJKnAXJ0TNiCT45rthBNURB5lPCTYpDJIbmxwsscVPloiMhe1Yi+eIrgYi2kQ9r2jcp4XDEeCCYg/7ho134Bzi+AI7
#RyHByt1vhI7UTmD8sN7HgOpzmoGRtj0vvhCtiw0rKwskeUekyJRQ0YWZDCsXSPIOfd581ueR59bwWBW3nfUvfbT1SAgEEwTz6sMo+pkxyrJZSl
#+DIqrof8G0vnoqjxYaPS+jUFDZHOT6XhQi57hpGvCZVonyqa7O3t7bb/9+r6qGO0YKfCaixc+9Q/tiGzNEOyzT5gkyTTxjYIb9UxAZWdksL2+4
#LxunGzv2mI5OREg6T3HUIuOKsIiom60EewxXDDwBUcTCx1bEGXzQVfp2kZs+xiTINEXIZVpeaSzHwRVNOoVT5EeIMlegVBgxgRyWErsYwEeRw7
#PcyKjT0kqth7UWV6cK931YPWHEAhD2vXmakoKwSJCUZeFAIHwqJDDLJLnF057GFyZaa4rt/KQwn4fxm99m2MYngwHqqrAoV4l0YsmOKtorqvej
#RJWCV8OR0R8Waz6RU4amxSTAM/V5KgUOddqCnDymg3T1bQn6d2B+weGBEvQ6KtDL1LEMBavR9qJSihaU4oGxaTtXbtrL7TsF1B/KYUXQdBB6aQ
#fYfEQsGuiOFWVQYOCZEKnxCYpuqKNQzDR6MiMUjRe0EJAaTGbxgSakokF/5ZYUNOPuSgiFVRtS8ELuSG1bP8mrSQdLUbtzXf3D3SsZqYN7K62K
#axROZRCltBhFKd0Io0RJ4XEFRjJvh2soyVZCPppJdQyPsQlvixHE0EJbDW/Glq02dVPWLQ0+4XBJPMuUIRwxu53f6lCctOEfY+Gncnv05CQPTE
#l6l6785DqOpsoopUXpKOcM3ClorgKnmpgy41QrOg2irabvY2FxvRNERVPasRvk5rhjp7ztil+3wCSk0riIpcNKjXkMD4UG09He0y66eVyDR8TU
#O/JC+mCUk9ordPTYEovFWtThLe+f44W3lPdkq0TxYsS5wQLnaLL4yqyN6UuThZ0UT40WNUv71jkvL9AqVMfchWjfmD6yZV5f81Vbmdt+svVYr/
#vJJjEDcU2zclgwphO7y7/lwGCfVE4gURBHo5G7zWLHuHsTsnh6mWlTplcMPKYHCtB8N0baabC0dKJ+EEqJLc+zpNGEsA4uHWvrfZnvm1YaXCFU
#lojYR6bQyqRLC4RDAFkFs6OSsZHeUtR8d3eLUQJXKngTCxqLrnqwjfIWHAWICz45IYersS1CWmgwYsr8/wdrMWUFyyi6mGneR5BXJZMqe55Pwf
#bm0U63zWlgX7BaiIMGeZUM5ZXnZ+fOD1PKJCZ/tmGhVnHMkgkICpnzpiZSckU9Xs/mtafwTB3RVfDZ9UYZMFiSyPWn3S2ERik/Xm7zT6mqeLPS
#ZJg73uhPndDVldJ+sPwMHdlU6KMVWULIBCr6Zf5Is6Nnm5v8FWG/QFmFCSU+8oZ2S/+EvJkwzLqHAipO8mt6ES1EH0Zxzzr7Meg7jZTs0sPBlf
#XSIdP7tn3urNh3lHazfZLQ9tDYzVyjOfM223MPSCpqjJJg4H5+8ky8Zc0fjaZ6Eb7ux5dsxGimpAnUU6U3kj2dCWkEHmK3xAyx0CRYxGOtUK7P
#dtro4C7NfHJV1AiWEoR507mBYLnvkgKpoTB2N/wrUFW26aj/pmSkJttKd0ZGtoVAqwaxUBSqfLayIqRZUU6CmgTxsNIEpMCA0G8aqmQ5K0r4VV
#mViyPRnfR+ZCuFgjer8MSkZQzyVWJ5DRiFRC41A/dI8z8dNNgDtUMX5IY6EN6ndjf35Cq0GhUDuwAVKZQEUra13YU+H+vQrlu1riGRJGVMYIwP
#DBMnC/jzGNFMv27LG/w4ee0BS1yt5RhXoEmqZUBQpa4xYdNR81tvetwQmKT+nQqsU6k5+aaBpuTIr5KsW2KsIbrecGqt1s5HTz52VoLZdBAkCx
#5I5nO+ruY7t9HuTR++JnegnNCqIqvgcqLijIgG4Iqhm8jkUIUaCkKzqmZBO2LZFfP6eyHcFyMuCmkkx7wvWCT2XWKghDdvFcHveW3t57BUdjZC
#851mHvNZH1/aLeFjSdqETZV+h0fl8yCSh0I+HcbmLJMGPW+bYbx0+0CbPsy5wBW/OBOpOQKGzdbRslQcPozDxAhTPCHlyVAJbu3sXMLQ3UZp+X
#tiBdsIasvgln3LtBwCVnOT1+eA+5rd5lLZbX4s9rjCKYwtFG8SHCxqMzkoL3uL5GE5GFMX3ZPSpZNeOemlk45yyeD7e2G1D+93N/2vip5QWlXk
#FQV58J8SAnwQ1dEfCtc/k3Zt976ZBUPTaTw41F3IFH7vPIlsiTnmws12Bz7Rq5DmWJ3cGxMy4cB+7eQPNbRg5Ecg1IGIZZaq1wGJtRgNCpFdxp
#SQ7hcF012OyBBoxhHKilr3WPtjfCjyufxOfm9kyHflNmFg3E+6lS5wK3jPXm9dTIRub2sZaUT5z3yBRNRVw6NRmfVFfYJ+YulVzUpHfD1xJvYm
#0oYaiHDq+X7A5vWmQDguuW3cnKVb9MlQqNSKb35fjikR/NW0Yh4KYzwr+ewWhs6ZV4qNA7ti4Da6FN7TTHPggqfalg6WCblvLZVc6+tulaA5t2
#/oWfoCI4yApxb7dM4LIEuOf3CHFpagP03X3c67nFt6d4O1tdoPbmVtt3c/cTwoCv9trDRStr6RA24ZvneWxv/wYR4GXhnQvrDLaG84RytTn7TS
#32mw/GxKxehdAFkKqKkDRDxnQx3dflJowUvnapsJJZKVsP4u7wFscyZwyB2g5CRwjEZ3HelcUPm6ja/bXX1b8uYghaRfKLTuBMG6WXl4BKJw2E
#OfNnMWz3BFMx2TnVZMoZSJDRw/TU+BDNEQYpB1zNoSTfdhgZvB9RVd1+tJC278Vs3E6zZet28OFhiAEourBtYyii9fcBMsyZ+/Yleg23YHNaP/
#T3h3EPsMBkVstRf1XqxMhTj8RO0DqixrtPBpFo8vGHVADj4xEKAlyy7FBkeo1wVIAOhVYUNH8rXnt/Hmh4PBwDzf9JpuHegB3oKtI4lmK8BHPD
#fcax3cu99oP9ivFUG5G4dO392/X3p62OZ5H+gk0EMK+B4j21/CDZXrx6nl2ff68sWVfJECZ1MvNBNcoIL0LHxv/xzIgpgVPLEOS418nwJcdpl7
#bU9g8qfcQFAb2xyBGmznAQxr4dBCgJitNDwlCqfjV+wTU1p51uIXjlr88ua0TFvYmqaHjUxAp4GeVWroDZU6rfeRIiUwHB+JhHFXP1/jV5I8LT
#ayFHiNn/XIIzAxQVYxLkPo0ksb5IcSGyw68YaxHcYIQOVjdGpCvMAXMS+UFYVboHYcaZDlwZTV0GDaCNM8w3Ror+CR2nAtdNwiRDEf6p1PYy7W
#UmlREQWFO46zjg4E44AqGKR4Nt5pNO+XopNubtr/0M8MQlcfaFv3IFuyxjzacJNJc7grEEHL7Z0lAbdXthYkUQ5UJ841x+h3AIN7BquwOFqEO7
#MS8bUSxVXdjvGeIFy3YK+aNbOMqAr1V6CkVkGRZtWPVRQMEaCswTHbrfcpekMRE9TUDzjzz8c4Fy5/NBVRbGXCTSyFKKsOTiYN+ESAMRVV7Kgq
#DFixvQ9Ue03WUbMwgtWjrKDOp/jc4tNLSmGvyNsNTw7h54p+Jnw3udKiaMwwiCtmEDyVJ7A68ZiBGKxVuV4roLzNXRzUrii3Onvctt4EWxGGHH
#K460zjzAIKts082iS2AcFx8BcEHViA5UeXDi9FcwMN7iHBY8otcDjO0s2PCOoczMfeS4Sge5W//BJewtqC70YK/2TbASX2uGUt641D+16rjb5m
#H4fLoG+1YTz7wZAlm+qcS8zZOKxfbct5Q7U4wtaSEBhUxpbNh6Fb82BTr6rzyJOrm0Yclgocch4NSK5gu1ASjvBwnhTm4dLNw0iDjD+8ctvNpp
#Mt3eHSya7cIRoN3EpUkFwNVhdyqcFZI+wlqLKLgKE/sZssNT+iOJ7x7NhRLHYU9vvB1F4NlzXXypb14RIEkVZ3eIW3V/XhFd/KKNdoKQ+TZuKa
#dBmBhLMPjLQ2JKnDgQsSOZymba6TALhxminfgY8Tgn6DRgCTBYJd/2BFc3ksdjYL+GCbfcCGFfn+aJajPIx5l7a6Qt7bkJXwsFy51WBk3Zvdis
#tEkwLRXNndrU6ao35l8HmuDjcXr44eQF9sjJom40zGPw1fKxlncYuisNCFxEX42tyUVw/v6/Lq9khBIQUJKomYIDCidNc4KMt3jQ+KczQF2ZIk
#xfaGJIhQODCvukrbq/eDyLvq1CF1MWlp3qcmfF8paNBWaYFwJlH/nOEaMu1bC3sjCLRurF3SOLG/Binom0Q1ziA9xX+IwaWtN4OUDu6LkFQ9mv
#KDVB6dy11yDTfoD9oqPbgJsaoCPap9AP8XQEorEaQ4GR2WiqjWTWcI/3rw79IVO/Q34kSJ3ScN/QnBohyGiXIYIKoIBVX1fuw2Woc1i/CgbMST
#6iY1Qp26N+4OawJ0Cq57NYE5BdeXNXfMWBPJnnvZHeKfHv7RPnoTlYrBqjaQqehxJToVo17khxV9Rv6bEJhZEWEKHmygTIlUOdIUJyqjTYmnm4
#hTax34ysvcfnRcjX6F8F5+/lmQ1mns3ydDIG57b6i5dRPpuuYoRW/ukZpoODcNs5b6hSfvGe32e7apiinxwQF61m0pKW+PX2s1nUNtfeWS9++/
#JyScfFu3qqU/bPnt/YOm2d1S/w/3e/uD9z2zqCMO0s8JGUMgINHUxGVct3sCztylF97GC5gUV89iD6EHtRAecoZ3BxVKnz8aSj1zUNAzB2X1g1
#OWwJCIzTgTd28Rvtqzzv5i77xmv9rbawTLgEIhkFWWMwrdybEpTYnDxlUWToag3E8g255Zm5y1QF/fA6IH5arPmNGNb2ZDs0P72gq/lfZB08R3
#Bj2xqu7A3U2bq7ccKWwHZqLvkiWjglo8YXgIYtDu7kBhT2IJFtzywMDHIT9NfBf+dTW+u9YqrUJmKtcKJaqSyWqqVDx1sF4Hyvt5vM6JbAM9oJ
#JGoUMIV/AH6huFx3DRoVyoR24CoFQ5Dm2iP0ZXnwYTd7V2gPzCKajmZIwSXT3tL916Gy4YDzK6+mwwoF/cikhkKjYdg4sP52kJWiG6eo7iG+j6
#VirAluJn8aUEgMijjJ/9hVd/3ax/8Obf19/89/OaiDmuoJlyofLqMYaSF/MLeaXnYkQMLjyPZJ7eq8M/UB1C/+5eWIxovggW8cZDSG3F6D8Vet
#E1X4B686rXuCeT5jBRdBaF1Wab1Z69sl6d/Y9v//r87C9e2a/O/8e3PzuHZ+JKflYhw//8f395fY7VYC008Pr7mjWANftV4/h6wH8DJGPcGHmV
#5m3TM5zV3377N2+//fn5ceU3XbNf2fG1oI5rEOZnhnrrzfthfD3qXx+Mt3y9PP9he6qsWCdc70n9cZLbYIll+5nLBGFNzpqwCj+St16OmLfz6P
#oa/uROR8/s3d2dZ/n9I9u2PRcL0NpkwHhMFIKf2Fow6jkJaZh4npN2gBjF6BUR7KKrF2RRkC2zyrCDOWxgNEXcQAEsislVbyTHr6Z7dgHRcuJG
#U5AJcLnZ+wvLOu68OnvVr3XgH1yfNTrncGUfvzq3gfnCmDXu2Xf3WMWeVCJS4qoBXdAudkHeuCzFxiFb5lpxM2vv1ZmF1XTor6iXrrHmvaFscb
#7sZOnZ/vmxwPQymw2zRk9g5dfDpXVEAnjXOrdRlMgfgKhVG0B3Y3vz2HSYWUeVnDWy+kUjU2fs+F5QTvsYbjq88bIBcBVd/SjILG2gcGjXbs4i
#QMyTBMZihqRM4ndn43PF/sW9hn86B94O0nL/isM6BwkKsx/NOW6jfbz5zMJ+Ufl/LCxe5oWT7iIE3lyDs4vHx/xKItvRR+ciioaoycuDDLYQu0
#clB79YevctGRwJdGXXrAVTP+4Hn588RXAcWL1A/l8o9NtdWON7wJFdtcZHCbCFXmMaZHveDNZ4hWTl6kGthuJ7fmxh7poJ3XFs1i6sFfutfEXW
#LB7br/BNKrBgYRCGu7sgWkEnBf1nxJJsn2lqqLD4/FJYlaRUH0Nfc5V6JU6h/jWbBDFibZjSr5XYtu8mxRgxelvWf0ATLjqK0BRi4Z+i6hKcKi
#oF8+SoCU0S8wjPmgTyMUroFihogiqvQf2tw42dy+/W1eZbamWewkfumiei/Pjn6OBQb8y6EElI8k7KXPgg0WhIZMuZhvFxdFdQvCvw4ZcZ7R7R
#oQidByy8yBKCh93VJZBSNsR2vjUfSMmFl/7YabWb/J4NN7Uy+ZHcWxUi0vX1DrEH+EXNfeMU13dzFvFYBDYP0XiqRlJUrdE+lHMqdEnSetg8rr
#c6dClPVY5ckFJFhaCcNrIj3w7dOiHYXo7CKMDIug9FAhXpRmUAHbaRPXQhT60miwTdkKrQGsxyniaov2CNI0IfIIQJi/rQfH1v5xvQT795+EJq
#5t/gDs+Ls2/Ot3g0fIPeT3Z3S4qZBykehgV76hdn+O3HYacp44B6ttam7duDX1pCB2QEcM7DBrkwAmxLdK9xULc8oSydxrOavObXe22bjg9ts3
#LNEfrZalM/c8aI5hpK7a0Ef8til70iYRrGQ5J4V5e5u1KartT1CGuxALg5JsxbyrS7aynSZFHcLowxlgvJu7r2R23pCsFd+pBsaxjJ/l2pFHS1
#4ch900wzp6JnglPKZVoLsCQUFj5lIM2JWlJor65McGc+k3Nt9Q6dIxv/rCv18HJbn/EyGYn4grNiBMG7q6iRcixVcagU3CFcLnyMbrHwa3fMt7
#/4DXpkz8oee+9IrE3e5djQ1eljFDcTpmFMybonizQY2TzYmQkXkxn0WYljyV4W/CkNgvFpbGlBQSX/qM208CUgoxEJ2A575Ek6KATt9rOPU7V7
#XL1vQZ/n+Ru+WKA6Q8J0wwuraqgpu7PfpBN6be/ls1kwtQrGjsprSfjbCAu+O8/Q8djomwznS17dDPdwR6ch2pLlEET5vk5X7reWvoliWqi92I
#KxjJeEXp2PPkzHJJqGtKK3BHV/8kXpqGSr2QqGGyZUDctMl3Wszv7ki8YsTrNPOegXt0G3bpfNEkcWH8P0S/0kYC/K6jfWRkA0eUz9yRcuWwU0
#cFNhEuzuFm4bl0EPbcMLO9efhH2MtKixFskEtWme8z61FV7R2ZIICKKJCeldep2iqxXJ5TE7X6xk87r5MPzpRkEOgSpxoLpYlGmrV8EyvGEE1j
#/g9kE1FUd2XCkf2GHYbFZMA5rBNsU9TDtNc3eXGKj8YhxWVftmoXlT2XgyPw3b2f45qgrRveI0c5D2sqnGvni28tAtC88pn8hz25k3zaGcADbT
#Zohjk2aEh0aJN48sKbNfsh28K8K4aj5HlE48vDkppZyCzltKuYJ2J8+9BfOUKXkrrDk1Bty7PXW9JdNz5JvCYgDPe+KxbEgeyscXIigvE9ui1B
#SD4lAUndzvU0TT4dP6mjis32s7dEJfkwf0ID2tRV/hykJtJOdoV1Amr0HKjaNKkcZ29O3i+lS0zN1rNZv3+rwUrdWrbc6jxbzsSdr9wSaxgHiE
#LnK6KcXe0+cvPj+9Pn3y56ePTp48un755NmTx6d7jSygwEKi3Mwb4iGovbubP7qaBTu5V3XBWiposNxmPkl9bxaY5Smj+7dtpr3AiWNfnLL4TG
#yykCPPcmFeX6ubPzNxIw0oIUsiEhd3MEpk5slrL8r4kkWsihiQssrC0pLXNtBr+/idaqusBus/Vn3Rkcu6Xikmwb4WlRlmZUEbE3OziLz1kd76
#Z+/Y+g3x3t2U+KXtM0seG6+PFbwXAXMSrkRHPSPQLXpm58ujPkttoZDkDzY/Ushz+tc6+tciIv2KtVJXe3jcOOzUG4e5xC81Yen+Ixtp1izKfd
#Q8NmsUGpJ13IJli1ESSUpDiGCGlycEbWkzY+zelPJZMJAJgSeyyUz59IPBDPtzxhMke+jpFIFHEHFIxEL4giSX1C6diQhBQNmy6ELlqO/eaIFB
#kuaor834Ub8sK2Y9/SQuXbgzMvNbDClW64fx0r3TNJpGqw3/3zEwXLF7ZxpPA8QyTuIxgtkxP3/MYKr8tM6H+HdajUP1CFFngW+g2R/w+8JjVF
#fk8yOzNkOjN2jCkabCffroz5+66cIyHxJuETQLmnNFf0VdD+4YwmQAL5Ml1n7/zt4RyOcnT15WZt6HBDL7/cZBXgDdcBGHUMTDGagksELc+fSg
#0TYg10/3H7UaBwb+o94xDhv34e7+Jx+UnreacLm/2G8clF58YLzfeDCqixZqhxmw4vrOKHfR6N9i+dLXLF98uMu1yhEeKsh93f5aV4cnYxx5xB
#IrwcRkvSkDY2e9iUK/xXBxhFMskZ5kiHvfvYMxN+8IgEKBGLNZJJ7pyGJ7qtgXiAj05jsQirNtpfujYKFQs9HxC+1lhknY7yoltpPEGapDrQcI
#h2x/r7YMVFtezsOFd0s7iiXrg/ZYdKhf1aEjWdtI1SZAfrbVhq6NN9R2ImpDA+sv6PqyouKpqu0E+nge4jCZNZoEiprbxv3RAyJAnHHVXZaTwS
#PCHw0TLAen4/Y8S5XnY4o8UlEzzBf4F91vPDDg36cfwMSA+2f4HK7LbTI3jBDg29OZC/xsw/B5xokfFyymBnb3RDywlIuOg3JqgMFAHQ3C3/nC
#FqxSWlA9cx47J8RN05kNz/WC4Um3aNYfInZb9mEAxBlYo75TfDsIQXKlrFTL3h66T9KJKSFj7Rme6GWEH+vH814U1EFmuJhjWBfE9pPYuNzELS
#pJLjuS3Ma9CEtWk2SG6jiYDsnGDs4px3Ma6XxYoUj2Ew9dTWQPbVbf70Uk4qja/7j6EIZYVPfFxlBPS2rKRuZQBPfczDq5Lau33JZ1eUtWCasC
#mW/XjyWPLyrJpHUoXBFsTMdEzblpV39JzvMJnwXTt8xjXPU6OFHXktSm3iIcctibWc58gehSZn/5HLvsF07X4P6zse44uHDh0Rn8Exvv9ZYKuL
#CzswD5bkFCMAYUADHi+lrc7+7yr+atvwmcw7Ytd5HF9cqKKBIUpcdSSl5M84Qq68JFAyXdPmFVoIN7FxvKuCrzxO6qmNt5RYOqiuiry8br9OUw
#4rR3hBUs8squr6HTKEDwosqrWrjtbI0HnDdnVGqOcHaXryeVm6/vrlxPMP4ra8+gM4u4rw8Q9vvtv/uF8SKHz+NtlqL3IuLQ/f5XP/+ZIQEMJw
#xgiFiHnH4TfQTzvP2XvzEkPCftc0r4AePlLM7CwZXKPCVIlkLe/+MfjRe60ar1catlc4aqvS7K88u/Nf5sHmaZArSsTi/m6/k5k4N+HkeUoAix
#4kQJIfs0euwqWtqWVpJUVw1z9TlVeU6snfYh+fbZ1qY5rwKKtD4KgtfwuTXQJsbhDKZ36DkMU4kjZFd6l/ZfPyY7t089ImlEFXz91G06/dePXB
#lLt//6z4gfyLsfxTxL+OQPUj482N2FROqEGh7Val18wsAS2Gx9f77/2kJZwCGoxtRdrTW1BrUrfFkzQYkrgRNxerlTDU1n+K1AnTAZL5IYsT0b
#QIFxtAgoDcwDTqOd8+Ini7QWngc7SfCNzZstBn4v8wtLPVKnqT3X/Oqr/mtQNWs16CkQU74yax+BCNrAEM1ajN/9++iRLYPFKXsGbxY2+jROZL
#YI6g58q7CbMYySBcWq0WjwNzvxPIP1smOiUcbMdHwvipCRdfyehrCj4lDNG2wOQJM5JbwdFYxKM6vdbpENfCmcZcJ7I4udQTjNz8A022rQBRXH
#hDSSWWJy2i0sHK1kMUhLsHZlgXDnO/N7593Uzx1bgXDq9S5SmCVtHDFiXPksZoX1Em/9xsIefoImkJYp6B+YCyxvs3jaR3xvXFEQ1ZycY7nAvH
#JYMVVhSFFAxg2yp7SLRYunDbF6g2oFzzFcAVeJuKFkVonkljK5OX1sX2r1lRklcBe/aK9542cw2qwO0mDrBZHLeU5umhw6CrySlOqLT5ewLdzB
#ZHusnadMB5MMA2ILV8mowfZTH4OI5gFJDJL6xyems5qixgWzuGMCAc/w4APDMYWT+eTjxKP5/VE4DLO002LKxMxk4CEZyFWC3W712WaRbeWazo
#F6jzQzfaTbav7JzSnLxoRCtTp1V17Um0865iP8MZ00xAAWHfMl/YLQNuuYT17A9IMvD/HFY7rgQB0qbNOIDE3Fujxi0/RBFMPYpnv794EQJawC
#2wakaO7e3LvfVGZYo2Ngf8YIwah5dCcb8cLhPQq4nYm4EDHXe2EMGsRsFCKWdb4MGB+fcPzHJ89z1j+Ngbj0bp7iYEXha1iFnn/8kd6LZ6/mzf
#1ms44/9wdkPrrdhPaV1bh3/MoWiTYsazeNasUez+cv3T0838muE6TeOf9cozU8/OC5qH+NHR+nIcZguX7V++jHr3rXsyTuz33xpAfaEzzDcQsS
#LiC57s/ja6grvgbeObxMIHdyTeN8jY7CXDLIR9diJd0LN0LIXkJPWhEIPISLVAjmqji7WcMENbOBiWcB9HojToZ7l8TyZ6MZLGdiNXip8WZrxX
#OmY5Jobzo8Y5jRmw7jenXMe6YzRAXCA7G/I2y9TIcm8zBN+L6DbatRM2kbPIEVVEUPoI6lyDXUnWhOwN8N4hT3loF9BwowlBeFkxCacN90oHOB
#5IMlGrVl6XU4HcQmqm70eJ5EMCWWIaxWccds4TWMdUgeOuJelETxZJKAYcdTfLfWdHoZ1dMqGiXawgLRmbpEqhb1vYZPgehnbhF5zvqGVaTdXX
#HRoFQ2I9GxkZrnoNW/xxpWvce/dtGqFg2RuYKC/WwmWjLjSH/CtKEh+uf6Wl0KUejhgyaiGpVsZ/G0AqU74IrWVFqY7oPalOXWxVNo8jS/zWz4
#b3cX5gif+OQVSf6JfEVAZCsLYxqIPCnPN0SCgod4XjpHMHXrNgo+BrUi7LsgqlBnhn3bwXRrGbW9YBW4YaiEWkgYW2re5EaoPTHsNLmQXHlyYZ
#8qf4heMbwuZpbht7W8eLDO0RMKqUsNQ/6o6cB6+FWlE6409BMl2Uu7nxkOcAHjjrm1Us9II5xVaYSzP0QjrOhNVMYeEZv68Ao3fa3Eu9QaPXV5
#8aTHRJy6QWBV5Off/QOsMlNYRH7324p4u9LIFAR2wXT2mEmCHHDRmTo8vWGhdzwXVErcvsBvxjibuSG9V0BfQ+Qp4BfzhYeRkAnCXmtDwXTK0D
#7X8hAm0hNBMioi8gqBDCM4BFJOI5+orT1oCdxJfdBx14K2EWiforSPoJIt3BUwNdkTEr5SBP00HXSQAZZKB/sOFkRTZRhbC7vCLdLT+piLhIkY
#9oWotqAvdvnDu4sGCD5wA38RFf6rJczf/K4XDvXbCcxgWOPwGGDRGIAaiKX0voIruJ/2SMThR7QYqgEjgnXdhYZhTOsMT2QxBAjwM0X06NWiAU
#KH27u+Zv2gqoB1wSHzDMQ3B6qEBSE6Fx8v9TZQa3CvIQr61lmpQ2rmHmQEwmOiax8C1W0moU9JVSqMqVmVDINgY4xLla69ts9Vl0M9LvwDzdPL
#5iktpvMIT78gx7GFb2i5yemdLPiWIEkBXSx5bXC8jrVscK27u/KKOw9HCS+ckNJgk4H7iyuG6FOjV3hqQ1aigbVtd87O9V5Ng2Cq8OXVl3B3uP
#Cz5WPwTfljdFtu6wokOOApafAV2p2xoEgR2gOUfb0kgHZvpLA1o/KVBJS3RM9U+F/VzGuztiSc1aT/FZos0H47fJIA2Ja8VoCB4gs8wBwrkZmN
#aFSfLLBNbkKwB1WfnUj4+fyztbxiArvbKbrot1nOsUB10VVsqHpObGFNOGDImWi8HRYz/lAGxUoMFEbFdFTvc+Ed+vvHciyso8iw+PDH41/0zS
#fISU/QNbMsviaGJRJAwjFIYu7J6ZmnEwIGbGZtTNE0zSQoUE4uT59cXZngab8qSdiHBFewlLlXieUVKBdxBNDdxlMeB/CA4q3BI/qVLeAofy6I
#kuISK+Ar3sLPmcLQPRo2lODKdvYZqP+eQL/EnHyV58yXziwR4uH1tbp8aBHP5kyoV9vk2EOFVgwLsk1KWuSJtiD8LNFkJt3nOhupIZOsSNznQy
#YHnMp3oYXflw3KsSIiDDvZaG3b/9STEMVCvJ/nmjHGJvCSPvBNKOEI/tCHeZtxVYahkfRlQGMmS4xp3MBAKvyUVm8RwMhTIb420I0wU3HdPv76
#YTgZGrjNo7IXU0BBhhdBjXcM+eV3Iu/11Z2jrzuhjwdgvgqEtYGbVGzRFhQlbNVXX12Oro4x6oyQGEG+opz0wu6YLEwFZs2S4gWonb/7ryjSDS
#aZeog7FiiEkF2OCjNeFWZGjEHUqxiDpQZeudxYKRVDk6vC5njJwSLhBzp2qY0VMyrR20uNXy11fuXbKmoOn3LL9Myrq0fX3xxO/9bxQ/186wga
#22ovPdg6tMD/iis3BlMrPhEDiYGC7q6AMS+rGfPGaK4rhjPJ0g9BbuATLVKt8JE4/8NLwd4wan0JZizwlRXIxEuG4bSOMH+tg9myEnzsSFBkug
#V4bJj0jdFrom4xzy3ViJwyJUDY1x30JZEyln/qZsgGKmq9u8rWWo16HPN0NB8MooDwZxlFI1JnJfiO98oRJB1utlj043kZPrIiR9tQLCLHqFIR
#dr0cxkooPb7uMiRkCXGSCb0qlx+hoQNfd8umJfjwztHbf/HXxkmQgfqWm2kIPZkYr73yM+1kGjPVCt0GaXrQcbMjPBXkHW7kLv4IDy/J0IFjiH
#YMJmgulVxc7q5YKzouT+8ZiHdibl7ImbFQTPexDJ6XqjicOclqAQ01DVRs4QZe3y003hsVKc+Dua1oFJsHnPr46xzLo074tJ15ElmmbBYksdem
#TTXfOZKZTLOSdxfpfA499+jk9OnL0yciyah1pH8uTE3S5pEgW8W8IA6nXB1y4x1yqsI5p0eshTQUBwz5N6ez18S8BWbd18wRlBa5Jb96vzaI32
#pPjlrHJi0Fa73ITSy8rxVNCRa5u7tDhFpFXzhORaA+Cs9r1iSin6UB6mkeWgR0k5dQHGkfzcJKZAZTkc26vFmkGPEzMrJ6+3f/uM0uKuyJTOmo
#kIlCDUZvvvOymIr4/a9+/u22MobCnswbxNjDYfpxHEXxpaTyY/PtL/8Go/6l8xC793/+t39lvKSof2Ye003r2b097cRAdEUPITpFp6Nm77pAwA
#EGGezbeG8Wg3MaUR+nFs5asmESAbxVqUCHCsMwt7qloqXxPYajdekJwdCoHdEHEsAHai2FBL27wkxEDPAWDbMxcHJkysnEU0GWWLUK9mApxpRY
#zgYjwW4mNoIGjpCWq2CaVvVJyzqolIYRQ6/Pw0zvaqZqz6B4OHf0ZiEcP6z/IvTTna96kTcd3zFQa70zjVETRMO5lzIesnaUY4lGNAob/R+fQD
#OePDfX9sM9Tw6xsnPeNm4CXV87NaKtOTRMpp05CiXLq2lDG8VRzX3XVbrdxlX67gqXTsv8UFXEoVvDeK2ttIIiRYjkWTybc4xlbXsTdzRwc/QY
#lyxBKB2FtdRqOtpz+6amqiadlmtDrok9hdMsAaaBSfHXoqLldvvUdtjjQZAWEFJe81GrWUFSBhJTr0BY/DFMV+LDzJ/GGHMTAyrDiNLNLJqnG0
#S10W281YPmXHRYmfeaF7mW3AlixVT3+NckOgp0RBIdirylF+LIEy0vh+9Y3o4qDzW/0gtVnobigMcMFoj6ztjJbBb6bxIK5RhmYsRy+Y6EO6FA
#WAsMqw5ldbA8OX6ttp0PXV7RUav9biNHIdtx3Chme2HMTuN5RmFZSdiwzFpefM20bxjIjilnF/aE5UUOdF8E6yVGBuV9TbtGr9IhvXo5RQQwPp
#ymSMJPXijQ1B0vUo74O+kwv1ZLqX3r3JCVFro3mMyyK8E6mOgk02hsyM6iLRZtxzGtiLl5e93SrEmLtb4xzhtyPNZTIcMTjenywkhY08ECXjK2
#06bxcS5zwx+naXf0oCQiZn05IAkWmpYt+AoKAJSlUg7isumhRD7gGFrdF42B+4IjaanInN5YrvdqpwiSIIzMSpjX8K30jwF5YBqQSECsBDTzRX
#6OwivEinO4GAJooQJycbK1CHRFf6khdEXRMXE/TdSiSR6qBtD5OyRu45ZyiL5FGPTWe/OfgGKERbOIoExhb0WDVLg7sUlTEZOXt0lv0mXE9tg/
#F3WGGWGVNrNN60A/L/eMNyv1ZU1f+qB/iQrR80lffoRwjWHaHdrUPB5NLLqgR5bcwuQpybq6YwBvFxue55KlfxjHeKDIe5nQcAVphfsC9sa02u
#yXWUlT6oVFRYk2VnRVqagk8akHqEmGT6ele/QAOKWWgeMVDG2pRnGRiJggQBG2K1FcjcVbz2o/Aw8nPkfLET6cUPxEU7LkVvo2LQsKl18ZYbid
#pA5ajo9b7I392bI7AOqvp+HrQOxi0PpPDK+kSnlRiGJhaYMx3+Ku2maUb21NEpZPhLZ1d4XUpW3vCI0On1ZpYRx5u6yF0RQ7/npD4QIWrhQuqV
#R3/nlpVbk6UCnmFWW7r+WaKhcMipx449LBYF362tF9t4VB7kin8+EwSDkqTN9UNr59tOaVTiDIYBJ1mK92ryErRZJFlwoOVzUfnjrw5zlGrZoP
#n2bBBGOt4fVL0DcQxkex11HYD17Oh5a9grfljagRRUzrqnw6YLOXjDkfBhXEvFWhh6FFOfq81SPEk23hhxEhiGuydbgEjLiCFYX4FcT+1SfRo7
#x1ZP9Az9Rmm/o6jdtiWzXgmAI1gx6o7SZyJAAukSBbPAHZIiiSROU7fHMnL+NOEdClsNefTjzaftm61U8J8p1imkg6g5iNmrQRoO0Z8X7KWkQZ
#6G1s9WMAAixVfhm25x037rF0yqqCF2yJE1+gHYmUIchHX83hM4lsQrkX4LlyOM8EWIonLVjywUNartVwRl2o2M3CQkI860VzPCDaaj8ikm2Nny
#4tvwv2yziPJJbBhavXrsEfolO0PKlr0yzCplYRntRpazVMJLqtgDtD58OlIHU3muQIgxwMKALtmPIMer67W9FWeHdhy8mk2+4UtDkmgR10PtKN
#q3KHhO72rqxAMSjSRY5cwpSxgV02VcQgEb5KuAXkg/0RVlLpeC9YgcW/tZb93rSrGNW6CtyACvx89i7F1Vu16e0FPqFYOLu7nIeiQ1eULKeB4H
#frG3AX7JyUbu7+QezPUy2uarEnK2kix0m9aQJjrfj+Vu9DaeZXEe4DVwI29LupO2p5CPqQI7reABJzq+PhDwdAYqr3qjz1AwwAnBjBcAiCOvld
#Bsbhm39Lesrv/sHwXgdJFhu/+61hxXMDYSyNn8TAUEK7Akbfe43Lrff6FL1csqtTPaIoPtBtDd8pSJiAZ9JmDZVTmDYikJh4oYVam7jotvVXf2
#k6+POP8PP2l7+mm3/zS372X/DZf/xruvnNd/zqv/Or/5t+fv4fquKAvd/kuAqa5cBtwcC6hZhe/mCJQb10/PFgcha+F0jU3nMZCKw67lfpCAwj
#mdTMxWW3Xk/xbascWKz9gAIxcBgwCtXQOCgnadzfDOuAocSsYmUU4KXdbOYFJlsSfSAS9YPhRgCIzU/YqP6PCyB2X/q+5ItO7xZYgZ4+QrOeh+
#KR2e3pctKTfK6I7R9jR8gVnz45efzU+Ojtt7/4/PTps6cvn5wYLz97/tnJI5QuHv1vT05OP5NyhHlzpL3exnf18u86OBDfJRdGlLBfA0vb5vio
#ES9GtBg/POiOgXbLzkUSUrbYLI5qQdBDj6ZX74I+5Izv7R+KFupiBPMD4HL0W/ZtymP7iVns3D+sDOyHrSgGdqRIfj8cDPb7D1ocui+Ascerdr
#u/HwR45T04PBy8j1fNZnD//fs3hPhrt793iL92e3uIv8Nm6ekHzT86xB/5gqD3xAAnS/d1nWz5Ox/s/0mC//lysSwEASwzlAflIIDVCf64OfyB
#CAIoSXzr8qcEVyFNiwxdr2I5T0ceonRx0AavELTBK6t+Mm2ZmGGBg8Jfb5AxL38tDF4Ir58r3Fd87rr7ttg0fCwcI95++/fG73/1s2/V9jWkO3
#IP7RWV0xUrptxqxJUM9xq9VPGeKEDrjAT9V4HviJV6h6Ji5GGpfgLzQ0p4TvmKxMiKa4L4cXRgoBte4Fa9B5OJeExI0VNuEYy/N7bXhpQ8ZrAk
#QavQu61jflAwse3Qsy40agxJfnI2Ds+Px2Gt1bH4vnl+3Oo0ZfePUfv+idKb6VM2BuE33xmPcyFI4kZRryNKIElXbvk/49PPTp98fmJ89MQ4ef
#L4s08/ffT8o0enTz97/rIirdrT+OjRl+6D+wfBobInGpOrInnjCJ+Hqa15mxnsfiaT4266CKJLl/xzfb3yOqu1k+GfAf6ZdprKja8f+N4V4ppb
#cYMMLe/RvJ7FlxYwNCt3+q1DAi+7vs6f2Paetd+8B622VRPkWT22e2fH4v193tm3z7wxNF9zsT51gbdTdJJ3tqUc9IQV5fc3KTfJHUsIw0YaDq
#fefGn0zTff+TCf8fwZd3HmSWCAtgACtGGBLuUY8jUe5UVvfp3J5+k4nBmJN6OU9RYIQIYmGPszjtchUQWFW7G2uE1mj6zM6dsr7cAD2BA7tIyL
#gAzyoMSJ3RcN72x8fn1t8YW7SjtNPscQBIJlOF7WyccJPhvG1qWRtmK71u/iSLp5gu6LxrRW05Ze+OJp9gLktgL0smpF2BfAy9Se7Czsc4PoCo
#2yYR7DMEJL0Ny1EToL+LtAsnOA32ZAfTQDY6y1i0f8aaE1CFPcWNhxY+HCL9+GcBtS4HbZcy1NKhorDzmY/Sm2hEoZy6XtCIUouCvY/GN7l+eN
#6b1W0NqviTtsC5A63l0V3l2Jd7kvL4UTlNt8Y/dInUpleEhFOx18xKMLNbSdzC6u0LVAJausOFgOrPbQT/15An9pHIJ+hwOVBUnCV+tygYQU5y
#MxSTD7mT5R6/4MBhyj8DSL0Ij+EbyBCm3+cX3GgoQ7NBHvq8AAs4Zoye4upzzKQ1G1gUtwhuvrDz74AOSgAxu/TGYRLvKKouBNVg7126c3WutL
#sCeuPwMaX7hiNnXF7OqWZhd/k6yYTBB9bBi0mhtNd/cwdPqKychvECHxQK31HQmobnd3x8cTrN1dvSuhJ4+wJ0Wh0Kt6YcQIZHl5jCBjBtJHCs
#w2zZEsOkYv7EVhnI3e/Bp18JpkNalh9YNJWF+EgbHfNL6x4ZXKhTA2YSpZTe67S4JZquvbkxzywlEnrbnQ1O+75K/oXMJ8tjUPFuTS0kVxZ3x9
#vWNdHjVLCDGxO2HECfQ5HRf4D+V1LoF6wz6uM3HjsuZeUlSoPk7ivhv2uxOB1hCztz8CqfYRV4J9BOSkykDCArEM+cg+m8zDiiYQVVI9viuO9A
#yLRmhJLMssE9Bq3Z1VFL/BfH3kqZZPLBZ0Wdpex7uH7gNbtqWFYR2pOdZLNPgAsUfsKW62G6iBUhYdeIF356ljTh2zs5Tk0tXZeCFVWQecdcBZ
#HzgD6IMCAggeU0xkdvu84Bvca1zWvcalXeGAKQ/emEDGQPlTOTn5RhRPN7qMVqQdmay5cbaOBWHAa3oik8kD97J3pnWTe2aB6nhjeD93/Ch6jw
#0iWPaWUqBaVglSuv8PBg2Z9nGLGDOCmEGVAI3R7RhlCisBkRJEEHqC18JvULk050nFVelVngc9n2UaaRt4jK87Cr/fUF3kese41d9pdpUZQaEL
#C76jchTWCgQjCnsvw6E4zitMPXnivmfW9LmWBP059BNQzgzVntqsmN7BbR/Ioi/CBdFP7WxLfkjtSOYCKQf42pvvQPR/82uyUkPwUAX00zGGiZ
#fNw8wxmsbFPM4848t4fjrvBQWBCw2vcnRzB2+/AKqRS0OJwHtzUEZPII0FU8kPJHHLQoqOeJsC0IlLEz9uO1+4ivOK9eeL/FykXAoBbmF9u7sn
#hUXlBJfnw3uIkBHs7+6COFa3ThqEJ/Kw1YbUDRgxDD1B42bZGyWrr5dhJUrObBNv+YX7BdLaZcmdsp/K+aV5p8JHSCnnAVtFcP9dKo4Js5lzKV
#ZxyUzoElmQJMewf4zoPrjCrDnEkp17TSqrC+Xcr8Ulo5aVIvJo0DwyDk6UbrrWWpwXW52CVKZ7xaaNSr/YNgik7OpLx0H5IVGOCA93doE9EOtT
#rqhfUHXQPZcNmOwOtuAp9Kx8XWhRSkza8b1pXwOlYpsgSqeOjlM6ecWvxHA06rHnfCOPO7gech/1qNhcvNND0mJdtF5TIlQIndSHFXoAvdY5O1
#93/Ubq11wrbVxiXMkv7HtWq/7NniWrFlyhbWPwWszEyFGpsM+i4lNRvOPb62JXwZi4uBBRsvJaxML4FdRfX8IfG9oUpCMX8kg68UGTpN7mzwRB
#t+FJllkI0xbPPhuAcFEa8w2f6gfvMthFMsMlXg1madGX1Lvf5JmS0eiOYKHqqyz49ZzHgasSy5WZipXiGVPZ01l8pzcO2IB00HOmTjzOhTcROi
#9H+Fgiwocwv8AsNgnFWsg3d2r3ksAby0A1LmjlrJQ7YxldB3Jga4STMgiE8RiXNAX3QS+Fo7IKVQcyfh5gDnF78AP29hC0yp/P3nyXePKUCIb6
#za+jQF+nvckLl+dCDpwkpw8NsyUmEXTQC5copsywfJkSqUVKRepkIPDLFeyLOG4853R2ouYfk6MH5Lg57zQmJt0ouXp6zfSWJbjRgQHakA3aJR
#qLXribTKxU6hZ+VoIDONTZmbUsOfB7EbYCyNCLnK++8jo8iYkx38DuBnGpfVskU83ymGoblFpMEmo5NlGxqjMYfmd66cAgIXjCo8iByisgFKwz
#/QZpBvQc7QnSRvEJDruNZb7AIl/ghNMXw1EQLYLUlTIjEGvLNj4Nl4hq/k1MsButvX20R4LKwigMEsdo84NpPF8E3rxIw6cgfEwaKNMhi4fhJ9
#LC6YvXNMBIV7Rs7sN0O9phHiHRAAq9Al9z6k4vtxZHkwCL8/QCiQ1VljcJl/ilorFtVzIJbDfMq/wBVixyMhTioK3ctadttXmKKrO6g8KZC8Aj
#AY7Ithq3phhsphjkKdZSPsCXkoPdt8XIiRiZIBab8N4UeACmNoImB0dMO5hfY9wSugOGvG0jOKgfGKiSZ/NcJ3/77d8XOchLF/4w0yC4KeYc1k
#pUW10KzNnCuIv2cAFqcIdiXIewRjjDm4ZUfUUbv6Jo1lIQ0bGfhKMRNF0JE+hqLFOqIZcPVL+gDQPkwjCym33da5q4qokEWlfu28ZznhfZm+9w
#88PI9P0P66HROkB/gtTWOjYSIalROtZ3n1sH98RecyOLn778TCICattxttOfz6rXTIGT8SiiLrbKzhy5MzD7cOT3RyBzT8oPH+YtvKE1dknC0U
#u4EVxEAVxV4YssG8C0CUnkBqQR2sabzyphRfB5FapI3vSDfNQRQUTMx82Bh04wHbQpFiAcqZpyNwy76ZBpYQdK1kjlwDZOC7TB21x2QXl3gWmX
#lQfV0sENDYV8qqFUQ97S04qmDfSWHdqGctJ48+8RyRxm8iIJE61pCLBXkkJaB0oMocUWpBCHsAQ6LEDTTMlbjyWoiXpQ8QmYYNs3VLdPfg3m1L
#7nvm3AwKCa/bt/0Djd736b8wYV2FlpHEtibRVTH6gwxNMQ+MIlfU+uwInEW1U4oUG7q+L297QD2q8Dim5HKruOKGpd2uuQqu5G2F7eI8eT/nAK
#yz6Cqel7A/k2SBLQoOE+AO2FaLsCIs6PZvl71Qvoldql1oLLpIGP74qb6zviC3d31RaBGmJ4uKM2G1Zqs4I+SUB4FDHYJJKHYZQbyZKeP1I84t
#KV5XVLuyDopOTDsn1pbyKS5yhWehy0YgHr4lkGUuNLGBuQxmWnpAxvA6WicbwCj8MbS8bsNnOXJRMx1Gr6g265HEnstgK7KPtTYQuqIRLYJjjN
#QSLeFSkB5GoyvF5v8/XS2ie8x/4Jmida9f9DhPxpIUI4FayqtJCu0XyrEjfkBvyPajoRfW+aXe0gKIEPjDkcQRYgK47RTg5ZcEf6BGueEDMCpF
#Go57ZDa+kwfvPbLDV6cZzSEiu2QUt7nP3XL8mpMLEyZ6qdC21u3aljZ7UXrzuUoexkVaL3bdlKK26+C6Y0VntdOTcUe2Znl42xc9m4PLd13NMQ
#JVKUP4Q6jZpz2ikYHdWsy7HcFJJbQseN9zssCpf2l3B7KRdy3ldodkv8+PxYLMlAA1xJ30DtTH2Nixy1Svss0PGrdiAJ6UW0u9BnXmP7dlSiHG
#V0Q/VKrbwCDA+3mCgsGTZzyxYVCKXn2h4V7xY5/jTD4zHNMi5xm90E4e7zjaKH025Sq9lF2zn8emVpXUhbtpZdItIgaj1nCfs7LPPtI9GTidh6
#wr6T6pHahALKH3t0SJeI4WI2nGPnXV9b8CFnY48O7mCFzSvQgfREGldPXGtp21aJrYGqwuOK0zH21U1OY5xYLnTqagucqD7/8KuV/7W7L9eLpB
#LMVdTw5Sln1dhHPO3FsEQBj0Tj7REoTyFDvSiWoZ2JQGKCzSNLFLj5kUtu2wS/7AefTXvisARevRyHs/yOhCXgW2JXEV4DD9D2qvn5Z88//JG7
#whI7TecFghXtt50TD35b952T2B93Wodt581follNEsPTfcc82f3Q7LTuH+qBEpDpQ2P0s+uhi83FPpOtcd2hFK/ko6EWvCWcuhHviesZtE+BN8
#Mdl4rVymFUwRtFLrLdhTmMTq44hfGrz4bnuO0m5XAxk/eb2lSGFm2bxvjqjJidJkxBY9DkWO+E6cC9/UCNRU1LjihMgx0xnLu708HD/U3p8+GB
#LVVCPYD4Jv6PlFM+CtP6NJ6nRr6f4YWTIvLUTGaCymcIlYKUCVQ5Z8AAY1+3e+BQJUb69ttfBEDsQZIxEAcsiIi5HcMTOhOchEty+MfrqaZSoq
#cC1D9PEK9jVlzTR+GMVnW953DIFFBhWRTCHHdXiDGCtHFswkgwwArLNvFQihZDEmmEZ6l4cIOH2LqI7SOJzaXZaK8U0XdvlByRLvBzcHSqAApy
#TBoFQaNJISJu/Y6ovKSM/WE1bnH91lhQw/g8CyNYC9GHM3fdpCFOCafHmEsbAyyEMPtTAYXV2JTToEGDO9swguDl8s4Rx2Are75WimPf86sFzo
#bsQbXddmDfCJeI5YWUDVhnfk4A5JUGUYG+gAu/G5qi7hBJ3vy//BtJfv88gRa3T4pbR5cxzsT4xuM7qifRnfzhPnRjP0wRW7tPfXn0U7LYTG4D
#lGJieYHwEBmsonly6luRwhfjLatbG+mb7yKmmemb7wrvNhC+KiivyOQfzWZRwS2qAIKx2oShQENJrlBuxwDNEZJFLvUypIWnIC08HdKikI7ozN
#YKJTt3jANcEAm6UiSgHQm5VUM2d9KoUSGtv/3l39PmndBKUsS8QNyFIcyXBNi1aUsLhXyPQ4GbavsqJOZUW1N//PTZE+Mj89Hp6ZPnp0+MmvH4
#2dPHxkcnnz09rbanfsGysKuFY9w37o9a+/DTaovfB6MHn7beN1oHi/ejw/p+4/A1xmSU0s2FDjSN0hRFghYy0sVHiTcs+pRfYMrB1FZSILWgQf
#qec+Eq+fy8O5haF3b3gl+5SZebetG9OOH9KEv3BEcbnOcYeTdTG09csDyDuQgfggSqHPHPcLcxW587zU0vXN/ll/Q5XuZehCD68qGOlz3Ui93d
#vWDBmiMdexmIK17G/g30oRfu0QXt5/iY12k6PsgzFyxm+8p6/u2//o+Me581MkK+x8XeM6I5EAijiBWFIKrtEZrO/Qk/Nm8vh8erbOj//p+NR9
#/EKF7gLirhMuICh14WGbrrbbh047DEl/+LGio6FsdHdK0qiXU8fFPquh/PJzP0MFfxqsNzu5Qr1AkLqI0cZDgLekJchNfXOyqvEJJlo1aqVSFa
#zGKWhxehfRHW6+tCsZ9iobjF7WQxFY3XD6nwLOZffHLk6h22URt1zdny3FXVUpEtnDfiQRYf4bPjLK63OlkMHbW0i015zLyNugTHY+snUXeuFT
#V8XBp7YxH233yHTsGSN8BaihCpWSPcXFjJjXf7WmoWFvILWG3e/uI3YvUwu4XxEdxAj3xxER65zWM2vvaWIIjovViH0WjZoIz1yG+/5/WHwpup
#V3A9nR598MGx+cEHNbMz7VYhU5ALtLMzVb7+yPpsaJGEpC7SET/VXPTmgvthiHRnPhOt5qameY8LMHqGpjTl3i/GryTgLE1IuIik6P2EvBOStL
#je6klDaoCOR3HBgBQ4alR6QcC7IJAWIcFgXM1Mwkfkkj4+9uzSGq/iGl8EFzKUsZL4t3/Am2+FECxLE/XMZxL6SF1pwEfqWQH2qNgiWXGhJLX3
#cyjsk6zMGdsldF/oM+gvWNKGKFO5d3CNLnZgrVVjKDixLmQgymo90I/zjVjJR2ce4l6F3DUCXpmGILthALKq7s82O1/P7+XiI6PievAF8awMlE
#MLDqLs/D8bYqLKluShoE+CDPIlKGf/7YZiwYA5Sqyl/ahOAVXlQqhLJyGouLCkCMWHlCDgLpOY/CMf9pKjxzBC0PlxyFBhCnPt7b/4N7h46q2H
#FVRHqBSR5niy61F1uvKJjgW3kcq9Kk7kU579MW8Ws7hDIZUVNOrxDj3txFMB7XYx2xrek3lGVyZKg+xRliUhdGSAG6KhVwcu08egRuLwnMvmuK
#EXvWx6W8lbWVOeXwchkp/H5S+3vBUHf5jEjxItES8mjETRu8k3NdBdU0HercCFgOlmig33rOioELq1MMvhIJwqWIkzQa3nyo20R0tcDiMBlOy6
#ZjIx7XyRp9CNYnUOhfyQSyK4nO+gBGBLOYJxN0AaH4ImD1JbHWN4084MkTAI9nHSj5G8cv/Fi0+9ZJy6IsQtdVMFPlKcOY0Y32k2KMsKx90YXU
#0xoX1TryPXStGfSkfjuL3br6/DrBKkBVh9DjbBYn5hSLocTOU08abpIEgawWAA3/YIfR6Dvmti080ubgaX0kHmj+DeMnEh3qMIcoryqRoFPbO0
#V+tC48g1OY9KfnNf4Pmc8rmlgnPBpwKEhIfMkoA/N3WcIJNsd3fnpr7b3S30F1IVfZ7Si8LtQZs3Phu95vH9lw/LyAPHSB8doo/1bb2Cpy3v3C
#O3dwRHiy3Ir+/aOe/SC06JCYBU6t7QD2EH5nKuTaBIzD3eVUqqGuSicN5VXPN2soKEwu1+s9Qb5jpT7W0znVPZ0j0XQ3cjME3lqqg7vZGV2qcY
#6Dtzls6VQyEA3bNzTRSNxm6YPhtbDEZKQcEx5Rmt2Gfm27/7R15gJxTRcepNBSxWrt+dOzItKLP6YqwlZP08Tym1SWCOW7RJyqupuzJvND423/
#7iPxhC+qCt7ygc4zYKIj3+n6pc9F0WL3hceIV8FqI5KHE5JYHv7uIZmrpFDya27LbR5CZ/nmORqi9BaHXtS/SQ5ggKSTUDwWhjgKJj3hO//9XP
#/i+DcIMj/HgRREVFXC8E+UMpT2QEfZjG8lw77Zzk0BwFQgMqw2FVDGqSz7HJdkaDh3EcFP6IZSSaTvUH9kTAcmB0NKVmPXD0RHLy1QXmhYCs8L
#NqsSCmUKHURikcEAfhYzlJszrESwXnSTrTOLMa6dg2bcevSuF7SV9LJHojkb0BTCXReQrF0hLoc/nZF6I9ihZxdPmcDpGM5dgLkmOscG1XQOwN
#bkaBXJ+f6861PjrPysakOzr4/koaY7vAMF+y5ddZTUt9Dm1PR7u76UgFl1KXesLwXJ5+ZDdwe52FSCb75+rqSx4eDYSs985j/KcRADNXbsh0C5
#+Cnfn9v4ZlvOPKsUUWJdiSEhrPzzvkCyO+vgf84t2+X3qTKObS/SMHoo5QfNiM24FGNrDkqvkGL1DMOtQCNXGPJgqPZkt9rD9p1fHw7u5qAy1W
#uKpnmkjAlctO+cObyUy3WwZ6A4l94iW4eJeQ22AoxwPSbdJ5b4IkCp+yVRQao34JXVqGgUQfXnuFU/4nwRXaVvRi4D4UCB4yJAEQcBn2G6d+PB
#2EycQyH488CsicebDWv/nOePTiqXGMEpIsEf1x0Uwal3o0xYq9vip9OyXmSpgQAKrmXzTl6RfZG6tQpCafN5VyUS+Iyii4OkY6un9k4SD0hUtT
#QcU3uQhvAaXq+mTeQuT3wOuAVWan3NBtqxaJL2pRajWdpJHQQtQ+aNqOXNBqDxyc4P/uFwYF337zazQqy9fcl8Jo1YLFFhfon//MkEMxyYeC02
#vjSK3mPG//5W8MPAVOUCrQRQLj5Qw74kplnoaTmZb33NbNPphckFV6eCaWt0saNfzkyZeEQQwNmBf3GUpYq4RTPNsMKSVe52puZWF60oqSyriu
#bHiEGmcgreW64lZ5307GPw1fqwn0TsCHAtSQwgabGyBZOV6aSOC02wVcuHQ7cJmfhDMkw7SBm9QqDvbl5WXjCsqf94D84sleOABiCb7yZqGZsy
#I8Di/gd6US1H8RRwqVVrOEhsdd9ZYlKXj3AlSwAHGVzHoddLFi+pr5nqnLDHmkaehoLel81n80z+Ld3eKzz5OoDG4HTx+PAiA53s1xDpsCWy7E
#zsKykZkgZ5URfoEU4enDPe6sI7hC5DL8HWWT6OgH/x9uTW7FrooCAA==
