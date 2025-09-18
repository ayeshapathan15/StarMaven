@echo off
echo ========================================
echo Emergency Flutter Build Fix
echo ========================================

echo Step 1: Stopping all Dart/Flutter processes...
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
taskkill /f /im java.exe 2>nul

echo Step 2: Clearing system temp files...
del /q /s "%TEMP%\dart*" 2>nul
del /q /s "%TEMP%\flutter*" 2>nul

echo Step 3: Full Flutter clean...
flutter clean

echo Step 4: Removing all build artifacts...
rmdir /s /q .dart_tool 2>nul
rmdir /s /q build 2>nul
rmdir /s /q android\.gradle 2>nul

echo Step 5: Setting memory environment variables...
set DART_VM_OPTIONS=--old_gen_heap_size=2048
set FLUTTER_BUILD_MEMORY=2048
set GRADLE_OPTS=-Xmx2g -XX:MaxMetaspaceSize=256m

echo Step 6: Getting packages with memory limit...
flutter pub get

echo Step 7: Building with minimal memory usage...
flutter build apk --debug --android-skip-build-dependency-validation --verbose

echo ========================================
echo Build process completed!
echo ========================================
pause