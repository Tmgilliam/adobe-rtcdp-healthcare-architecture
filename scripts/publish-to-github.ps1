# publish-to-github.ps1
# Creates the standalone GitHub repo and publishes this project from the MTP monorepo.
#
# Prerequisites:
#   gh auth login
#
# Usage (from monorepo root):
#   .\adobe-rtcdp-healthcare-architecture\scripts\publish-to-github.ps1
#
# Or:
#   .\scripts\push-standalone-project.ps1 `
#     -ProjectPath adobe-rtcdp-healthcare-architecture `
#     -RepoUrl https://github.com/Tmgilliam/adobe-rtcdp-healthcare-architecture.git

param(
    [string]$RepoName = "adobe-rtcdp-healthcare-architecture",
    [string]$Description = "HIPAA-governed Adobe RTCDP healthcare architecture case study — XDM schema, identity stitching, consent model. Portfolio project by Dr. Tatianna Gilliam.",
    [ValidateSet("public", "private")]
    [string]$Visibility = "public"
)

$ErrorActionPreference = "Stop"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) {
    $gh = "gh"
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MonorepoRoot = Split-Path -Parent $ProjectRoot

Write-Host "Checking GitHub authentication..."
& $gh auth status
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run: gh auth login"
    exit 1
}

Set-Location $MonorepoRoot

$repoExists = $false
try {
    & $gh repo view "Tmgilliam/$RepoName" --json url -q .url 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $repoExists = $true }
} catch {}

if (-not $repoExists) {
    Write-Host "Creating GitHub repository: $RepoName ($Visibility)..."
    & $gh repo create $RepoName `
        --$Visibility `
        --description $Description
    if ($LASTEXITCODE -ne 0) { throw "gh repo create failed" }
}

Write-Host "Publishing standalone via subtree split..."
& (Join-Path $MonorepoRoot "scripts\push-standalone-project.ps1") `
    -ProjectPath $RepoName `
    -RepoUrl "https://github.com/Tmgilliam/$RepoName.git"

if ($LASTEXITCODE -eq 0) {
    $url = & $gh repo view "Tmgilliam/$RepoName" --json url -q .url
    Write-Host ""
    Write-Host "Published successfully: $url"
}
