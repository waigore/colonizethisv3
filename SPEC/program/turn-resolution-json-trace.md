# Turn Resolution JSON Trace

**SPEC/program** - Debug-only structured trace contracts for turn resolution and AI planner diagnostics. This document defines schema contracts only. Runtime wiring and export lifecycle are specified in follow-up slices.

---

## Scope

This spec authorizes the versioned JSON contracts used by issue #2218:

- `SPEC/program/schemas/turn-trace/ai-trace.v1.schema.json`
- `SPEC/program/schemas/turn-trace/turn-resolution-trace.v1.schema.json`
- `SPEC/program/schemas/turn-trace/merged-trace.v1.schema.json`

These schemas define diagnostic payload shape for:

1. Per-AI decision traces.
2. Per-phase turn-resolution execution traces.
3. One merged logical-turn document.

---

## Versioning

- `schemaVersion` is required on every merged trace document.
- Initial schema version is `v1`.
- Version bumps:
  - Backward-compatible additive fields -> minor bump.
  - Breaking field removals or type changes -> major bump.
- Merged trace documents must use a version string that matches the merged schema.

---

## Contracts

### AI trace (`ai-trace.v1.schema.json`)

Required top-level fields:

- `factionId`: string.
- `state`: object.
- `thresholds`: object.
- `outcome`: object.

State section requires:

- `winningCandidate`: object.
- `topAlternates`: array.
- `aggregates`: object.

Thresholds section requires:

- `constants`: object.
- `derived`: object.
- `effective`: object.
- `gates`: array.

Outcome section requires:

- `finalAggregatedOrders`: array.
- `domainOutputs`: object.

### Turn-resolution trace (`turn-resolution-trace.v1.schema.json`)

Required top-level fields:

- `phases`: array.

Each phase entry requires:

- `phaseId`: string.
- `beforeState`: object.
- `afterState`: object.
- `orderEvents`: array.

Each order event requires:

- `sequence`: integer (`>= 0`).
- `orderId`: string.
- `eventType`: string.

### Merged trace (`merged-trace.v1.schema.json`)

Required top-level fields:

- `schemaVersion`: string.
- `meta`: object.
- `ai`: array.
- `turnResolution`: object.

Meta section requires:

- `gameId`: string.
- `turnNumber`: integer (`>= 1`).
- `traceEnabled`: boolean.
- `exportedAt`: RFC3339 timestamp string.

`ai` entries must validate against AI trace schema, and `turnResolution` must validate against turn-resolution schema.

---

## Acceptance Criteria

- Given a JSON payload intended as an AI trace, when validated against `ai-trace.v1.schema.json`, then validation passes only if `state`, `thresholds`, and `outcome` sections all satisfy required fields and types.
- Given a JSON payload intended as a turn-resolution trace, when validated against `turn-resolution-trace.v1.schema.json`, then validation passes only if each phase contains `beforeState`, `afterState`, and ordered `orderEvents` entries with non-negative `sequence`.
- Given a JSON payload intended as a merged logical-turn trace, when validated against `merged-trace.v1.schema.json`, then validation passes only if `meta`, `ai`, and `turnResolution` are present and nested sections satisfy referenced contracts.
- Given a payload with missing required fields for any of the three trace schemas, when validated, then validation fails deterministically with at least one schema violation.
