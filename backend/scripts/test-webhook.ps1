# Pruebas del webhook desde PowerShell (UTF-8 para acentos y ñ)
# Uso: .\scripts\test-webhook.ps1   o   .\scripts\test-webhook.ps1 -Text "tu mensaje"
#       .\scripts\test-webhook.ps1 -EdgeCasesOnly   solo casos borde

param(
    [string] $BaseUri = "http://localhost:8080/api/v1/webhook/message",
    [string] $UserId = "u1",
    [string] $ConversationId = "u1@web",
    [string] $Text,
    [switch] $EdgeCasesOnly
)

# Que la consola muestre bien acentos y ñ (evita ver "Â¿" en vez de "¿")
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Send-ChatMessage {
    param(
        [string] $Message,
        [string] $Label = "",
        [string] $Uid = $UserId,
        [string] $Cid = $ConversationId
    )
    $json = (@{ userId = $Uid; conversationId = $Cid; text = $Message } | ConvertTo-Json -Compress)
    $body = [System.Text.Encoding]::UTF8.GetBytes($json)
    try {
        $resp = Invoke-RestMethod -Method POST -Uri $BaseUri -ContentType "application/json; charset=utf-8" -Body $body
        if ($Label) { Write-Host "  -> intent: $($resp.intentSource)" -ForegroundColor DarkGray }
        return @{ ok = $true; text = $resp.text; intentSource = $resp.intentSource; response = $resp }
    } catch {
        $status = ""
        if ($_.Exception.Response) { $status = $_.Exception.Response.StatusCode.value__ }
        Write-Host "  ERROR: $status - $($_.Exception.Message)" -ForegroundColor Red
        return @{ ok = $false; error = $_.Exception.Message }
    }
}

function Show-Response {
    param($r)
    if (-not $r) { return }
    if ($r.ok) {
        $txt = if ($r.text) { $r.text.Substring(0, [Math]::Min(200, $r.text.Length)) + $(if ($r.text.Length -gt 200) { "..." }) } else { "(vacío)" }
        Write-Host "  Respuesta: $txt" -ForegroundColor Green
    }
}

# --- Un solo mensaje por parámetro ---
if ($Text) {
    $r = Send-ChatMessage -Message $Text
    Show-Response $r
    exit
}

# --- Suite estándar (FAQ + UTF-8) ---
if (-not $EdgeCasesOnly) {
    Write-Host "=== FAQ: saludo ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "hola" -Label "faq"
    Show-Response $r
    Write-Host ""

    Write-Host "=== FAQ: horario ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "cual es el horario" -Label "faq"
    Show-Response $r
    Write-Host ""

    Write-Host "=== FAQ: contacto ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "quiero contactar" -Label "faq"
    Show-Response $r
    Write-Host ""

    Write-Host "=== Con acentos (UTF-8) ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "cuál es el horario" -Label "utf8"
    Show-Response $r
    Write-Host ""

    Write-Host "=== RAG: limpieza / precios ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "¿Cuánto cuesta una limpieza?"
    Show-Response $r
    Write-Host ""

    Write-Host "=== RAG: urgencias ===" -ForegroundColor Cyan
    $r = Send-ChatMessage -Message "¿Atendéis urgencias?"
    Show-Response $r
    Write-Host ""
}

# --- Casos borde ---
Write-Host "========== CASOS BORDE ==========" -ForegroundColor Yellow

Write-Host "`n--- Mensaje vacío ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message ""
Show-Response $r

Write-Host "`n--- Solo espacios ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "   `t  `n  "
Show-Response $r

Write-Host "`n--- Solo números ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "123 456"
Show-Response $r

Write-Host "`n--- Solo símbolos ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "??? !!! @#$%"
Show-Response $r

Write-Host "`n--- Caracteres especiales (comillas y barra) ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message 'Pregunta "entre comillas" y barra \ backslash'
Show-Response $r

Write-Host "`n--- Unicode / ñ y acentos ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "Niño, mañana, caña, pingüino"
Show-Response $r

Write-Host "`n--- Emojis ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "Hola 😀 ¿horario? 🦷"
Show-Response $r

Write-Host "`n--- Mensaje muy largo ---" -ForegroundColor Cyan
$long = "hola " + ("palabra " * 500)
$r = Send-ChatMessage -Message $long
Show-Response $r

Write-Host "`n--- Pregunta ambigua / fuera de contexto ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "¿Qué hora es en Tokio?"
Show-Response $r

Write-Host "`n--- Múltiples preguntas en uno ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "Horario, precio limpieza y si atendéis niños"
Show-Response $r

Write-Host "`n--- Otro usuario (conversationId distinto) ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "¿Cuánto es la primera visita?" -Uid "u2" -Cid "u2@web"
Show-Response $r

Write-Host "`n--- RAG: keyword parcial ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "blanqueamiento"
Show-Response $r

Write-Host "`n--- RAG: ortodoncia ---" -ForegroundColor Cyan
$r = Send-ChatMessage -Message "¿Hacen ortodoncia?"
Show-Response $r

Write-Host "`n========== FIN CASOS BORDE ==========" -ForegroundColor Yellow
