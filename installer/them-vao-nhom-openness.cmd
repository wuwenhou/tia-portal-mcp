@echo off
rem Them user dang dang nhap vao nhom "Siemens TIA Openness".
rem Cach dung: chuot phai file nay -> "Run as administrator".
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Add-OpennessUser.ps1"
pause
