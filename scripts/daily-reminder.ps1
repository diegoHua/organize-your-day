# =============================================================================
#  Organiza tu día — Notificaciones toast modernas de Windows 10/11
# =============================================================================
#  Notificación nativa (fondo oscuro, esquinas redondeadas, se desliza desde la
#  esquina superior derecha y queda en el Centro de Acciones) usando
#  [Windows.UI.Notifications].
#
#  El mismo script sirve para VARIOS momentos del día y elige el contenido
#  según la hora a la que se ejecuta (o el parámetro -Mode):
#
#     mañana   (07:55 y 09:00)  -> 🐱 gatito,  "planifica tu día"
#     mediodía (12:00)          -> 🐶 perro escéptico, "¿cómo va la carga?"
#     tarde    (16:00)          -> 🐶 perro escéptico, "recta final"
#
#  Cada momento muestra una foto grande (imagen "hero") + un círculo con la
#  carita + una frase chistosa que rota cada día.
#
#  NO usa BurntToast ni ningún módulo. NO usa VBScript ni MsgBox.
#  Se guarda como UTF-8 con BOM (acentos y emojis correctos en PowerShell 5.1).

param(
    # mañana | mediodia | tarde   (vacío = autodetecta por la hora actual)
    [ValidateSet('', 'manana', 'mediodia', 'tarde')]
    [string]$Mode = ''
)

