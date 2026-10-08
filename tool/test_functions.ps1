# Runs the Cloud Functions tests (functions/test/) against fresh Auth,
# Firestore and Functions emulators, which start and stop with the tests:
#
#   powershell -ExecutionPolicy Bypass -File tool/test_functions.ps1
#
# The tests call the real callables over HTTP. Stop tool/emulators.ps1
# first: both use the same ports.
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

# Loading the functions (firebase-admin) can take over the emulator's 10 s
# discovery limit while the Java emulators start on a cold machine.
if (-not $env:FUNCTIONS_DISCOVERY_TIMEOUT) { $env:FUNCTIONS_DISCOVERY_TIMEOUT = '60' }

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root 'functions\node_modules'))) {
        npm --prefix functions ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    # The Functions emulator runs the compiled code in functions/lib.
    npm --prefix functions run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    firebase emulators:exec --only auth,firestore,functions "npm --prefix functions test"
    exit $LASTEXITCODE
}
finally {
    Pop-Location
    $env:PATH = $originalPath
}
