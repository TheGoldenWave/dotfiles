# ═══════════════════════════════════════════════════
# GoldenWave Dev Environment Bootstrap (Windows)
# ═══════════════════════════════════════════════════
$ErrorActionPreference = "Stop"

$DotfilesDir = "$env:USERPROFILE\Documents\dotfiles"
$RepoUrl = "git@github.com:TheGoldenWave/dotfiles.git"

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Write-Ok   { param($msg) Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ─── Phase 0: Check Git and SSH ───
Write-Info "Checking prerequisites..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "Git not found. Install from: https://git-scm.com/download/win"
    exit 1
}

# Ensure Git Bash is available (for .sh scripts)
$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $gitBash)) {
    $gitBash = (Get-Command bash -ErrorAction SilentlyContinue)?.Source
}
if (-not $gitBash) {
    Write-Warn "Git Bash not found — some .sh scripts won't run"
    Write-Info "Install Git for Windows which includes Git Bash"
}

function Invoke-Bash {
    param([string]$script, [string[]]$args = @())
    if ($gitBash) {
        & $gitBash $script @args
    } else {
        Write-Warn "Cannot run bash script: $script"
    }
}

# ─── Phase 1: Clone dotfiles repo ───
if (-not (Test-Path "$DotfilesDir\.git")) {
    Write-Info "Cloning dotfiles repository..."
    New-Item -ItemType Directory -Path (Split-Path $DotfilesDir -Parent) -Force -ErrorAction SilentlyContinue | Out-Null
    git clone $RepoUrl $DotfilesDir 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "SSH clone failed, trying HTTPS via proxy..."
        git clone "https://ghfast.top/$RepoUrl" $DotfilesDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            git clone "https://github.com/TheGoldenWave/dotfiles.git" $DotfilesDir
        }
    }
    Write-Ok "Repository cloned"
}

# ─── Phase 2: Install Chocolatey + core tools ───
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Ok "Chocolatey installed"
}

Write-Info "Installing core tools..."
& "$DotfilesDir\scripts\install-tools-win.ps1"

# ─── Phase 3: Node.js ───
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Node.js..."
    choco install nodejs-lts -y
    refreshenv 2>$null  # refresh PATH
    Write-Ok "Node.js installed"
}

# ─── Phase 4: Python ───
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Python..."
    choco install python -y
    Write-Ok "Python installed"
}

# ─── Phase 5: PowerShell profile (instead of zshrc) ───
Write-Info "Setting up PowerShell profile..."
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Create/update profile
$profileContent = @"
# GoldenWave PowerShell Profile
# PATH additions
`$env:Path = "`$env:USERPROFILE\bin;`$env:USERPROFILE\.local\bin;`$env:USERPROFILE\.npm-global\bin;`$env:Path"

# Hermes Agent
`$env:HERMES_CODING_PLAN_SK = "sk-zco...312f"

# Aliases (PowerShell equivalents)
function claude-mem { & bun "`$env:USERPROFILE\.zcode\plugins\marketplaces\zyb-plugins\plugins\claude-mem\scripts\worker-service.cjs" }
"@

$profileContent | Out-File -FilePath $PROFILE -Encoding UTF8
Write-Ok "PowerShell profile installed"

# Also set up Git Bash profile (for .sh scripts)
if ($gitBash) {
    $bashrcPath = "$env:USERPROFILE\.bashrc"
    if (Test-Path "$DotfilesDir\dotfiles\zshrc") {
        # Convert zshrc to bashrc-compatible subset
        $zshrc = Get-Content "$DotfilesDir\dotfiles\zshrc" -Raw
        # Write a simplified bashrc
        @"
# GoldenWave Git Bash profile (auto-generated from dotfiles)
export PATH="`$HOME/bin:`$HOME/.local/bin:`$HOME/.npm-global/bin:`$PATH"
export PATH="`$HOME/.opencode/bin:`$PATH"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
export API_TIMEOUT_MS=600000
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
"@ | Out-File -FilePath $bashrcPath -Encoding UTF8
        Write-Ok "Git Bash profile installed"
    }
}

# ─── Phase 6: Hermes Agent ───
Write-Info "Setting up Hermes Agent..."
$HermesDir = "$env:USERPROFILE\.hermes"
New-Item -ItemType Directory -Path $HermesDir -Force -ErrorAction SilentlyContinue | Out-Null

