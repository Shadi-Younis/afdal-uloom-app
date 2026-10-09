# Downloads the seed's recitations (al-Minshawi, murattal) listed in
# tool/seed/test_audio.json into a folder OUTSIDE the repo, by default
# ..\test-audio\minshawi next to the repo (C:\dev\test-audio\minshawi).
# Audio is never committed and only ever uploaded to the local emulators.
#
#   powershell -ExecutionPolicy Bypass -File tool/seed/download_test_audio.ps1
#
# Files already present are kept; pass -Force to download them again. Set
# SEED_AUDIO_DIR (here and for the seed) to use another folder.
param([switch]$Force)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$target = if ($env:SEED_AUDIO_DIR) { $env:SEED_AUDIO_DIR } else { Join-Path (Split-Path -Parent $repo) 'test-audio\minshawi' }
$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'test_audio.json') | ConvertFrom-Json

# Windows PowerShell 5.1 does not offer TLS 1.2 by default.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# The progress bar makes Invoke-WebRequest many times slower on 5.1.
$ProgressPreference = 'SilentlyContinue'

New-Item -ItemType Directory -Force $target | Out-Null

foreach ($clip in $manifest.clips) {
    $path = Join-Path $target $clip.file
    if ((Test-Path $path) -and -not $Force) {
        Write-Host "kept        $($clip.file)"
        continue
    }
    $partial = "$path.part"
    Invoke-WebRequest -UseBasicParsing -UserAgent 'afdal-uloom-seed' -Uri $clip.url -OutFile $partial

    # An error page saved as .mp3 would only fail later, in the player.
    $head = [byte[]](Get-Content -Encoding Byte -TotalCount 3 $partial)
    $isId3 = $head[0] -eq 0x49 -and $head[1] -eq 0x44 -and $head[2] -eq 0x33
    $isFrame = $head[0] -eq 0xFF -and ($head[1] -band 0xE0) -eq 0xE0
    if (-not ($isId3 -or $isFrame)) {
        Remove-Item $partial
        Write-Error "$($clip.url) did not return an MP3 file."
        exit 1
    }
    Move-Item -Force $partial $path
    Write-Host "downloaded  $($clip.file)  <- $($clip.url)"
}

$bytes = ($manifest.clips | ForEach-Object { (Get-Item (Join-Path $target $_.file)).Length } | Measure-Object -Sum).Sum
Write-Host ("{0} files, {1:N1} MB in {2}" -f $manifest.clips.Count, ($bytes / 1MB), $target)
