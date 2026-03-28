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

Rendering of human-readable strings (including year labels derived from turn) is delegated to UI/TUI layers based on this structured event model.

---

## Algorithm / Flow

Diplomacy phase runs before Movement. Resolution steps in order:

1. **Process overture offers (two-way)** — For each Establish Overture order (Consulate, Embassy, NAP; Join Empire in step 3): the **target** faction must accept or reject. **Target = Minor/Tribe:** accept/reject is decided by rule at resolution (e.g. Consulate/Embassy/NAP accepted by rule); if accepted, validate treasury, deduct cost, advance stage. **Target = Great Power:** if the target GP is **AI-controlled**, decide accept/reject at resolution (e.g. relation-based) and apply. If the target GP is **human-controlled**, do **not** apply; add this offer to a **pending overture decisions** list and **return** from the phase so that turn resolution suspends. The app prompts the human; when the app resumes with the human’s decision(s), apply each (deduct cost and advance stage if accept, else leave state unchanged) and continue with the rest of the phase.
2. **Advance in-progress overtures** — Apply turn delays; mark completed.
3. **Resolve Join Empire/Colony** — For each valid Join Empire order (target Minor/Tribe, NAP stage, relation score ≥ 51): compute cost = base + (province count × per-province); if GP treasury ≥ cost, deduct cost, transfer all provinces/units/fleets from target to GP, remove target from minorNations or tribes, remove overtures and relations involving the target. Tribe absorption uses the same cost and transfer rules as Minor (colony semantics deferred).
4. **Process alliance proposals** — Apply accept/refuse; update alliance state; apply refusal relation penalties per game rules.
5. **Process Declare War and Peace** — Update relationState, sinceTurn, lastInteractionTurn; cancel subsidies between newly warring pairs as per game rules.
5b. **Call to arms (alliance mutual defence)** — After GP–GP wars from step 5 are applied, for each aggressor–defender GP pair at war due to a declare-war order this phase, process each other GP allied (`RelationLevel.allied`, at peace) with the defender: AI resolves join/refuse per score threshold; human-controlled allies add to **pending call to arms** and suspend the phase until **resumeTurnResolutionWithCallToArmsDecisions** supplies decisions. See [diplomacy.md](../game/diplomacy.md) § Alliances.
6. **Terminate agreements on war** — Clear overtures between warring pairs; further steps per implementation (subsidies, convergence, grants) follow the live resolver order in `diplomacy_resolver.dart`.
7. **Apply relation modifiers** — From trade, grants (GrantAid), subsidies (SetSubsidy), war, broken treaties per game rules. SetSubsidy: valid if consulate/embassy exists; deducts payer treasury; if target is GP adds to target treasury, else (Minor/Tribe) improves relation.
8. **Update relation scores** — Convergence and score derivation per implementation; clamp 0–100; derive level.

At the same hook points where relation state, overtures, or economic diplomacy are mutated, the resolver **appends one or more Diplomatic history events** to the flat world log:

- When an overture is **accepted or rejected** and reaches a new stage (including Join Empire/Colony), an event with primaryType `overtureAccepted` or `overtureRejected` is appended.
- When **war** is successfully declared (relationState flips to AT_WAR), an event with primaryType `declareWar` is appended, and any overture/subsidy cancellations caused by that war append `agreementsClearedOnWar` / `subsidyCancelled` events.
- When **peace** takes effect between a pair (GP–GP mutual offer, or GP–Minor/Tribe), an event with primaryType `peace` is appended.
- When an **alliance** is formed or broken, events with primaryType `allianceFormed` / `allianceBroken` are appended.
- When **GrantAid** is applied, an event with primaryType `grantAidApplied` is appended.
- When a **subsidy** is created, updated, or cancelled (including automatic cancellation on war or insufficient funds), events with primaryType `subsidySet`, `subsidyUpdated`, or `subsidyCancelled` are appended.
- When an **Intervention** decision is applied (Intervene, Do Nothing, Protest), events with primaryType `interventionIntervene`, `interventionDoNothing`, or `interventionProtest` are appended.
- When **call to arms** is resolved (join or refuse), events with primaryType `callToArmsAccepted` or `callToArmsRefused` are appended.

**Order validation:** Each diplomatic order type (see game/diplomacy.md § Diplomatic Order Types) is validated by the order engine — preconditions (AT_PEACE/AT_WAR, overture stage, treasury) checked at submission and again at resolution. Establish Overture may target Minor, Tribe, or Great Power. At most one Establish Overture per (player, target faction) per turn; a second such order for the same target is rejected at validation (see game/diplomacy.md, program/orders.md).

**Blocking:** When an overture targets a human-controlled GP, the diplomacy phase returns a **DiplomacyPhaseResult** that includes the updated game state and a non-empty list of **pending overture offers** (offerer, target, stage). Turn resolution returns a **TurnResolutionResult** indicating pending human input. The app presents the offer(s) to the human target(s), collects accept/reject, and calls the **resume** API with the corresponding **overture decisions**. When **call to arms** requires a human ally’s choice, the phase returns **pending call to arms** (ally, defender, aggressor); the app calls **resumeTurnResolutionWithCallToArmsDecisions** with **CallToArmsDecision** entries. The resolver then applies those decisions and continues the Diplomacy phase and remaining phases.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Diplomacy (before Movement) |
| Upstream | Player orders, world state (relations, overtures, treasury) |
| Downstream | Relation state → combat/movement validation; AI evidence/dossier pipeline |

**Economy:** GrantAid and SetSubsidy deduct payer treasury; SetSubsidy transfers to target GP or improves relation with Minor/Tribe. Trade agreement slots gated by embassy level. War terminates trade agreements with target.

