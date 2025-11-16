# Run in Profile Mode for Performance Testing
# Profile mode has optimizations enabled but still allows debugging

Write-Host "🚀 Starting Satsang Admin in PROFILE mode..." -ForegroundColor Green
Write-Host "This mode has performance optimizations enabled for testing scrolling performance." -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome --profile --web-port 5174

# Note: Profile mode benefits:
# - Optimized code (similar to release)
# - Performance overlay available
# - Better scrolling performance than debug mode
# - DevTools profiling enabled
