@echo off
rem =========================================================================
rem PERFECT COMMANDER 112 — АВТОМАТИЗИРОВАННЫЙ СБОРЩИК И КАРТОГРАФ ПАМЯТИ
rem =========================================================================
rem Ключи sjasmplus:
rem   --dirbol        - строгий синтаксис (инструкции с начала строки)
rem   --lst=list.txt  - генерация сквозного потактового листинга пассов
rem   --sym=map.txt   - генерация точной карты адресов всех глобальных меток
rem =========================================================================

echo [BUILD] Запуск компиляции проекта Perfect Commander 112...
tools\sjasmplus.exe --dirbol --lst=list.txt --sym=map.txt src/main.asm

if errorlevel 1 goto :BUILD_FAILED

echo.
echo [SUCCESS] Сборка успешно завершена! (Pass 3 complete, 0 errors).
echo [MAP] Файл карты памяти сохранен в: map.txt
echo [LST] Файл сквозного листинга сохранен в: list.txt
goto :END

:BUILD_FAILED
echo.
echo [ERROR] Крах сборки! SjASMPlus обнаружил критические ошибки.
echo [ERROR] Изучите последние строки файла list.txt для поиска коллизий.
pause
exit /b 1

:END
pause
