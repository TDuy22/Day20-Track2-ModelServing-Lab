# Bonus — GPU Offload Sweep

Runtime: official llama.cpp prebuilt CUDA binary `b9041` on RTX 3050 Laptop GPU.

Build-from-source note: a local CUDA source build was attempted, but CUDA Toolkit 12.1 is not compatible with the installed Visual Studio 2026 / MSVC 14.50 toolchain. The run below uses the official CUDA 12.4 prebuilt binary to keep the serving and benchmark path native.

Model: `Llama-3.2-3B-Instruct-Q4_K_M.gguf`

Settings:

- Threads: `6`
- Prompt tokens: `0`
- Generated tokens: `64`
- Repetitions: `1`

| GPU layers (`-ngl`) | Decode speed (`tg64`, tok/s) |
|--:|--:|
| 0 | 15.06 |
| 8 | 20.34 |
| 16 | 28.71 |
| 24 | 44.98 |
| 99 | 70.70 |

## Observation

Full GPU offload (`-ngl 99`) was the single biggest improvement: decode speed rose from `15.06 tok/s` CPU-only to `70.70 tok/s`, about `4.7x` faster. The curve is monotonic here because the 3B Q4_K_M model fits in the RTX 3050 Laptop GPU's 4 GB VRAM with enough room for KV/cache buffers.
