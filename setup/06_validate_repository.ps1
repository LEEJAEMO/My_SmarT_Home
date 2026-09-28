param([string]$PythonPath = '.\.venv\Scripts\python.exe')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $files = Get-ChildItem -LiteralPath $repoRoot -Filter '*.ps1' -Recurse | Where-Object { $_.FullName -notmatch '[\\/]\.venv[\\/]' }
    foreach ($file in $files) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count -gt 0) { throw "PowerShell parse error: $($file.Name)" }
    }
    Write-Output "PASS PowerShell: $($files.Count) files"
    & $PythonPath setup/validate_repository.py
    if ($LASTEXITCODE -ne 0) { throw 'Syntax validation failed' }
    & $PythonPath -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { throw 'Safety tests failed' }
    git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Diff whitespace validation failed' }
} finally {
    Pop-Location
}
