# Starts the Firebase Emulator Suite and keeps its data between runs.
#
#   powershell -ExecutionPolicy Bypass -File tool/emulators.ps1
#
# Stop it with Ctrl+C: the data is exported to .emulator-data (gitignored) and
# imported again on the next start.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $root '.emulator-data'
$originalPath = $env:PATH

# Oracle's installer puts a java.exe launcher stub (javapath) first on PATH,
# which starts the real JVM as a child. The CLI stops the Firestore emulator by
# killing the process it started, i.e. the stub, so the real JVM would keep
# port 8080 busy after Ctrl+C. Put the real java.exe first for this run.
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
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir | Out-Null
    }

    if (-not (Test-Path (Join-Path $root 'functions\node_modules'))) {
        npm --prefix functions ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    npm --prefix functions run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    firebase emulators:start --import=.emulator-data --export-on-exit=.emulator-data
}
finally {
    Pop-Location
    $env:PATH = $originalPath
}
