---
name: interpret-ai-traces
description: Interprets ColonizeThis full-AI turn-trace JSON (from `run_observer_game` or app/ctdev exports) to explain why a deterministic AI emitted specific orders and to spot performance bottlenecks. Use when the user supplies a merged turn trace, asks why the AI did/did not do X on turn N, asks why a GP chose a goal/phase/target, asks why orders were suppressed, or wants to optimize next-turn resolution against the 15-second budget.
---

# Interpret AI Traces (ColonizeThis)

## When this applies

Use this skill whenever the user wants to understand AI behavior or performance from a merged turn-trace JSON:

- "Why did gp3 declare war on gp1 on turn 42?"
- "Why did gp5 not build any regiments this turn?"
- "Why was no naval planner output produced?"
- "Phase says EXPAND but I expected COLONIAL — what happened?"
- "This turn took 18s — find the hot path."
- "The observer trace shows X — is the AI misbehaving?"

The Full AI path is **deterministic** for fixed `(save, seeds, ruleset, hidden agendas)`. Every emitted order is reconstructable from the trace fields plus the planner specs — never speculate; always cite the field that authorizes the conclusion.

## Required reading (in this exact order)

The agent **must** read these before drawing conclusions. Stop at the first three if the question is purely behavioral; read all five for perf:

1. **`SPEC/ai/turn-trace-interpretation.md`** — Canonical field-to-decision mapping for `state`, `thresholds`, `outcome`. **The primary reader guide.**
2. **`SPEC/program/turn-resolution-json-trace.md`** — Normative JSON contract (required fields, decision-provenance fields, merged document shape, retention).
3. **`SPEC/program/turn-resolution-json-trace-schema-reference.md`** — Field-by-field tables for the three v1 schemas.
4. **`SPEC/program/run_observer_game-tool.md`** — Artifact layout, full vs minimal trace mode, ObserverSnapshot v4 (snapshots are **not** AI traces).
5. **`SPEC/program/turn-resolution.md`** + **`.cursor/rules/colonizethis-turn-resolution-budget.mdc`** — The 15 000 ms hard budget and hot-path no-nos (read for perf questions).

For follow-up context when a specific decision needs explaining:

| Question | Spec |
|----------|------|
| What phase was active and why? | `SPEC/ai/ai-architecture.md` § Observer goal phases, `SPEC/ai/phase-planner-architecture.md` |
| What does `state.phasePlan` mean? | `SPEC/ai/phase-planner-dispatch.md` (`PhasePlanOutcome` projection) |
| Why was a planner skipped? | `SPEC/ai/phase-planner-dispatch.md` § orchestrator slices |
| What do `agendaModifiers` do? | `SPEC/ai/hidden-agendas.md`, `SPEC/program/ai-planner.md` § Hidden agendas |
| What does an `army_move_ignored` `ignoreReason` mean? | `SPEC/program/turn-resolution-json-trace.md` § Turn-resolution trace |
| What does a goal score reflect? | `packages/colonizethis_ai/lib/src/planning/goal_manager.dart` (read only when SPEC is thin) |

