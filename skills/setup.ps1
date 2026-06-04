# Botai AI Skills setup (Windows PowerShell)
# Usage: .\skills\setup.ps1 [-Claude] [-Codex] [-Copilot] [-Gemini] [-All]

param(
    [switch]$Claude,
    [switch]$Codex,
    [switch]$Copilot,
    [switch]$Gemini,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$SkillsSource = Join-Path $RepoRoot "skills"
$AgentsSource = Join-Path $RepoRoot "agents"

function Add-GitIgnorePattern {
    param([string]$Pattern)
    $gitignore = Join-Path $RepoRoot ".gitignore"
    $header = "# AI coding assistants (generated symlinks)"
    if (-not (Test-Path $gitignore)) { New-Item -ItemType File -Path $gitignore | Out-Null }
    $content = Get-Content $gitignore -Raw
    if ($content -notmatch [regex]::Escape($Pattern)) {
        if ($content -notmatch [regex]::Escape($header)) {
            Add-Content $gitignore "`n$header"
        }
        Add-Content $gitignore $Pattern
        Write-Host "  Added $Pattern to .gitignore" -ForegroundColor Green
    }
}

function Link-Directory {
    param([string]$Target, [string]$Source)
    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-Item $Target -Force -Recurse }
        else { Rename-Item $Target "$Target.backup.$(Get-Date -Format 'yyyyMMddHHmmss')" }
    }
    # Junction (/J) works without admin on Windows; symlink needs Developer Mode or elevation
    $ok = $false
    cmd /c "mklink /J `"$Target`" `"$Source`"" 2>$null | Out-Null
    if (Test-Path $Target) { $ok = $true }
    if (-not $ok) {
        try {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
            $ok = $true
        } catch {
            Write-Warning "Could not link $Target -> $Source. Enable Developer Mode (symlinks) or run as Administrator, or use Git Bash: ./skills/setup.sh --claude"
        }
    }
}

function Link-AgentsMd {
    param([string]$LinkName)
    $count = 0
    Get-ChildItem -Path $RepoRoot -Filter "AGENTS.md" -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
        ForEach-Object {
            $dir = $_.DirectoryName
            $linkPath = Join-Path $dir $LinkName
            if (Test-Path $linkPath) { Remove-Item $linkPath -Force -ErrorAction SilentlyContinue }
            $linked = $false
            try {
                cmd /c "mklink `"$linkPath`" `"$($_.Name)`"" 2>$null | Out-Null
                if (Test-Path $linkPath) { $linked = $true }
            } catch { }
            if (-not $linked) {
                Copy-Item $_.FullName $linkPath -Force
            }
            $count++
        }
    Write-Host "  Linked/copied $count AGENTS.md -> $LinkName" -ForegroundColor Green
}

if ($All) { $Claude = $Codex = $Copilot = $Gemini = $true }
if (-not ($Claude -or $Codex -or $Copilot -or $Gemini)) { $Claude = $true }

$skillCount = (Get-ChildItem $SkillsSource -Recurse -Filter "SKILL.md").Count
Write-Host "Botai AI Skills Setup ($skillCount skills)" -ForegroundColor Cyan

if ($Claude) {
    Link-Directory (Join-Path $RepoRoot ".claude\skills") $SkillsSource
    Write-Host "  .claude\skills -> skills\" -ForegroundColor Green
    $cursorSkills = Join-Path $RepoRoot ".cursor\skills"
    Link-Directory $cursorSkills $SkillsSource
    if (Test-Path $cursorSkills) {
        Write-Host "  .cursor\skills -> skills\" -ForegroundColor Green
        Add-GitIgnorePattern ".cursor/skills"
    }
    if (Test-Path $AgentsSource) {
        Link-Directory (Join-Path $RepoRoot ".claude\agents") $AgentsSource
        Write-Host "  .claude\agents -> agents\" -ForegroundColor Green
        Add-GitIgnorePattern ".claude/agents"
    }
    Add-GitIgnorePattern ".claude/skills"
    Link-AgentsMd "CLAUDE.md"
    Add-GitIgnorePattern "CLAUDE.md"
}

if ($Gemini) {
    Link-Directory (Join-Path $RepoRoot ".gemini\skills") $SkillsSource
    Add-GitIgnorePattern ".gemini/skills"
    Link-AgentsMd "GEMINI.md"
    Add-GitIgnorePattern "GEMINI.md"
}

if ($Codex) {
    Link-Directory (Join-Path $RepoRoot ".codex\skills") $SkillsSource
    Add-GitIgnorePattern ".codex/skills"
}

if ($Copilot -and (Test-Path (Join-Path $RepoRoot "AGENTS.md"))) {
    $gh = Join-Path $RepoRoot ".github"
    if (-not (Test-Path $gh)) { New-Item -ItemType Directory -Path $gh | Out-Null }
    $target = Join-Path $gh "copilot-instructions.md"
    if (Test-Path $target) { Remove-Item $target -Force }
    cmd /c mklink $target "..\AGENTS.md" 2>$null | Out-Null
    Add-GitIgnorePattern ".github/copilot-instructions.md"
}

Write-Host "`nDone. Restart your AI assistant." -ForegroundColor Green
Write-Host "Regenerate Auto-invoke: bash skills/skill-sync/assets/sync.sh" -ForegroundColor Cyan
