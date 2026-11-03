@echo off
chcp 65001 >nul
set LC_ALL=en_US.UTF-8
set LANG=en_US.UTF-8
D:\Tools\komorebi\komorebi.exe --config "%USERPROFILE%\.config\komorebi\komorebi.json"