**Combat/movement:** Before move or attack, check AT_WAR for Minors; for Tribes, check only if province has another GP's investment. Enforced by order engine and turn resolver. Intervention choices for Minors with Embassies or GP **investment** (purchased land in that Minor’s provinces) and for Tribes with GP investment are evaluated during combat resolution, and may change relationState to `AT_WAR` between additional faction pairs (e.g., an intervening GP and each attacking GP) immediately before battle odds are computed.

**AI:** Diplomatic actions feed into AI evidence and dialogue event pipelines for hidden-agenda discovery. See [ai-events-and-dossier.md](ai-events-and-dossier.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).

---

## Logging

Per [ctdev-logging.md](ctdev-logging.md): diplomacy is in **logic** scope. Phase start/end are logged by the turn resolver (`logic: phase diplomacy start` / `logic: phase diplomacy end`). The diplomacy resolver logs **key outcomes** with the `logic:` prefix so that flows and state changes are grep-friendly:

- **Phase boundaries:** Diplomacy resolver logs phase start and end at debug (redundant with turn resolver but allows filtering by file).
- **Key outcomes (info):** Overture payment applied (gpId, targetId, stage); Join Empire/Colony applied; alliance formed (faction pair); war declared (faction pair); peace offered (faction pair); agreements terminated due to war; GrantAid/SetSubsidy applied when modifier changes relation or treasury.

Rejections and validation failures are logged by the order engine; diplomacy resolution logs only applied state changes.

---

## Acceptance criteria

- **Phase order:** Diplomacy phase runs before Movement; resolution steps 1–7 run in the specified order (overture payments → advance overtures → Join Empire/Colony → alliances → war/peace → terminate agreements on war → relation modifiers and score update).
- **Upstream orders:** The diplomacy phase receives merged orders that include `diplomaticOrdersByPlayerId`; the turn resolver supplies the output of the order engine (see [order-engine.md](order-engine.md), [turn-resolution-phases.md](turn-resolution-phases.md)). The order engine must preserve diplomatic orders and pass them into the diplomacy phase input.
- **Overture two-way:** Each Establish Overture is considered by the **target** at resolution. For Minor/Tribe targets, accept/reject is applied by rule (e.g. accept Consulate/Embassy/NAP); only when accepted are cost deducted and stage advanced. For GP targets: if AI, decision at resolution and apply; if human, phase returns pending and turn resolution blocks until app supplies decisions and resumes.
- **Overture payments:** When the target **accepts** (by rule or decision): Consulate/Embassy orders deduct cost and advance stage; NAP is free. Join Empire has a separate cost (base + per-province); see step 3.
- **Join Empire/Colony:** Requires NAP stage, relation score ≥ 51 (Friendly/Allied), and treasury ≥ cost. Cost = base + (province count × per-province); see game/diplomacy.md § Configurable Values. On success: cost deducted from GP treasury; all provinces, units, and fleets owned by the target transfer to the GP; target is removed from minorNations or tribes; overture state and diplomacy relations involving the target are removed.
- **Alliances:** GP–GP only; relation set to allied (score ≥ 76), state atPeace.
- **War and peace:** Declare War / Offer Peace update relationState, sinceTurn, lastInteractionTurn and scores per game rules; evidence and dialogue events emitted when applicable. Intervention-driven war state changes (from human or AI intervention decisions) also update relationState, sinceTurn, and lastInteractionTurn outside the Diplomacy phase so that combat validation uses the updated state for the current battle.
- **Agreements on war:** Overtures between a faction pair at war are terminated. When relationState changes from `AT_PEACE` to `AT_WAR` between a GP and a Minor/Tribe, any overture state between that GP and that Minor/Tribe is removed so that the effective overture stage is `none`, and later peace between them does not restore the previous overture stage automatically. When a GP (human or AI) chooses **Do Nothing** in response to an intervention trigger for a Minor it has an Embassy with, the overture state between that GP and that Minor is also cleared to `none` even if relationState remains `AT_PEACE`.
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

## Config source (MVP)

Relation thresholds (score-to-level bands), overture costs (Consulate £500, Embassy £1000), and Join Empire cost (base £5000, per-province £2000) are currently **code constants** in the diplomacy resolver (`colonizethis_logic`: `overtureConsulateCost`, `overtureEmbassyCost`, `joinEmpireBaseCost`, `joinEmpirePerProvinceCost`, `scoreToLevel`). The **default values** are defined in [diplomacy.md](../game/diplomacy.md) § Configurable Values; that table is the source of truth for design. Ruleset loading for these parameters is **not implemented** in MVP. When ruleset-driven config is added, the resolver will read from the resolved ruleset per [ruleset-config.md](ruleset-config.md) and the key path will be specified in the GDD and here.

**Propaganda tech:** The effect "Decreases diplomatic penalties for declaring war" (Propaganda tech per [tech-tree-diplomacy-civilian.md](../game/tech-tree-diplomacy-civilian.md)) is **not implemented** in MVP. When implemented, it would apply in step 6 (Apply relation modifiers) or in a war-declaration-specific modifier.

---

## Constraints

- All diplomatic rules (relation thresholds, overture chain, order preconditions) are defined in game/diplomacy.md; this module references, not restates, them.
- Resolution order is strict (steps 1–7); reordering may break precondition checks.
- Overture stage transitions are linear; no stage may be skipped.
- Any province id used in diplomacy state or in diplomatic order payloads must be in prefixed form and resolved per [world-model-identity.md](../game/world-model-identity.md).
