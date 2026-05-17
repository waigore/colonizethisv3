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

This spec also authorizes phase-level snapshot capture hooks as
non-exporting runtime plumbing for #2218 follow-up slices, and the
turn-trace file export path and retention behavior.

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

Full AI planner traces populate the AI section from `colonizethis_ai`
planner internals: selected strategic goal as `state.winningCandidate`,
ranked alternates in `state.topAlternates`, world/order/economy aggregates,
seed/personality/domain-weight thresholds, and per-domain order output. App
and ctdev exporters may fall back to submitted-order summaries when callers
provide only an `Orders` payload.

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

When structured tracing is enabled with `TurnResolverConfig.turnTraceRuntime`
and `onTurnTracePhase`, the Movement phase records civilian and army order
attempts in apply order with these `eventType` values:

- `civilian_move_applied` / `civilian_move_ignored` for direct `MoveOrder`
  handling.
- `bundled_work_move_applied` / `bundled_work_move_skipped` for implicit move
  legs emitted while preparing `WorkOrder` execution.
- `army_move_applied` / `army_move_ignored` for `ArmyMoveOrder` handling
  across cross-region instant moves and same-region moves.

Movement event payloads include destination tile/province context and
optional `ignoreReason` for skipped/ignored attempts. Army move payloads
include `destinationProvinceId` (always set), optional `regionId` for
region-scoped decisions, and `ignoreReason` values from `army_not_found`,
`owner_mismatch`, `home_army_locked`, `destination_in_other_region`, or
`invalid_adjacency`; global-decision rejections fire exactly once per order.
Other phases may emit empty `orderEvents` until additional hooks land
(GitHub #2218).

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

### App worker-isolate path

When the Flutter app resolves a turn in a worker isolate (`TurnResolutionRunner`,
`SPEC/program/turn-resolution.md`), AI orders and `FullAIResult.aiTraceSections`
are computed on the main isolate before the worker runs. When debug turn tracing
is enabled, phase traces and order events are collected inside the isolate and
returned with the terminal result; the app merges those phase payloads with the
main-isolate AI sections and writes the same merged JSON document as the
in-process `GameService.runTurnResolution` path.

---

## Acceptance Criteria

- Given a JSON payload intended as an AI trace, when validated against `ai-trace.v1.schema.json`, then validation passes only if `state`, `thresholds`, and `outcome` sections all satisfy required fields and types.
- Given a JSON payload intended as a turn-resolution trace, when validated against `turn-resolution-trace.v1.schema.json`, then validation passes only if each phase contains `beforeState`, `afterState`, and ordered `orderEvents` entries with non-negative `sequence`.
- Given a JSON payload intended as a merged logical-turn trace, when validated against `merged-trace.v1.schema.json`, then validation passes only if `meta`, `ai`, and `turnResolution` are present and nested sections satisfy referenced contracts.
- Given a payload with missing required fields for any of the three trace schemas, when validated, then validation fails deterministically with at least one schema violation.
- Given turn resolution runs with `TurnResolverConfig.onTurnTracePhase` and `turnTraceRuntime` set, when each phase resolves (including pending-exit phases), then the callback receives one `TurnTracePhaseTrace` payload per phase containing `phaseId`, full `beforeState`, full `afterState`, and an ordered `orderEvents` array (Movement phase includes direct civilian move apply/ignore events, bundled work move applied/skipped events, and army move applied/ignored events when those orders are present; other phases may still emit empty `orderEvents` until further hooks land).
- Given the movement phase processes `ArmyMoveOrder` entries with structured tracing enabled, when an order is rejected because the army is missing, owned by another faction, or a home army, then the runtime emits exactly one `army_move_ignored` event per order with the matching `ignoreReason` and the order's `destinationProvinceId` in the payload.
- Given the movement phase processes `ArmyMoveOrder` entries with structured tracing enabled, when a same-region move applies via `applyArmyMoveOrdersToRegion`, then the runtime emits one `army_move_applied` event whose payload contains the resolved `destinationProvinceId` and the matching `regionId`.
- Given the full AI planner generates orders for an AI-controlled player, when the caller reads the returned AI trace section, then the trace contains the player's `factionId`, a `state.winningCandidate.goal` strategic goal string, ranked `state.topAlternates`, `thresholds.constants`, `thresholds.derived`, `thresholds.effective`, `thresholds.gates`, and an `outcome.finalAggregatedOrders` array matching the emitted order domains.
- Given app or ctdev turn trace export receives full AI trace sections for the resolving turn, when the merged trace is written, then the top-level `ai` array uses those full AI trace sections instead of rebuilding only submitted-order summaries.
- Given no custom trace root override is provided, when the system exports a merged turn trace for `gameId = G` and `turnNumber = N`, then the system writes one JSON file to `tmp/turn-traces/G/` using filename pattern `turn-N-YYYYMMDDTHHMMSSmmmZ.json`.
- Given a custom trace root override path `R` is provided, when the system exports a merged turn trace for `gameId = G`, then the system writes to `R/turn-traces/G/` and keeps the same filename pattern.
- Given a game trace directory contains more than 10 trace JSON files after a new export, when retention runs, then the system deletes oldest files first until exactly 10 files remain in that gameId directory.
