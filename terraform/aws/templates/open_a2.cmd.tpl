@echo off
SetDefaultBrowser.exe HKLM "Google Chrome"
powershell -Command "Start-Process https://${var_automate_hostname}"