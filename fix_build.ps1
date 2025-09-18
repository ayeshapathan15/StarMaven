# Flutter Build Fix Script
Write-Host "Fixing Flutter build memory issues..." -ForegroundColor Green

# Step 1: Clean everything
Write-Host "Cleaning Flutter cache..." -ForegroundColor Yellow
flutter clean

# Step 2: Clean Android
Write-Host "Cleaning Android build cache..." -ForegroundColor Yellow
Set-Location android
.\gradlew clean
Set-Location ..

# Step 3: Remove .dart_tool
Write-Host "Removing .dart_tool directory..." -ForegroundColor Yellow
if (Test-Path ".dart_tool") {
    Remove-Item -Recurse -Force ".dart_tool"
}

# Step 4: Set memory environment variables
Write-Host "Setting memory environment variables..." -ForegroundColor Yellow
$env:FLUTTER_BUILD_MEMORY = "4096"
$env:GRADLE_OPTS = "-Xmx4g -XX:MaxMetaspaceSize=512m"

# Step 5: Get packages
Write-Host "Getting Flutter packages..." -ForegroundColor Yellow
flutter pub get

# Step 6: Build with verbose output
Write-Host "Building APK..." -ForegroundColor Yellow
flutter build apk --debug --verbose

Write-Host "Build process completed!" -ForegroundColor Green