if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
    Write-Info "Installing Hermes..."
    # Try pip install
    pip install hermes-agent 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Hermes pip install failed. Install manually from https://hermes-agent.nousresearch.com"
    }
}

# Config
if (Test-Path "$DotfilesDir\dotfiles\hermes\config.yaml") {
    if (Test-Path "$HermesDir\config.yaml") {
        Copy-Item "$HermesDir\config.yaml" "$HermesDir\config.yaml.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\hermes\config.yaml" "$HermesDir\config.yaml" -Force
    Write-Ok "Hermes config installed"
}

# .env template
if (Test-Path "$DotfilesDir\dotfiles\hermes\env.template") {
    if (-not (Test-Path "$HermesDir\.env")) {
        Copy-Item "$DotfilesDir\dotfiles\hermes\env.template" "$HermesDir\.env" -Force
        Write-Warn "Hermes .env created — EDIT SECRETS BEFORE USE"
    }
}

# Scripts
if (Test-Path "$DotfilesDir\dotfiles\hermes\scripts") {
    New-Item -ItemType Directory -Path "$HermesDir\scripts" -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$DotfilesDir\dotfiles\hermes\scripts\*" "$HermesDir\scripts\" -Force
    Write-Ok "Hermes scripts installed"
}

# Memories
if (Test-Path "$DotfilesDir\dotfiles\hermes\memories") {
    New-Item -ItemType Directory -Path "$HermesDir\memories" -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$DotfilesDir\dotfiles\hermes\memories\*.md" "$HermesDir\memories\" -Force
    Write-Ok "Hermes memories restored"
}

# SOUL.md
if (Test-Path "$DotfilesDir\dotfiles\hermes\SOUL.md") {
    Copy-Item "$DotfilesDir\dotfiles\hermes\SOUL.md" "$HermesDir\SOUL.md" -Force
    Write-Ok "Hermes SOUL.md installed"
}

# ─── Phase 7: Claude Code ───
Write-Info "Setting up Claude Code..."
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    npm install -g @anthropic-ai/claude-code 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "Claude Code installed" }
}

$ClaudeDir = "$env:USERPROFILE\.claude"
New-Item -ItemType Directory -Path $ClaudeDir -Force -ErrorAction SilentlyContinue | Out-Null

if (Test-Path "$DotfilesDir\dotfiles\claude\settings.json") {
    if (Test-Path "$ClaudeDir\settings.json") {
        Copy-Item "$ClaudeDir\settings.json" "$ClaudeDir\settings.json.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\claude\settings.json" "$ClaudeDir\settings.json" -Force
    Write-Ok "Claude Code settings installed"
}

if (Test-Path "$DotfilesDir\dotfiles\claude\hooks") {
    New-Item -ItemType Directory -Path "$ClaudeDir\hooks" -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$DotfilesDir\dotfiles\claude\hooks\*" "$ClaudeDir\hooks\" -Force
    Write-Ok "Claude Code hooks installed"
}

if (Test-Path "$DotfilesDir\dotfiles\claude\CLAUDE.md") {
    Copy-Item "$DotfilesDir\dotfiles\claude\CLAUDE.md" "$ClaudeDir\CLAUDE.md" -Force
    Write-Ok "Claude CLAUDE.md installed"
}

# ─── Phase 8: Codex ───
Write-Info "Setting up Codex..."
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    npm install -g @openai/codex 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "Codex installed" }
}

$CodexDir = "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Path $CodexDir -Force -ErrorAction SilentlyContinue | Out-Null

if (Test-Path "$DotfilesDir\dotfiles\codex\config.toml") {
    if (Test-Path "$CodexDir\config.toml") {
        Copy-Item "$CodexDir\config.toml" "$CodexDir\config.toml.bak.$(Get-Date -Format 'yyyyMMdd')"
    }
    Copy-Item "$DotfilesDir\dotfiles\codex\config.toml" "$CodexDir\config.toml" -Force
    Write-Ok "Codex config installed"
}

if (Test-Path "$DotfilesDir\dotfiles\codex\agents") {
    New-Item -ItemType Directory -Path "$CodexDir\agents" -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$DotfilesDir\dotfiles\codex\agents\*" "$CodexDir\agents\" -Force
    Write-Ok "Codex agents installed"
}

