$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host "===== DIAGNOSTIC RESEAU - $(Get-Date -Format 'dd/MM/yyyy HH:mm') =====" -ForegroundColor Cyan

Write-Host "`n--- 1. CARTES RESEAU ACTIVES ---" -ForegroundColor Cyan
Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
  "  {0}" -f $_.Name
  "     Interface   : {0}" -f $_.InterfaceDescription
  "     Debit lien  : {0}" -f $_.LinkSpeed
  "     Type        : {0}" -f $_.MediaType
  "     Pilote      : version {0} du {1}" -f $_.DriverVersion, $_.DriverDate
}

Write-Host "`n--- 2. DETAIL WIFI ---" -ForegroundColor Cyan
$w = netsh wlan show interfaces
if ($w -match 'SSID') { $w | Where-Object { $_ -match 'SSID|Signal|Radio|Canal|Channel|reception|emission|Type|Authentification|Bande|Band' } | ForEach-Object { "  $($_.Trim())" } }
else { Write-Host "  Pas de connexion Wi-Fi active (ou cable Ethernet)" }

Write-Host "`n--- 3. LATENCE ---" -ForegroundColor Cyan
$gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop
function PingStat($t, $n) {
  $r = Test-Connection -ComputerName $t -Count 10 -EA 0
  if ($r) {
    $m = $r | Measure-Object ResponseTime -Average -Maximum
    "  {0,-24} {1,2}/10 reponses   moyenne {2,4} ms   pic {3,4} ms" -f $n, $r.Count, [math]::Round($m.Average,0), $m.Maximum
  } else { "  {0,-24} AUCUNE REPONSE" -f $n }
}
if ($gw) { PingStat $gw "Box / routeur ($gw)" } else { Write-Host "  Passerelle introuvable" }
PingStat "8.8.8.8" "Internet (Google DNS)"
PingStat "1.1.1.1" "Internet (Cloudflare)"

Write-Host "`n--- 4. DNS ---" -ForegroundColor Cyan
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | ForEach-Object {
  "  {0} : {1}" -f $_.InterfaceAlias, ($_.ServerAddresses -join ', ')
}
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$null = Resolve-DnsName www.wikipedia.org -EA 0
$sw.Stop()
"  Temps de resolution DNS : {0} ms" -f [math]::Round($sw.Elapsed.TotalMilliseconds,0)

Write-Host "`n--- 5. ERREURS SUR LA CARTE ---" -ForegroundColor Cyan
Get-NetAdapterStatistics | ForEach-Object {
  "  {0}" -f $_.Name
  "     Recu   : {0} Go   erreurs {1}   rejets {2}" -f [math]::Round($_.ReceivedBytes/1GB,2), $_.ReceivedPacketErrors, $_.ReceivedDiscardedPackets
  "     Envoye : {0} Go   erreurs {1}   rejets {2}" -f [math]::Round($_.SentBytes/1GB,2), $_.OutboundPacketErrors, $_.OutboundDiscardedPackets
}

Write-Host "`n--- 6. TRAFIC EN COURS (15 secondes) ---" -ForegroundColor Cyan
1..5 | ForEach-Object {
  $t = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.BytesTotalPersec -gt 0 }
  if ($t) { $t | ForEach-Object { "  {0,-45} {1,7} ko/s" -f $_.Name.Substring(0,[Math]::Min(45,$_.Name.Length)), [math]::Round($_.BytesTotalPersec/1KB,0) } }
  else { "  Aucun trafic" }
  Start-Sleep 3
}

Write-Host "`n--- 7. TEST DE DEBIT DESCENDANT ---" -ForegroundColor Cyan
try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $null = Invoke-WebRequest -Uri "https://speed.cloudflare.com/__down?bytes=10000000" -UseBasicParsing -TimeoutSec 120
  $sw.Stop()
  $s = $sw.Elapsed.TotalSeconds
  "  10 Mo telecharges en {0} s" -f [math]::Round($s,1)
  "  Debit mesure : {0} Mbit/s" -f [math]::Round((10*8)/$s,1)
} catch { "  Test impossible : $($_.Exception.Message)" }

Write-Host "`n--- 8. GROS CONSOMMATEURS POTENTIELS ---" -ForegroundColor Cyan
Get-Process OneDrive, MsMpEng, msedge, chrome, TiWorker, MoUsoCoreWorker, wuauclt -EA 0 |
  Select-Object ProcessName, @{n='Mo';e={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize

Write-Host "`n===== FIN =====" -ForegroundColor Cyan
