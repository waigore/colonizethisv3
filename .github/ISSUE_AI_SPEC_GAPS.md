# AI implementation vs SPEC — missing parts

**Summary:** Comparison of current AI implementation (`colonizethis_ai`, `colonizethis_logic` AI paths) against SPEC/ai and SPEC/program AI docs. Identifies missing or partial features for Phase 6 full AI.

## Specs consulted

- **SPEC/ai/ai-architecture.md** — Hybrid stack, turn pipeline, tactical rules, seeding
- **SPEC/ai/ai-personalities.md** — Leader personalities, domain weights, behavioral modifiers
- **SPEC/ai/ai-dossier.md** — Dossier structure, PlayerView-safe rules
- **SPEC/ai/hidden-agendas.md** — Agenda assignment, behavior modifiers, evidence
- **SPEC/ai/dialogue-and-mood.md** — DialogueEvent, PortraitMoodEvent, when to emit
- **SPEC/program/ai-planner.md** — Control rules, seeding, order merge
- **SPEC/program/ai-systems-impl.md** — Module boundaries, strategic/tactical APIs
- **SPEC/program/ai-events-and-dossier.md** — Events, evidence flow, dossier projection

---

## 1. Bug: Naval mission orders dropped in full-AI aggregation — **FIXED**

**Spec:** `generateOrdersForGameFullAI` should aggregate all order types including naval (ai_planner.md: "Aggregates all order types including naval").

**Current:** `packages/colonizethis_logic/lib/src/ai/ai_planner.dart` — `generateOrdersForGameFullAI` now aggregates both `navalMoveOrdersByPlayerId` and `navalMissionOrdersByPlayerId` and passes them into the returned `Orders()`. Regression test in `ai_planner_test.dart` ensures per-player naval (move + mission) orders are preserved in game-level aggregation.

---

## 2. Evidence accumulation — **IMPLEMENTED** (diplomacy phase)

**Spec:** SPEC/ai/hidden-agendas.md — "When the game or AI performs an action, evidence rules may add points to that agenda's suspicion counter". SPEC/program/ai-events-and-dossier.md — "Evidence rules evaluated when actions are applied (turn resolution or post-resolution hook)."

**Current:** `colonizethis_logic/lib/src/dossier/evidence_rules.dart` defines evidence rules. Diplomacy resolver calls them when applying declare war and offer peace: **declare war** → warmonger +2 if target is weaker GP (by military level), backstabber +2 if target was allied; **offer peace** → peacemaker +1. Evidence is appended to `game.dossierEvidenceEntries` per (observer, subject, agenda type); only human observers receive entries, and only when the actor (subject) is AI-controlled. Combat/other actions not yet hooked.

---

## 3. Dossier projection incomplete

**Spec:** SPEC/ai/ai-dossier.md — Dossier sections: **Basic intel** (personality/archetype, relation, relative military/economic strength), **Hidden agenda analysis** (suspicion scores, bands, best-guess agenda id and confidence %), **Evidence list**, **Behavioral notes** (war history, diplomatic pattern, military buildup), **Timeline** (chronological notable actions).

**Current:** `DossierView` in `colonizethis_ai/lib/src/dossier.dart` has only `subjectId`, `suspicionByAgendaType`, `evidenceList`. Basic intel (personality, relation, relative strength), behavioral notes, and timeline are not exposed. No "best-guess agenda id and confidence %" derived from suspicion.

**Missing:** Extend dossier projection (and optionally storage) to include basic intel, behavioral notes, timeline; add best-guess agenda id + confidence % from suspicion bands for display.

---

## 4. Dialogue and mood mostly stubs

**Spec:** SPEC/ai/dialogue-and-mood.md — Dialogue categories: diplomatic, reactive, event, agenda, negotiation. Emit `DialogueEvent` on diplomatic actions, game events, reactive banter, agenda-flavour (keys + context; content in data assets). Emit `PortraitMoodEvent` on negotiation mood transition (mood state machine: current mood, offerQualityDelta, stallCounter → next mood).

