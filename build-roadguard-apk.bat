@echo off
setlocal

set "PROJECT_DIR=C:\dev\RoadGaurd"
set "ANDROID_SDK_DIR=C:/Users/pc/AppData/Local/Android/Sdk"
set "API_URL=http://10.0.2.2:8000"

cd /d "%PROJECT_DIR%"
if errorlevel 1 (
  echo Failed to enter %PROJECT_DIR%
  exit /b 1
)

echo Running flutter pub get...
call flutter pub get
if errorlevel 1 exit /b 1

if not exist android (
  echo Android folder not found. Generating platform project...
  call flutter create .
  if errorlevel 1 exit /b 1
)

echo Writing android\local.properties...
(
  echo sdk.dir=%ANDROID_SDK_DIR%
) > android\local.properties

echo Building release APK...
call flutter build apk --release --dart-define=ROADGUARD_API_BASE_URL=%API_URL%
if errorlevel 1 exit /b 1

echo Installing APK with adb...
call adb install -r build\app\outputs\flutter-apk\app-release.apk
if errorlevel 1 exit /b 1

echo Build and install complete.
exit /b 0