The **producer** of `ai[]` sections is `packages/colonizethis_ai/lib/src/planning/ai_trace_builder.dart` (consult only when a field's meaning is not in the SPEC).

## Trace file location and shape

`run_observer_game` writes one merged JSON per resolved turn under:

```
<output>/observer-traces/<gameId>/turn-<N>-<YYYYMMDDTHHMMSSmmmZ>.json
```

`turn-NNNNNN.snapshot.json` / `.html` are **ObserverSnapshot v4** (world rollup) — different format, used for verify gates, not for AI decision-tracing.

App / ctdev write the same merged contract under `tmp/turn-traces/<gameId>/`.

Per-turn merged document shape:

```json
{
  "schemaVersion": "v1",
  "meta": { "gameId", "turnNumber", "exportedAt", "traceEnabled", "source" },
  "ai":  [ /* one TurnTraceAiSection per AI-controlled GP */ ],
  "turnResolution": { "phases": [ /* per-phase before/after + orderEvents */ ] }
}
```

`meta.source` is `"run_observer_game"` for observer runs and `"app"` / `"ctdev"` elsewhere.

## Behavior debugging workflow

Apply these steps in order. **Skip none.** Always cite the JSON path that authorizes the conclusion (e.g. `ai[2].thresholds.domainGates.navalPlannerRan == false`).

### Step 1 — Identify the faction and isolate its AI section

`ai[]` may contain multiple GPs. Filter by `factionId`. All subsequent steps reference fields under that one section.

### Step 2 — Resolve the phase

Read `state.observerGoalPhase` (`expand` / `colonialLite` / `colonial` / `develop`). This is **structural** — many planner outputs are suppressed by phase, not by score. Cross-check with `state.aggregates.snapshot.oldWorldProvincesOwned` and `kObserverConquestMinOwProvincesPerGp` (10) to verify the phase resolution.

If a phase looks wrong, the user usually wants:
- EXPAND but expected COLONIAL → check `hasColonialAcquisitionTargets` preconditions in `observer_goal_phase.dart`.
- COLONIAL-lite but expected COLONIAL → check turn ≥ `kObserverColonialLiteMinTurn` and OW range.

### Step 3 — Resolve the strategic goal

Inspect:

- `state.winningCandidate.goal` — selected goal.
- `state.topAlternates[]` — ranked losers.
- `thresholds.effective.adjustedGoalScores` — final per-goal scores fed into `pickWeightedIndex`.
- `thresholds.constants.goalWeights` + `thresholds.constants.agendaModifiers.{conquer,diplomacy}` — inputs that produced the adjusted scores.
- `thresholds.gates[]` — per-candidate score and `selected` flag.

For deterministic replays, the winner is whatever `pickWeightedIndex` draws from these scores under `AISeedBundle.goalSeed` — same trace ⇒ same outcome.

### Step 4 — Read the phase plan (structural targets)

`state.phasePlan` (compact `PhasePlanOutcome` projection) — only arms that match the active phase are present:

| Phase | Expected arms |
|-------|---------------|
| EXPAND | `expandDeclareWarTarget`, `expandPeaceTargets` |
| COLONIAL-lite | `expandDeclareWarTarget`, `expandPeaceTargets`, `colonialLiteOvertures` |
| COLONIAL | `colonialAcquisition.{targetFactionId,method}`, `colonialPeaceTargets` |
| DEVELOP | `developPeaceTargets` |

If a target you expected (e.g. `colonialAcquisition.method == "declareWar"`) is **absent**, the suppression is structural at the phase planner — not a score miss.

### Step 5 — Read the domain gates

`thresholds.domainGates` tells you **which planners actually ran**:

- `workPlannerRan`, `buildPlannerRan`, `navalPlannerRan`, `researchPlannerRan`, `diplomacyPlannerRan`, `movePlannerRan`, `conquestArmyMovePlannerRan` (booleans).
- `conquestPasses` — `kStalledConquestArmyMovePasses` (22) under EXPAND / COLONIAL-lite, `1` otherwise.
- Optional `thresholds.{work,build,research}` — the cutoffs the orchestrator compared domain weights against.

Compare against `thresholds.derived.domainWeights` (per-domain weights pre-threshold). A `false` gate with weight below the cutoff = "skipped on threshold"; `false` with weight above cutoff = SPEC contradiction (file a bug).

### Step 6 — Read the emitted orders

`outcome.finalAggregatedOrders` — every emitted order, in the order applied.
`outcome.domainOutputs` — per-domain counts (`armyMove`, `conquestArmyMove`, `work`, `build`, etc.).

If an expected order **type** is absent, check Step 5; if the **target** is wrong, check Step 4; if the **goal** that authorized it is wrong, check Step 3; if the **phase** is wrong, check Step 2.

### Step 7 — Cross-check resolver outcomes

`turnResolution.phases[]` shows what the engine actually applied (not what was proposed). For movement issues, scan `phases[].orderEvents[]` for:

- `army_move_ignored` with `ignoreReason` ∈ `{army_not_found, owner_mismatch, home_army_locked, destination_in_other_region, invalid_adjacency}` — order was emitted but rejected at apply time. Spec: `SPEC/program/turn-resolution-json-trace.md`.
- `bundled_work_move_skipped` — implicit work-leg failed.

An order present in `ai[].outcome.finalAggregatedOrders` but missing/`_ignored` in `turnResolution` is a resolver issue, not a planner issue.

## Misbehavior diagnosis template

When concluding "the AI is misbehaving" or "the AI is correct given the input", structure the answer like this:

```
Faction: gpN | Turn: T | Phase: <observerGoalPhase> (cause: <field>)
Goal: <winningCandidate.goal> (score X over alternates Y,Z; cause: agenda=<id> modifier=<n>)
Phase plan arm read: <plan.field> = <value>
Domain gates triggered: <list>; skipped: <list with reason>
Final orders: <count by domain>
Resolver outcome: <applied | ignored: reason>

Conclusion: behavior is <expected | misbehaving>
- If expected: cite the specs/fields that authorized it.
- If misbehaving: identify which step (2-7) shows a value that contradicts a SPEC.
```

Never claim misbehavior without naming the SPEC line the trace contradicts.

## Performance analysis workflow

Used when a turn breaches the **15 000 ms hard budget** (`kTurnProcessingWallClockBudgetMs`, see `colonizethis-turn-resolution-budget.mdc`).

### Step P1 — Confirm budget scope

The budget covers `generateOrdersForGameFullAI` → `validateOrdersAndResolveTurnFromTrustedOrders` returning `TurnResolutionComplete`. Init, trace export, snapshot I/O, and `run-summary.json` are **excluded**.

### Step P2 — Inspect phase-level timing

Read the logging signals listed in `SPEC/program/logging/turn-resolution.md`: `session_start`, `ai_complete`, `resolve_complete`, `success_ready`, plus per-phase slices. These are emitted via `logger` per `colonizethis-core-principles.mdc`.

### Step P3 — Map slow segments to known no-nos

The budget rule lists canonical regressions. Compare against trace + logs:

- Large isolate payloads on the success envelope.
- Uncapped `units/armies × tiles/provinces/destinations` probe loops in order suggestions (see `SPEC/program/order-suggestions.md`).
- Redundant per-probe validator construction.
- Duplicate `WorldState` / ownership / `allProvinces` scans (governed by `SPEC/program/logic-dual-region-province-access.md`).
- Per-candidate `observerGoalPhaseFor` recomputes (should be hoisted via `runPhasePlanners`; see the orchestrator slices in `SPEC/ai/phase-planner-dispatch.md`).
- `logger` chatter at province / tile / candidate scale.
- UI blocking `Processing Turn` on synchronous persistence (`SPEC/ui/next-turn-confirmation.md`).

### Step P4 — Bound the worst contributor

Identify the **single largest slice** and check whether it has deterministic probe/acceptance caps. The budget rule requires bounded candidate search, reused validation state, and memoized scoring while preserving determinism. Any uncapped loop above budget is a defect, not a tuning opportunity.

## Anti-patterns when reading traces

- **Speculating about goal/phase choice** without quoting `state.observerGoalPhase`, `state.winningCandidate.goal`, and the `thresholds.gates[]` row.
- **Confusing `turn-NNNNNN.snapshot.json` with the merged turn-trace JSON.** Snapshots have no `ai[]` array and cannot answer planner-level questions.
- **Treating order absence as a bug** without checking phase suppressions (Step 4) and domain gates (Step 5) first.
- **Claiming "AI did X for reason Y"** when Y is not a trace field. If you cannot cite a JSON path, do not state the reason.
- **Using `print` / ad-hoc dumps to investigate** — the trace is the contract. Read it; do not regenerate it from logs.
- **Editing planner code before reading `SPEC/ai/turn-trace-interpretation.md`** when the field already explains the behavior.

## Quick reference cheat sheet

| Symptom | First field to read |
|---------|---------------------|
| Wrong phase | `state.observerGoalPhase`, `state.aggregates.snapshot.oldWorldProvincesOwned` |
| Wrong goal | `thresholds.effective.adjustedGoalScores`, `thresholds.constants.agendaModifiers` |
| No declare-war | `state.phasePlan.expandDeclareWarTarget` / `colonialAcquisition.method` |
| No regiment build | `thresholds.domainGates.buildPlannerRan`, `thresholds.domainGates.thresholds.build` |
| No naval orders | `thresholds.domainGates.navalPlannerRan` |
| No NW work / purchase | `state.observerGoalPhase` (EXPAND / DEVELOP structurally suppress) |
| Orders emitted but no map change | `turnResolution.phases[].orderEvents[].eventType` + `ignoreReason` |
| Slow turn | logging slices in `SPEC/program/logging/turn-resolution.md` |

## Producing the answer

End every analysis with:

1. **Conclusion** — one line: expected vs misbehaving vs perf-regression.
2. **Evidence** — the JSON paths (and spec sections) that prove it.
3. **If misbehaving or over-budget** — name the SPEC line contradicted, or the no-no pattern matched, and suggest the next step (file an issue via `create-github-issue` skill, run `verify-github-issue`, or open a focused refactor via `refactoring-opportunity-github-issue`). Do **not** propose code edits until the contradiction is documented.
