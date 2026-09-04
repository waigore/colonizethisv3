---
name: interpret-ai-traces
description: Interprets ColonizeThis full-AI turn-trace JSON (from `run_observer_game` or app/ctdev exports) to explain why a deterministic AI emitted specific orders and to spot performance bottlenecks. Use when the user supplies a merged turn trace, asks why the AI did/did not do X on turn N, asks why a GP chose a goal/phase/target, asks why orders were suppressed, or wants to optimize next-turn resolution against the 15-second budget.
---

# Interpret AI Traces (ColonizeThis)

Full AI is **deterministic** for fixed `(save, seeds, ruleset, hidden agendas)`. Cite the JSON path that authorizes every conclusion. Do not speculate. Field meaning lives in SPEC — read it; do not copy constants out of code into this skill.

## Authority

- Behavior: `SPEC/ai/turn-trace-interpretation.md` (primary), `SPEC/program/turn-resolution-json-trace.md`, `SPEC/program/turn-resolution-json-trace-schema-reference.md`
- Artifacts: `SPEC/program/run_observer_game-tool.md` (`turn-NNNNNN.snapshot.json` is **not** an AI trace)
- Perf: `SPEC/program/turn-resolution.md`, `colonizethis-turn-resolution-budget.mdc`, logging annex `SPEC/program/logging/turn-resolution.md`

Follow-up SPECs as needed: phase (`SPEC/ai/ai-architecture.md`, `phase-planner-architecture.md`, `phase-planner-dispatch.md`), agendas (`SPEC/ai/hidden-agendas.md`). Producer: `packages/colonizethis_ai/lib/src/planning/ai_trace_builder.dart` only when SPEC is silent.

## Files

Observer: `<output>/observer-traces/<gameId>/turn-<N>-<timestamp>.json`. App/ctdev: `tmp/turn-traces/<gameId>/`. Shape: `{ schemaVersion, meta, ai[], turnResolution }`. Filter `ai[]` by `factionId`.

## Behavior (cite paths)

Walk in this order; skip a step only if the question cannot touch it:

1. **Phase** — `state.observerGoalPhase`. Cross-check OW counts / phase constants **in SPEC/code**, not memorized numbers. Wrong EXPAND vs COLONIAL → `hasColonialAcquisitionTargets` / colonial-lite turn gate in `observer_goal_phase.dart`.
2. **Goal** — `state.winningCandidate.goal`, `state.topAlternates[]`, `thresholds.effective.adjustedGoalScores`, `thresholds.constants.{goalWeights,agendaModifiers}`, `thresholds.gates[]`. Winner is `pickWeightedIndex` under `AISeedBundle.goalSeed`.
3. **Phase plan** — `state.phasePlan` arms present for that phase (`expandDeclareWarTarget`, `colonialAcquisition`, peace/overture fields per `phase-planner-dispatch.md`). Absent arm = structural suppression, not a score miss.
4. **Domain gates** — `thresholds.domainGates.*Ran`, `conquestPasses`, optional domain cutoffs vs `thresholds.derived.domainWeights`. False + weight below cutoff = skipped; false + weight above = SPEC contradiction.
5. **Orders** — `outcome.finalAggregatedOrders`, `outcome.domainOutputs`. Missing type → gates; wrong target → plan; wrong goal/phase → steps 1–2.
6. **Resolver** — `turnResolution.phases[].orderEvents[]` (`army_move_ignored` + `ignoreReason`, `bundled_work_move_skipped`). Emitted but ignored = resolver, not planner.

```
Faction: gpN | Turn: T | Phase: <field> (cause)
Goal: <winningCandidate.goal> (scores / agenda)
Phase plan: <arm>=<value>
Gates ran/skipped: …
Orders / resolver: …

Conclusion: expected | misbehaving
```

Misbehavior requires a SPEC line the trace contradicts.

## Perf

Budget scope and no-nos: `colonizethis-turn-resolution-budget.mdc`. Timing: logging slices in `SPEC/program/logging/turn-resolution.md`. Name the single largest slice and whether it has deterministic caps. Uncapped loops over budget are defects.

## Answer

1. Conclusion (expected / misbehaving / perf-regression)
2. Evidence (JSON paths + SPEC sections)
3. If misbehaving or over-budget: SPEC line or no-no pattern; next step is `create-github-issue` — no code edits until the contradiction is documented