**Current:**  
- **Dialogue:** Only one emission in `generateStrategicOrders`: when `dialogueSeed % 7 == 0`, a single generic `DialogueEvent(leaderId, category: 'agenda', situation: 'comment', era: 'earlyModern')`. No diplomatic, reactive, event, or negotiation dialogue; no use of actual situation/era/variables from context.  
- **Mood:** `PortraitMoodEvent` is never emitted. No mood state machine, no negotiation offer/quality/stall inputs.

**Missing:**  
- Emit dialogue on actual events (declare war, peace offer, battle result, etc.) with correct category/situation/era/variables.  
- Implement negotiation mood state machine and emit `PortraitMoodEvent` on transition.  
- (Optional) Dialogue content keys/catalog in data package per spec.

---

## 5. Tactical (Quick Battle) not state-aware

**Spec:** SPEC/ai/ai-architecture.md — Tactical behavior rules: prefer good terrain (hill, town, woods) with high-value units; avoid fragile units in swamp; use Volley Fire / Defend when outmatched or holding key lanes; use Maneuver / Fall Back to rotate damaged units; use Assault / Charge when enemy lane disrupted and terrain favorable. SPEC/program/ai-systems-impl.md — `decideQuickBattleActions(QuickBattleState, nationId, config, tacticalSeed)` returns CP-based actions per lane; deterministic given state and seed.

**Current:** `decideQuickBattleActions` in `colonizethis_ai/lib/src/tactical_ai.dart` takes `QuickBattleInput` (and nationId, config, tacticalSeed) but **ignores** input state. It picks a random strategy from a fixed list of action lists. No use of lane state, strength, terrain, or unit health.

**Missing:** Use `QuickBattleInput` (and any extended state) to choose actions per spec: e.g. when outmatched or holding center → Volley Fire / Defend; when damaged → Maneuver / Fall Back; when enemy disrupted and terrain favorable → Assault / Charge. Remain deterministic via `tacticalSeed`.

---

## 6. Perception summary incomplete

**Spec:** SPEC/ai/ai-architecture.md — Perception: threats, opportunities, economy, relations from PlayerView only.

**Current:** `AIWorldSnapshot` / `ThreatSummary` / `OpportunitySummary` in `perception.dart`:  
- `ThreatSummary`: `atWarWith` is populated; `neighborProvincesHostile` and `capitalThreatened` are never set (comment: "stub for now").  
- `OpportunitySummary`: `unclaimedProvinces` is set; `weakNeighbors` and `richUnexploitedProvinces` are always empty.

**Missing:** Compute `neighborProvincesHostile` and `capitalThreatened` from topology + visibility (and optionally unit positions). Populate `weakNeighbors` and `richUnexploitedProvinces` from view data where observable.

---

## 7. No diplomacy domain planner

**Spec:** SPEC/ai/ai-architecture.md — Domain planning: economy, military, diplomacy, research planners; each emits candidate orders. SPEC/program/ai-systems-impl.md — AI uses suggestion API for all order types; when naval in scope, API exposes naval candidates.

