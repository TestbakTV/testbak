# tv-scan.ps1 - zoekt je Google TV via ADB, maakt verbinding en slaat de lijst met apps op.
# Er wordt NIETS verwijderd. Resultaat: de map .\tv\ naast dit script.
# Testbak - https://github.com/TestbakTV/testbak
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$out  = Join-Path $base 'tv'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$adb  = Join-Path $base 'platform-tools\adb.exe'

# 1. ADB (de officiële Android platform-tools van Google) downloaden als die er nog niet staat
if (-not (Test-Path $adb)) {
    Write-Host '[1/4] ADB (Android platform-tools van Google) downloaden...' -ForegroundColor Cyan
    $zip = Join-Path $base 'platform-tools.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $base -Force
    Remove-Item $zip
} else {
    Write-Host '[1/4] ADB staat er al.' -ForegroundColor Cyan
}

# 2. Je thuisnetwerk scannen op apparaten met ADB aan (poort 5555)
Write-Host '[2/4] Netwerk scannen op apparaten met ADB (poort 5555)...' -ForegroundColor Cyan
$cfg = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
$myIp = $cfg.IPv4Address.IPAddress
$prefix = ($myIp -split '\.')[0..2] -join '.'
Write-Host "      Ik scan $prefix.1 t/m $prefix.254"

$tasks = @{}
1..254 | ForEach-Object {
    $ip = "$prefix.$_"
    $c = New-Object System.Net.Sockets.TcpClient
    $tasks[$ip] = @{ Client = $c; Task = $c.ConnectAsync($ip, 5555) }
}
Start-Sleep -Milliseconds 1500
$found = @()
foreach ($ip in $tasks.Keys) {
    $t = $tasks[$ip]
    if ($t.Task.IsCompleted -and -not $t.Task.IsFaulted -and $t.Client.Connected) { $found += $ip }
    $t.Client.Close()
}

if ($found.Count -eq 0) {
    Write-Host '      Niets gevonden met poort 5555 open.' -ForegroundColor Yellow
    Write-Host '      Check op de tv: Ontwikkelaarsopties -> USB-foutopsporing AAN.'
    $tv = Read-Host '      Of typ hier het IP-adres van de tv (Instellingen -> Netwerk en internet)'
} elseif ($found.Count -eq 1) {
    $tv = $found[0]
    Write-Host "      Gevonden: $tv" -ForegroundColor Green
} else {
    Write-Host "      Meerdere gevonden: $($found -join ', ')"
    $tv = Read-Host '      Welk IP-adres is de tv'
}

# 3. Verbinden (de tv vraagt één keer om toestemming)
Write-Host "[3/4] Verbinden met $tv ..." -ForegroundColor Cyan
& $adb kill-server | Out-Null
& $adb connect "${tv}:5555"
Write-Host ''
Write-Host '      >>> Kijk nu op de tv: "Foutopsporing toestaan?" -> vink "Altijd toestaan" aan en kies OK <<<' -ForegroundColor Yellow
$ok = $false
for ($i = 0; $i -lt 30; $i++) {
    $state = (& $adb -s "${tv}:5555" get-state 2>$null)
    if ($state -eq 'device') { $ok = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ok) {
    Write-Host '      Geen toestemming ontvangen. Start het script opnieuw en accepteer de melding op de tv.' -ForegroundColor Red
    Read-Host 'Enter om af te sluiten'; exit 1
}
Write-Host '      Verbonden!' -ForegroundColor Green

# 4. Info en applijsten opslaan
Write-Host '[4/4] Applijsten ophalen...' -ForegroundColor Cyan
$s = "${tv}:5555"
"model=$(& $adb -s $s shell getprop ro.product.model)"            | Out-File "$out\info.txt" -Encoding ascii
"android=$(& $adb -s $s shell getprop ro.build.version.release)"  | Out-File "$out\info.txt" -Encoding ascii -Append
"launcher=$(& $adb -s $s shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN)" | Out-File "$out\info.txt" -Encoding ascii -Append
& $adb -s $s shell pm list packages      | Out-File "$out\packages_all.txt"      -Encoding ascii
& $adb -s $s shell pm list packages -s   | Out-File "$out\packages_system.txt"   -Encoding ascii
& $adb -s $s shell pm list packages -3   | Out-File "$out\packages_user.txt"     -Encoding ascii
"$tv" | Out-File "$out\tv_ip.txt" -Encoding ascii

$n = (Get-Content "$out\packages_all.txt").Count
Write-Host ''
Write-Host "Klaar! $n apps gevonden. De lijsten staan in $out" -ForegroundColor Green
Write-Host 'Volgende stap: kijk packages.txt na en start daarna START-tv-debloat.cmd'
Read-Host 'Enter om af te sluiten'
