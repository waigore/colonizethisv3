# Turn Trace Schema Reference (V1)

Field reference for the versioned schemas introduced for issue #2218.

---

## `SPEC/program/schemas/turn-trace/ai-trace.v1.schema.json`

| Field | Type | Required | Notes |
|---|---|---|---|
| `factionId` | string | yes | AI-controlled faction identifier. |
| `state` | object | yes | Decision context block. |
| `state.winningCandidate` | object | yes | Candidate selected by AI. |
| `state.topAlternates` | array<object> | yes | Ranked non-winning candidates. |
| `state.aggregates` | object | yes | Aggregated scoring/input signals. |
| `thresholds` | object | yes | Threshold and gate data. |
| `thresholds.constants` | object | yes | Rule constants used by planner. |
| `thresholds.derived` | object | yes | Derived threshold values. |
| `thresholds.effective` | object | yes | Runtime effective thresholds. |
| `thresholds.gates` | array<object> | yes | Gate checks used for filtering/approval. |
| `outcome` | object | yes | Emitted planner outcomes. |
| `outcome.finalAggregatedOrders` | array<object> | yes | Final orders emitted for the faction. |
| `outcome.domainOutputs` | object | yes | Domain planner diagnostics. |

## `SPEC/program/schemas/turn-trace/turn-resolution-trace.v1.schema.json`

| Field | Type | Required | Notes |
|---|---|---|---|
| `phases` | array<object> | yes | Ordered phase traces. |
| `phases[].phaseId` | string | yes | Stable phase token. |
| `phases[].beforeState` | object | yes | State projection before phase execution. |
| `phases[].afterState` | object | yes | State projection after phase execution. |
| `phases[].orderEvents` | array<object> | yes | Order-application events in apply order. |
| `phases[].orderEvents[].sequence` | integer | yes | `>= 0`, monotonic within a phase. |
| `phases[].orderEvents[].orderId` | string | yes | Order identifier for the event. |
| `phases[].orderEvents[].eventType` | string | yes | Event discriminator token. |
| `phases[].orderEvents[].timestamp` | string (`date-time`) | no | Optional event timestamp. |
| `phases[].orderEvents[].payload` | object | no | Optional event-specific payload. |

## `SPEC/program/schemas/turn-trace/merged-trace.v1.schema.json`

| Field | Type | Required | Notes |
|---|---|---|---|
| `schemaVersion` | string | yes | Must match `^v[0-9]+(\\.[0-9]+)*$` (`v1` for current schema). |
| `meta` | object | yes | Turn/document identity metadata. |
| `meta.gameId` | string | yes | Stable game/session identifier. |
| `meta.turnNumber` | integer | yes | `>= 1`. |
| `meta.traceEnabled` | boolean | yes | Whether tracing was enabled for this turn. |
| `meta.exportedAt` | string (`date-time`) | yes | RFC3339 UTC timestamp. |
| `ai` | array<object> | yes | AI section list; each item follows AI v1 schema. |
| `turnResolution` | object | yes | Turn-resolution section; follows resolution v1 schema. |