$BurroAudio = Join-Path $PSScriptRoot 'audio\Tonos Graciosos Para Celular - Burro Shrek.mp3'

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Reproduce un MP3 de fondo (el burro 🫏) con MCI (winmm.dll). Nativo de Windows,
# sin módulos ni ventanas. Solo suenan los primeros $MaxMs milisegundos (6 s por
# defecto). Bloquea hasta que termina ese tramo; se llama DESPUÉS de mostrar el
# toast y es best-effort: nunca lanza, así que jamás rompe la notificación
# aunque falle el sonido.
# -----------------------------------------------------------------------------
function Play-Audio {
    param([string]$Path, [int]$MaxMs = 6000)
    if (-not (Test-Path $Path)) { return }
    try {
        if (-not ([System.Management.Automation.PSTypeName]'OrganizaTuDia.Mci').Type) {
            Add-Type -Name Mci -Namespace OrganizaTuDia -MemberDefinition @'
[DllImport("winmm.dll", CharSet=CharSet.Auto)]
public static extern int mciSendString(string cmd, System.Text.StringBuilder ret, int len, System.IntPtr hwnd);
'@
        }
        $alias = 'burro_' + $PID
        [OrganizaTuDia.Mci]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero) | Out-Null
        $rc = [OrganizaTuDia.Mci]::mciSendString("open `"$Path`" type mpegvideo alias $alias", $null, 0, [IntPtr]::Zero)
        if ($rc -ne 0) { return }
        [OrganizaTuDia.Mci]::mciSendString("play $alias from 0 to $MaxMs wait", $null, 0, [IntPtr]::Zero) | Out-Null
        [OrganizaTuDia.Mci]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero) | Out-Null
    } catch { }
}

# --- Identidad de la app (idéntica en registro, shortcut y notifier) ----------
$AppId       = 'OrganizaTuDia.DailyReminder'
$DisplayName = 'Organiza tu d' + [char]0x00ED + 'a'   # "Organiza tu día"

# --- Rutas (derivadas del propio script para evitar acentos en literales) -----
$scriptDir   = $PSScriptRoot
$repo        = Split-Path $scriptDir -Parent
$iconPath    = Join-Path $scriptDir 'icon.png'         # icono de respaldo
$shortcutDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcut    = Join-Path $shortcutDir 'Organiza tu dia.lnk'

# -----------------------------------------------------------------------------
# Icono de respaldo (amanecer) la primera vez. Best-effort.
# -----------------------------------------------------------------------------
function Ensure-Icon {
    param([string]$Path)
    if (Test-Path $Path) { return }
    try {
        Add-Type -AssemblyName System.Drawing
        $s = 128
        $bmp = New-Object System.Drawing.Bitmap $s, $s
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Transparent)
        $rect = New-Object System.Drawing.Rectangle 0, 0, $s, $s
        $c1 = [System.Drawing.Color]::FromArgb(255, 255, 138, 0)
        $c2 = [System.Drawing.Color]::FromArgb(255, 255, 61, 119)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 50
        $g.FillEllipse($brush, 1, 1, $s - 2, $s - 2)
        $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $r = 24
        $g.FillEllipse($white, ($s / 2 - $r), ($s / 2 - $r - 4), 2 * $r, 2 * $r)
        $g.Dispose()
        $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    } catch { }
}
Ensure-Icon -Path $iconPath

# -----------------------------------------------------------------------------
# Recorta una imagen a una proporción dada, anclando hacia ARRIBA (para
# conservar las caras/cejas en fotos verticales). Cachea el resultado.
# -----------------------------------------------------------------------------
function Get-Crop {
    param(
        [string]$Src, [string]$Dst,
        [double]$AspectW, [double]$AspectH,
        [double]$TopAnchor = 0.0   # 0 = recorta desde arriba, 0.5 = centrado
    )
    if (-not (Test-Path $Src)) { return $null }
    if ((Test-Path $Dst) -and (Get-Item $Dst).LastWriteTime -ge (Get-Item $Src).LastWriteTime) {
        return $Dst
    }
    try {
        Add-Type -AssemblyName System.Drawing
        $img = [System.Drawing.Image]::FromFile($Src)
        $sw = $img.Width; $sh = $img.Height
        $target = $AspectW / $AspectH
        $srcRatio = $sw / $sh
        if ($srcRatio -gt $target) {
            $ch = $sh; $cw = [int]($sh * $target)
            $x = [int](($sw - $cw) / 2); $y = 0
        } else {
            $cw = $sw; $ch = [int]($sw / $target)
            $x = 0; $y = [int](($sh - $ch) * $TopAnchor)
        }
        $bmp = New-Object System.Drawing.Bitmap $cw, $ch
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $srcRect = New-Object System.Drawing.Rectangle $x, $y, $cw, $ch
        $dstRect = New-Object System.Drawing.Rectangle 0, 0, $cw, $ch
        $g.DrawImage($img, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()
        $bmp.Save($Dst, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $bmp.Dispose(); $img.Dispose()
        return $Dst
    } catch { return $Src }   # si algo falla, usa el original
}

# -----------------------------------------------------------------------------
# Registrar el AppUserModelID en el registro (nombre + icono del toast).
# -----------------------------------------------------------------------------
try {
    $regPath = "HKCU:\Software\Classes\AppUserModelId\$AppId"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    New-ItemProperty -Path $regPath -Name 'DisplayName' -Value $DisplayName -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $regPath -Name 'IconUri' -Value $iconPath -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $regPath -Name 'IconBackgroundColor' -Value 'FF2D2D30' -PropertyType String -Force | Out-Null
} catch { Write-Host "Aviso: no se pudo registrar el AppId en el registro: $_" }

# -----------------------------------------------------------------------------
# Crear (una sola vez) el acceso directo del menú Inicio con AppUserModelID.
# Método oficial vía COM IShellLink + IPropertyStore. Best-effort.
# -----------------------------------------------------------------------------
if (-not (Test-Path $shortcut)) {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'OrganizaTuDia.ShortcutHelper').Type) {
            Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace OrganizaTuDia
{
    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    internal class CShellLink { }

    [ComImport, Guid("000214F9-0000-0000-C000-000000000046"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IShellLinkW
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder f, int cch, IntPtr pfd, uint flags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder n, int cch);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string n);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder d, int cch);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string d);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder a, int cch);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string a);
        void GetHotkey(out short k);
        void SetHotkey(short k);
        void GetShowCmd(out int c);
        void SetShowCmd(int c);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder p, int cch, out int i);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string p, int i);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string r, uint res);
        void Resolve(IntPtr hwnd, uint flags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string f);
    }

    [ComImport, Guid("0000010b-0000-0000-C000-000000000046"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPersistFile
    {
        void GetClassID(out Guid id);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string f, uint mode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string f, [MarshalAs(UnmanagedType.Bool)] bool remember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string f);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string f);
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPropertyStore
    {
        void GetCount(out uint c);
        void GetAt(uint i, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant pv);
        void SetValue(ref PropertyKey key, ref PropVariant pv);
        void Commit();
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct PropertyKey
    {
        public Guid fmtid;
        public uint pid;
        public PropertyKey(Guid f, uint p) { fmtid = f; pid = p; }
    }

    [StructLayout(LayoutKind.Explicit, Size = 24)]
    internal struct PropVariant
    {
        [FieldOffset(0)] public ushort vt;
        [FieldOffset(8)] public IntPtr pointerValue;
    }

    public static class ShortcutHelper
    {
        const ushort VT_LPWSTR = 31;
        static PropertyKey PKEY_AppUserModel_ID =
            new PropertyKey(new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

        [DllImport("ole32.dll")]
        static extern int PropVariantClear(ref PropVariant pv);

        public static void Create(string lnk, string target, string args,
                                  string workDir, string icon, string appId)
        {
            IShellLinkW link = (IShellLinkW)new CShellLink();
            link.SetPath(target);
            if (!string.IsNullOrEmpty(args))    link.SetArguments(args);
            if (!string.IsNullOrEmpty(workDir)) link.SetWorkingDirectory(workDir);
            if (!string.IsNullOrEmpty(icon))    link.SetIconLocation(icon, 0);

            IPropertyStore store = (IPropertyStore)link;
            PropVariant pv = new PropVariant();
            pv.vt = VT_LPWSTR;
            pv.pointerValue = Marshal.StringToCoTaskMemUni(appId);
            PropertyKey key = PKEY_AppUserModel_ID;
            store.SetValue(ref key, ref pv);
            store.Commit();
            PropVariantClear(ref pv);

            ((IPersistFile)link).Save(lnk, true);
        }
    }
}
'@
        }
        $ps = (Get-Command powershell.exe).Source
        $args = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        $iconForLnk = if (Test-Path $iconPath) { $iconPath } else { "$ps,0" }
        [OrganizaTuDia.ShortcutHelper]::Create($shortcut, $ps, $args, $repo, $iconForLnk, $AppId)
        Write-Host "Acceso directo creado con AppUserModelID."
    } catch {
        Write-Host "Aviso: no se pudo crear el acceso directo (el toast funciona igual por registro): $_"
    }
}

# -----------------------------------------------------------------------------
# Fecha dinámica en español:  "lunes 22-jun-2026"
# -----------------------------------------------------------------------------
$ci    = [System.Globalization.CultureInfo]::GetCultureInfo('es-ES')
$now   = Get-Date
$dia   = $now.ToString('dddd', $ci)
$num   = $now.ToString('dd', $ci)
$mes   = $now.ToString('MMM', $ci).TrimEnd('.').ToLower()
$anio  = $now.ToString('yyyy', $ci)
$fecha = "$dia $num-$mes-$anio"

# -----------------------------------------------------------------------------
# Determinar el momento del día.
# -----------------------------------------------------------------------------
if (-not $Mode) {
    $h = $now.Hour
    if     ($h -lt 11) { $Mode = 'manana'   }
    elseif ($h -lt 15) { $Mode = 'mediodia' }
    else               { $Mode = 'tarde'    }
}

# -----------------------------------------------------------------------------
# Imágenes disponibles — se rota una distinta cada día
$imgDir = Join-Path $scriptDir 'img'
$gatos  = @(Get-ChildItem (Join-Path $imgDir 'gato') -Filter '*.jpg' | Select-Object -ExpandProperty FullName)
$perros = @(Get-ChildItem (Join-Path $imgDir 'perro') -Filter '*.jpg' | Select-Object -ExpandProperty FullName)
$burro  = Join-Path $imgDir 'burroo.png'

# Seleccion aleatoria — distinta cada vez que corre
$mananaPool = @($gatos) + @($burro)
$gato  = Get-Random -InputObject $mananaPool
$perro = Get-Random -InputObject $perros

switch ($Mode) {
    'manana' {
        $titulo = $DisplayName
        $foto   = $gato
        $pie    = "$fecha · planifica tu bloque"
        $boton  = '¡A darle! 🚀'
        $frases = @(
            '¡Chócalas! 🐾 Hoy la vas a romper.',
            'El gato ya está en modo productivo. ¿Y tú? 😼',
            '¡Arriba esas patas! A planificar tu bloque. 🙌',
            'Menos maullar, más avanzar. ¡Vamos con todo! 🐱',
            'Otro día para ser legendario (el gato lo confirma). ✨',
            'Estírate como gato y dale con ganas al día. ☀️🐾',
            'Hoy toca comerte el mundo (y de premio, un atún). 🐟',
            'Modo felino activado: enfócate y caza tu día. 🎯',
            'Si el gato se ve así de épico, tú también puedes. 💪',
            'Plan de hoy: 1) café ☕  2) planificar  3) conquistar.',
            'Respira, ronronea un poco y a por todas. 😸',
            '7 vidas, pero este día solo se vive una vez. ¡Aprovéchalo! 🐈'
        )
    }
    'mediodia' {
        $titulo = 'Pausa de mediodía 🐶'
        $foto   = $perro
        $pie    = "$fecha · revisión de mediodía"
        $boton  = 'Sigo en ello 💪'
        $frases = @(
            'El perro te vigila: ¿de verdad vas avanzando? 🤨',
            '¿Cómo va la carga? Si es mucha, prioriza UNA cosa.',
            'Mmm... ¿cerraste pendientes o solo abriste pestañas? 🤨',
            'Medio día hecho. ¿Vamos por buen camino?',
            'Check rápido: 1 logro de la mañana y 1 pendiente.',
            '¿Lo importante de hoy ya está en marcha? 🤨',
            'Hidrátate 💧, estírate y revisa tu avance.',
            '¿Hace falta reordenar el día? Buen momento para hacerlo.'
        )
    }
    'tarde' {
        $titulo = '¿Cómo vamos? Recta final 🐶'
        $foto   = $perro
        $pie    = "$fecha · revisión de la tarde"
        $boton  = 'Cerrando 🏁'
        $frases = @(
            'Recta final: ¿qué falta por cerrar hoy? 🤨',
            'El perro sigue mirando... ¿avanzaste de verdad?',
            'Últimas horas buenas: elige 1 cosa y termínala.',
            '¿El día fue acorde al plan o se desvió? 🤨',
            '¿Qué dejas listo para el tú de mañana?',
            'Suelta lo que no es de hoy. Cierra lo que sí.',
            'Si avanzaste en lo importante, festéjalo. 🎉',
            'Antes de soltar el día: anota dónde quedaste.'
        )
    }
}

$frase = $frases[$now.DayOfYear % $frases.Count]

# Recortes: hero (2:1, ancho) y logo (1:1), ambos anclados arriba.
$base    = Join-Path $scriptDir ([System.IO.Path]::GetFileNameWithoutExtension($foto))
$heroSrc = Get-Crop -Src $foto -Dst "${base}_hero.jpg" -AspectW 2 -AspectH 1 -TopAnchor 0.0
$logoSrc = Get-Crop -Src $foto -Dst "${base}_logo.jpg" -AspectW 1 -AspectH 1 -TopAnchor 0.0
if (-not $logoSrc) { $logoSrc = $iconPath }

# -----------------------------------------------------------------------------
# Construir y mostrar el toast.
# -----------------------------------------------------------------------------
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]          | Out-Null

$heroLine = ''
if ($heroSrc) { $heroLine = "<image placement=`"hero`" src=`"$heroSrc`"/>" }

$logoLine = "<image placement=`"appLogoOverride`" hint-crop=`"circle`" src=`"$logoSrc`"/>"

$toastXml = @"
<toast scenario="reminder" activationType="protocol" launch="ms-actioncenter:">
  <visual>
    <binding template="ToastGeneric">
      $heroLine
      $logoLine
      <text>$titulo</text>
      <text>$frase</text>
      <text>$pie</text>
    </binding>
  </visual>
  <audio silent="true"/>
  <actions>
    <action content="$boton" arguments="dismiss" activationType="system"/>
  </actions>
</toast>
"@

$doc = New-Object Windows.Data.Xml.Dom.XmlDocument
$doc.LoadXml($toastXml)

$toast    = New-Object Windows.UI.Notifications.ToastNotification $doc
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
$notifier.Show($toast)

# Sonido de fondo (el burro) — DESPUÉS de mostrar el toast, para que un fallo de
# audio nunca impida que salga la notificación. Bloquea hasta que termina el MP3.
Play-Audio -Path $BurroAudio

Write-Host "Toast mostrado [$Mode]."
Write-Host "  Titulo: $titulo"
Write-Host "  Frase : $frase"
