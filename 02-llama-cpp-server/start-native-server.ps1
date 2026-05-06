# Launch native llama-server.exe from the bonus llama.cpp source build.
# Requires:
#   BONUS-llama-cpp-optimization\llama.cpp built with CMake
#   models\active.json present
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$candidates = @(
    'BONUS-llama-cpp-optimization\llama.cpp\build\bin\Release\llama-server.exe',
    'BONUS-llama-cpp-optimization\llama.cpp\build\bin\llama-server.exe',
    'BONUS-llama-cpp-optimization\llama.cpp\build\Release\bin\llama-server.exe',
    'D:\tmp\day20-llama.cpp\build\bin\Release\llama-server.exe',
    'D:\tmp\llama-release\extract\llama-server.exe'
)

$server = $null
foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
        $server = (Resolve-Path $candidate).Path
        break
    }
}

if (-not $server) {
    throw 'Native llama-server.exe not found. Build llama.cpp first under BONUS-llama-cpp-optimization\llama.cpp.'
}

$model = python -c 'import json; print(json.load(open("models/active.json", encoding="utf-8"))["primary_model"])'
if (-not (Test-Path $model)) {
    throw "Model path from models/active.json does not exist: $model"
}

# Some native Windows builds parse paths with spaces/non-ASCII poorly. Use a short hardlink.
$shortModelDir = 'D:\tmp\day20-models'
$shortModel = Join-Path $shortModelDir 'llama-3.2-3b-q4_k_m.gguf'
if (Test-Path $shortModel) {
    $model = $shortModel
} elseif (Test-Path $shortModelDir) {
    New-Item -ItemType HardLink -Path $shortModel -Target (Resolve-Path $model).Path | Out-Null
    $model = $shortModel
}

$threads = if ($env:LAB_N_THREADS) { $env:LAB_N_THREADS } else { '6' }
$gpu = if ($env:LAB_N_GPU_LAYERS) { $env:LAB_N_GPU_LAYERS } else { '99' }
$ctx = if ($env:LAB_N_CTX) { $env:LAB_N_CTX } else { '2048' }
$parallel = if ($env:LAB_PARALLEL) { $env:LAB_PARALLEL } else { '4' }
$port = if ($env:LAB_SERVER_PORT) { $env:LAB_SERVER_PORT } else { '8081' }

Write-Host "==> Starting native llama-server" -ForegroundColor Cyan
Write-Host "    server    : $server"
Write-Host "    model     : $model"
Write-Host "    threads   : $threads"
Write-Host "    gpu layers: $gpu"
Write-Host "    ctx       : $ctx"
Write-Host "    parallel  : $parallel"
Write-Host "    metrics   : enabled"
Write-Host "    listening : http://0.0.0.0:$port"
Write-Host ""

& $server `
    -m "$model" `
    --host 0.0.0.0 --port $port `
    -t $threads `
    -ngl $gpu `
    --ctx-size $ctx `
    --parallel $parallel `
    --cont-batching `
    --metrics
