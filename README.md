# andela/pydantic-pipeline-schema

Harbor task for preserving chained numeric constraints in Pydantic’s experimental pipeline JSON Schema output via `TypeAdapter.json_schema()`.

Supported constraints include `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, and `multipleOf`.

## Files

* `instruction.md` — task prompt
* `environment/repo/` — Pydantic checkout
* `environment/Dockerfile` — editable environment
* `tests/test_outputs.py` — verifier tests
* `solution/solve.sh` — oracle fix

## Commands

```bash
# Baseline
harbor run --path . --agent nop --job-name nop-baseline

# Oracle
harbor run --path . --agent oracle --job-name oracle-check

# Codex
harbor run --path . \
  --agent codex \
  --model gpt-5.4-mini \
  --agent-env CODEX_FORCE_AUTH_JSON=true \
  --n-attempts 5 \
  --n-concurrent 5

# Results
harbor view jobs
```

## Validation

* Baseline: 10 failures, 3 regression tests passing
* Oracle: reward `1.0`, all 13 tests passing
* Repository `HEAD` matches `task.toml`’s `base_commit_sha`
