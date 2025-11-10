#!/usr/bin/env pwsh
# Run E2E tests in isolated environment (prevents loading installed plugins)

$env:XDG_DATA_HOME = Join-Path $PSScriptRoot ".nvim-data"
$env:XDG_STATE_HOME = Join-Path $PSScriptRoot ".nvim-data"
$env:XDG_CONFIG_HOME = Join-Path $PSScriptRoot ".nvim-data"
$env:NVIM_APPNAME = "qb-test-isolated"

Write-Host "Running E2E tests in isolated environment..."
Write-Host "XDG_DATA_HOME: $env:XDG_DATA_HOME"

# Change to repo root (parent of tests directory)
Set-Location (Join-Path $PSScriptRoot "..")

nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/e2e_spec.lua"

$exitCode = $LASTEXITCODE
Write-Host "`nTest completed with exit code: $exitCode"
exit $exitCode
