# Kills the rice stack cleanly.
& 'D:\Tools\komorebi\komorebic.exe' stop --whkd 2>$null
Get-Process yasb -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process whkd -ErrorAction SilentlyContinue | Stop-Process -Force
