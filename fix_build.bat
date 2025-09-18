@echo off
echo Fixing Flutter build issues...

echo Step 1: Cleaning Flutter cache...
flutter clean

echo Step 2: Cleaning Android build cache...
cd android
call gradlew clean
cd ..

echo Step 3: Removing .dart_tool directory...
rmdir /s /q .dart_tool

echo Step 4: Getting Flutter packages...
flutter pub get

echo Step 5: Building APK with increased memory...
set FLUTTER_BUILD_MEMORY=4096
flutter build apk --debug --verbose

echo Build process completed!
pause