# AI implementation vs SPEC — missing parts

**Summary:** Comparison of current AI implementation (`colonizethis_ai`, `colonizethis_logic` AI paths) against SPEC/ai and SPEC/program AI docs. Identifies missing or partial features for Phase 6 full AI.

**Issue #18 resolution:** All gaps listed in GitHub issue #18 are addressed: gaps 1–3, 5–9, 11 are implemented; gap 10 is documented (weighted choice satisfies spec). Gap 4 (dialogue and mood) is partial by design: optional reactive situations (attack on ally, tech first, colony founded, threat ignored, gift, spies caught) are deferred until game hooks exist; negotiation remains UI-driven via `dialogueEventForNegotiation`. See SPEC/ai/dialogue-and-mood.md.

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

## 2. Evidence accumulation — **IMPLEMENTED** (diplomacy + combat)

**Spec:** SPEC/ai/hidden-agendas.md — "When the game or AI performs an action, evidence rules may add points to that agenda's suspicion counter". SPEC/program/ai-events-and-dossier.md — "Evidence rules evaluated when actions are applied (turn resolution or post-resolution hook)."

**Current:** `colonizethis_logic/lib/src/dossier/evidence_rules.dart` defines evidence rules. **Diplomacy:** declare war → warmonger +2 if target is weaker GP, backstabber +2 if target was allied; offer peace → peacemaker +1. **Combat:** Land battle victory (AI wins as attacker, province flips) → warmonger +1, or +2 if defender was weaker GP; naval battle victory (one side eliminated) → warmonger +1. Evidence is appended to `game.dossierEvidenceEntries` per (observer, subject, agenda type); only human observers receive entries, and only when the actor (subject) is AI-controlled. Turn resolver calls evidence after each land battle (quick and auto-resolve) and each naval battle.

---

## 3. Dossier projection incomplete — **IMPLEMENTED**

**Spec:** SPEC/ai/ai-dossier.md — Dossier sections: **Basic intel** (personality/archetype, relation, relative military/economic strength), **Hidden agenda analysis** (suspicion scores, bands, best-guess agenda id and confidence %), **Evidence list**, **Behavioral notes** (war history, diplomatic pattern, military buildup), **Timeline** (chronological notable actions).

**Current:** `DossierView` in `colonizethis_ai/lib/src/dossier.dart` includes **basic intel** (`DossierBasicIntel`: relation level/state, relative military/economic strength, personality archetype from config), **best-guess agenda** (`DossierBestGuessAgenda`: agenda type with highest suspicion + confidence % from bands), **evidence list**, **behavioral notes** (summary from evidence, e.g. "Declared war (2).", "Offered peace (1)."), and **timeline** (chronological notable actions from evidence). `colonizethis_data` exposes `getArchetypeDisplayNameForLeader(leaderId)` for display names (e.g. "Fortifier", "Explorer"). All PlayerView-safe; true hidden agenda never exposed.

---

## 4. Dialogue and mood — **PARTIAL** (diplomatic + event battle + event era change + mood state machine + base mood + reactive forts_on_border + negotiation helper)

**Spec:** SPEC/ai/dialogue-and-mood.md — Dialogue categories: diplomatic, reactive, event, agenda, negotiation. Emit `DialogueEvent` on diplomatic actions, game events, reactive banter, agenda-flavour (keys + context; content in data assets). Emit `PortraitMoodEvent` on negotiation mood transition (mood state machine: current mood, offerQualityDelta, stallCounter → next mood).