**Current:** `runDomainPlanners` runs economy (work/build), movement, naval (move + mission), and research. The order suggestion API **does** provide `suggestDiplomaticOrders` (see gap #11); domain_planners calls it. The diplomacy planner is a **stub**: it picks one candidate at random from the list rather than scoring by personality/agenda. Full AI can produce `DiplomaticOrder`s via this path but selection is not utility-based.

**Missing:**  
- Replace the stub diplomacy planner with one that, when goal is diplomacy/conquer/trade, scores and selects diplomatic orders using personality and agenda modifiers (e.g. war likelihood, peace tendency, alliance tendency from ai-personalities.md).

---

## 8. Hidden agenda modifiers incomplete — **PARTIAL** (tech_thief, envy build/research)

**Spec:** SPEC/ai/hidden-agendas.md — Behavior modifiers per agenda: war declaration, peace acceptance, alliance acceptance, build/order choice (e.g. tech_thief: spy/research; envy: mirror human), treaty breaking.

**Current:** `hidden_agenda.dart` implements `agendaConquerModifier`, `agendaDiplomacyModifier`, **`agendaResearchModifier`** (tech_thief +35), and **`agendaBuildOrderModifier`** (envy +20). Domain planners use them: tech_thief lowers the research domain threshold so research is chosen more often; envy lowers the economy threshold so build orders are chosen more often. No modifiers for peace acceptance, alliance acceptance, or treaty breaking; no spy-order type yet (research boost only). Envy "mirror human" is expressed as build-order tendency boost; full mirroring of human builds/targets can use this weight when visibility exists.

**Missing:** Peace/alliance/treaty-breaking thresholds or weights for diplomacy planner. Spy order type and tech_thief boost for spy when available.

---

## 9. Personality thresholds not implemented

**Spec:** SPEC/ai/ai-personalities.md — Personality also adjusts **thresholds**: War likelihood, Peace tendency, Alliance tendency, Research preference (weights per tech category). "Applied when scoring actions (e.g. declare war, accept peace, choose research slot)."

**Current:** Personality config in `colonizethis_data` provides only **domain weights** (economy, military, diplomacy, research) and **goal weights** (defend, expand, conquer, trade, tech, diplomacy). No war likelihood, peace tendency, alliance tendency, or per-category research preference.

**Missing:** Add personality (and optionally agenda) threshold/weight config for war, peace, alliance, and research category; use them in goal selection and in diplomacy/research planners when scoring actions.

---

## 10. Goal selection is weighted random, not behavior tree

**Spec:** SPEC/ai/ai-architecture.md — "Behavior trees pick top-level goals"; "Behavior trees pick long-term strategy (expand, defend, trade, conquer, tech, diplomacy)."

**Current:** `goal_manager.dart` implements **weighted random** choice over `StrategicGoal` using personality goal weights, agenda modifiers, and snapshot situational modifiers. No actual behavior tree (nodes, sequences, selectors).

**Note:** This may be acceptable if "behavior tree" is interpreted as "hierarchical goal selection"; the spec also says "utility AI scores and selects concrete objectives". If strict behavior-tree structure is required (e.g. for designer-editable trees), replace weighted random with a small tree (e.g. selector over defend/expand/conquer/trade/tech/diplomacy) that uses the same weights as inputs.

---

## 11. Order suggestion API has no diplomatic suggestions — **IMPLEMENTED**

**Spec:** SPEC/program/ai-systems-impl.md — "AI calls the suggestion API with PlayerView and current orders"; "When naval is in scope, API also exposes naval candidates."

**Current:** `OrderSuggestionAPI` in `colonizethis_logic` exposes `suggestDiplomaticOrders(PlayerView, Game, MapTopology, Orders)`. `order_suggestion.dart` implements it: returns candidate `DiplomaticOrder`s that are valid and visible (declare war, offer peace, alliance, establish overture, grant aid, set subsidy) using game relations and overture state. `DefaultOrderSuggestionAPI` delegates to it; `domain_planners.dart` calls it for the diplomacy planner. Tests in `order_suggestion_api_impl_test.dart` cover each order type.

---

## Summary table

| # | Area | Status | Priority |
|---|------|--------|----------|
| 1 | Naval mission orders dropped in full-AI aggregation | Fixed | High |
| 2 | Evidence accumulation | Implemented (diplomacy) | High |
| 3 | Dossier (basic intel, behavioral notes, timeline) | Partial | Medium |
| 4 | Dialogue and mood | Stub only | Medium |
| 5 | Tactical Quick Battle state-aware | Missing | Medium |
| 6 | Perception (threats/opportunities) | Partial | Medium |
| 7 | Diplomacy domain planner + API | Missing | High |
| 8 | Hidden agenda (tech_thief, envy; peace/alliance/treaty) | Partial (tech_thief/envy research/build) | Medium |
| 9 | Personality thresholds (war/peace/alliance/research) | Missing | Medium |
| 10 | Behavior tree vs weighted random | Design choice | Low |
| 11 | OrderSuggestionAPI diplomatic | Implemented | High (for #7) |
