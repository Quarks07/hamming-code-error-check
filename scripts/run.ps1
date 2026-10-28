param(
    [string]$VivadoBin = 'S:\Vivado\2026.1\Vivado\bin'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Force build, sim | Out-Null
    Push-Location build
    try {
        & "$VivadoBin\xvlog.bat" --sv ../rtl/hamming74.v ../tb/tb_hamming74.v
        if ($LASTEXITCODE -ne 0) { throw 'Compilation failed' }
        & "$VivadoBin\xelab.bat" tb_hamming74 -s hamming_sim -debug typical
        if ($LASTEXITCODE -ne 0) { throw 'Elaboration failed' }
        & "$VivadoBin\xsim.bat" hamming_sim -tclbatch ../scripts/simulate.tcl -log ../sim/simulation.log
        if ($LASTEXITCODE -ne 0) { throw 'Simulation failed' }
        if (-not (Select-String -Path ../sim/simulation.log -SimpleMatch 'ALL TESTS PASSED' -Quiet)) {
            throw 'Simulation did not report success'
        }
    } finally { Pop-Location }
} finally { Pop-Location }
