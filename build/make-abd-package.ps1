# Build the downstream package using the exact upstream release binaries.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$work = Join-Path $root '.tools/abd-upstream'
$cache = Join-Path $root 'bin/FreeBSD-16-amd64'
New-Item -ItemType Directory -Force $work, $cache | Out-Null
$archive = Join-Path $work 'upstream.pkg'
Invoke-WebRequest 'https://github.com/MarceloMayo74/pfsense-amneziawg/releases/download/v1.2.0/pfSense-pkg-AmneziaWG-1.2.0-FreeBSD-16-amd64.pkg' -OutFile $archive
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne '0014c583da9942f6fd0446c870a972cf51c78b8d7af938dc95e13870f333049f') { throw 'Upstream package checksum mismatch' }
tar -xf $archive -C $work
if ($LASTEXITCODE -ne 0) { throw 'Extraction failed' }
$expected = @{
    'awg' = '18569c903f01ed052db382a821f6563b232ecc7c9693e08b0df9a36e4f7cf5a5'
    'amneziawg-go' = '53ea484d0475100ebee1bc39ce279f1e14f730c20e3e64e34b3b8028d66c79d8'
}
foreach ($name in $expected.Keys) {
    $binary = Join-Path $work "usr/local/bin/$name"
    if ((Get-FileHash $binary -Algorithm SHA256).Hash -ne $expected[$name]) { throw "Binary checksum mismatch: $name" }
    Copy-Item $binary (Join-Path $cache $name) -Force
}
& (Join-Path $PSScriptRoot 'make-pkg.ps1') -Abi 'FreeBSD:16:amd64'
