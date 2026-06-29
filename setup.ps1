# ═══════════════════════════════════════════════════
# GoldenWave Dev Environment Bootstrap (Windows)
# ═══════════════════════════════════════════════════
$ErrorActionPreference = "Stop"

$DotfilesDir = "$env:USERPROFILE\Documents\dotfiles"
$RepoUrl = "git@github.com:TheGoldenWave/dotfiles.git"

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ─── Phase 0: Check Git and SSH ───
Write-Info "Checking prerequisites..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git not found. Install from: https://git-scm.com/download/win"
    exit 1
}

# Test SSH connection to GitHub
$sshTest = ssh -T git@github.com 2>&1
if (-not ($sshTest -match "success|Hi ")) {
    Write-Warn "SSH key not configured for GitHub"
    Write-Info "Generate SSH key: ssh-keygen -t ed25519 -C 'goldenwave0322@gmail.com'"
    Write-Info "Then add to: https://github.com/settings/keys"
}

# ─── Phase 1: Clone dotfiles repo ───
if (-not (Test-Path "$DotfilesDir\.git")) {
    Write-Info "Cloning dotfiles repository..."
    $parentDir = Split-Path $DotfilesDir -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    git clone $RepoUrl $DotfilesDir
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "SSH clone failed, trying HTTPS..."
        git clone "https://github.com/TheGoldenWave/dotfiles.git" $DotfilesDir
    }
    Write-Ok "Repository cloned"
}

# ─── Phase 2: Install Chocolatey (package manager) ───
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Ok "Chocolatey installed"
}

# ─── Phase 3: Core tools via Chocolatey ───
Write-Info "Installing core tools..."
& "$DotfilesDir\scripts\install-tools-win.ps1"

# ─── Phase 4: Node.js ───
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Node.js..."
    choco install nodejs-lts -y
    Write-Ok "Node.js installed"
}

# ─── Phase 5: Python ───
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Python..."
    choco install python -y
    Write-Ok "Python installed"
}

# ─── Phase 6: Hermes Agent ───
Write-Info "Setting up Hermes Agent..."
$HermesDir = "$env:USERPROFILE\.hermes"
if (-not (Test-Path $HermesDir)) {
    New-Item -ItemType Directory -Path $HermesDir -Force | Out-Null
}

if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Hermes..."
    # Hermes Windows installation (placeholder - adjust as needed)
    Write-Warn "Hermes Windows installation not yet automated"
    Write-Info "Visit: https://hermes-agent.nousresearch.com/docs"
}

# Copy config
if (Test-Path "$DotfilesDir\dotfiles\hermes\config.yaml") {
    if (Test-Path "$HermesDir\config.yaml") {
        Copy-Item "$HermesDir\config.yaml" "$HermesDir\config.yaml.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\hermes\config.yaml" "$HermesDir\config.yaml"
    Write-Ok "Hermes config installed"
}

# Copy .env template
if (Test-Path "$DotfilesDir\dotfiles\hermes\env.template") {
    if (-not (Test-Path "$HermesDir\.env")) {
        Copy-Item "$DotfilesDir\dotfiles\hermes\env.template" "$HermesDir\.env"
        Write-Warn "Hermes .env created — EDIT SECRETS BEFORE USE"
    }
}

# ─── Phase 7: Claude Code ───
Write-Info "Setting up Claude Code..."
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    npm install -g @anthropic-ai/claude-code
    Write-Ok "Claude Code installed"
}

$ClaudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

if (Test-Path "$DotfilesDir\dotfiles\claude\settings.json") {
    if (Test-Path "$ClaudeDir\settings.json") {
        Copy-Item "$ClaudeDir\settings.json" "$ClaudeDir\settings.json.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\claude\settings.json" "$ClaudeDir\settings.json"
    Write-Ok "Claude Code settings installed"
}

# ─── Phase 8: Codex ───
Write-Info "Setting up Codex..."
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    npm install -g @openai/codex
    Write-Ok "Codex installed"
}

$CodexDir = "$env:USERPROFILE\.codex"
if (-not (Test-Path $CodexDir)) {
    New-Item -ItemType Directory -Path $CodexDir -Force | Out-Null
}

if (Test-Path "$DotfilesDir\dotfiles\codex\config.toml") {
    if (Test-Path "$CodexDir\config.toml") {
        Copy-Item "$CodexDir\config.toml" "$CodexDir\config.toml.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\codex\config.toml" "$CodexDir\config.toml"
    Write-Ok "Codex config installed"
}

# ─── Phase 9: Clone repos ───
Write-Info "Cloning project repositories..."
if (Test-Path "$DotfilesDir\scripts\clone-repos.sh") {
    bash "$DotfilesDir\scripts\clone-repos.sh"
}

# ─── Phase 10: SSH key ───
if (-not (Test-Path "$env:USERPROFILE\.ssh\id_ed25519")) {
    Write-Warn "No SSH key found!"
    Write-Info "Options:"
    Write-Info "  1. Copy from old device"
    Write-Info "  2. Generate new: ssh-keygen -t ed25519 -C 'goldenwave0322@gmail.com'"
    Write-Info "     Then add to GitHub: https://github.com/settings/keys"
}

# ─── Done ───
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ Bootstrap complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit secrets:  $DotfilesDir\scripts\restore-secrets.sh"
Write-Host "  2. Restart terminal or run: refreshenv"
Write-Host "  3. Test Hermes:   hermes"
Write-Host "  4. Test Claude:   claude"
Write-Host "  5. Test Codex:    codex"
Write-Host ""
