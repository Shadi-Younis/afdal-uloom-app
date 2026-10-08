# Fills the running Auth and Firestore emulators with test data
# (tool/seed/src/data.ts). Start tool/emulators.ps1 first, in another
# terminal; the data then persists in .emulator-data.
#
#   powershell -ExecutionPolicy Bypass -File tool/seed_emulator.ps1
#
# Safe to run again: accounts and documents have fixed ids and are
# overwritten. Every account's password is test1234.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

# Point the Admin SDK at the emulators (ports from firebase.json), unless
# the caller already did. The seed script itself refuses to run without
# these, so it can never write to the real project.
if (-not $env:FIRESTORE_EMULATOR_HOST) { $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080' }
if (-not $env:FIREBASE_AUTH_EMULATOR_HOST) { $env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099' }

foreach ($hostPort in @($env:FIRESTORE_EMULATOR_HOST, $env:FIREBASE_AUTH_EMULATOR_HOST)) {
    $emulatorHost, $port = $hostPort -split ':'
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($emulatorHost, [int]$port)
    }
    catch {
        Write-Error "No emulator at $hostPort. Start tool/emulators.ps1 first."
        exit 1
    }
    finally {
        $client.Dispose()
    }
}

Push-Location $root
try {
    if (-not (Test-Path (Join-Path $root 'tool\seed\node_modules'))) {
        npm --prefix tool/seed ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    npm --prefix tool/seed run seed
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