**Current:**  
- **Dialogue:** (1) In `generateStrategicOrders`: when `dialogueSeed % 7 == 0`, a generic `DialogueEvent(leaderId, category: 'agenda', situation: 'comment', era: 'earlyModern')`. (2) **Diplomatic:** When an AI applies declare war or offer peace in the diplomacy phase, `resolveDiplomacyPhase` invokes optional `onDialogue` with `DialogueEvent(leaderId: gpId, category: 'diplomatic', situation: 'declare_war' | 'peace_offer', era: 'earlyModern', variables: {'otherNation': targetId})`. Callback is threaded via `resolveTurnForGame` / `resolveTurnForGameFromOrderEngine` / `validateOrdersAndResolveTurn`. (3) **Event (battle result):** When a land or naval battle is resolved, `_runCombatPhase` and `_runNavalInterceptionCombatPhase` invoke `onDialogue` with `DialogueEvent(category: 'event', situation: 'battle_won' | 'battle_lost', era: 'earlyModern', variables: {'otherNation', 'province' for land})` for AI victor and/or AI loser; only AI leaders emit. Helpers in `event_dialogue.dart`: `dialogueEventsForLandBattleResult`, `dialogueEventsForNavalBattleResult`. (4) **Event (era change):** When the calendar era changes at end of turn, `_runEndOfTurnPhase` invokes `onDialogue` with `DialogueEvent(category: 'event', situation: 'era_change', era: newEra, variables: {'previousEra': previousEra})` for each AI leader. Era is derived from turn via `TurnTimeMapping.yearAtTurn` and `eraFromYear` (discovery < 1600, earlyModern 1600–1699, imperial 1700–1799, industrial ≥ 1800). (5) **Reactive (forts_on_border):** When a human completes `build_fort` in the build/work phase, `applyBuildAndWorkOrders` (with topology and `onDialogue`) invokes `dialogueEventsForReactiveFortsOnBorder` and emits one `DialogueEvent(leaderId, category: 'reactive', situation: 'forts_on_border', era, variables: {'otherNation', 'province'})` per AI leader who owns a province adjacent to the fortified province. (6) **Negotiation:** `dialogueEventForNegotiation(leaderId, situation, era, mood, variables)` in `event_dialogue.dart` builds a `DialogueEvent(category: 'negotiation', ...)` for UI/negotiation flow (opening, counter_offer, accepting, rejecting); UI calls this and passes to `onDialogue` or displays.  
- **Mood:** **Mood state machine** in `colonizethis_ai/lib/src/mood_state_machine.dart`: `computeNextNegotiationMood(currentMood, offerQualityDelta, stallCounter, seed)` returns next mood (considering, pleased, gracious, calculating, skeptical, impatient, irritated, dismissive); deterministic. **PortraitMoodEvent** is emitted from `generateStrategicOrders` when `dialogueSeed % 7 == 0` with base mood `considering` (from/to same; durationMs 0). When the app has negotiation UI and offer/stall inputs, it can call `computeNextNegotiationMood` and emit `PortraitMoodEvent` on transition.  
- **Dialogue key catalog:** `colonizethis_data` exposes `dialogueKeyForEvent(category, situation, era, mood)` and constants `kDialogueCategories`, `kDialogueEras`, `kPortraitMoodValues` for resolving DialogueEvent to localization keys per SPEC/ai/dialogue-and-mood.md.

**Missing:**  
- Optional further reactive situations (attack on ally, tech first, colony founded, threat ignored, gift, spies caught) as hooks become available; negotiation emission is UI-driven via `dialogueEventForNegotiation`.

---

## 5. Tactical (Quick Battle) not state-aware — **IMPLEMENTED**

**Spec:** SPEC/ai/ai-architecture.md — Tactical behavior rules: prefer good terrain (hill, town, woods) with high-value units; avoid fragile units in swamp; use Volley Fire / Defend when outmatched or holding key lanes; use Maneuver / Fall Back to rotate damaged units; use Assault / Charge when enemy lane disrupted and terrain favorable. SPEC/program/ai-systems-impl.md — `decideQuickBattleActions(QuickBattleState, nationId, config, tacticalSeed)` returns CP-based actions per lane; deterministic given state and seed.

**Current:** `decideQuickBattleActions` in `colonizethis_ai/lib/src/tactical_ai.dart` uses `QuickBattleInput` and `nationId` to identify our vs enemy deployment, computes effective strength (mirroring resolver formula with terrain and cohesion), and chooses actions by situation: **damaged** → Maneuver / Fall Back; **enemy disrupted and terrain favorable** → Assault / Charge; **outmatched or holding center** → Volley Fire / Defend; else weighted mix. Deterministic given `tacticalSeed`. Tests cover outmatched, damaged, and assault-favorable cases.

---

## 6. Perception summary incomplete — **IMPLEMENTED**

**Spec:** SPEC/ai/ai-architecture.md — Perception: threats, opportunities, economy, relations from PlayerView only.

