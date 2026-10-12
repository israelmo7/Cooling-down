# Windows shop PC. Docker Desktop must already be running.
#   powershell -ExecutionPolicy Bypass -File .\start.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Install Docker Desktop, start it, and run this again.'
}

$compose = Join-Path $here 'docker-compose.yml'
$imageLine = Select-String -Path $compose -Pattern 'image:\s*(\S+)' | Select-Object -First 1
if (-not $imageLine) {
  throw 'docker-compose.yml has no image name.'
}
$image = $imageLine.Matches[0].Groups[1].Value

$loaded = $false
try {
  docker image inspect $image --format '{{.Id}}' *> $null
  if ($LASTEXITCODE -eq 0) { $loaded = $true }
} catch {
  $loaded = $false
}
if (-not $loaded) {
  $tar = Join-Path $here 'cooling-down-server.tar'
  if (-not (Test-Path $tar)) {
    throw 'cooling-down-server.tar is missing next to this script.'
  }
  docker load -i $tar
  if ($LASTEXITCODE -ne 0) { throw 'docker load failed.' }
}

$shop = Join-Path $here 'shop.json'
if (-not (Test-Path $shop)) {
  throw 'shop.json is missing next to this script.'
}
New-Item -ItemType Directory -Force -Path (Join-Path $here 'data') | Out-Null
Copy-Item -Force $shop (Join-Path $here 'data\shop.json')

docker compose run -T --rm --no-deps server --apply-shop
if ($LASTEXITCODE -ne 0) { throw 'Could not apply shop.json.' }
Copy-Item -Force (Join-Path $here 'data\shop.json') $shop

docker compose up -d --force-recreate
if ($LASTEXITCODE -ne 0) { throw 'Could not start the server.' }
docker compose logs --tail 40

$envFile = Join-Path $here 'data\.env'
$tokenLine = Select-String -Path $envFile -Pattern '^SYNC_TOKEN=(.*)$' | Select-Object -First 1
$token = ''
if ($tokenLine) {
  $token = $tokenLine.Matches[0].Groups[1].Value.Trim().Trim('"')
}
Write-Host ''
Write-Host "Token: $token"
Write-Host 'Tablets: http://<this-computer>:8080'
Write-Host 'Admin:   http://<this-computer>:8080/admin'
