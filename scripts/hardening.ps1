# Run as Administrator

Write-Host "[*] Windows post-incident hardening" -ForegroundColor Cyan

# Block execution from %TEMP%
$tempPath = $env:TEMP
$acl = Get-Acl $tempPath

$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Everyone",
    "ExecuteFile",
    "ContainerInherit,ObjectInherit",
    "None",
    "Deny"
)

$acl.SetAccessRule($rule)
Set-Acl -Path $tempPath -AclObject $acl

# Block certutil outbound connections
New-NetFirewallRule `
    -DisplayName "BLOCK_certutil_outbound" `
    -Direction Outbound `
    -Program "C:\Windows\System32\certutil.exe" `
    -Action Block `
    -Profile Any `
    -Enabled True

# Enable process creation auditing
auditpol /set `
    /subcategory:"Process Creation" `
    /success:enable `
    /failure:enable

# Remove the scheduled task created by the lab
Get-ScheduledTask |
    Where-Object { $_.TaskName -match "Updater|WindowsUpdater" } |
    Unregister-ScheduledTask `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

Write-Host "[OK] Hardening completed" -ForegroundColor Green