**Current:** `AIWorldSnapshot.fromPlayerView(view, topology: topology)` in `perception.dart` computes all fields from PlayerView (and topology when provided).  
- `ThreatSummary`: `atWarWith` from diplomacy; when topology is provided, `neighborProvincesHostile` counts neighbor provinces owned by nations at war, and `capitalThreatened` is true if the player's capital has an adjacent province owned by a nation at war.  
- `OpportunitySummary`: `unclaimedProvinces` counts provinces with no owner; `richUnexploitedProvinces` counts unclaimed plus other-owned provinces with `townDevelopmentLevel > 0`; when topology is provided, `weakNeighbors` lists faction ids that own provinces adjacent to our provinces.  
Tests in `perception_test.dart` cover threats (including neighbor/capital with topology), opportunities (weakNeighbors, richUnexploitedProvinces).

---

## 7. No diplomacy domain planner — **IMPLEMENTED**

**Spec:** SPEC/ai/ai-architecture.md — Domain planning: economy, military, diplomacy, research planners; each emits candidate orders. SPEC/program/ai-systems-impl.md — AI uses suggestion API for all order types; when naval in scope, API exposes naval candidates.

**Current:** `_runDiplomacyPlanner` in `domain_planners.dart` calls `suggestDiplomaticOrders`, then scores each candidate by order type: **offerPeace** → `agendaPeaceAcceptanceModifier` + (peaceTendency − 50); **alliance** → `agendaAllianceAcceptanceModifier` + (allianceTendency − 50); **declareWar** → `agendaConquerModifier` + `agendaTreatyBreakingModifier` + (warLikelihood − 50). Other order types use base score 50. Weighted random choice selects one candidate; only runs when diplomacy/conquer/trade goal or domain weight ≥ 25. Deterministic given seeds.

---

## 8. Hidden agenda modifiers incomplete — **IMPLEMENTED**

**Spec:** SPEC/ai/hidden-agendas.md — Behavior modifiers per agenda: war declaration, peace acceptance, alliance acceptance, build/order choice (e.g. tech_thief: spy/research; envy: mirror human), treaty breaking.

**Current:** `hidden_agenda.dart` implements `agendaConquerModifier`, `agendaDiplomacyModifier`, `agendaResearchModifier` (tech_thief +35), `agendaBuildOrderModifier` (envy +20), **`agendaPeaceAcceptanceModifier`** (peacemaker +30, warmonger -25), **`agendaAllianceAcceptanceModifier`** (isolationist -40, peacemaker +10), **`agendaTreatyBreakingModifier`** (backstabber +25, warmonger +20), and **`agendaSpyOrderModifier`** (tech_thief +25). Domain planners: research and build use existing modifiers; diplomacy planner scores offer peace / alliance / declare war by these modifiers (weighted choice); work planner lowers threshold when spy work (steal_tech, counter_spy) exists and tech_thief prefers spy work. Envy "mirror human" remains build-order tendency boost; full mirroring can use this when visibility exists.

---

## 9. Personality thresholds not implemented — **IMPLEMENTED**

**Spec:** SPEC/ai/ai-personalities.md — Personality also adjusts **thresholds**: War likelihood, Peace tendency, Alliance tendency, Research preference (weights per tech category). "Applied when scoring actions (e.g. declare war, accept peace, choose research slot)."

**Current:** `colonizethis_data` defines `PersonalityThresholds` (warLikelihood, peaceTendency, allianceTendency, researchNaval/Military/Economic/Exploration) and `personalityThresholds` map per leader; `getThresholdsForLeader(leaderId)` returns thresholds or defaults. **Goal manager:** conquer weight is adjusted by (warLikelihood - 50), diplomacy weight by (peaceTendency + allianceTendency)/2 - 50. **Diplomacy planner:** offerPeace/declareWar/alliance order scores are adjusted by the corresponding threshold. **Research planner:** research candidates are weighted by tech category (transport→naval, military→military, gathering→economic, else→exploration) and selected by weighted random. Tests in `ai_personality_config_test.dart`.

---

## 10. Goal selection is weighted random, not behavior tree — **DOCUMENTED**

**Spec:** SPEC/ai/ai-architecture.md — "Behavior trees pick top-level goals"; "Behavior trees pick long-term strategy (expand, defend, trade, conquer, tech, diplomacy)."

