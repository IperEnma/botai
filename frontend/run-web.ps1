# Run Flutter web on fixed port for Google OAuth to work
Write-Host "Starting Flutter web on http://localhost:5000" -ForegroundColor Green
Write-Host "Make sure this origin is configured in Google Cloud Console:" -ForegroundColor Yellow
Write-Host "  - http://localhost:5000" -ForegroundColor Cyan
Write-Host "  - http://localhost" -ForegroundColor Cyan
Write-Host ""

flutter run -d chrome --web-port=5000
