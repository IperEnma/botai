# Flutter web en modo servidor (mismo criterio que start-dev.ps1).
# No abre Chrome; cuando compile, abri la URL en el navegador.
param(
    [int]$Port = 5173,
    [string]$HostName = "127.0.0.1"
)

$webUrl = "http://${HostName}:${Port}/"
Write-Host "Flutter web-server en $webUrl" -ForegroundColor Green
Write-Host "Agenda publica (ej.): ${webUrl}#/agenda/public/search" -ForegroundColor Cyan
Write-Host "Para OAuth en otro puerto: .\run-web.ps1 -Port 5000" -ForegroundColor DarkGray
Write-Host ""

flutter pub get
flutter run -d web-server --web-port=$Port --web-hostname=$HostName
