# Runs the Firestore and Storage security rules tests (rules-tests/)
# against fresh Firestore and Storage emulators, which start and stop with
# the tests (the Storage rules read Firestore documents, so both run):
#
#   powershell -ExecutionPolicy Bypass -File tool/test_rules.ps1
#
# Stop tool/emulators.ps1 first: both use ports 8080 and 9199. Run this
# after every change to firestore.rules or storage.rules.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$originalPath = $env:PATH

# Same java.exe launcher-stub fix as tool/emulators.ps1: without it the
# emulator's JVM can outlive the run and keep port 8080 busy.
if (Get-Command java -ErrorAction SilentlyContinue) {
    $javaHome = cmd /c 'java -XshowSettings:properties -version 2>&1' |
        Select-String 'java\.home = (.+)' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } |
        Select-Object -First 1
    if ($javaHome) { $env:PATH = "$javaHome\bin;$env:PATH" }
}

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root 'rules-tests\node_modules'))) {
        npm --prefix rules-tests ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
    exit $LASTEXITCODE
}
finally {
    Pop-Location
    $env:PATH = $originalPath
}
