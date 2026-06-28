# Diplomacy Resolution

## Responsibility

Resolves diplomatic orders, manages overture state machine, updates relation scores, and feeds AI evidence pipeline during the Diplomacy phase. Game rules: [diplomacy.md](../game/diplomacy.md). Province identity (e.g. in order payloads or state that reference a province) follows [world-model-identity.md](../game/world-model-identity.md).

---

## Data Model

**Relation record** (per faction-pair): score (int 0–100), level (enum: Hostile, Neutral, Friendly, Allied — derived from score per game thresholds), sinceTurn (int), lastInteractionTurn (int), relationState (enum: AT_PEACE, AT_WAR). Stored in world state; serialized in save/load.

**Overture state** (per Minor/Tribe per GP): current stage (none, TradeConsulate, Embassy, NAP, JoinEmpire/Colony). Costs and turn delays per game rules. Stored in world state; serialized in save/load.

**Diplomatic history event** (per Great-Power-centric world log): structured record of notable diplomatic actions and state changes involving at least one Great Power. Stored in world state on `Game` as a **flat, append-only list** and serialized in save/load. Each event includes:

- **turn** (int, same domain as `worldState.turnState.turnNumber`).
- **intraTurnIndex** (int, monotonically increasing for events created in the same turn, to preserve resolution order).
- **participants**: set of faction ids involved in the event (always includes at least one Great Power id).
- **primaryType**: enum describing the main event (e.g. `declareWar`, `peace`, `allianceFormed`, `allianceBroken`, `overtureAccepted`, `overtureRejected`, `joinEmpireResolved`, `grantAidApplied`, `subsidySet`, `subsidyUpdated`, `subsidyCancelled`, `interventionIntervene`, `interventionProtest`, `interventionDoNothing`, `agreementsClearedOnWar`, `callToArmsAccepted`, `callToArmsRefused`).
- **details**: structured payload fields specific to the primaryType (e.g. `fromFactionId`, `toFactionId`, `overtureStage`, `amount`, `reason`, `wasAiInitiator`).

Rendering of human-readable strings (including year labels derived from turn) is delegated to UI layers based on this structured event model.

---

## Algorithm / Flow

Diplomacy phase runs after Production and before Research/Movement. Resolution steps in order:

