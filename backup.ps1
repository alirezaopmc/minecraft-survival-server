# Zips the world folders into backups/. Stop the server first so the copy is consistent.
# Old backups are never deleted automatically.
$ErrorActionPreference = 'Stop'
$root   = $PSScriptRoot
$server = Join-Path $root 'server'

if (Get-NetTCPConnection -LocalPort 25565 -State Listen -ErrorAction SilentlyContinue) {
    throw 'The server is running. Stop it, then run the backup again.'
}

$worlds = Get-ChildItem $server -Directory -Filter 'world*' | Select-Object -ExpandProperty Name
if (-not $worlds) { throw 'No world folders found in server/.' }

$backups = Join-Path $root 'backups'
New-Item -ItemType Directory -Force -Path $backups | Out-Null
$zip = Join-Path $backups ('world-{0:yyyy-MM-dd_HH-mm-ss}.zip' -f (Get-Date))

# Windows' own tar: GNU tar from Git Bash treats C: paths as remote hosts.
& "$env:SystemRoot\System32\tar.exe" -a -c -f $zip -C $server @worlds
if ($LASTEXITCODE -ne 0) { throw 'Backup failed.' }
Write-Host ("Backup created: {0} ({1:N0} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))
