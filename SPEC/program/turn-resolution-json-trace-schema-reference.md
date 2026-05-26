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
| `state.observerGoalPhase` | string | no | Resolved phase (`expand`, `colonialLite`, `colonial`, `develop`) for full-AI traces. Omitted for fallback/submitted-order summaries (Refs #2832). |
| `state.phasePlan` | object | no | Compact `PhasePlanOutcome` provenance projection. Optional sub-fields: `colonialAcquisition.{targetFactionId,method}`, `expandDeclareWarTarget`, `expandPeaceTargets`, `colonialPeaceTargets`, `colonialLiteOvertures`, `developPeaceTargets`. Null / empty arms are omitted (Refs #2832). |
| `state.decisionContext` | object | no | Turn / leader / personality / hidden-agenda block. |
| `thresholds` | object | yes | Threshold and gate data. |
| `thresholds.constants` | object | yes | Rule constants used by planner. |
| `thresholds.constants.agendaModifiers` | object | no | Hidden-agenda integer modifiers keyed by `conquer`, `diplomacy`, `spyOrder`, `buildOrder`, `research` (each `0` when no modifier applies for the active agenda). Refs #2832. |
| `thresholds.derived` | object | yes | Derived threshold values. |
| `thresholds.effective` | object | yes | Runtime effective thresholds. |
| `thresholds.gates` | array<object> | yes | Gate checks used for filtering/approval. |
| `thresholds.domainGates` | object | no | Per-planner activation record + resolved thresholds. Required sub-keys when present: `workPlannerRan`, `buildPlannerRan`, `movePlannerRan`, `diplomacyPlannerRan`, `navalPlannerRan`, `researchPlannerRan`, `conquestArmyMovePlannerRan` (booleans); `conquestPasses` (integer). Optional `thresholds.{work,build,research}` integer cutoffs (omitted when the orchestrator did not compute them). Refs #2832. |
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
