# Server local pentru dashboard-ul de cereri (oformo).
# Serveste dashboard-cereri.html pe http://localhost si descarca CSV-ul de pe oformo.com
# in locul browserului, ca sa nu mai fie blocat de CORS. Totul ruleaza doar pe acest calculator.
# Compatibil cu Windows PowerShell 5.1 si PowerShell 7. Pentru oprire: inchide fereastra.

$ErrorActionPreference = 'Stop'
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

$Root  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Page  = Join-Path $Root 'dashboard-cereri.html'
$Ports = 8765..8775
$AllowedHosts = @('oformo.com')

function Test-AllowedHost([string]$h) {
  $h = $h.ToLowerInvariant()
  foreach ($a in $AllowedHosts) { if ($h -eq $a -or $h.EndsWith('.' + $a)) { return $true } }
  return $false
}

function Send-Bytes($res, [int]$code, [string]$type, [byte[]]$bytes) {
  $res.StatusCode = $code
  $res.ContentType = $type
  $res.AddHeader('Cache-Control', 'no-store')
  $res.AddHeader('X-Content-Type-Options', 'nosniff')
  $res.ContentLength64 = $bytes.Length
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Send-Text($res, [int]$code, [string]$text) {
  Send-Bytes $res $code 'text/plain; charset=utf-8' ([Text.Encoding]::UTF8.GetBytes($text))
}

function Test-OurServer([int]$port) {
  try {
    $wc = New-Object System.Net.WebClient
    $wc.Proxy = $null
    return ($wc.DownloadString("http://localhost:$port/__ping") -eq 'oformo-dashboard')
  } catch { return $false }
}

if (-not (Test-Path -LiteralPath $Page)) {
  Write-Host ''
  Write-Host "  Nu gasesc fisierul dashboard-cereri.html langa acest script:" -ForegroundColor Red
  Write-Host "  $Root"
  Write-Host '  Pastreaza toate fisierele in acelasi folder.'
  Read-Host '  Apasa Enter pentru a inchide'
  exit 1
}

# Daca serverul ruleaza deja (pornit de doua ori), doar deschidem browserul.
foreach ($p in $Ports) {
  if (Test-OurServer $p) {
    Write-Host "  Dashboard-ul ruleaza deja: http://localhost:$p/"
    Start-Process "http://localhost:$p/"
    Start-Sleep -Seconds 2
    exit 0
  }
}

$listener = $null
$port = 0
foreach ($p in $Ports) {
  $l = New-Object System.Net.HttpListener
  $l.Prefixes.Add("http://localhost:$p/")
  try { $l.Start(); $listener = $l; $port = $p; break } catch { try { $l.Close() } catch {} }
}
if (-not $listener) {
  Write-Host '  Nu am gasit un port liber intre 8765 si 8775.' -ForegroundColor Red
  Read-Host '  Apasa Enter pentru a inchide'
  exit 1
}

$url = "http://localhost:$port/"
Write-Host ''
Write-Host '  Dashboard cereri - server local' -ForegroundColor Cyan
Write-Host "  Adresa: $url"
Write-Host '  Lasa aceasta fereastra deschisa cat folosesti dashboard-ul.'
Write-Host '  Inchide fereastra pentru a opri serverul.'
Write-Host ''
if ($env:DASHBOARD_NO_BROWSER -ne '1') { Start-Process $url }

while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $path = $req.Url.AbsolutePath
    if ($path -eq '/' -or $path -eq '/index.html' -or $path -eq '/dashboard-cereri.html') {
      Send-Bytes $res 200 'text/html; charset=utf-8' ([IO.File]::ReadAllBytes($Page))
    }
    elseif ($path -eq '/__ping') {
      Send-Text $res 200 'oformo-dashboard'
    }
    elseif ($path -eq '/data.csv') {
      $target = $req.QueryString['url']
      $uri = $null
      $ok = $target -and [Uri]::TryCreate($target, [UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -eq 'https' -and (Test-AllowedHost $uri.Host)
      if (-not $ok) {
        Send-Text $res 400 'Link nepermis: serverul local descarca doar de pe https://oformo.com'
      } else {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', 'oformo-dashboard-local/1.0')
        if ($wc.Proxy) { try { $wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials } catch {} }
        $bytes = $wc.DownloadData($uri)
        Send-Bytes $res 200 'text/csv; charset=utf-8' $bytes
        Write-Host ('  [{0}] Date actualizate de pe oformo.com ({1} KB)' -f (Get-Date -Format 'HH:mm:ss'), [math]::Round($bytes.Length / 1KB))
      }
    }
    else {
      Send-Text $res 404 'Not found'
    }
  } catch {
    $ex = $_.Exception
    while ($ex -and -not ($ex -is [System.Net.WebException])) { $ex = $ex.InnerException }
    $code = 502
    $msg = $_.Exception.Message
    if ($ex) {
      $msg = $ex.Message
      if ($ex.Response) {
        try { $code = [int]$ex.Response.StatusCode } catch {}
        try {
          $sr = New-Object System.IO.StreamReader($ex.Response.GetResponseStream())
          $body = $sr.ReadToEnd().Trim()
          if ($body) { $msg = $body }
        } catch {}
      }
    }
    if ($code -lt 400) { $code = 502 }
    Write-Host ('  [{0}] Eroare la descarcare: {1} {2}' -f (Get-Date -Format 'HH:mm:ss'), $code, $msg) -ForegroundColor Yellow
    try { Send-Text $res $code $msg } catch {}
  } finally {
    try { $res.Close() } catch {}
  }
}
