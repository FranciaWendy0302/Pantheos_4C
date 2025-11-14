@echo off
echo Stopping any running Godot server processes...
taskkill /F /IM Godot_v4.4.1-stable_win64.exe /FI "WINDOWTITLE eq *headless*" 2>nul
timeout /t 2 /nobreak >nul

echo Starting server...
cd /d "C:\Users\Gerick and Wendy\Documents\aarpg - 55 - final"
start "Godot Server" Godot_v4.4.1-stable_win64.exe --headless --path "C:\Users\Gerick and Wendy\Documents\aarpg - 55 - final\Pantheos_4C" res://Network/server.tscn

echo Server restarted!
pause
