# Prueba rápida: muestra un toast y reproduce el sonido del burro (🫏).
# Sirve para verificar en cualquier momento que notificación + audio funcionan,
# sin esperar a la hora programada ni pasar -Mode.

$BurroAudio = Join-Path $PSScriptRoot 'audio\Tonos Graciosos Para Celular - Burro Shrek.mp3'

# --- Toast -------------------------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$textNodes = $template.GetElementsByTagName('text')
$textNodes.Item(0).AppendChild($template.CreateTextNode('Notificación de prueba')) | Out-Null
$textNodes.Item(1).AppendChild($template.CreateTextNode('Las alertas funcionan correctamente')) | Out-Null
$toast = New-Object Windows.UI.Notifications.ToastNotification $template
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Organiza Tu Dia').Show($toast)
Write-Host 'Toast de prueba enviado!'

# --- Sonido del burro (MCI / winmm.dll, nativo, sin ventanas) ----------------
if (Test-Path $BurroAudio) {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'OrganizaTuDia.Mci').Type) {
            Add-Type -Name Mci -Namespace OrganizaTuDia -MemberDefinition @'
[DllImport("winmm.dll", CharSet=CharSet.Auto)]
public static extern int mciSendString(string cmd, System.Text.StringBuilder ret, int len, System.IntPtr hwnd);
'@
        }
        $alias = 'burro_' + $PID
        [OrganizaTuDia.Mci]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero) | Out-Null
        $rc = [OrganizaTuDia.Mci]::mciSendString("open `"$BurroAudio`" type mpegvideo alias $alias", $null, 0, [IntPtr]::Zero)
        if ($rc -eq 0) {
            # Solo los primeros 6 segundos (6000 ms).
            [OrganizaTuDia.Mci]::mciSendString("play $alias from 0 to 6000 wait", $null, 0, [IntPtr]::Zero) | Out-Null
            [OrganizaTuDia.Mci]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero) | Out-Null
            Write-Host 'Burro reproducido (6 s)!'
        }
    } catch { Write-Host "Audio no disponible: $_" }
}
