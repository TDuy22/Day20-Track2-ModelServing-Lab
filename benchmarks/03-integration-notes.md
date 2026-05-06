# 03 — Milestone Integration Notes

This run uses a stubbed local RAG pipeline because the N16-N19 project stack is not available yet.

| Piece | Status | Notes |
|---|---|---|
| N16 Cloud/IaC | stub | Localhost-only demo, no cluster/compose dependency. |
| N17 Data pipeline | stub | `TOY_DOCS` in `03-milestone-integration/pipeline.py` acts as processed records. |
| N18 Lakehouse | stub | In-memory toy records stand in for a Delta/Iceberg table. |
| N19 Vector + Feature Store | stub | Keyword-overlap retrieval replaces vector index; Feast is not configured. |
| N20 Serving | real | Calls local OpenAI-compatible `llama-server` at `http://localhost:8080/v1`. |

Latency is measured in `pipeline.py` with `time.perf_counter()` for embed, retrieve, LLM, and total time. In this stub version, the LLM call should dominate because embedding and retrieval are in-memory.