1. **Process overture offers (two-way)** — For each Establish Overture order (Consulate, Embassy, NAP; Join Empire in step 3): the **target** faction must accept or reject. **Target = Minor/Tribe:** accept/reject is decided by rule at resolution (e.g. Consulate/Embassy/NAP accepted by rule); if accepted, validate treasury, deduct cost, advance stage. **Target = Great Power:** if the target GP is **AI-controlled**, decide accept/reject at resolution (e.g. relation-based) and apply. If the target GP is **human-controlled**, do **not** apply; add this offer to a **pending overture decisions** list and **return** from the phase so that turn resolution suspends. The app prompts the human; when the app resumes with the human’s decision(s), apply each (deduct cost and advance stage if accept, else leave state unchanged) and continue with the rest of the phase.
2. **Advance in-progress overtures** — Apply turn delays; mark completed.
3. **Resolve Join Empire/Colony** — For each valid Join Empire order (target Minor/Tribe, NAP stage, relation score ≥ 51): compute cost = base + (province count × per-province); if GP treasury ≥ cost, deduct cost, transfer all provinces/units/fleets from target to GP, remove target from minorNations or tribes, remove overtures and relations involving the target. After ownership transfer is applied, run a civilian ownership-change legality relocation pass for civilians in the changed provinces only (same legality rule as civilian movement/work tile occupancy); civilians illegal on their standing tile relocate to owner capital tile with normalized idle/cleared-assignment state, and unresolved owner capital tile is a hard error. **Tribe target (Refs #3753 R5):** the Tribe is **not** absorbed — only the Join Empire cost is deducted, a `ColonyState { tribeId, colonyOfGpId, sinceTurn }` is recorded on `Game.colonyStates` (one per Tribe; re-resolution replaces the prior record), the Tribe stays in `tribes`, and its provinces/units/fleets, overtures, and relations are preserved. Minor targets keep full absorption (transfer + removal) as above.
4. **Process alliance proposals** — Apply accept/refuse; update alliance state; apply refusal relation penalties per game rules.
4a. **Process voluntary alliance breaks** — For each `breakAlliance` order whose issuer holds a `formalAlliance = true` with the GP target, clear that pair's alliance flag and apply the **unified alliance-break penalty** (−50 to the broken-with ally, −10 to every other Great Power the breaker has a relation with, excluding the broken-with ally; all clamped 0–100), then append an `allianceBroken` event. Valid at peace or at war; orders without an existing formal alliance are ignored at resolution (validation already rejects them).
5. **Process Declare War and Peace** — Within this step, apply all `declareWar` orders first, then all `offerPeace` orders (so same-turn peace offers are not undone by later declare-war orders in the merged batch). Update relationState, sinceTurn, lastInteractionTurn; cancel subsidies between newly warring pairs as per game rules. GP–GP peace may be mutual or one-sided per survival rules in the resolver (Refs #2509).
5b. **Intervention (GP → Minor/Tribe war)** — For each Great Power at `AT_WAR` with a Minor or Tribe this turn via a resolved `Declare War` order, and another Great Power has an Embassy or purchased land in that Minor/Tribe (see [diplomacy.md](../game/diplomacy.md) § Intervention): resolve AI choices immediately; if any **human** Great Power must choose, suspend the Diplomacy phase and return **pending intervention prompts**. On resume, apply **InterventionDecision** values and continue. Intervention runs only in the Diplomacy phase, not during Combat.
5c. **Call to arms (alliance mutual defence)** — After step 5 and 5b, for each aggressor–defender GP pair at war due to a declare-war order this phase, process each other GP that holds a **formal alliance** with the defender (the `formalAlliance` flag on the GP–defender relation) **at the end of the preceding turn** and is at peace with the defender: AI resolves join/refuse per score threshold; human-controlled allies add to **pending call to arms** until **resumeTurnResolutionWithCallToArmsDecisions** supplies decisions. Eligibility uses a snapshot of formally-allied pairs captured at the **start of the Diplomacy phase**, before step 4 (`processAlliances`) resolves this turn's `Alliance` orders, so an alliance formed the same turn does not grant mutual defence. The informal `RelationLevel.allied` band alone does **not** trigger call to arms. On **refuse**, the formal alliance flag is cleared, the **unified alliance-break penalty** is applied (−50 to the defended ally and −10 to every other Great Power the refuser has a relation with, excluding both the defended ally and the aggressor; all clamped 0–100), and an `allianceBroken` event is appended in addition to `callToArmsRefused`. Through turn `kDeclareWarEarlyAntiDogpileMaxTurn`, AI allies **refuse** call to arms when the **aggressor** GP is below the observer Old World conquest quota (`kObserverConquestMinOwProvincesPerGp` in `ai_victory_config.dart`) so allies do not pile onto a below-quota counter-attack victim (observer seed-42; Refs #2509). See [diplomacy.md](../game/diplomacy.md) § Alliances.
6. **Terminate agreements on war** — Clear overtures between warring pairs; further steps per implementation (subsidies, grants, decay) follow the live resolver order in `diplomacy_resolver.dart`.
7. **Apply relation modifiers** — From trade, grants (GrantAid), subsidies (SetSubsidy), war, broken treaties per game rules. SetSubsidy: valid if an **Embassy** exists (Refs #3753 R2 — Consulate alone is insufficient); deducts payer treasury; if target is GP adds to target treasury, else (Minor/Tribe) improves relation.
8. **Apply per-turn relation decay (final step)** — After all relation-modifier events for the turn have resolved, every non-`AT_WAR` pair that received **no** relation-score delta event this turn drifts **±4.0 toward equilibrium 50**, clamped so it never crosses 50 (`relationDecayPerTurn = 4.0`); pairs modified by any event this turn (including pairs created this turn) are **skipped** (skip-on-event, no double-application), and `AT_WAR` pairs keep frozen scores. Decay is detected against a snapshot of each pair's score captured at the **start of the Diplomacy phase**. Scores clamp 0–100; the relation level is recomputed. See [diplomacy.md](../game/diplomacy.md) § Relation Model — Per-turn relation decay (Refs #3753 R9.3/R9.4).

At the same hook points where relation state, overtures, or economic diplomacy are mutated, the resolver **appends one or more Diplomatic history events** to the flat world log:

- When an overture is **accepted or rejected** and reaches a new stage (including Join Empire/Colony), an event with primaryType `overtureAccepted` or `overtureRejected` is appended.
- When **war** is successfully declared (relationState flips to AT_WAR), an event with primaryType `declareWar` is appended, and any overture/subsidy cancellations caused by that war append `agreementsClearedOnWar` / `subsidyCancelled` events.
- When **peace** takes effect between a pair (GP–GP mutual offer, or GP–Minor/Tribe), an event with primaryType `peace` is appended.
- When an **alliance** is formed or broken, events with primaryType `allianceFormed` / `allianceBroken` are appended.
- When **GrantAid** is applied, an event with primaryType `grantAidApplied` is appended.
- When a **subsidy** is created, updated, or cancelled (including automatic cancellation on war or insufficient funds), events with primaryType `subsidySet`, `subsidyUpdated`, or `subsidyCancelled` are appended.
- When an **Intervention** decision is applied (Intervene, Do Nothing, Protest), events with primaryType `interventionIntervene`, `interventionDoNothing`, or `interventionProtest` are appended.
- When **call to arms** is resolved (join or refuse), events with primaryType `callToArmsAccepted` or `callToArmsRefused` are appended.

**Order validation:** Each diplomatic order type (see game/diplomacy.md § Diplomatic Order Types) is validated by the order engine — preconditions (AT_PEACE/AT_WAR, overture stage, treasury, tech) checked at submission and again at resolution. **Establish Overture** toward a **Minor Nation or Tribe** at stages Trade Consulate, Embassy, or Non-Aggression Pact requires the offering Great Power to have **`diplomatic_expertise`** in `techUnlocked` (see [tech-tree-diplomacy-civilian.md](../game/tech-tree-diplomacy-civilian.md), game/diplomacy.md § GP–Minor). The diplomacy resolver skips applying such orders when the tech is missing (defense in depth). **Join Empire** toward another **Great Power** requires the offerer to have **`empire_building`** and the target to be **nearly defeated** (game/diplomacy.md: at most three provinces owned by the target and the target does not own its original capital province). Establish Overture may target Minor, Tribe, or Great Power. At most one Establish Overture per (player, target faction) per turn; a second such order for the same target is rejected at validation (see game/diplomacy.md, program/orders.md).

**Blocking:** When an overture targets a human-controlled GP, the diplomacy phase returns **pending overture offers** (offerer, target, stage) and turn resolution returns **TurnResolutionPendingOvertures**; the app calls **resumeTurnResolutionWithOvertureDecisions**. When intervention requires human input, the phase returns **pending intervention prompts** (aggressor GP, defender Minor/Tribe, intervening GP) and turn resolution returns **TurnResolutionPendingIntervention**; the app calls **resumeTurnResolutionWithInterventionDecisions**. When **call to arms** requires a human ally’s choice, the phase returns **pending call to arms**; the app calls **resumeTurnResolutionWithCallToArmsDecisions** with **CallToArmsDecision** entries. The resolver continues the Diplomacy phase (re-entering from the start with supplied decisions where applicable) and runs remaining phases.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Diplomacy (after Production; before Research and Movement) |
| Upstream | Player orders, world state (relations, overtures, treasury) |
| Downstream | Relation state → combat/movement validation; AI evidence/dossier pipeline |

**Economy:** GrantAid and SetSubsidy deduct payer treasury; SetSubsidy transfers to target GP or improves relation with Minor/Tribe. **`tradeSlotsForGp`** returns commodity capacity for trade agreements: **0** without embassy toward the target, **3** with embassy (baseline), **6** with embassy when the ordering GP has **`trade_fairs`** unlocked. War terminates trade agreements with target. See [tech-tree-labour-economy.md](../game/tech-tree-labour-economy.md) § trade_fairs.

**Combat/movement:** Before military move into a foreign province or naval **Blockade** against a province owner, require `AT_WAR` or same-turn `Declare War` on that owner (Great Power, Minor, or Tribe). Enforced by order validation and turn resolver. **Intervention** is evaluated only in the Diplomacy phase (step 5b), not during Combat; it may set `AT_WAR` between an intervening GP and the declaring GP before Movement.

**AI:** Diplomatic actions feed into AI evidence and dialogue event pipelines for hidden-agenda discovery. See [ai-events-and-dossier.md](ai-events-and-dossier.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).

---

## Logging

Per [ctdev-logging.md](ctdev-logging.md): diplomacy is in **logic** scope. Phase start/end are logged by the turn resolver (`logic: phase diplomacy start` / `logic: phase diplomacy end`). The diplomacy resolver logs **key outcomes** with the `logic:` prefix so that flows and state changes are grep-friendly:

- **Phase boundaries:** Diplomacy resolver logs phase start and end at debug (redundant with turn resolver but allows filtering by file).
- **Key outcomes (info):** Overture payment applied (gpId, targetId, stage); Join Empire/Colony applied; alliance formed (faction pair); war declared (faction pair); peace offered (faction pair); agreements terminated due to war; GrantAid/SetSubsidy applied when modifier changes relation or treasury.

Rejections and validation failures are logged by the order engine; diplomacy resolution logs only applied state changes.

---

## Acceptance criteria

- **Phase order:** Diplomacy phase runs after Production and before Research/Movement; resolution steps 1–8 run in the specified order (overture payments → advance overtures → Join Empire/Colony → alliances → **voluntary alliance breaks (4a)** → war/peace → **intervention (5b)** → **call to arms (5c)** → terminate agreements on war → relation modifiers and score update).
- **Upstream orders:** The diplomacy phase receives merged orders that include `diplomaticOrdersByPlayerId`; the turn resolver supplies the output of the order engine (see [order-engine.md](order-engine.md), [turn-resolution-phases.md](turn-resolution-phases.md)). The order engine must preserve diplomatic orders and pass them into the diplomacy phase input.
- **Overture two-way:** Each Establish Overture is considered by the **target** at resolution. For Minor/Tribe targets, accept/reject is applied by rule (e.g. accept Consulate/Embassy/NAP); only when accepted are cost deducted and stage advanced. For GP targets: if AI, decision at resolution and apply; if human, phase returns pending and turn resolution blocks until app supplies decisions and resumes.
- **Overture payments:** When the target **accepts** (by rule or decision): Consulate/Embassy orders deduct cost and advance stage; NAP is free. Join Empire has a separate cost (base + per-province); see step 3.
- **Join Empire/Colony:** Requires NAP stage, relation score ≥ 51 (Friendly/Allied), and treasury ≥ cost. Cost = base + (province count × per-province); see game/diplomacy.md § Configurable Values. **Minor target — absorption:** on success, cost deducted from GP treasury; all provinces, units, and fleets owned by the target transfer to the GP; target removed from minorNations; overture state and diplomacy relations involving the target removed. **Tribe target — colony (Refs #3753 R5):** on success, only the cost is deducted; a `ColonyState { tribeId, colonyOfGpId, sinceTurn }` is recorded on `Game.colonyStates` (one per Tribe, replacing any prior record); the Tribe **stays** in `tribes` with its provinces/units/fleets, overtures, and relations intact.
- **Ownership-change civilian legality pass:** Whenever Join Empire/Colony changes province ownership, the resolver evaluates civilians in changed provinces only using the same occupancy legality rule as civilian movement/work (`civilianMayOccupyLandTileKey`). Civilians illegal on their standing tile are relocated to owner capital tile and normalized to idle with cleared work/assignment tracking; legal civilians are left in place. If a required relocation cannot resolve owner capital tile, diplomacy resolution throws a hard error.
- **Alliances:** GP–GP only; relation set to allied (score ≥ 76), state atPeace.
- **War and peace:** Declare War / Offer Peace update relationState, sinceTurn, lastInteractionTurn and scores per game rules; evidence and dialogue events emitted when applicable. Intervention-driven war state changes (from human or AI intervention decisions) update relationState, sinceTurn, and lastInteractionTurn during the Diplomacy phase (step 5b) so that Movement and Combat validation in the same turn use the updated state.
- **Agreements on war:** Overtures between a faction pair at war are terminated. When relationState changes from `AT_PEACE` to `AT_WAR` between a GP and a Minor/Tribe, any overture state between that GP and that Minor/Tribe is removed so that the effective overture stage is `none`, and later peace between them does not restore the previous overture stage automatically. **GP–GP exception (Refs #3753 R1):** when two Great Powers enter `AT_WAR`, `embassy`-tier overtures between them are **preserved**; `nap` and `joinEmpire` stages are downgraded to `embassy` and emit `agreementsClearedOnWar` for the cleared treaty tier; stages below `embassy` are removed. When a GP (human or AI) chooses **Do Nothing** in response to an intervention trigger for a Minor it has an Embassy with, the overture state between that GP and that Minor is also cleared to `none` even if relationState remains `AT_PEACE`.
- **GrantAid / SetSubsidy:** GrantAid requires Embassy; SetSubsidy requires Consulate or Embassy. Payer treasury deducted; SetSubsidy to GP adds to target treasury, to Minor/Tribe improves relation modifier.
- **Order validation:** Preconditions for each diplomatic order type (AT_PEACE/AT_WAR, overture stage, treasury, etc.) are checked at order submission by the order engine and again at resolution; invalid orders are rejected and not applied. In particular, when relationState between a GP and a Minor/Tribe is `AT_WAR`, `Establish Overture` orders targeting that faction are invalid and must not create or advance overture state or deduct overture costs. See game/diplomacy.md § Diplomatic Order Types.
- **Save/load:** Relation records (per faction-pair) and overture state (per Minor/Tribe per GP) are serialized in the game save and restored on load so that relation scores, levels, sinceTurn, lastInteractionTurn, relationState, and overture stages are preserved.
- **Logging:** Phase start and end at debug with `logic:` prefix; key outcomes at info (overture applied, join empire, alliance formed, war declared, peace offered, agreements terminated, GrantAid/SetSubsidy applied). Rejections and validation failures are logged by the order engine only.

- **Diplomatic history events — creation:** Given the Diplomacy phase resolves an action that changes diplomatic state or applies economic diplomacy (war/peace, alliance formed/broken, overture accepted/rejected including Join Empire/Colony, GrantAid applied, subsidy set/updated/cancelled, intervention decisions, overtures cleared on war), when that change is applied to `Game`, then the resolver appends at least one `DiplomaticEvent` to the flat diplomatic history list on `Game` with:
  - `turn` equal to the current turn index;
  - `participants` including all factions directly affected by the change (at least one Great Power);
  - `primaryType` matching the kind of change (e.g. `declareWar` when relationState flips to AT_WAR).
- **Diplomatic history events — ordering:** Given the resolver appends multiple diplomatic history events during a single turn, when the turn completes and the game is saved, then all `DiplomaticEvent` entries for that turn have strictly increasing `intraTurnIndex` values that preserve the order in which the underlying changes were applied.
- **Diplomatic history events — save/load:** Given a Game whose diplomatic history list contains one or more `DiplomaticEvent` entries, when the system saves and reloads that Game, then the reloaded Game contains the same diplomatic history entries with identical `turn`, `intraTurnIndex`, `participants`, `primaryType`, and `details` values.

---

## Config source (current product)

Relation thresholds (score-to-level bands), overture costs (Consulate £500, Embassy £1000), and Join Empire cost (base £5000, per-province £2000) are currently **code constants** in the diplomacy resolver (`colonizethis_logic`: `overtureConsulateCost`, `overtureEmbassyCost`, `joinEmpireBaseCost`, `joinEmpirePerProvinceCost`, `scoreToLevel`). The **default values** are defined in [diplomacy.md](../game/diplomacy.md) § Configurable Values; that table is the source of truth for design. Ruleset loading for these parameters is **not implemented** in current product. When ruleset-driven config is added, the resolver will read from the resolved ruleset per [ruleset-config.md](ruleset-config.md) and the key path will be specified in the GDD and here.

**Propaganda tech:** When the **aggressor** Great Power in an **intervention** flow has **`propaganda`** unlocked, **Diplomatic Protest** applies a **reduced** relation penalty (**5** points instead of **10**) between the protesting GP and the aggressor. See [tech-tree-diplomacy-civilian.md](../game/tech-tree-diplomacy-civilian.md) and `warDeclarationThirdPartyPenaltyDelta` in diplomacy relation lookup.

---

## Constraints

- All diplomatic rules (relation thresholds, overture chain, order preconditions) are defined in game/diplomacy.md; this module references, not restates, them.
- Resolution order is strict (steps 1–8); reordering may break precondition checks.
- Overture stage transitions are linear; no stage may be skipped.
- Any province id used in diplomacy state or in diplomatic order payloads must be in prefixed form and resolved per [world-model-identity.md](../game/world-model-identity.md).
