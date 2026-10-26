# tv-debloat.ps1 - verwijdert de apps uit packages.txt van je Google TV.
# Gebruikt 'pm uninstall --user 0': de app verdwijnt voor jou, maar blijft in het systeem staan.
# Daardoor is alles terug te zetten met tv-restore.ps1, en blijven fabrieksreset en updates gewoon werken.
# Testbak - https://github.com/TestbakTV/testbak
$ErrorActionPreference = 'Continue'
$base = $PSScriptRoot
$adb  = Join-Path $base 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) { Write-Host 'ADB niet gevonden. Start eerst START-tv-scan.cmd.' -ForegroundColor Red; Read-Host 'Enter'; exit 1 }

$tv = (Get-Content (Join-Path $base 'tv\tv_ip.txt') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $tv) { $tv = Read-Host 'IP-adres van de tv' }
$s = "$($tv.Trim()):5555"

# Applijst lezen (alles achter # wordt genegeerd)
$packages = Get-Content (Join-Path $base 'packages.txt') |
    ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ }

Write-Host "Deze $($packages.Count) apps worden verwijderd:" -ForegroundColor Cyan
$packages | ForEach-Object { Write-Host "  - $_" }
Write-Host ''
$ja = Read-Host 'Doorgaan? Typ J en Enter (alles is terug te zetten met START-tv-restore.cmd)'
if ($ja -notmatch '^[jJyY]') { Write-Host 'Gestopt, er is niets veranderd.'; Read-Host 'Enter'; exit 0 }

& $adb connect $s | Out-Null
if ((& $adb -s $s get-state 2>$null) -ne 'device') {
    Write-Host 'Geen verbinding met de tv. Staat USB-foutopsporing nog aan?' -ForegroundColor Red
    Read-Host 'Enter om af te sluiten'; exit 1
}

$log = Join-Path $base 'tv\debloat-log.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
"Debloat $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $log -Encoding ascii
foreach ($p in $packages) {
    $r = (& $adb -s $s shell pm uninstall --user 0 $p 2>&1 | Out-String).Trim()
    if ($r -match 'Success') { Write-Host "  [weg]   $p" -ForegroundColor Green }
    else                     { Write-Host "  [skip]  $p  (staat niet op deze tv of is al weg)" -ForegroundColor DarkGray }
    "$p : $r" | Out-File $log -Encoding ascii -Append
}

Write-Host ''
$rb = Read-Host 'Klaar. Tv nu herstarten zodat alles schoon opstart? (J/N)'
if ($rb -match '^[jJyY]') { & $adb -s $s reboot }
Write-Host ''
Write-Host 'BELANGRIJK: zet daarna op de tv de Ontwikkelaarsopties / USB-foutopsporing weer UIT.' -ForegroundColor Yellow
Write-Host "Logbestand: $log"
Read-Host 'Enter om af te sluiten'
