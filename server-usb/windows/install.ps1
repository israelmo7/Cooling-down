# Windows shop PC, from the USB stick. Run twice.
# First run installs WSL and Docker Desktop. Restart, start Docker Desktop,
# then run this again. The second run starts the shop program.
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

$principal = New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw 'Open PowerShell as Administrator, then run this script again.'
}

$archFile = Join-Path $here 'arch.txt'
if (-not (Test-Path $archFile)) {
  throw 'arch.txt is missing. Run server-usb/windows/fetch.sh before copying this folder to the stick.'
}
$wanted = (Get-Content $archFile -Raw).Trim()
$actual = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
if ($wanted -ne $actual) {
  throw "This stick is for $wanted Windows. This PC is $actual."
}

try {
  Get-NetConnectionProfile | ForEach-Object {
    if ($_.NetworkCategory -ne 'Private') {
      Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private
      Write-Host "Set $($_.Name) to Private so tablets can use port 8080."
    }
  }
} catch {
  Write-Host 'Leave the shop network set to Private so tablets can use port 8080.'
}

function Test-DockerEngine {
  docker info *> $null
  return $LASTEXITCODE -eq 0
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
  if (-not (Test-DockerEngine)) {
    throw 'Start Docker Desktop, wait until it says it is running, then run this script again.'
  }
  $shop = Join-Path $here 'cooling-down\start.ps1'
  if (-not (Test-Path $shop)) {
    throw 'Docker is running. The cooling-down folder is not on this stick. Pack it with server-ssh/pack-windows.sh and copy it here.'
  }
  & $shop
  return
}

$msi = Get-ChildItem -Path $here -Filter 'wsl*.msi' | Select-Object -First 1
$exe = Join-Path $here 'Docker Desktop Installer.exe'
if (-not $msi) { throw 'The WSL installer is not in this folder.' }
if (-not (Test-Path $exe)) { throw 'Docker Desktop Installer.exe is not in this folder.' }

Write-Host 'Turning on the Windows features Docker needs.'
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
  throw "Could not turn on Windows Subsystem for Linux ($LASTEXITCODE)."
}
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
  throw "Could not turn on the virtual machine platform ($LASTEXITCODE)."
}

Write-Host 'Installing WSL from the stick.'
$wsl = Start-Process -FilePath msiexec.exe -ArgumentList @(
  '/i', $msi.FullName, '/quiet', '/norestart'
) -Wait -PassThru
if ($wsl.ExitCode -ne 0 -and $wsl.ExitCode -ne 3010) {
  throw "WSL install failed ($($wsl.ExitCode))."
}

Write-Host 'Installing Docker Desktop from the stick.'
$docker = Start-Process -FilePath $exe -ArgumentList @(
  'install', '--quiet', '--accept-license', '--backend=wsl-2'
) -Wait -PassThru
if ($docker.ExitCode -ne 0 -and $docker.ExitCode -ne 3010) {
  throw "Docker Desktop install failed ($($docker.ExitCode))."
}

Write-Host ''
Write-Host 'Restart Windows. Start Docker Desktop and wait until it says it is running.'
Write-Host 'Then run this script again. The second run starts the shop program and prints the token.'
