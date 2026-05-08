# Turn Resolution JSON Trace

**SPEC/program** - Debug-only structured trace contracts for turn resolution and AI planner diagnostics.

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

This spec also authorizes phase-level snapshot capture hooks in the turn
resolver as non-exporting runtime plumbing for issue #2218 follow-up slices.
This spec authorizes turn-trace file export path and retention behavior for
debug tracing outputs.

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

### Trace file export path and retention

- Default trace root directory is repo-root `tmp/`.
- Export path pattern is
  `tmp/turn-traces/{gameId}/turn-{turnNumber}-{timestamp}.json`.
- `timestamp` uses UTC sortable filename format `YYYYMMDDTHHMMSSmmmZ`.
- A configurable trace root directory override is allowed for ctdev/app startup
  wiring slices, while keeping the same sub-path and filename pattern.
- Retention keeps at most 10 `.json` trace files per `gameId` directory by
  pruning oldest files first.

---

## Acceptance Criteria

- Given a JSON payload intended as an AI trace, when validated against `ai-trace.v1.schema.json`, then validation passes only if `state`, `thresholds`, and `outcome` sections all satisfy required fields and types.
- Given a JSON payload intended as a turn-resolution trace, when validated against `turn-resolution-trace.v1.schema.json`, then validation passes only if each phase contains `beforeState`, `afterState`, and ordered `orderEvents` entries with non-negative `sequence`.
- Given a JSON payload intended as a merged logical-turn trace, when validated against `merged-trace.v1.schema.json`, then validation passes only if `meta`, `ai`, and `turnResolution` are present and nested sections satisfy referenced contracts.
- Given a payload with missing required fields for any of the three trace schemas, when validated, then validation fails deterministically with at least one schema violation.
- Given turn resolution runs with `TurnResolverConfig.onTurnTracePhase` set, when each phase resolves (including pending-exit phases), then the callback receives one `TurnTracePhaseTrace` payload per phase containing `phaseId`, full `beforeState`, full `afterState`, and an ordered `orderEvents` array (which may be empty until order-event hooks are wired).
- Given no custom trace root override is provided, when the system exports a merged turn trace for `gameId = G` and `turnNumber = N`, then the system writes one JSON file to `tmp/turn-traces/G/` using filename pattern `turn-N-YYYYMMDDTHHMMSSmmmZ.json`.
- Given a custom trace root override path `R` is provided, when the system exports a merged turn trace for `gameId = G`, then the system writes to `R/turn-traces/G/` and keeps the same filename pattern.
- Given a game trace directory contains more than 10 trace JSON files after a new export, when retention runs, then the system deletes oldest files first until exactly 10 files remain in that gameId directory.
