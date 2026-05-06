# 02 — llama-server Results

Runtime: official llama.cpp prebuilt CUDA binary `b9041` (`llama-b9041-bin-win-cuda-12.4-x64.zip`) on RTX 3050 Laptop GPU.

Server settings:

- Port: `8081`
- Model: `Llama-3.2-3B-Instruct-Q4_K_M.gguf`
- Threads: `6`
- GPU layers: `99`
- Context: `2048`
- Parallel slots: `4`
- Continuous batching: enabled
- Metrics endpoint: enabled

## Smoke Test

`02-llama-cpp-server/smoke-test.py` passed against `http://localhost:8081/v1/chat/completions`.

Metrics after one request included:

- `llamacpp:prompt_tokens_total 33`
- `llamacpp:tokens_predicted_total 49`
- `llamacpp:n_decode_total 49`
- `llamacpp:n_busy_slots_per_decode 1`

## Load Test

| Concurrency | Requests | Failures | RPS | E2E P50 (ms) | E2E P95 (ms) | E2E P99 (ms) |
|--:|--:|--:|--:|--:|--:|--:|
| 10 | 98 | 0 | 1.66 | 4600 | 6300 | 7100 |
| 50 | 104 | 0 | 1.76 | 15000 | 28000 | 29000 |

Raw outputs:

- `benchmarks/02-smoke-test.txt`
- `benchmarks/02-locust-10.txt`
- `benchmarks/02-locust-50.txt`
- `benchmarks/02-server-metrics.csv`
- `benchmarks/02-metrics-full.txt`

## KV Cache / GPU Observation

This llama.cpp release (`b9041`) did not expose `llamacpp:kv_cache_usage_ratio` in `/metrics`; the full scrape is saved in `benchmarks/02-metrics-full.txt`.

The server log still confirms GPU/KV placement:

- CUDA backend loaded: `ggml-cuda.dll`
- Model offload: `offloaded 29/29 layers to GPU`
- CUDA model buffer: `1918.35 MiB`
- CUDA KV buffer: `224.00 MiB`
- `tokens_predicted_total` reached `17600` during the concurrency-50 metrics run.
