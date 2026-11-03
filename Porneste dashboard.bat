@echo off
title Dashboard cereri - server local
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dashboard-server.ps1"
if errorlevel 1 pause
