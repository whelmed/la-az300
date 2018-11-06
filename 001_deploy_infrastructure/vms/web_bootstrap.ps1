# Start by installing IIS
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature


# Edit the default landing page to show that this was successful.
Add-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value "Bootstrapped on $(Get-Date) <br> VM Name: $($env:computername)"