if (Test-Path "$DotfilesDir\dotfiles\codex\hooks.json") {
    Copy-Item "$DotfilesDir\dotfiles\codex\hooks.json" "$CodexDir\hooks.json" -Force
    Write-Ok "Codex hooks installed"
}

if (Test-Path "$DotfilesDir\dotfiles\codex\AGENTS.md") {
    Copy-Item "$DotfilesDir\dotfiles\codex\AGENTS.md" "$CodexDir\AGENTS.md" -Force
    Write-Ok "Codex AGENTS.md installed"
}

# ─── Phase 9: ~/bin tools ───
Write-Info "Setting up ~/bin tools..."
New-Item -ItemType Directory -Path "$env:USERPROFILE\bin" -Force -ErrorAction SilentlyContinue | Out-Null

# Note: multica and opencode are macOS binaries — Windows needs different versions
if (Test-Path "$DotfilesDir\bin\multica-post-commit.py") {
    Copy-Item "$DotfilesDir\bin\multica-post-commit.py" "$env:USERPROFILE\bin\" -Force
    Write-Ok "multica-post-commit.py installed"
}

Write-Warn "multica binary is macOS-only. Windows version needed separately."
Write-Warn "opencode wrapper is macOS-only. Install Windows version from nicepkg/opencode."

# ─── Phase 10: NPM global packages ───
Write-Info "Installing npm global packages..."
$npmGlobals = @("@anthropic-ai/claude-code", "@openai/codex", "bun")
foreach ($pkg in $npmGlobals) {
    npm list -g $pkg 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        npm install -g $pkg 2>$null
        if ($LASTEXITCODE -eq 0) { Write-Ok "  $pkg installed" }
    }
}

# ─── Phase 11: Clone repos ───
Write-Info "Cloning project repositories..."
Invoke-Bash "$DotfilesDir\scripts\clone-repos.sh" 2>$null

# ─── Phase 12: AI Workflow files ───
Write-Info "Installing AI workflow files..."
if (Test-Path "$DotfilesDir\dotfiles\ai-workflow") {
    $aiDir = "$env:USERPROFILE\Documents\AI工作流"
    New-Item -ItemType Directory -Path $aiDir -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$DotfilesDir\dotfiles\ai-workflow\*" $aiDir -Force
    Write-Ok "AI workflow files installed"
}

# ─── Phase 13: Git config ───
if (Test-Path "$DotfilesDir\dotfiles\gitconfig") {
    Copy-Item "$DotfilesDir\dotfiles\gitconfig" "$env:USERPROFILE\.gitconfig" -Force
    Write-Ok "Git config installed"
}

# ─── Phase 14: Skills sync ───
Write-Info "Syncing skills..."
Invoke-Bash "$DotfilesDir\scripts\sync-skills.sh" 2>$null

# ─── Phase 15: SSH key ───
if (-not (Test-Path "$env:USERPROFILE\.ssh\id_ed25519")) {
    Write-Warn "No SSH key found!"
    Write-Info "  Option A: Copy from old device"
    Write-Info "  Option B: ssh-keygen -t ed25519 -C 'goldenwave0322@gmail.com'"
    Write-Info "     Then add to GitHub: https://github.com/settings/keys"
}

# ─── Phase 16: SeaDrive ───
if (-not (Test-Path "$env:USERPROFILE\SeaDrive") -and -not (Get-Process SeaDrive -ErrorAction SilentlyContinue)) {
    Write-Warn "SeaDrive not found. Install from: https://www.seafile.com/en/download/"
}

# ─── Done ───
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Bootstrap complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit secrets:  notepad $HermesDir\.env"
Write-Host "  2. Restart PowerShell to load profile"
Write-Host "  3. Test Hermes:   hermes"
Write-Host "  4. Test Claude:   claude"
Write-Host "  5. Test Codex:    codex"
Write-Host ""
Write-Host "Windows-specific notes:" -ForegroundColor Yellow
Write-Host "  - multica binary is macOS-only; contact team for Windows build"
Write-Host "  - Some .sh scripts require Git Bash (included with Git for Windows)"
Write-Host "  - LaunchAgents are macOS-only; use Task Scheduler for equivalents"
Write-Host "  - SeaDrive path on Windows: C:\Users\yourname\SeaDrive"
Write-Host ""
