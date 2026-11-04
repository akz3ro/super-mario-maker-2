@echo off
setlocal
title Maker Packs - by akz3ro
set "MP_FILE=%~f0"
set "MAKER_TOOL_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:MP_FILE); $m='###PSCODE'+'_BELOW###'; $i=$t.LastIndexOf($m); & ([scriptblock]::Create($t.Substring($i+$m.Length)))"
pause
exit /b
###PSCODE_BELOW###
# Maker Packs - Mario Maker 2 (suyu) level pack installer
# Copies ALL files of the selected level folder into the save game folder (duplicates are overwritten by the level folder files).

$ErrorActionPreference = 'Stop'

$toolDir = $env:MAKER_TOOL_DIR
if ([string]::IsNullOrWhiteSpace($toolDir)) { $toolDir = $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($toolDir)) { $toolDir = (Get-Location).Path }
$toolDir = $toolDir.TrimEnd('\')

$defaultLevels = Join-Path $toolDir 'levels'
$defaultSave   = Join-Path $env:APPDATA 'suyu\nand\user\save\0000000000000000\7D25BAE9D30B00C638F5BA0B4299DE43\01009B90006DC000'
$slotPattern   = '^course_(data|thumb)_(1[2-7]\d)\.(bcd|btl)$'

function Read-PathWithDefault([string]$label, [string]$default) {
    Write-Host ''
    Write-Host $label -ForegroundColor Cyan
    Write-Host "  Press Enter for default: $default" -ForegroundColor DarkGray
    $v = Read-Host '  Path'
    if ([string]::IsNullOrWhiteSpace($v)) { return $default }
    return $v.Trim().Trim('"')
}

function Select-FolderName([string[]]$names) {
    $filter = ''
    $idx    = 0
    $page   = 12
    $total  = $page + 3
    for ($i = 0; $i -lt $total; $i++) { Write-Host '' }
    $top = [Console]::CursorTop - $total
    if ($top -lt 0) { $top = 0 }
    $width = [Console]::WindowWidth - 1
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            $items = @($names | Where-Object { $_ -like "*$filter*" })
            if ($idx -ge $items.Count) { $idx = [Math]::Max(0, $items.Count - 1) }
            $start = 0
            if ($items.Count -gt $page) {
                $start = [Math]::Max(0, [Math]::Min($idx - [int]($page / 2), $items.Count - $page))
            }

            [Console]::SetCursorPosition(0, $top)
            $head = "Select folder (Up/Down, PageUp/PageDown, Enter = select, Esc = cancel). Type to filter: $filter"
            Write-Host $head.PadRight($width).Substring(0, $width) -ForegroundColor Yellow
            Write-Host ("  {0} match(es)" -f $items.Count).PadRight($width) -ForegroundColor DarkGray

            for ($i = 0; $i -lt $page; $i++) {
                $n = $start + $i
                if ($n -lt $items.Count) {
                    if ($n -eq $idx) {
                        $line = ("> " + $items[$n]).PadRight($width)
                        Write-Host $line.Substring(0, $width) -ForegroundColor Black -BackgroundColor Green
                    } else {
                        $line = ("  " + $items[$n]).PadRight($width)
                        Write-Host $line.Substring(0, $width)
                    }
                } else {
                    Write-Host (' ' * $width)
                }
            }

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'    { if ($idx -gt 0) { $idx-- } }
                'DownArrow'  { if ($idx -lt $items.Count - 1) { $idx++ } }
                'PageUp'     { $idx = [Math]::Max(0, $idx - $page) }
                'PageDown'   { $idx = [Math]::Min([Math]::Max(0, $items.Count - 1), $idx + $page) }
                'Home'       { $idx = 0 }
                'End'        { $idx = [Math]::Max(0, $items.Count - 1) }
                'Enter'      { if ($items.Count -gt 0) { return $items[$idx] } }
                'Escape'     { return $null }
                'Backspace'  { if ($filter.Length -gt 0) { $filter = $filter.Substring(0, $filter.Length - 1); $idx = 0 } }
                default {
                    if ($key.KeyChar -and -not [char]::IsControl($key.KeyChar)) { $filter += $key.KeyChar; $idx = 0 }
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $true
        [Console]::SetCursorPosition(0, [Math]::Min($top + $total, [Console]::BufferHeight - 1))
    }
}

Write-Host '=== Mario Maker 2 level pack installer ===' -ForegroundColor Green

$levelsPath = Read-PathWithDefault 'Path of the levels folder (contains the "Week ..." folders)' $defaultLevels
$savePath   = Read-PathWithDefault 'Path of the save game folder' $defaultSave

if (-not (Test-Path -LiteralPath $levelsPath -PathType Container)) { Write-Host "Levels path not found: $levelsPath" -ForegroundColor Red; Read-Host 'Press Enter to exit'; return }
if (-not (Test-Path -LiteralPath $savePath   -PathType Container)) { Write-Host "Save path not found: $savePath"     -ForegroundColor Red; Read-Host 'Press Enter to exit'; return }

# ---- Backup question ----
Write-Host ''
$doBackup = $true
$ans = Read-Host 'Do you want to back up the save game folder first? (Y/n, Enter = yes)'
if ($ans -and $ans.Trim().ToLower().StartsWith('n')) { $doBackup = $false }

$backupRoot = $null
if ($doBackup) {
    $backupRoot = Read-PathWithDefault 'Path to store the backup' (Join-Path $toolDir 'backups')
} else {
    Write-Host ''
    Write-Host 'WARNING: No backup will be made. The current save game files that have the same names as the level files' -ForegroundColor Yellow
    Write-Host '(including save.dat / network.dat / quest.dat ...) will be OVERWRITTEN and LOST.' -ForegroundColor Yellow
    $c = Read-Host 'Press Enter to continue, or type anything then Enter to cancel'
    if ($c) { Write-Host 'Cancelled.'; return }
}

# Only folders that actually contain level files; folders starting with "_" (backups) are hidden
$packs = Get-ChildItem -LiteralPath $levelsPath -Directory |
    Where-Object { $_.Name -notlike '_*' } |
    Where-Object { Get-ChildItem -LiteralPath $_.FullName -File | Where-Object { $_.Name -match $slotPattern } | Select-Object -First 1 } |
    Sort-Object @{ Expression = { $m = [regex]::Match($_.Name, '\d+'); if ($m.Success) { [int]$m.Value } else { 0 } } }, Name |
    ForEach-Object { $_.Name }

if (-not $packs -or $packs.Count -eq 0) { Write-Host 'No level folders found in that path.' -ForegroundColor Red; Read-Host 'Press Enter to exit'; return }

Write-Host ''
Write-Host "Found $($packs.Count) level folders." -ForegroundColor Cyan
$chosen = Select-FolderName @($packs)
if (-not $chosen) { Write-Host 'Cancelled.'; return }

$src = Join-Path $levelsPath $chosen
Write-Host ''
Write-Host "Selected : $chosen" -ForegroundColor Green
Write-Host "Save     : $savePath"

$suyu = @(Get-Process -Name 'suyu*' -ErrorAction SilentlyContinue)
if ($suyu.Count -gt 0) {
    Write-Host 'suyu is running. Closing it...' -ForegroundColor Yellow
    # try a normal close first so suyu can flush its files
    foreach ($p in $suyu) { try { [void]$p.CloseMainWindow() } catch {} }
    $waited = 0
    while ($waited -lt 10 -and (Get-Process -Name 'suyu*' -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 1; $waited++ }
    # force close whatever is still alive
    Get-Process -Name 'suyu*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (Get-Process -Name 'suyu*' -ErrorAction SilentlyContinue) {
        Write-Host 'Could not close suyu. Close it manually, then run the tool again.' -ForegroundColor Red
        Read-Host 'Press Enter to exit'
        return
    }
    Write-Host 'suyu closed.' -ForegroundColor DarkGray
}

# ---- Backup ----
if ($doBackup) {
    if (-not (Test-Path -LiteralPath $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
    $bak = Join-Path $backupRoot (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
    Copy-Item -LiteralPath $savePath -Destination $bak -Recurse -Force
    Write-Host "Backup created: $bak" -ForegroundColor DarkGray
}

# ---- Full copy: everything inside the selected folder goes into the save folder, overwriting duplicates ----
Copy-Item -Path (Join-Path $src '*') -Destination $savePath -Recurse -Force
$count = (Get-ChildItem -LiteralPath $src -File -Recurse).Count

Write-Host ''
Write-Host "Done. Copied $count files from '$chosen' into the save folder (duplicates overwritten)." -ForegroundColor Green
Write-Host ''
Write-Host 'Created by akz3ro' -ForegroundColor Magenta
