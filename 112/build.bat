@echo off
setlocal

rem =========================================================================
rem PROJECT112 - ATM TURBO 2+ v7.10 VIDEO MODE TEST BUILD
rem This script always builds from its own directory, regardless of the
rem directory from which it was launched.
rem =========================================================================

cd /d "%~dp0"
if errorlevel 1 goto :BUILD_FAILED

echo [BUILD] Working directory: %CD%
echo [BUILD] Assembling Project112 for ATM Turbo 2+ v7.10...

if not exist "tools\sjasmplus.exe" (
    echo [ERROR] tools\sjasmplus.exe was not found.
    goto :BUILD_FAILED
)

del /q "project112.TRD" 2>nul
tools\sjasmplus.exe --dirbol --lst=list.txt --sym=map.txt src/main.asm

if errorlevel 1 goto :BUILD_FAILED
if not exist "project112.TRD" (
    echo [ERROR] Assembly returned success but project112.TRD was not created.
    goto :BUILD_FAILED
)

echo.
echo [SUCCESS] Assembly completed.
echo [OUTPUT] %CD%\project112.TRD
echo [MAP]    %CD%\map.txt
echo [LIST]   %CD%\list.txt
echo.
pause
exit /b 0

:BUILD_FAILED
echo.
echo [ERROR] Build failed. Do NOT run an older project112.TRD.
echo [ERROR] Check the messages above and list.txt.
echo.
pause
exit /b 1
