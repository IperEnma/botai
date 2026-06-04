# Botai AI Skills setup (Windows PowerShell)
# Usage: .\skills\setup.ps1  |  .\skills\setup.ps1 -Claude  |  .\skills\setup.ps1 -Help

param(
    [switch]$All,
    [switch]$Claude,
    [switch]$Gemini,
    [switch]$Codex,
    [switch]$Copilot,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$SkillsSource = Join-Path $RepoRoot "skills"
$AgentsSource = Join-Path $RepoRoot "agents"

function Show-Help {
    Write-Host @"
Usage: .\skills\setup.ps1 [OPTIONS]

Configure AI coding assistants for botai (optional local symlinks).

Options:
  -All       All assistants
  -Claude    .claude/skills, .cursor/skills, .claude/agents
  -Gemini    .gemini/skills
  -Codex     .codex/skills
  -Copilot   .github/copilot-instructions.md
  -Help      This help

No options = interactive menu.

NOTE: On Windows, .\skills\setup.sh does NOT run in PowerShell.
      Use this file or:  skills\setup.cmd

If you only use Cursor with AGENTS.md, you can skip setup entirely.
"@
}

function Add-GitIgnorePattern {
    param([string]$Pattern)
    $gitignore = Join-Path $RepoRoot ".gitignore"
    $header = "# AI Coding assistants assets"
    if (-not (Test-Path $gitignore)) { New-Item -ItemType File -Path $gitignore | Out-Null }
    $lines = @(Get-Content $gitignore -ErrorAction SilentlyContinue)
    if ($lines -notcontains $Pattern) {
        if ($lines -notcontains $header) {
            Add-Content $gitignore "`n$header"
        }
        Add-Content $gitignore $Pattern
        Write-Host "  [ok] Added $Pattern to .gitignore" -ForegroundColor Green
    }
}

function Link-Directory {
    param([string]$Target, [string]$Source)
    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item $Target -Force -Recurse
        } else {
            Rename-Item $Target "$Target.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        }
    }
    cmd /c "mklink /J `"$Target`" `"$Source`"" 2>$null | Out-Null
    if (-not (Test-Path $Target)) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction SilentlyContinue | Out-Null
    }
    if (-not (Test-Path $Target)) {
        Write-Warning "Could not link $Target -> $Source"
        return $false
    }
    return $true
}

function Test-IsReparsePoint {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    return ([IO.FileAttributes]::ReparsePoint -band (Get-Item $Path -Force).Attributes) -ne 0
}

function Link-AgentsMd {
    param([string]$LinkName)
    # Botai keeps a real CLAUDE.md at repo root (not a symlink to AGENTS.md).
    # Cursor reads AGENTS.md natively; only optional copies in subfolders for other tools.
    $linked = 0
    $skipped = 0
    Get-ChildItem -Path $RepoRoot -Filter "AGENTS.md" -Recurse -File |
        Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
        ForEach-Object {
            $linkPath = Join-Path $_.DirectoryName $LinkName
            # Never touch committed root CLAUDE.md / GEMINI.md
            if ($_.DirectoryName -eq $RepoRoot) {
                $skipped++
                return
            }
            if ((Test-Path $linkPath) -and -not (Test-IsReparsePoint $linkPath)) {
                $skipped++
                return
            }
            if (Test-IsReparsePoint $linkPath) {
                Remove-Item $linkPath -Force -ErrorAction SilentlyContinue
            }
            $agentsDir = $_.DirectoryName
            try {
                Copy-Item -LiteralPath $_.FullName -Destination $linkPath -Force
                $linked++
            } catch {
                Write-Host "  [skip] ${agentsDir}: could not write $LinkName" -ForegroundColor DarkYellow
            }
        }
    if ($linked -gt 0) {
        Write-Host "  [ok] Copied $linked AGENTS.md -> $LinkName (optional for Claude Code subfolders)" -ForegroundColor Green
    }
    if ($skipped -gt 0) {
        Write-Host "  [skip] $skipped existing $LinkName kept (e.g. root CLAUDE.md)" -ForegroundColor DarkGray
    }
    if ($linked -eq 0 -and $skipped -eq 0) {
        Write-Host "  [skip] No $LinkName copies needed" -ForegroundColor DarkGray
    }
}

function Setup-Claude {
    if (Link-Directory (Join-Path $RepoRoot ".claude\skills") $SkillsSource) {
        Write-Host "  [ok] .claude\skills -> skills\" -ForegroundColor Green
        Add-GitIgnorePattern ".claude/skills"
    }
    if (Link-Directory (Join-Path $RepoRoot ".cursor\skills") $SkillsSource) {
        Write-Host "  [ok] .cursor\skills -> skills\" -ForegroundColor Green
        Add-GitIgnorePattern ".cursor/skills"
    }
    if (Test-Path $AgentsSource) {
        if (Link-Directory (Join-Path $RepoRoot ".claude\agents") $AgentsSource) {
            Write-Host "  [ok] .claude\agents -> agents\" -ForegroundColor Green
            Add-GitIgnorePattern ".claude/agents"
        }
    }
    Link-AgentsMd "CLAUDE.md"
}

