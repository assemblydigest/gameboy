@echo off
rgbasm -ogame.obj game.z80
if %errorlevel% neq 0 call :exit 1
rgblink -mgame.map -ngame.sym -ogame.gb game.obj
if %errorlevel% neq 0 call :exit 1
rgbfix -p0 -v game.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
pause
exit