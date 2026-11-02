@echo off
rem =========================================================================
rem PROJECT112 — ATM TURBO 2+ v7.10 VIDEO MODE TEST BUILD
rem Run this script from the 112 directory.
rem =========================================================================

echo [BUILD] Assembling Project112 for ATM Turbo 2+ v7.10...
tools\sjasmplus.exe --dirbol --lst=list.txt --sym=map.txt src/main.asm

if errorlevel 1 goto :BUILD_FAILED

echo.
echo [SUCCESS] Assembly completed.
echo [OUTPUT] project112.TRD
echo [MAP]    map.txt
echo [LIST]   list.txt
goto :END

:BUILD_FAILED
echo.
echo [ERROR] SjASMPlus reported an assembly error.
echo [ERROR] Check list.txt for the failing source line.
pause
exit /b 1

:END
pause
