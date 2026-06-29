Drop the profile in C:\Users\<username>\Documents\PowerShell
Drop the Admin folder in Program Files\PowerShell\7\Modules

This module requires PowerShell 7. If a machine only has Windows PowerShell 5.1,
bootstrap 7 first (the module can't load on 5.1):
    powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1
