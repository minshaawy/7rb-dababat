@echo off
rem Double-click to play on this computer (opening index.html directly does not work in browsers).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
