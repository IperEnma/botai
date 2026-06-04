# Regenerates Available Skills + Auto-invoke tables in AGENTS.md (Prowler-style)
param(
    [switch]$DryRun,
    [ValidateSet("", "root", "backend", "frontend")]
    [string]$Scope = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$SkillsDir = Join-Path $RepoRoot "skills"

function Get-AgentsPath([string]$s) {
    switch ($s) {
        "root" { return Join-Path $RepoRoot "AGENTS.md" }
        "backend" { return Join-Path $RepoRoot "backend\AGENTS.md" }
        "frontend" { return Join-Path $RepoRoot "frontend\AGENTS.md" }
        default { return $null }
    }
}

function Get-SkillLinkPath([string]$scope, [string]$skillName) {
    switch ($scope) {
        "root" { return "skills/$skillName/SKILL.md" }
        default { return "../skills/$skillName/SKILL.md" }
    }
}

function Get-FrontmatterBlock([string]$path) {
    $raw = Get-Content $path -Raw
    if ($raw -notmatch '(?s)^---\r?\n(.*?)\r?\n---') { return $null }
    return $Matches[1]
}

function Get-YamlField([string]$fm, [string]$field) {
    if ($fm -match "(?ms)^${field}:\s*(?:>\s*\r?\n)?(.+?)(?=\r?\n[a-z_]+:|\r?\n---|\z)") {
        $v = $Matches[1].Trim() -replace '\s+', ' '
        return $v.Trim('"')
    }
    return $null
}

function Get-MetadataField([string]$fm, [string]$field) {
    if ($fm -notmatch '(?s)metadata:\s*\r?\n(.*)') { return @() }
    $meta = $Matches[1]
    if ($field -eq "scope") {
        if ($meta -match 'scope:\s*\[([^\]]+)\]') {
            return ($Matches[1] -split ',') | ForEach-Object { $_.Trim().Trim('"') }
        }
        if ($meta -match 'scope:\s*(\w+)') { return @($Matches[1]) }
    }
    if ($field -eq "auto_invoke") {
        if ($meta -match '(?s)auto_invoke:\s*\r?\n((?:\s+-\s+".+"\r?\n?)+)') {
            return [regex]::Matches($Matches[1], '-\s+"(.+)"') | ForEach-Object { $_.Groups[1].Value }
        }
        if ($meta -match 'auto_invoke:\s*"(.+)"') { return @($Matches[1]) }
    }
    return @()
}

function Short-Description([string]$desc) {
    if (-not $desc) { return "-" }
    $line = ($desc -split [Environment]::NewLine)[0] -replace 'Trigger:.*', ''
    $line = $line.Trim()
    if ($line.Length -gt 120) { $line = $line.Substring(0, 117) + "..." }
    return $line
}

$catalog = @{}
$invoke = @{}

Get-ChildItem $SkillsDir -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) { return }
    $fm = Get-FrontmatterBlock $skillFile
    if (-not $fm) { return }
    $name = Get-YamlField $fm "name"
    $desc = Get-YamlField $fm "description"
    $scopes = Get-MetadataField $fm "scope"
    $actions = Get-MetadataField $fm "auto_invoke"
    if (-not $Scope -or $Scope -eq 'root') {
        if (-not $catalog.ContainsKey('root')) { $catalog['root'] = @() }
        $catalog['root'] += [PSCustomObject]@{
            Name = $name
            Description = Short-Description $desc
            Link = Get-SkillLinkPath 'root' $name
        }
    }

    foreach ($s in $scopes) {
        if ($Scope -and $s -ne $Scope) { continue }
        if ($s -ne 'root') {
            if (-not $catalog.ContainsKey($s)) { $catalog[$s] = @() }
            $catalog[$s] += [PSCustomObject]@{
                Name = $name
                Description = Short-Description $desc
                Link = Get-SkillLinkPath $s $name
            }
        }
        if ($actions.Count -gt 0) {
            if (-not $invoke.ContainsKey($s)) { $invoke[$s] = @() }
            foreach ($a in $actions) {
                $invoke[$s] += [PSCustomObject]@{ Action = $a; Skill = $name }
            }
        }
    }
}

$scopesToProcess = @("root", "backend", "frontend") | Where-Object {
    ($Scope -eq "" -or $Scope -eq $_) -and ($catalog.ContainsKey($_) -or $invoke.ContainsKey($_))
}

foreach ($s in $scopesToProcess) {
    $agentsPath = Get-AgentsPath $s
    if (-not $agentsPath -or -not (Test-Path $agentsPath)) {
        Write-Warning "No AGENTS.md for scope $s"
        continue
    }
    Write-Host "Processing: $s -> $agentsPath" -ForegroundColor Cyan

    $availLines = @(
        '## Available Skills', '',
        '| Skill | Description | Path |',
        '|-------|-------------|------|'
    )
    if ($catalog.ContainsKey($s)) {
        foreach ($row in ($catalog[$s] | Sort-Object Name -Unique)) {
            $skillRef = '`' + $row.Name + '`'
            $availLines += '| ' + $skillRef + ' | ' + $row.Description + ' | [SKILL.md](' + $row.Link + ') |'
        }
    }
    $availBlock = $availLines -join "`n"

    $invokeLines = @(
        '### Auto-invoke Skills', '',
        'When performing these actions, ALWAYS invoke the corresponding skill FIRST:', '',
        '| Action | Skill |',
        '|--------|-------|'
    )
    if ($invoke.ContainsKey($s)) {
        foreach ($row in ($invoke[$s] | Sort-Object Action, Skill)) {
            $skillRef = '`' + $row.Skill + '`'
            $invokeLines += '| ' + $row.Action + ' | ' + $skillRef + ' |'
        }
    }
    $invokeBlock = $invokeLines -join "`n"

    if ($DryRun) {
        Write-Host "[DRY RUN]`n$availBlock`n`n$invokeBlock`n"
        continue
    }

    $content = Get-Content $agentsPath -Raw

    if ($content -match '(?s)## Available Skills\r?\n') {
        if ($s -eq "root") {
            $content = [regex]::Replace($content, '(?s)## Available Skills\r?\n.*?(?=\r?\n## Available Subagents)', "$availBlock`n`n")
        } else {
            $content = [regex]::Replace($content, '(?s)## Available Skills\r?\n.*?(?=\r?\n### Auto-invoke Skills)', "$availBlock`n`n")
        }
    }

    if ($content -match '(?s)### Auto-invoke Skills\r?\n') {
        $content = [regex]::Replace($content, '(?s)### Auto-invoke Skills\r?\n.*?(?=\r?\n---|\r?\n## )', "$invokeBlock`n")
    }

    Set-Content -Path $agentsPath -Value $content.TrimEnd() -NoNewline
    Add-Content -Path $agentsPath -Value ""
    Write-Host "  Updated Available Skills + Auto-invoke" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green

Write-Host ""
Write-Host "Skills missing scope and/or auto_invoke:" -ForegroundColor Cyan
$missing = 0
Get-ChildItem $SkillsDir -Directory | ForEach-Object {
    $skillFile = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) { return }
    $fm = Get-FrontmatterBlock $skillFile
    $name = Get-YamlField $fm "name"
    $scopes = Get-MetadataField $fm "scope"
    $actions = Get-MetadataField $fm "auto_invoke"
    if ($scopes.Count -eq 0 -or $actions.Count -eq 0) {
        Write-Host "  $name" -ForegroundColor Yellow
        $missing++
    }
}
if ($missing -eq 0) { Write-Host "  All skills have scope + auto_invoke" -ForegroundColor Green }
