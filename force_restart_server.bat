@echo off
echo ========================================
echo FORCE RESTARTING SERVER
echo ========================================

echo.
echo Step 1: Killing ALL Godot processes...
taskkill /F /IM Godot_v4.4.1-stable_win64.exe 2>nul
if %errorlevel% equ 0 (
    echo SUCCESS: Godot processes terminated
) else (
    echo No Godot processes found
)

echo.
echo Step 2: Waiting 3 seconds...
timeout /t 3 /nobreak >nul

echo.
echo Step 3: Starting fresh server...
cd /d "C:\Users\Gerick and Wendy\Documents\aarpg - 55 - final"
start "Godot Server" Godot_v4.4.1-stable_win64.exe --headless --path "C:\Users\Gerick and Wendy\Documents\aarpg - 55 - final\Pantheos_4C" res://Network/server.tscn

echo.
echo ========================================
echo Server restarted successfully!
echo ========================================
echo.
echo Now restart your client in Godot (press F5)
echo.
pause
