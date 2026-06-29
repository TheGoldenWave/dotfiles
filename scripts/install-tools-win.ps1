# Windows tools installation via Chocolatey
$ErrorActionPreference = "Stop"

function Write-Info { param($msg) Write-Host "[TOOLS] $msg" -ForegroundColor Blue }
function Write-Ok { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }

Write-Info "Installing Windows tools via Chocolatey..."

$packages = @(
    "git",
    "gh",           # GitHub CLI
    "ripgrep",
    "ffmpeg",
    "jq",
    "7zip",
    "notepadplusplus",
    "vscode",
    "postman",
    "docker-desktop"
)

foreach ($pkg in $packages) {
    if (-not (choco list --local-only $pkg 2>$null | Select-String "^$pkg ")) {
        Write-Info "  Installing $pkg..."
        choco install $pkg -y
        Write-Ok "  $pkg installed"
    } else {
        Write-Ok "  $pkg already installed"
    }
}

# Install WSL2 (optional)
Write-Info "Checking WSL2..."
$wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wsl.State -ne "Enabled") {
    Write-Warn "WSL2 not enabled. Enable manually if needed:"
    Write-Info "  wsl --install"
}
