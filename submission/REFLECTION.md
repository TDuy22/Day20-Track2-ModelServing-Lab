# Reflection — Lab 20 (Personal Report)

> **Đây là báo cáo cá nhân.** Mỗi học viên chạy lab trên laptop của mình, với spec của mình. Số liệu của bạn không so sánh được với bạn cùng lớp — chỉ so sánh **before vs after trên chính máy bạn**. Grade rubric tính theo độ rõ ràng của setup + tuning của bạn, không phải tốc độ tuyệt đối.

---

**Họ Tên:** Phạm Thành Duy  
**Cohort:** [E403] Mã học viên: 2A202600267  
**Ngày submit:** 2026-05-06

---

## 1. Hardware spec (từ `00-setup/detect-hardware.py`)

- **OS:** Windows 10
- **CPU:** AMD Ryzen 5 6600H with Radeon Graphics
- **Cores:** 6 physical / 12 logical
- **CPU extensions:** AVX2 / FMA / F16C
- **RAM:** 16 GB installed, 15.2 GiB detected by Windows API
- **Accelerator:** NVIDIA GeForce RTX 3050 Laptop GPU, 4 GB VRAM
- **llama.cpp backend đã chọn:** CUDA
- **Recommended model tier:** Llama-3.2-3B-Instruct (Q4_K_M)

**Setup story** (≤ 80 chữ):  
Windows path có dấu/khoảng trắng làm native `llama-server` parse model path lỗi, nên tôi hardlink model sang `D:\tmp\day20-models`. CUDA Toolkit 12.1 không build được với VS 2026/MSVC 14.50, nên tôi dùng official llama.cpp CUDA 12.4 prebuilt binary cho native server/bonus.

---

## 2. Track 01 — Quickstart numbers (từ `benchmarks/01-quickstart-results.md`)

| Model | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode rate (tok/s) |
|---|--:|--:|--:|--:|--:|
| Llama-3.2-3B-Instruct-Q4_K_M.gguf | 5048 | 27 / 65 | 15.3 / 16.1 | 988 / 1059 / 1061 | 65.5 |
| Llama-3.2-3B-Instruct-Q2_K.gguf | 1389 | 26 / 66 | 15.2 / 15.2 | 982 / 1024 / 1047 | 65.9 |

**Một quan sát** (≤ 50 chữ):  
Trên RTX 3050, Q2_K load nhanh hơn Q4_K_M rất nhiều, nhưng decode gần như không đổi. Vì Q4_K_M vẫn vừa VRAM/RAM và chất lượng tốt hơn, Q4_K_M là lựa chọn hợp lý hơn cho serving.

---

## 3. Track 02 — llama-server load test

| Concurrency | Total RPS | TTFB P50 (ms) | E2E P95 (ms) | E2E P99 (ms) | Failures |
|--:|--:|--:|--:|--:|--:|
| 10 | 1.66 | not separately measured | 6300 | 7100 | 0 |
| 50 | 1.76 | not separately measured | 28000 | 29000 | 0 |

**KV-cache observation**: official llama.cpp `b9041` binary did not expose `llamacpp:kv_cache_usage_ratio` in `/metrics`; full scrape is saved in `benchmarks/02-metrics-full.txt`. Server log shows CUDA KV buffer size = `224.00 MiB`, model buffer on CUDA = `1918.35 MiB`, and full model offload = `29/29 layers`. During the concurrency-50 metrics run, `tokens_predicted_total` reached `17600`.

---

## 4. Track 03 — Milestone integration

- **N16 (Cloud/IaC):** stub: localhost-only demo, no cluster/compose dependency
- **N17 (Data pipeline):** stub: `TOY_DOCS` in `pipeline.py` acts as processed records
- **N18 (Lakehouse):** stub: in-memory toy records stand in for a lakehouse table
- **N19 (Vector + Feature Store):** stub: keyword-overlap retrieval replaces vector index; Feast is not configured

**Nơi tốn nhiều ms nhất** trong pipeline (đo bằng `time.perf_counter` trong `pipeline.py`):

- embed: 0.0 ms
- retrieve: 0.1 ms
- llama-server: 2855.7–13328.7 ms across the 3 example queries

**Reflection** (≤ 60 chữ):  
Bottleneck nằm hoàn toàn ở llama-server. Điều này khớp kỳ vọng vì embed/retrieve đang là stub in-memory, còn LLM phải prefill prompt và decode output thật qua local CUDA serving.

---

## 5. Bonus — The single change that mattered most

**Change:** dùng native CUDA full GPU offload với official llama.cpp prebuilt binary, tăng `-ngl` từ `0` lên `99`.

**Before vs after** (paste 2-3 dòng từ sweep output):

```text
before: -ngl 0   -> 15.06 tok/s
after:  -ngl 99  -> 70.70 tok/s
speedup: ~4.7x
```

**Tại sao nó work**:

Với `-ngl 0`, model chạy gần như CPU-only, decode bị giới hạn bởi băng thông RAM và throughput CPU. Khi chuyển sang `-ngl 99`, log server xác nhận `offloaded 29/29 layers to GPU`, model buffer CUDA khoảng `1918 MiB`, KV buffer CUDA `224 MiB`. Model 3B Q4_K_M vừa trong 4 GB VRAM của RTX 3050 nên phần lớn compute và KV-cache traffic nằm trên GPU.

Kết quả sweep tăng đều từ `15.06` → `20.34` → `28.71` → `44.98` → `70.70 tok/s` khi tăng số layer offload. Vì model vừa VRAM, full offload thắng rõ rệt; không có điểm mà partial offload tốt hơn full offload trong setup này.

---

## 6. (Optional) Điều ngạc nhiên nhất

Q2_K không nhanh hơn Q4_K_M đáng kể ở decode khi đã full GPU offload. Khác biệt lớn nhất nằm ở load time, không phải TPOT.

---

## 7. Self-graded checklist

- [x] `hardware.json` đã commit
- [x] `models/active.json` đã commit (hoặc paste path snapshot vào section 1)
- [x] `benchmarks/01-quickstart-results.md` đã commit
- [x] `benchmarks/02-server-results.md` (hoặc CSV từ `record-metrics.py`) đã commit
- [x] `benchmarks/bonus-*.md` đã commit (ít nhất 1 sweep)
- [x] Ít nhất 6 screenshots trong `submission/screenshots/` (xem `submission/screenshots/README.md`)
- [x] `make verify` exit 0 (chạy ngay trước khi push)
- [ ] Repo trên GitHub ở chế độ **public**
- [ ] Đã paste public repo URL vào VinUni LMS

---

**Quan trọng:** repo phải **public** đến khi điểm được công bố. Nếu private, grader không xem được → 0 điểm.
