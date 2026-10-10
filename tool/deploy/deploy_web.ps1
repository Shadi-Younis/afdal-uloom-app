# Builds the web app and deploys it to Firebase Hosting of the REAL project:
# https://afdal-al-uloom.web.app. Run it yourself, in your own PowerShell
# window (it asks you to confirm):
#
#   powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_web.ps1
#
# Rollback: git checkout <tag>, then run it with -RollbackTag <tag>.
# Same guards as deploy_backend.ps1. The release build has no emulator
# defines, so it always talks to the real project. See docs/DEPLOY_NOTES.md.
param([string]$RollbackTag)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$siteUrl = "https://$ProjectId.web.app"

Push-Location $root
try {
    Assert-DeployableCheckout $RollbackTag
    Assert-FirebaseLogin

    # Only the app is deployed here, so the rules and functions tests are
    # left to deploy_backend.ps1.
    Invoke-Checked 'flutter analyze' { flutter analyze }
    Invoke-Checked 'flutter test' { flutter test }

    Write-Step 'About to deploy'
    Write-Host "Project: $ProjectId (REAL, not the emulators)"
    Write-Host "Commit:  $(git log -1 --format='%h %s')"
    Write-Host "Hosting: build/web (flutter build web --release) -> $siteUrl"
    Confirm-Deploy

    Invoke-Checked 'flutter build web --release' { flutter build web --release }
    Invoke-Checked 'firebase deploy --only hosting' {
        firebase deploy --project $ProjectId --only hosting
    }

    Write-Host ''
    Write-Host "Done: $siteUrl" -ForegroundColor Green
}
finally {
    Pop-Location
}
