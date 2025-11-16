# Build for WASM (WebAssembly)
# WASM provides better performance than JavaScript in browsers

Write-Host "🔨 Building Satsang Admin with WASM..." -ForegroundColor Green
Write-Host "This creates a highly optimized WebAssembly build." -ForegroundColor Yellow
Write-Host ""

# Build with WASM compiler
flutter build web --wasm --release

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host "📁 Output: build/web/" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test locally:" -ForegroundColor Yellow
Write-Host "  cd build/web" -ForegroundColor White
Write-Host "  python -m http.server 8080" -ForegroundColor White
Write-Host "  # OR" -ForegroundColor White
Write-Host "  npx serve" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: WASM requires HTTPS in production or localhost for testing" -ForegroundColor Yellow
