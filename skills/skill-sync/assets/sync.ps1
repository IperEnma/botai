# PowerShell port of sync.sh — regenerates Auto-invoke tables in AGENTS.md
param(
    [switch]$DryRun,
    [ValidateSet("", "root", "backend", "frontend")]
    [string]$Scope = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$SkillsDir = Join-Path $RepoRoot "skills"

function Get-AgentsPath([string]$s) {
    switch ($s) {
        "root" { return Join-Path $RepoRoot "AGENTS.md" }
        "backend" { return Join-Path $RepoRoot "backend\AGENTS.md" }
        "frontend" { return Join-Path $RepoRoot "frontend\AGENTS.md" }
        default { return $null }
    }
}

function Parse-SkillMetadata([string]$path) {
    $lines = Get-Content $path -Raw
    if ($lines -notmatch '(?s)^---\r?\n(.*?)\r?\n---') { return $null }
    $fm = $Matches[1]
    $name = if ($fm -match '(?m)^name:\s*(.+)$') { $Matches[1].Trim() } else { $null }
    $inMeta = $false
    $scope = @()
    $auto = @()
    foreach ($line in ($fm -split '\r?\n')) {
        if ($line -match '^metadata:\s*$') { $inMeta = $true; continue }
        if ($inMeta -and $line -match '^[a-z]') { $inMeta = $false }
        if (-not $inMeta) { continue }
        if ($line -match '^\s+scope:\s*\[(.+)\]\s*$') {
            $scope = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"') }
        }
        elseif ($line -match '^\s+scope:\s*(\w+)\s*$') { $scope = @($Matches[1]) }
        elseif ($line -match '^\s+auto_invoke:\s*"(.+)"\s*$') { $auto += $Matches[1] }
        elseif ($line -match '^\s+-\s*"(.+)"\s*$' -and $auto.Count -ge 0) {
            # could be scope list or auto_invoke list — heuristic: after auto_invoke: block
        }
    }
    # Simpler regex pass for auto_invoke list
    if ($fm -match '(?s)auto_invoke:\s*\r?\n((?:\s+-\s+".+"\r?\n?)+)') {
        $auto = [regex]::Matches($Matches[1], '-\s+"(.+)"') | ForEach-Object { $_.Groups[1].Value }
    }
    elseif ($fm -match 'auto_invoke:\s*"(.+)"') {
        $auto = @($Matches[1])
    }
    if ($fm -match 'scope:\s*\[([^\]]+)\]') {
        $scope = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"') }
    }
    [PSCustomObject]@{ Name = $name; Scope = $scope; AutoInvoke = $auto }
}

$byScope = @{}
Get-ChildItem $SkillsDir -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) { return }
    $m = Parse-SkillMetadata $skillFile
    if (-not $m -or -not $m.Scope -or -not $m.AutoInvoke) { return }
    foreach ($s in $m.Scope) {
        if ($Scope -and $s -ne $Scope) { continue }
        if (-not $byScope.ContainsKey($s)) { $byScope[$s] = @() }
        foreach ($a in $m.AutoInvoke) {
            $byScope[$s] += [PSCustomObject]@{ Action = $a; Skill = $m.Name }
        }
    }
}

foreach ($s in $byScope.Keys) {
    $agentsPath = Get-AgentsPath $s
    if (-not $agentsPath -or -not (Test-Path $agentsPath)) {
        Write-Warning "No AGENTS.md for scope $s"
        continue
    }
    $rows = $byScope[$s] | Sort-Object Action, Skill
    $section = @(
        "### Auto-invoke Skills",
        "",
        "When performing these actions, ALWAYS invoke the corresponding skill FIRST:",
        "",
        "| Action | Skill |",
        "|--------|-------|"
    )
    foreach ($r in $rows) {
        $section += "| $($r.Action) | ``$($r.Skill)`` |"
    }
    $newBlock = $section -join "`n"
    if ($DryRun) {
        Write-Host "[DRY RUN] $agentsPath`n$newBlock`n"
        continue
    }
    $content = Get-Content $agentsPath -Raw
    $pattern = '(?s)### Auto-invoke Skills\r?\n.*?(?=\r?\n---|\r?\n## )'
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, "$newBlock`n")
        Set-Content -Path $agentsPath -Value $content.TrimEnd() -NoNewline
        Add-Content -Path $agentsPath -Value ""
        Write-Host "Updated $agentsPath" -ForegroundColor Green
    }
    else {
        Write-Warning "No Auto-invoke section in $agentsPath"
    }
}

Write-Host "Done." -ForegroundColor Green
