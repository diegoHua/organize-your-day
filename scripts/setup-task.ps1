# =============================================================================
#  Registra/actualiza la tarea programada del recordatorio diario.
#
#  Uso:
#     powershell -ExecutionPolicy Bypass -File setup-task.ps1
#     powershell -ExecutionPolicy Bypass -File setup-task.ps1 -TestNow
#
#  La tarea dispara en VARIOS momentos del día; el script daily-reminder.ps1
#  elige el contenido (gato/perro y frases) según la hora:
#     07:55  -> arranque   (gato:  planifica tu día)
#     09:00  -> recordatorio por si encendiste tarde (gato)
#     12:00  -> mediodía    (perro: ¿cómo va la carga?)
#     16:00  -> tarde       (perro: recta final)
#
#  -TestNow  añade además un disparador único ~2 minutos en el futuro para
#            comprobar el flujo del Programador de tareas.
#
#  No requiere ejecutarse como administrador (RunLevel Limited, logon
#  Interactive) para que el toast se muestre en la sesión del usuario.
# =============================================================================

param([switch]$TestNow)

$scriptPath = Join-Path $PSScriptRoot 'daily-reminder.ps1'
$taskName   = 'OrganizaTuDia - Recordatorio diario'
$user       = "$env:USERDOMAIN\$env:USERNAME"

# Eliminar la versión anterior.
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Acción: lanzar el script de toast sin ventana de consola.
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Disparadores diarios (el script decide el contenido por la hora).
$horas = @('07:55', '09:00', '12:00', '16:00')
$triggers = foreach ($h in $horas) { New-ScheduledTaskTrigger -Daily -At $h }
if ($TestNow) {
    $triggers += New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2)
}

# StartWhenAvailable -> si la laptop estaba apagada a una hora programada, se
# ejecuta en cuanto el equipo vuelve a estar disponible (tras encender/iniciar
# sesión). El contenido se ajusta a la hora real en que finalmente corre.
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName `
    -Action $action -Trigger $triggers -Settings $settings `
    -User $user -RunLevel Limited | Out-Null

Write-Host "Tarea '$taskName' configurada."
Write-Host "  Horas: $($horas -join ', ')"
Write-Host "  Script: $scriptPath"
if ($TestNow) {
    $when = (Get-Date).AddMinutes(2).ToString('HH:mm:ss')
    Write-Host "  Prueba: disparador unico anadido para ~$when (en ~2 minutos)."
}