**Current:** `goal_manager.dart` implements **weighted random** choice over `StrategicGoal` using personality goal weights, agenda modifiers, and snapshot situational modifiers. No actual behavior tree (nodes, sequences, selectors).

**Spec clarification (ai-architecture.md):** Goal selection may be implemented as **weighted choice** over strategic goals; this satisfies the "behavior tree" requirement when interpreted as hierarchical goal selection. Strict behavior-tree node structure is optional for designer-editable trees.

---

## 11. Order suggestion API has no diplomatic suggestions — **IMPLEMENTED**

**Spec:** SPEC/program/ai-systems-impl.md — "AI calls the suggestion API with PlayerView and current orders"; "When naval is in scope, API also exposes naval candidates."

**Current:** `OrderSuggestionAPI` in `colonizethis_logic` exposes `suggestDiplomaticOrders(PlayerView, Game, MapTopology, Orders)`. `order_suggestion.dart` implements it: returns candidate `DiplomaticOrder`s that are valid and visible (declare war, offer peace, alliance, establish overture, grant aid, set subsidy) using game relations and overture state. `DefaultOrderSuggestionAPI` delegates to it; `domain_planners.dart` calls it for the diplomacy planner. Tests in `order_suggestion_api_impl_test.dart` cover each order type.

---

## 12. War declaration and attack target selection — **IMPLEMENTED** (relation threshold; target-specific scoring; movement filter and prefer)

**Spec:**  
- **SPEC/ai/hidden-agendas.md** — **War declaration:** "Warmonger: **lower relation threshold** to declare war; Peacemaker: strong negative modifier; **Backstabber: bonus if target is ally**." Agenda table: warmonger "**Attacks weaker neighbors**"; backstabber "**Attacks allies when weak**".  
- **SPEC/ai/ai-architecture.md** — **Movement:** "**Prefer** contested or enemy territory (at war); avoid factions at peace."

**Current:**  
- **Relation threshold:** Implemented in `_runDiplomacyPlanner`. Declare-war candidates are scored 0 when relation score > `getDeclareWarMaxRelationScore(agendaId)` (default 50; warmonger 70; peacemaker 30; backstabber 100). Config in `colonizethis_data/hidden_agenda_config.dart`.  
- **Target-specific scoring:** When scoring declare-war, warmonger receives `getDeclareWarTargetBonusWeakerNeighbor` (+30) when target is in `snapshot.opportunities.weakNeighbors`; backstabber receives `getDeclareWarTargetBonusAlly` (+25) when target relation level is allied.  
- **Movement filter:** `filterMoveOrdersByDiplomacy(game, playerId, orders)` in `order_suggestion.dart` drops moves to at-peace or minor-without-war destinations. Used by both simple heuristics and full-AI `_runMovePlanner`.  
- **Movement prefer enemy:** Full-AI move planner scores filtered moves with `kMovePreferEnemyTerritoryBonus` (+20) when destination owner is at war with the mover; weighted random selection prefers enemy territory.

---

## Summary table

| # | Area | Status | Priority |
|---|------|--------|----------|
| 1 | Naval mission orders dropped in full-AI aggregation | Fixed | High |
| 2 | Evidence accumulation | Implemented (diplomacy + combat) | High |
| 3 | Dossier (basic intel, behavioral notes, timeline) | Implemented | Medium |
| 4 | Dialogue and mood | Partial (diplomatic + event battle + era change + mood + reactive forts_on_border + negotiation helper) | Medium |
| 5 | Tactical Quick Battle state-aware | Implemented | Medium |
| 6 | Perception (threats/opportunities) | Implemented | Medium |
| 7 | Diplomacy domain planner + API | Implemented | High |
| 8 | Hidden agenda (tech_thief, envy; peace/alliance/treaty) | Implemented | Medium |
| 9 | Personality thresholds (war/peace/alliance/research) | Implemented | Medium |
| 10 | Goal selection (weighted choice vs behavior tree) | Documented | Low |
| 11 | OrderSuggestionAPI diplomatic | Implemented | High (for #7) |
| 12 | War declaration / attack target (relation threshold; target-specific scoring; movement filter and prefer) | Implemented | Medium |
