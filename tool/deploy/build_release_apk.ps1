# Builds the Android release APK, which talks to the REAL project (no
# emulator defines; release builds ignore USE_EMULATORS anyway):
#
#   powershell -ExecutionPolicy Bypass -File tool/deploy/build_release_apk.ps1
#
# Until the store release task adds an upload keystore, the release build is
# signed with the DEBUG key (android/app/build.gradle.kts). Such an APK is
# fine for installing on our own phones, but it cannot go to Google Play,
# and a later APK signed with the real key cannot update it (uninstall
# first). See docs/DEPLOY_NOTES.md.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'

Push-Location $root
try {
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $debugSigned = Select-String -Path android/app/build.gradle.kts -Pattern 'signingConfigs\.getByName\("debug"\)' -Quiet
    Write-Host ''
    if ($debugSigned) {
        Write-Host 'WARNING: this release APK is signed with the DEBUG key.' -ForegroundColor Yellow
        Write-Host '  OK for our own test phones. NOT for Google Play, and a future APK' -ForegroundColor Yellow
        Write-Host '  signed with the real upload key cannot update it (uninstall first).' -ForegroundColor Yellow
    }
    $sizeMb = [Math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host "APK ($sizeMb MB): $apk" -ForegroundColor Green
}
finally {
    Pop-Location
}
