# Builds the servers (first run only), starts them, and launches the SkySaga client.
#   .\play.ps1            build if needed, start servers, launch client
#   .\play.ps1 -Rebuild   force a rebuild first
#   .\play.ps1 -ServersOnly
param([switch]$Rebuild, [switch]$ServersOnly, [string]$GameDir = "$PSScriptRoot\game")

$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$servers = "$root\Servers"
$out     = 'bin\Release\net9.0'

# --- .NET 9 SDK (use the x64 dotnet explicitly; an x86 dotnet earlier on PATH has no SDKs) ---
$dotnet = "$env:ProgramFiles\dotnet\dotnet.exe"
if (-not (Test-Path $dotnet) -or -not ((& $dotnet --list-sdks) -match '^9\.')) {
    Write-Host 'Installing .NET 9 SDK via winget...'
    winget install Microsoft.DotNet.SDK.9 --architecture x64 --silent --accept-source-agreements --accept-package-agreements
}

# --- Build ---
$webExe  = "$servers\SkySaga.Web\$out\SkySaga.Web.exe"
$gameExe = "$servers\SkySaga.Game\$out\SkySaga.Game.exe"
if ($Rebuild -or -not (Test-Path $webExe) -or -not (Test-Path $gameExe)) {
    & $dotnet build "$servers\Servers.sln" -c Release --nologo -v q
    if ($LASTEXITCODE) { throw 'Build failed.' }
}

# --- Start servers (each in its own window; skip if already running) ---
foreach ($exe in $webExe, $gameExe) {
    $name = [IO.Path]::GetFileNameWithoutExtension($exe)
    if (-not (Get-Process $name -ErrorAction SilentlyContinue)) {
        Start-Process $exe -WorkingDirectory (Split-Path $exe)
    }
}
for ($i = 0; $i -lt 40; $i++) {
    try { Invoke-WebRequest http://localhost:5164/ping -UseBasicParsing -TimeoutSec 1 | Out-Null; break } catch { Start-Sleep -Milliseconds 250 }
}
Write-Host 'Servers up: web http://localhost:5164, game udp/42069'
if ($ServersOnly) { return }

# --- Launch client ---
# Pick a client under $GameDir (any depth, ...\Client\SkySaga.exe); prefer build 10414 if several exist.
$client = Get-ChildItem $GameDir -Recurse -Filter SkySaga.exe -ErrorAction SilentlyContinue |
          Where-Object { $_.Directory.Name -eq 'Client' } |
          Sort-Object { (Get-Content "$($_.DirectoryName)\version.txt" -TotalCount 1).Trim() -ne '10414' } |
          Select-Object -First 1
if (-not $client) { throw "SkySaga.exe not found. Extract the client into $GameDir (so that ...\Client\SkySaga.exe exists)." }

$version = (Get-Content "$($client.DirectoryName)\version.txt" -TotalCount 1).Trim()
$clientArgs = @('ws_host="localhost"', 'ws_port=5164', 'allowim=1', 'devimip="localhost"', 'manport=5164',
          'multiApp=1', 'useAnalytics=0', 'auth="Test123"')
if ([int]$version -gt 10414) { $clientArgs += 'ssl_active=0' }
if ($version -ne '10414') { Write-Warning "Client build $version detected. The server targets build 10414; other builds may not get in-game." }

Write-Host "Launching client build $version"
Start-Process $client.FullName -WorkingDirectory $client.DirectoryName -ArgumentList $clientArgs
