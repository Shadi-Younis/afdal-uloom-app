# Deploys the backend to the REAL project afdal-al-uloom: Firestore rules and
# indexes, Storage rules and every Cloud Function. Run it yourself, in your
# own PowerShell window (it asks questions), with the emulators stopped:
#
#   powershell -ExecutionPolicy Bypass -File tool/deploy/deploy_backend.ps1
#
# Rollback: git checkout <tag>, then run it with -RollbackTag <tag>.
# It refuses to run unless the checkout is clean main (or the given tag on
# main), runs every test, shows what it will deploy and asks you to type the
# project id. See docs/DEPLOY_NOTES.md.
param([string]$RollbackTag)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$targets = 'firestore:rules,firestore:indexes,storage,functions'

Push-Location $root
try {
    Assert-DeployableCheckout $RollbackTag
    Assert-FirebaseLogin

    Invoke-Checked 'flutter analyze' { flutter analyze }
    Invoke-Checked 'flutter test' { flutter test }
    Invoke-Checked 'Rules tests (tool/test_rules.ps1)' {
        powershell -ExecutionPolicy Bypass -File tool/test_rules.ps1
    }
    Invoke-Checked 'Functions tests (tool/test_functions.ps1)' {
        powershell -ExecutionPolicy Bypass -File tool/test_functions.ps1
    }

    # Read from the sources, so the list can never go stale.
    $functions = Select-String -Path functions/src/index.ts -Pattern '^export \{(\w+)\}' |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
    $region = (Select-String -Path functions/src/lib/constants.ts -Pattern 'REGION = "([^"]+)"').Matches[0].Groups[1].Value
    $indexCount = ((Get-Content firestore.indexes.json -Raw | ConvertFrom-Json).indexes).Count

    Write-Step 'About to deploy'
    Write-Host "Project:  $ProjectId (REAL, not the emulators)"
    Write-Host "Commit:   $(git log -1 --format='%h %s')"
    Write-Host 'Firestore rules:   firestore.rules'
    Write-Host "Firestore indexes: firestore.indexes.json ($indexCount composite indexes)"
    Write-Host 'Storage rules:     storage.rules'
    Write-Host "Functions ($($functions.Count), region $region):"
    $functions | ForEach-Object { Write-Host "  - $_" }
    Write-Host ''
    Write-Host 'Firebase may then ask (see docs/DEPLOY_NOTES.md):'
    Write-Host '  - to grant Storage an IAM role for cross-service rules: answer y'
    Write-Host '  - how many days to keep container images: answer 1'
    Confirm-Deploy

    Invoke-Checked "firebase deploy --only $targets" {
        firebase deploy --project $ProjectId --only $targets
    }

    Write-Step 'Deployed functions (every region must be me-west1)'
    firebase functions:list --project $ProjectId
    Write-Host ''
    Write-Host 'New indexes take a few minutes to build: Firebase Console > Firestore > Indexes.'
    Write-Host 'Done.' -ForegroundColor Green
}
finally {
    Pop-Location
}
