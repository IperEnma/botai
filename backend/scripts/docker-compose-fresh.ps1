# Elimina contenedores y volumen, levanta de nuevo. Ejecutar cuando cambies usuario/contraseña de Postgres.
# Uso: .\backend\scripts\docker-compose-fresh.ps1 (desde la raíz del proyecto)

# Ir a la raíz del proyecto (2 niveles arriba de scripts)
Set-Location $PSScriptRoot\..\..

# En Windows, los .sql con CRLF pueden romper el init de Postgres; normalizar a LF
$sqlDir = "backend\src\main\resources"
foreach ($f in @("schema.sql", "data.sql")) {
    $path = Join-Path $sqlDir $f
    if (Test-Path $path) {
        $fullPath = (Resolve-Path $path).Path
        $content = [System.IO.File]::ReadAllText($fullPath)
        if ($content -match "`r`n") {
            $content = $content -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($fullPath, $content)
            Write-Host "LF normalizado: $path" -ForegroundColor Gray
        }
    }
}

docker-compose down -v
docker-compose up -d
Write-Host ""
Write-Host "Espera ~30 s a que Postgres pase el healthcheck; la app se levanta sola si depende del servicio postgres." -ForegroundColor Yellow
Write-Host "Si la app no arranca, revisa: docker logs chatbot-postgres" -ForegroundColor Gray
