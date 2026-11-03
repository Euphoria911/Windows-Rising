# Starts the full rice stack: komorebi + whkd + yasb.
# Run this once interactively to verify everything comes up, and
# it also fires at login (via the Startup folder shortcut).
Start-Process -FilePath 'D:\Tools\komorebi\komorebic.exe' -ArgumentList 'start','--whkd' -WindowStyle Hidden
Start-Sleep -Seconds 2
Start-Process -FilePath 'D:\Tools\yasb\yasb.exe' -WindowStyle Hidden
