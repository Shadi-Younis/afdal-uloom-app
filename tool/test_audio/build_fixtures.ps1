# Builds the audio fixtures of the recording analysis from al-Minshawi's
# recitations (tool/test_audio/build_fixtures.mjs), outside the repo in
# ..\test-audio\fixtures (C:\dev\test-audio\fixtures). Never committed.
#
#   powershell -ExecutionPolicy Bypass -File tool/test_audio/build_fixtures.ps1
#
# Needs the recitations (tool/seed/download_test_audio.ps1) and ffmpeg from
# functions/node_modules (ffmpeg-static).
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root 'functions\node_modules\ffmpeg-static'))) {
        npm --prefix functions ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    node tool/test_audio/build_fixtures.mjs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
