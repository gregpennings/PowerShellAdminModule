Drop the profile in C:\Users\<username>\Documents\PowerShell
Drop the Admin folder in C:\Users\<username>\Documents\PowerShell\Modules
(avoid Program Files\PowerShell\7\Modules -- it requires admin rights to write,
which breaks the auto `git pull` on profile load for non-elevated sessions)

This module requires PowerShell 7. If a machine only has Windows PowerShell 5.1,
bootstrap 7 first (the module can't load on 5.1):
    powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1
