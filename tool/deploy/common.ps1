# Shared guards for the deploy scripts in this folder (dot-sourced, never
# run on its own). Deploys go to the REAL project, so every check stops the
# script instead of warning. See docs/DEPLOY_NOTES.md.

$ProjectId = 'afdal-al-uloom'

function Stop-Deploy([string]$message) {
    Write-Host ''
    Write-Host "STOPPED: $message" -ForegroundColor Red
    Write-Host 'Nothing was deployed.' -ForegroundColor Red
    exit 1
}

function Write-Step([string]$message) {
    Write-Host ''
    Write-Host "==> $message" -ForegroundColor Cyan
}

# Runs a native command and stops the deploy if it fails.
function Invoke-Checked([string]$label, [scriptblock]$command) {
    Write-Step $label
    & $command
    if ($LASTEXITCODE -ne 0) { Stop-Deploy "$label failed (exit code $LASTEXITCODE)." }
}

# What is deployed must be exactly a commit on origin/main: either the tip of
# main (normal deploy) or, with -RollbackTag, a release tag on main's history
# (rollback). Uncommitted changes would deploy code nobody reviewed.
function Assert-DeployableCheckout([string]$rollbackTag) {
    Write-Step 'Checking the git checkout'
    if (git status --porcelain) { Stop-Deploy 'there are uncommitted changes (git status).' }

    git fetch origin --tags --quiet
    if ($LASTEXITCODE -ne 0) { Stop-Deploy 'git fetch origin failed.' }

    $head = git rev-parse HEAD
    if ($rollbackTag) {
        $tagCommit = git rev-parse --verify --quiet "$rollbackTag^{commit}"
        if (-not $tagCommit) { Stop-Deploy "tag $rollbackTag does not exist." }
        if ($head -ne $tagCommit) { Stop-Deploy "check out the tag first: git checkout $rollbackTag" }
        git merge-base --is-ancestor $tagCommit origin/main
        if ($LASTEXITCODE -ne 0) { Stop-Deploy "tag $rollbackTag is not on main." }
        Write-Host "OK: clean checkout of $rollbackTag ($($head.Substring(0, 7))), which is on main."
        return
    }

    $branch = git branch --show-current
    if ($branch -ne 'main') { Stop-Deploy "you are on '$branch'. Run: git checkout main; git pull" }
    if ($head -ne (git rev-parse origin/main)) { Stop-Deploy 'main is not the same as origin/main. Run: git pull' }
    Write-Host "OK: clean main, same as origin/main ($($head.Substring(0, 7)))."
}

function Assert-FirebaseLogin {
    Write-Step 'Checking the Firebase CLI login'
    $login = firebase login:list 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $login -notmatch 'Logged in as (\S+)') {
        Stop-Deploy 'the Firebase CLI is not logged in. Run: firebase login'
    }
    Write-Host "Logged in as $($Matches[1])"
}

# The typed project id is the last chance to cancel.
function Confirm-Deploy {
    Write-Host ''
    $answer = Read-Host "Type the project id ($ProjectId) to deploy, anything else cancels"
    if ($answer -cne $ProjectId) { Stop-Deploy 'cancelled.' }
}
