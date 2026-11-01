# Downloads Java, Paper, plugins and the playit agent, verifies each checksum,
# and prepares server/. Safe to re-run: verified files are not downloaded again.
#
#   powershell -ExecutionPolicy Bypass -File setup.ps1 [-AcceptEula]
#
# -AcceptEula records your acceptance of https://aka.ms/MinecraftEULA.
# Without it the script asks you.
param([switch]$AcceptEula)

$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$cache   = Join-Path $root 'runtime\downloads'
$server  = Join-Path $root 'server'
$plugins = Join-Path $server 'plugins'
New-Item -ItemType Directory -Force -Path $cache, $plugins | Out-Null

$files = @(
    @{ Name = 'OpenJDK25U-jdk_x64_windows_hotspot_25.0.5_8.zip'; Algo = 'SHA256'
       Url  = 'https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.5%2B8/OpenJDK25U-jdk_x64_windows_hotspot_25.0.5_8.zip'
       Hash = '636bdc13dc649ddc7d5921c5c7d23cca6e44fd19d662b45cc9c02135a6c96c42' }
    @{ Name = 'paper-26.1.2-74.jar'; Algo = 'SHA256'
       Url  = 'https://fill-data.papermc.io/v1/objects/1d70b1dab9cf4a6de615209a536f3a45a2186240253c428213ce2188ab95e5f7/paper-26.1.2-74.jar'
       Hash = '1d70b1dab9cf4a6de615209a536f3a45a2186240253c428213ce2188ab95e5f7' }
    @{ Name = 'AuthMe-6.0.1-Paper.jar'; Algo = 'SHA512'
       Url  = 'https://cdn.modrinth.com/data/9js4IEHC/versions/fPuH4uYs/AuthMe-6.0.1-Paper.jar'
       Hash = '832eb1570f1887493dc09bd183360c6c890aafe24fbc635d36f7c3162c339f064e3a0e082519defe7e67569c1d78072f582cb49c14a24d125d4ece463b765271' }
    @{ Name = 'Chunky-Bukkit-1.5.3.jar'; Algo = 'SHA512'
       Url  = 'https://cdn.modrinth.com/data/fALzjamp/versions/MdY6JATr/Chunky-Bukkit-1.5.3.jar'
       Hash = '43ffecc6e6a734b752da41575bbb316526c124c3f878942437d5133c377bfbd9b78bda975520dc074d7158c15dade58a444ccd0fd8d8a25d165b6fc450140422' }
    @{ Name = 'playit-windows-x86_64-signed.exe'; Algo = 'SHA256'
       Url  = 'https://github.com/playit-cloud/playit-agent/releases/download/v1.2.0/playit-windows-x86_64-signed.exe'
       Hash = 'cb935ac28affee1ceea7b79c88c96ff023b7a1493eb6f9d0f4c7580baf0c0238' }
)

foreach ($f in $files) {
    $path = Join-Path $cache $f.Name
    $ok = (Test-Path $path) -and ((Get-FileHash $path -Algorithm $f.Algo).Hash -eq $f.Hash)
    if (-not $ok) {
        Write-Host "Downloading $($f.Name)"
        & curl.exe -fsSL --retry 3 -o $path $f.Url
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $($f.Name)" }
        if ((Get-FileHash $path -Algorithm $f.Algo).Hash -ne $f.Hash) {
            Remove-Item $path
            throw "Checksum mismatch, file removed: $($f.Name)"
        }
    }
    Write-Host "Verified $($f.Name)"
}

# Java stays inside the project; the system PATH is not touched.
$jdk = Join-Path $root 'runtime\jdk'
if (-not (Test-Path (Join-Path $jdk 'bin\java.exe'))) {
    Write-Host 'Extracting Java 25'
    $tmp = Join-Path $root 'runtime\jdk-extract'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp | Out-Null
    # The bundled ucrtbase.dll is skipped: it could not be written on the original
    # host, and Windows 10/11 supply their own copy in System32.
    & tar.exe -xf (Join-Path $cache $files[0].Name) -C $tmp --exclude '*/bin/ucrtbase.dll'
    if ($LASTEXITCODE -ne 0) { throw 'Could not extract Java.' }
    Move-Item -Path (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName -Destination $jdk
    Remove-Item $tmp -Recurse
}

Copy-Item (Join-Path $cache 'paper-26.1.2-74.jar') (Join-Path $server 'paper.jar') -Force
Copy-Item (Join-Path $cache 'AuthMe-6.0.1-Paper.jar') $plugins -Force
Copy-Item (Join-Path $cache 'Chunky-Bukkit-1.5.3.jar') $plugins -Force
Copy-Item (Join-Path $cache 'playit-windows-x86_64-signed.exe') (Join-Path $root 'runtime\playit.exe') -Force

# Tuned settings never overwrite a file you have already changed in server/.
$config = (Resolve-Path (Join-Path $root 'config')).Path
Get-ChildItem $config -Recurse -File | ForEach-Object {
    $target = Join-Path $server $_.FullName.Substring($config.Length + 1)
    if (-not (Test-Path $target)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
        Copy-Item $_.FullName $target
        Write-Host "Installed $target"
    }
}

$eula = Join-Path $server 'eula.txt'
if (-not ((Test-Path $eula) -and (Select-String -Path $eula -Pattern '^eula=true' -Quiet))) {
    if (-not $AcceptEula) {
        $answer = Read-Host 'Do you accept the Minecraft EULA (https://aka.ms/MinecraftEULA)? Type yes to accept'
        if ($answer -ne 'yes') { throw 'The server cannot start until the EULA is accepted.' }
    }
    Set-Content -Path $eula -Value 'eula=true' -Encoding Ascii
}

Write-Host 'Setup complete. Run start.bat to start the server.'