function Setup-Gemini {
    if (Link-Directory (Join-Path $RepoRoot ".gemini\skills") $SkillsSource) {
        Write-Host "  [ok] .gemini\skills -> skills\" -ForegroundColor Green
        Add-GitIgnorePattern ".gemini/skills"
    }
    Link-AgentsMd "GEMINI.md"
}

function Setup-Codex {
    if (Link-Directory (Join-Path $RepoRoot ".codex\skills") $SkillsSource) {
        Write-Host "  [ok] .codex\skills -> skills\" -ForegroundColor Green
        Add-GitIgnorePattern ".codex/skills"
    }
    Write-Host "  [ok] Codex uses AGENTS.md natively" -ForegroundColor Green
}

function Setup-Copilot {
    $agentsMd = Join-Path $RepoRoot "AGENTS.md"
    if (-not (Test-Path $agentsMd)) { return }
    $gh = Join-Path $RepoRoot ".github"
    if (-not (Test-Path $gh)) { New-Item -ItemType Directory -Path $gh | Out-Null }
    $target = Join-Path $gh "copilot-instructions.md"
    if ((Test-Path $target) -and (Test-IsReparsePoint $target)) {
        Remove-Item $target -Force -ErrorAction SilentlyContinue
    }
    Copy-Item -LiteralPath $agentsMd -Destination $target -Force
    Write-Host "  [ok] .github/copilot-instructions.md" -ForegroundColor Green
    Add-GitIgnorePattern ".github/copilot-instructions.md"
}

function Show-InteractiveMenu {
    $script:Claude = $true
    $script:Gemini = $false
    $script:Codex = $false
    $script:Copilot = $false

    $labels = @(
        "Claude Code / Cursor",
        "Gemini CLI",
        "Codex (OpenAI)",
        "GitHub Copilot"
    )
    $flags = @($true, $false, $false, $false)

    Write-Host ""
    Write-Host "Which AI assistants do you use?" -ForegroundColor White
    Write-Host "(numbers to toggle, a=all, n=none, Enter=confirm)" -ForegroundColor Cyan
    Write-Host ""

    $done = $false
    while (-not $done) {
        for ($i = 0; $i -lt $labels.Count; $i++) {
            $mark = if ($flags[$i]) { "[x]" } else { "[ ]" }
            $color = if ($flags[$i]) { "Green" } else { "Gray" }
            Write-Host "  $mark $($i + 1). $($labels[$i])" -ForegroundColor $color
        }
        Write-Host ""
        Write-Host "  a = all, n = none" -ForegroundColor Yellow
        $line = Read-Host "Toggle (1-4, a, n) or Enter to confirm"
        if ([string]::IsNullOrWhiteSpace($line)) {
            $done = $true
            continue
        }
        switch ($line.Trim().ToLower()) {
            "a" { for ($j = 0; $j -lt $flags.Count; $j++) { $flags[$j] = $true } }
            "n" { for ($j = 0; $j -lt $flags.Count; $j++) { $flags[$j] = $false } }
            default {
                foreach ($part in $line -split '\s+') {
                    $n = 0
                    if ([int]::TryParse($part, [ref]$n) -and $n -ge 1 -and $n -le 4) {
                        $flags[$n - 1] = -not $flags[$n - 1]
                    }
                }
            }
        }
        Write-Host ""
    }

    $script:Claude = $flags[0]
    $script:Gemini = $flags[1]
    $script:Codex = $flags[2]
    $script:Copilot = $flags[3]
}

if ($Help) {
    Show-Help
    exit 0
}

if ($All) {
    $Claude = $true
    $Gemini = $true
    $Codex = $true
    $Copilot = $true
}

$skillCount = (Get-ChildItem $SkillsSource -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue).Count
Write-Host ""
Write-Host "Botai AI Skills Setup" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "Found $skillCount skills" -ForegroundColor Blue
Write-Host ""

if (-not ($Claude -or $Gemini -or $Codex -or $Copilot)) {
    Show-InteractiveMenu
}

if (-not ($Claude -or $Gemini -or $Codex -or $Copilot)) {
    Write-Host "No assistants selected. Nothing to do." -ForegroundColor Yellow
    Write-Host "(AGENTS.md in repo is enough for Cursor without symlinks.)" -ForegroundColor DarkGray
    exit 0
}

$step = 1
$total = (@($Claude, $Gemini, $Codex, $Copilot) | Where-Object { $_ }).Count

if ($Claude) {
    Write-Host "[$step/$total] Claude / Cursor..." -ForegroundColor Yellow
    Setup-Claude
    $step++
}
if ($Gemini) {
    Write-Host "[$step/$total] Gemini..." -ForegroundColor Yellow
    Setup-Gemini
    $step++
}
if ($Codex) {
    Write-Host "[$step/$total] Codex..." -ForegroundColor Yellow
    Setup-Codex
    $step++
}
if ($Copilot) {
    Write-Host "[$step/$total] Copilot..." -ForegroundColor Yellow
    Setup-Copilot
}

Write-Host ""
Write-Host "Done. Restart the IDE if you use symlinks." -ForegroundColor Green
