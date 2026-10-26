# tv-restore.ps1 - zet de verwijderde apps weer terug.
# Alles terug:   dubbelklik START-tv-restore.cmd
# Eén app terug: powershell -ExecutionPolicy Bypass -File tv-restore.ps1 com.tcl.channelplus
# Testbak - https://github.com/TestbakTV/testbak
param([string[]]$Only)
$base = $PSScriptRoot
$adb  = Join-Path $base 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) { Write-Host 'ADB niet gevonden. Start eerst START-tv-scan.cmd.' -ForegroundColor Red; Read-Host 'Enter'; exit 1 }

$tv = (Get-Content (Join-Path $base 'tv\tv_ip.txt') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $tv) { $tv = Read-Host 'IP-adres van de tv' }
$s = "$($tv.Trim()):5555"

$packages = Get-Content (Join-Path $base 'packages.txt') |
    ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ }
if ($Only) { $packages = $Only }

& $adb connect $s | Out-Null
if ((& $adb -s $s get-state 2>$null) -ne 'device') {
    Write-Host 'Geen verbinding met de tv. Zet USB-foutopsporing tijdelijk weer aan.' -ForegroundColor Red
    Read-Host 'Enter om af te sluiten'; exit 1
}
foreach ($p in $packages) {
    $r = (& $adb -s $s shell cmd package install-existing $p 2>&1 | Out-String).Trim()
    Write-Host "  $p : $r"
}
Write-Host ''
Write-Host 'Klaar. Vergeet niet USB-foutopsporing daarna weer UIT te zetten.' -ForegroundColor Yellow
Read-Host 'Enter om af te sluiten'
