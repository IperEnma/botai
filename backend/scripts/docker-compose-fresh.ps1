# Elimina contenedores y volumen, levanta de nuevo. Ejecutar cuando cambies usuario/contraseña de Postgres.
# Uso: .\backend\scripts\docker-compose-fresh.ps1 (desde la raíz del proyecto)

# Ir a la raíz del proyecto (2 niveles arriba de scripts)
Set-Location $PSScriptRoot\..\..

docker-compose down -v
docker-compose up -d
Write-Host ""
Write-Host "Espera ~30 s a que Postgres pase el healthcheck; la app se levanta sola si depende del servicio postgres." -ForegroundColor Yellow
Write-Host "Si la app no arranca, revisa: docker logs chatbot-postgres" -ForegroundColor Gray
