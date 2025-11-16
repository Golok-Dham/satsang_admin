# Build for JavaScript (standard web build)
# Use this if WASM has compatibility issues

Write-Host "🔨 Building Satsang Admin with JavaScript (CanvasKit)..." -ForegroundColor Green
Write-Host ""

# Build with JavaScript compiler and CanvasKit renderer
flutter build web --release --web-renderer canvaskit

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host "📁 Output: build/web/" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test locally:" -ForegroundColor Yellow
Write-Host "  cd build/web" -ForegroundColor White
Write-Host "  python -m http.server 8080" -ForegroundColor White
