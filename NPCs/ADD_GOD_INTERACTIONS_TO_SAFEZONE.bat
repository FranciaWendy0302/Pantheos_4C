@echo off
echo ========================================
echo Adding God Interactions to Safezone
echo ========================================
echo.
echo This will modify safezone.tscn to add interaction scripts to all god sprites.
echo.
pause

powershell -ExecutionPolicy Bypass -File "%~dp0add_god_interactions.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! God interactions added.
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Open Godot Editor
    echo 2. Open safezone.tscn
    echo 3. Test by running the game
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR! Something went wrong.
    echo ========================================
    echo.
)

pause
