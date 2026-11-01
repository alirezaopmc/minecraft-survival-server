@echo off
rem Starts the playit.gg agent, which gives the server a public address.
cd /d "%~dp0runtime"
if not exist "playit.exe" (
  echo playit not found. Run setup.ps1 first.
  pause
  exit /b 1
)
playit.exe
pause
