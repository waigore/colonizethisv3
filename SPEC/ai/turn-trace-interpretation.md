# Turn Trace Interpretation (Full AI)

**SPEC/ai** - Companion to `SPEC/program/turn-resolution-json-trace.md`.
Explains how to read a full-AI trace JSON section so the recorded state,
thresholds, and gate outputs deterministically reconstruct the causal
chain from snapshot inputs to emitted orders without consulting the
planner source code. Refs #2832.

This doc is a derived spec (`AGENTS.md`). When the recorded value
contradicts the GDD/TDD, update the GDD/TDD first, then realign here.

---

## Scope

Applies to AI trace sections produced by `buildAiTraceSection`
(`packages/colonizethis_ai/lib/src/planning/ai_trace_builder.dart`) for
AI-controlled factions on the full-AI planner path. Fallback "submitted
orders" sections produced by ctdev / app exporters omit the
decision-provenance fields covered here.

---

## Field-to-decision mapping

### Goal selection

- `state.aggregates.snapshot.*` — perception inputs that score
  strategic goals (`atWarWith` -> defend / conquer pressure;
  `capitalThreatened` -> defend boost; `weakNeighbors` -> conquer /
  expand boost; `richUnexploitedProvinces` / `unclaimedProvinces` ->
  expand / trade; `treasury` + `provincesToVictory` -> tech / trade
  trade-offs). See `goal_manager.dart` for the canonical score deltas.
- `thresholds.constants.goalWeights` — per-leader weights applied
  before agenda modifiers.
- `thresholds.constants.agendaModifiers` — hidden-agenda deltas
  applied on top of leader weights. Keys: `conquer`, `diplomacy`,
  `spyOrder`, `buildOrder`, `research` (Refs #2832; the last three
  affect domain thresholds rather than goal scoring directly).
- `thresholds.effective.adjustedGoalScores` — final per-goal scores
  used by `pickWeightedIndex` (`AISeedBundle.goalSeed`-driven). The
  `state.winningCandidate.goal` is the selected outcome of that
  weighted draw.
- `thresholds.gates[]` lists each candidate goal with the score that
  fed the weighted draw and a `selected` flag.

### Phase gating

- `state.observerGoalPhase` — the resolved
  [`ObserverGoalPhase`](../program/turn-resolution-json-trace.md)
  driving phase dispatch (`expand` / `colonialLite` / `colonial` /
  `develop`). Computed deterministically from `oldWorldProvincesOwned`,
  `kObserverConquestMinOwProvincesPerGp`, `hasColonialAcquisitionTargets`,
  and the COLONIAL-lite turn/quota guards in
  `observer_goal_phase.dart`.
- `state.phasePlan` — compact projection of the structural targets the
  phase dispatcher selected:
  - `colonialAcquisition.{targetFactionId, method}` — set only under
    COLONIAL; `method ∈ {joinEmpire, purchaseLand, declareWar}` per
    the structural priority documented in `phase-planner-dispatch.md`.
  - `expandDeclareWarTarget`, `expandPeaceTargets` — populated under
    EXPAND and COLONIAL-lite (the OW push continues during the
    colonial-lite safeguard).
  - `colonialPeaceTargets` — populated under COLONIAL only.
  - `colonialLiteOvertures` — populated under COLONIAL-lite only.
  - `developPeaceTargets` — populated under DEVELOP only.
- Suppression is structural, not predicate-scored: EXPAND traces
  contain no NW colonial fields because the phase planners never call
  the colonial modules.

### Domain activation

- `thresholds.derived.domainWeights` — per-leader domain weights
  (economy / military / diplomacy / research) before threshold checks.
- `thresholds.domainGates.workPlannerRan` — `true` when the civilian
  work pass ran (primary goal expand, weight cleared `workThreshold`,
  colonial pressure active, or GP already owns NW provinces). `false`
  means the pass was skipped due to insufficient domain weight without
  a structural override.
- `thresholds.domainGates.buildPlannerRan` — `true` when build
  candidates cleared `buildThreshold` (or a force-rebuild signal
  pinned the threshold to zero). `false` means the threshold gate
  short-circuited.
- `thresholds.domainGates.navalPlannerRan` — `true` when the planner's
  internal weight (`computeNavalRunGate`) cleared `kNavalRunMinWeight`
  (after optional colonial-pressure boost). `false` distinguishes
  "skipped due to low weight" from "ran but produced no targets".
- `thresholds.domainGates.researchPlannerRan` — `true` when
  `primaryGoal == tech` OR `domainWeights.research >= researchThreshold`.
  `false` means the threshold gate short-circuited.
- `thresholds.domainGates.conquestArmyMovePlannerRan` — `true` when at
  least one conquest army-move pass executed. Today always `true`
  (the orchestrator always runs the first pass); recorded for forward
  compatibility.
- `thresholds.domainGates.conquestPasses` — resolved pass count:
  `kStalledConquestArmyMovePasses` (22) under EXPAND and COLONIAL-lite,
  `1` otherwise.
- `thresholds.domainGates.thresholds.{work,build,research}` — the
  computed cutoffs the orchestrator compared domain weights against.
  Entries are omitted when the orchestrator did not compute them.

### Hidden agendas

Five integer modifiers under `thresholds.constants.agendaModifiers`
adjust planner behavior:

- `conquer` — applied to the `conquer` goal score.
- `diplomacy` — applied to the `diplomacy` goal score.
- `spyOrder` — subtracted from the work threshold when spy work
  candidates exist.
- `buildOrder` — subtracted from the build threshold (positive value
  lowers the threshold and makes builds more likely).
- `research` — subtracted from the research threshold.

Defaults are `0` per `hidden_agenda_config.dart`.

### Final orders

- `outcome.finalAggregatedOrders` — emitted orders for the faction.
- `outcome.domainOutputs` — per-domain order counts (work / build /
  move / armyMove / navalMove / etc.). `conquestArmyMove` is the
  subset of `armyMove` produced by the conquest army-move planner.

---

## Acceptance criteria

- Given a full-AI trace from a COLONIAL turn, when a reader inspects
  the trace, then `state.observerGoalPhase` equals `"colonial"` and
  `state.phasePlan.colonialAcquisition.method` equals one of
  `"joinEmpire"`, `"purchaseLand"`, or `"declareWar"`.
- Given a full-AI trace from a turn whose naval planner was skipped
  on the `kNavalRunMinWeight` gate, when a reader inspects
  `thresholds.domainGates`, then `navalPlannerRan` is `false`.
- Given a full-AI trace from an EXPAND or COLONIAL-lite turn, when a
  reader inspects `thresholds.domainGates`, then `conquestPasses`
  equals `kStalledConquestArmyMovePasses`.
- Given a full-AI trace, when a reader inspects
  `thresholds.constants.agendaModifiers`, then it contains the keys
  `conquer`, `diplomacy`, `spyOrder`, `buildOrder`, and `research`,
  each holding the integer modifier returned by the corresponding
  `getAgenda*Modifier` function.
