@echo off
color 0a
cd ..
echo BUILDING GAME
lime clean windows -debug
echo.
echo done.
pause
pwd
explorer.exe export\debug\windows\bin