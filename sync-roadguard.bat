@echo off
setlocal

set "SOURCE=\\wsl$\Ubuntu\mnt\d\ssd data\RoadGaurd"
set "TARGET=C:\dev\RoadGaurd"

echo Syncing RoadGuard from:
echo   %SOURCE%
echo to:
echo   %TARGET%

robocopy "%SOURCE%" "%TARGET%" /E /XD .git .dart_tool build .idea node_modules

if %ERRORLEVEL% LEQ 7 (
  echo Sync complete.
  exit /b 0
)

echo Robocopy reported a failure. Exit code: %ERRORLEVEL%
exit /b %ERRORLEVEL%
