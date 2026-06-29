# Diplomacy

## Overview

Full diplomacy system: war/peace, alliances, overture chain for Minors/Tribes, relations, Join Empire/Colony, intervention, and foreign aid. Derived from GDD 07 and Imperialism II. Province identity (e.g. order targets, overture/province context, “in that province”): [world-model-identity.md](world-model-identity.md).

---

## Rules

### Relation Model

Per faction-pair: **relation state** (AT_PEACE | AT_WAR), **relation score** (0–100), **relation level** (Hostile 0–25, Neutral 26–50, Friendly 51–75, Allied 76–100), **formal alliance** flag, **sinceTurn**, **lastInteractionTurn**. Initial: all GP–GP at peace, score 50, formal alliance false. Updated by grants, trade, war, broken treaties.

The **relation score** is a **decimal** value (fixed-point, 0.1 precision; represented as a `num`/`double`) in the inclusive range `[0.0, 100.0]`. Whole-number scores represent ordinary integer-valued relations; fractional values arise from decimal deltas (per-turn decay and additive-scaled trade-deal boosts). All **threshold comparisons** (level bands, Join Empire ≥ 51, Alliance ≥ 76, FTP, intervention probability, war-desire) operate on the **raw decimal value** with no intermediate rounding. **Save/load** round-trips the decimal. **Legacy saves** that stored an integer score are migrated on load by multiplying by `1.0` (an old score of `50` loads as `50.0`); no other field changes.

**Per-turn relation decay (Refs #3753 R9.3/R9.4):** At the **end of the Diplomacy phase** (after all relation-modifier events for the turn have resolved), every faction-pair relation that is **not** `AT_WAR` drifts **±4.0 toward the equilibrium 50** — a score below 50 increases by `4.0`, a score above 50 decreases by `4.0`, and the step is **clamped to 50** when it would otherwise cross (for example `48.0 → 50.0`, `52.0 → 50.0`). A score already at `50.0` is unchanged. **Skip-on-event:** when **any** relation-score delta event applied to that pair the **same turn** — trade-deal boost, land purchase, grant aid, war declaration, peace, alliance form/break, call-to-arms refusal, or an intervention decision (intervene/protest/doNothing) — decay is **skipped** for that pair that turn (event deltas only; no double-application). A relation **created** this turn (first contact, a newly established overture, an alliance clamp) is treated as event-modified and does **not** decay on its creation turn. `AT_WAR` pairs keep their score **frozen** at the war-declaration value and never decay. The decay magnitude is the code constant `relationDecayPerTurn = 4.0`.

- Given a non-`AT_WAR` faction-pair relation with score `40.0` that received no relation-score delta event this turn, when the Diplomacy phase ends, then the system sets the pair's score to `44.0` (`+4.0` toward 50).
- Given a non-`AT_WAR` faction-pair relation with score `80.0` that received no relation-score delta event this turn, when the Diplomacy phase ends, then the system sets the pair's score to `76.0` (`−4.0` toward 50).
- Given a non-`AT_WAR` faction-pair relation with score `48.0` that received no relation-score delta event this turn, when the Diplomacy phase ends, then the system sets the pair's score to `50.0` (clamped — the step does not cross 50).
- Given a non-`AT_WAR` faction-pair relation with score `52.0` that received no relation-score delta event this turn, when the Diplomacy phase ends, then the system sets the pair's score to `50.0` (clamped).
- Given a non-`AT_WAR` faction-pair relation with score `50.0` that received no relation-score delta event this turn, when the Diplomacy phase ends, then the system leaves the pair's score at `50.0` (no change at equilibrium).
- Given a faction-pair that received a relation-score delta event this turn (for example a Grant Aid applied to that pair), when the Diplomacy phase ends, then the system does **not** apply decay to that pair (skip-on-event; only the event delta is reflected).
- Given an `AT_WAR` faction-pair relation with score `30.0`, when the Diplomacy phase ends, then the system leaves the pair's score at `30.0` (war scores are frozen and never decay).

**Trade-deal relation boost (Refs #3753 R10):** A faction pair that completed **at least one** world-market trade deal involving **at least one Great Power** is boosted in the **next** turn's Diplomacy phase, **before** decay (so the boosted pair is event-modified and skips that turn's decay). The boost is **volume-independent** and applied **once per pair per turn**: **`+2.0`** base, plus **`+0.4`** when an **Embassy** is in effect between the parties (code constants `tradeDealRelationBoostBase`, `tradeDealRelationBoostEmbassyBonus`). The score clamps to `[0.0, 100.0]`. `AT_WAR` pairs are skipped (war scores frozen). The deals are recorded by the World Market phase (`SPEC/program/world-market-resolution.md` § Step F) and consumed by the following Diplomacy phase, so the boost applies one turn after settlement. The subsidy-percentage modifier (R10 `+0.2` per subsidy point) is added when percentage subsidies (R3) land; current behaviour applies the base and Embassy terms only.

- Given a non-`AT_WAR` pair at score `50.0` with no Embassy that completed a Great-Power trade deal the previous turn, when the Diplomacy phase resolves, then the system sets the pair's score to `52.0` and does not also apply decay to that pair this turn.
- Given a non-`AT_WAR` pair at score `50.0` with an Embassy in effect that completed a Great-Power trade deal the previous turn, when the Diplomacy phase resolves, then the system sets the pair's score to `52.4` (`+2.0` base `+0.4` Embassy).
- Given a non-`AT_WAR` pair at score `99.0` that completed a Great-Power trade deal the previous turn, when the Diplomacy phase resolves, then the system clamps the boosted score to `100.0`.
- Given a pair that completed **no** Great-Power trade deal the previous turn, when the Diplomacy phase resolves, then the system applies **no** trade-deal boost to that pair.
- Given an `AT_WAR` pair that completed a trade deal the previous turn, when the Diplomacy phase resolves, then the system applies **no** trade-deal boost (war scores frozen).

The **formal alliance** flag is a **persisted treaty state**, distinct from the informal relation **level** `Allied` (score band 76–100). A formal alliance is created **only** when an `Alliance` diplomatic order resolves (`allianceFormed`) and is cleared on `allianceBroken` (e.g. a Call to Arms refusal). The informal `Allied` level (high relation score) does **not** by itself constitute a formal alliance and must **not** grant mutual-defence obligations. Old saves without the flag default to **formal alliance false**.

While relationState is `AT_WAR` between a Great Power and any other faction, **no new overtures may be established** between that pair. Any existing overtures between that pair are **terminated when war begins** and are **not restored automatically** by later peace; the GP must rebuild the overture chain from `none` after peace — **except** the GP–GP **auto-embassy** seeded at game start (see § GP–GP Rules), which survives war and peace.

### War required for hostile actions

- **Land invasion:** A Great Power must be at `AT_WAR` with the **owner** of a foreign province (Great Power, Minor Nation, or Tribe) before a **military** move order may enter that province as an attack, or the same turn must include a valid `Declare War` diplomatic order against that owner. Order validation and movement resolution enforce this uniformly for all owner types.
- **Naval blockade:** A fleet on **Blockade** mission against a port province is a hostile act; the blockading GP must be at `AT_WAR` with the **owner** of that province (same rule as land: existing war or same-turn declaration). See [capital-and-connectivity.md](capital-and-connectivity.md) § Blockade. Other orders (e.g. espionage, trade, civilian exploration) are not defined as hostile by this rule unless specified elsewhere.

### GP–GP Rules

- **Auto-embassy at game start (Refs #3753 R1):** Every unordered Great Power pair is seeded at `OvertureStage.embassy` with `sinceTurn = 0` in **both** directions (`gpA → gpB` and `gpB → gpA`). Auto-establishment costs **no** treasury. The auto-embassy is **never revoked**, including when the pair enters `AT_WAR` or returns to peace. **NAP** and **Join Empire** stages between warring GPs are still cleared on war (downgraded to `embassy` when the pair was at NAP or Join Empire) and must be rebuilt after peace if desired. **Diplomatic Expertise** does **not** gate GP→GP Embassy.
- **Overture chain (GP→GP):** Same four-stage chain as GP→Minor/Tribe: Trade Consulate → Embassy → Non-Aggression Pact → Join Empire. Each stage is a separate **Establish Overture** order; the target GP accepts or rejects at turn resolution. **Diplomatic Expertise** tech gates Embassy (and foreign civilian work) for **Minor/Tribe** targets only — GP→GP Embassy is **not** expertise-gated in current product (`establish_overture_validator.dart`). Grant Aid / Set Subsidy on GP rows require embassy-tier overture (`hasEmbassy`), same as Minors/Tribes.
- **Declare War:** Requires AT_PEACE. Sets AT_WAR; takes effect before Movement in same turn.
- **Peace (white peace):** Both sides must agree. Sets AT_PEACE; no border or ownership changes.
- **Alliances:** Offer/accept between GPs. A successful `Alliance` order sets the pair's **formal alliance** flag (treaty), clamps score into the Allied band, and records `allianceFormed`. **Mutual defence (call to arms):** When a Great Power **declares war** on another Great Power (same Diplomacy phase resolution as declare war—including any path that applies GP–GP war before Movement, e.g. naval context is still a declared GP–GP war), each other Great Power that holds a **formal alliance** with the **declared-upon** GP **at the end of the preceding turn** (i.e. before this turn's `Alliance` orders resolve) and is **at peace** (`AT_PEACE`) with that GP receives exactly **one** call to arms per aggressor–defender pair for that turn. The informal `RelationLevel.allied` band **alone** does **not** trigger call to arms; a formal alliance is required. An alliance **formed the same turn** as the war declaration does **not** grant mutual defence for that turn. **AI** allies **join** the war (enter `AT_WAR` with the aggressor) if their relation score with the defended ally is **≥ 50**; otherwise they **refuse**. **Human** allies: turn resolution **suspends** until the player chooses join or refuse (app UI; same blocking pattern as human overture target). **Join:** ally enters `AT_WAR` with the aggressor; subsidies between those two are cancelled like a normal war. **Refuse:** the **formal alliance is cleared** (`allianceBroken` recorded) and the **unified alliance-break penalty** (see **Breaking an alliance** below) is applied — the refuser's relation with the defended ally drops by **50** and its relation with **every other Great Power it has a relation with** drops by **10**, except the **aggressor** that triggered this call to arms (whose relation is governed by the war rules, not the alliance break). All drops clamp 0–100. **Subsidies are not** cancelled by this refusal. History records `callToArmsAccepted` / `callToArmsRefused` (and `allianceBroken` on refuse). Joining an ally's **offensive** war separately remains optional with no penalty; this rule is only for **defence** of an allied GP that was declared upon.
- **Breaking an alliance (voluntary or by refusal):** A Great Power may end a **formal alliance** either voluntarily via a **Break Alliance** diplomatic order or implicitly by **refusing a call to arms**. Both paths apply the same **unified penalty**: the breaker's relation with the **broken-with ally** drops by **50** and its `formalAlliance` flag for that pair is cleared; the breaker's relation with **every other Great Power for which it holds a relation at the moment the break resolves** drops by **10** (the broken-with ally is excluded from the −10 cascade; for the call-to-arms-refusal path the aggressor is also excluded). All score changes clamp 0–100 and the relation level is recomputed. An `allianceBroken` event is recorded for the broken pair (the refusal path additionally records `callToArmsRefused`). The voluntary **Break Alliance** order is valid whenever a formal alliance exists, **including while the pair is at war** (the `formalAlliance` flag is independent of relation state); it is **not** tech-gated and has **no** treasury cost. Forming an alliance is unchanged (a separate `Alliance` order).
- **Join Empire:** Requires target nearly defeated; tech-gated by Empire Building (see [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md)). Acceptance removes target GP and transfers provinces.

#### Nearly defeated (GP target)

For current product, a Great Power is treated as **nearly defeated** when **both** of the following are true:

- The target currently owns **three or fewer provinces** in total (Old World + New World combined; count is based on current world state, not starting setup).
- The target **no longer controls its original capital province** (its `capitalProvinceId` in world state is not owned by that faction at the time the Join Empire overture is resolved).

When these conditions hold, other Great Powers that meet the tech and overture requirements may offer **Join Empire** to that target.

### GP–Tribe first contact

GP–Tribe pairs are **not** initialized at game start. A GP **discovers** a Tribe for first-contact only when the GP holds **non-`unknown` tile visibility into at least one province that Tribe owns** (`discoveredTribeIdsForFirstContact`). Sea-reachable colonial intel alone — which can connect Old World coasts to a still-unrevealed New World at turn 0 — does **not** count as first-contact discovery, so the herald and the persisted relation do not fire before the New World is genuinely revealed. On discovery, `applyGpTribeFirstContactRelations` persists `AT_PEACE`, score `50`, Neutral with `sinceTurn` = current turn, and the app presents the first-contact herald once per `(gameId, tribeId)` per session (`OVL80001`). See [`tribe-first-contact-overlay.md`](../ui/tribe-first-contact-overlay.md).

**Per-GP parity.** Each GP makes first contact independently. For the live **human** GP, relation persistence and the once-per-session herald are applied in the app layer (`syncGpTribeFirstContact`) after turn resolution. For **AI-controlled** GPs (including every GP in observer games), first-contact relations are persisted **during turn resolution** at end-of-turn — after visibility is finalized — by `applyAiGpTribeFirstContactRelations`, using the **same** `AT_PEACE` / score `50` / Neutral standing and **no** herald. The human GP is skipped during turn resolution so the relation stays absent until the app enqueues its herald. First contact is irreversible: the relation persists even if visibility later decays.

The `knownDiplomaticTargetFactionIds` set (existing relations **and** non-`unknown` tile visibility) is the single source for **all** GP↔Tribe diplomatic visibility — diplomacy-panel targeting, order suggestions, and AI declare-war diplomatic targeting alike. Sea-reachable colonial intel alone does **not** add a Tribe to this set (Refs #3620, supersedes the colonial-intel discovery path of #2509/#3341): a GP cannot target an uncontacted sea-reachable Tribe with diplomatic orders. Colonial intel (sea-reachability) still drives **non-diplomatic** behaviour only — Explorer explore prioritization and AI colonial military scoring/pathfinding.

- Given a new game where the human GP has zero non-`unknown` tiles in any Tribe-owned province, when `applyGpTribeFirstContactRelations` runs, then no GP–Tribe relation is persisted and `newlyContactedTribeIds` is empty, even if a Tribe colony is sea-reachable from the GP's Old World anchors.
- Given the human GP holds non-`unknown` tile visibility into a province owned by Tribe `T`, when `applyGpTribeFirstContactRelations` runs and no GP–`T` relation exists, then the system persists `AT_PEACE`, score `50`, Neutral for the GP–`T` pair and includes `T` in `newlyContactedTribeIds`.
- Given an **AI-controlled** GP `G` holds non-`unknown` tile visibility into a province owned by Tribe `T` and no `G`–`T` relation exists, when the end-of-turn phase runs, then the system persists exactly one `AT_PEACE`, score `50`, Neutral `G`–`T` relation with `sinceTurn` = the resolved turn and emits **no** herald.
- Given an **AI-controlled** GP `G` has only sea-reachable colonial intel toward Tribe `T` (zero non-`unknown` tiles in any `T`-owned province), when the end-of-turn phase runs, then the system persists **no** `G`–`T` relation.
- Given the **human** GP `H` holds non-`unknown` tile visibility into a province owned by Tribe `T` and no `H`–`T` relation exists, when the end-of-turn phase runs during turn resolution, then the system persists **no** `H`–`T` relation (the human relation and herald are applied later by the app layer).

### GP–Minor Rules

- **Overture chain:** Trade Consulate (cost) → Embassy (cost) → Non-Aggression Pact (free) → Join Empire (cost, relation check). Each step unlocks the next. Embassies and foreign civilian work are tech-gated by Diplomatic Expertise. **Overtures are two-way:** one player offers; the **target** faction must accept or reject. When the target is a Minor or Tribe, the accept/reject decision is applied at turn resolution by rule (e.g. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation and cost). When the target is a Great Power, that GP's controller decides: if the target is **AI**, the decision is made during the Diplomacy phase; if the target is **human**, turn resolution **blocks** until the human responds (see [turn-resolution-phases.md](../program/turn-resolution-phases.md) § Blocking human input). Only when the target accepts are cost deducted and overture stage advanced. Minors never refuse Consulate/Embassy; Join Empire requires Friendly/Allied relation and a **cost in pounds** that scales with the size of the Minor/Tribe (see Configurable Values). When enacted, the Minor or Tribe is **absorbed**: all provinces, units, and fleets owned by that faction transfer to the requesting GP; the Minor/Tribe is removed from the game; overture and relation records involving that faction are removed. The GP’s treasury is reduced by the Join Empire cost.
- **Purchase land (Merchant):** The Merchant work order `purchase_land` (tile in Minor/Tribe province with resource) requires the player to have an **embassy** with that Minor/Tribe and to **not be at war** with them. See [civilian-units.md](civilian-units.md).
- **Foreign aid:** **Grant Aid** — deducts the chosen amount from the granting GP’s treasury and improves relation score. **current product** matches the **Grant Aid** order rules under **Diplomatic Order Types** below: **positive multiple of £1000** (minimum £1000), enforced at validation and resolution; there is **no** percentage mode and **no** fixed menu of allowed amounts—only step/min rules. UI **defaults** (e.g. £1000) and AI suggestions are conveniences, not an exclusive list of legal values (see **Amount parameters (current product)**).
- **Intervention (human and AI, at war declaration — Diplomacy phase only):**
  - Trigger (embassy or investment protection): When a Great Power **declares war** on a **Minor Nation or Tribe** that currently has **at least one other GP** with an **Embassy** with that Minor/Tribe **or** **purchased land** recorded in its provinces (`purchasedTilesByTileKey` entries where the tile’s province ownerId is that Minor/Tribe), each such other GP evaluates or is offered a **one-time Intervention choice** against the aggressor **during the Diplomacy phase** (after `Declare War` is applied for that pair, before Movement). Intervention is **not** a combat-phase action.
  - Human GP with Embassy or purchased land: For each valid GP–Minor/Tribe war declaration, each human GP that:
    - is **not** the declaring GP, and
    - has an **Embassy** with that Minor/Tribe **or** has **purchased land** in any province owned by that Minor/Tribe  
    is presented an Intervention choice **once, at war declaration time** in the Diplomacy phase:
    - **Intervene (human):** The intervening GP immediately enters a war state (`AT_WAR`) with the declaring Great Power; this war state is in effect for all subsequent Movement and Combat in that turn and beyond. The Minor remains an independent faction for province ownership purposes in current product.
    - **Do Nothing (human):** The intervening GP does not change relation score or war state with the declaring Great Power at that moment, but **loses its Embassy** with the attacked Minor (all overtures with that Minor are cleared). Any existing **purchased land** in that Minor’s provinces remains recorded until normal province conquest rules apply (see province conquest rules).
    - **Diplomatic Protest (human):** The intervening GP remains at peace but applies a relation penalty with the declaring Great Power; the Minor’s diplomatic state is unchanged. Purchased land and Embassy state remain unchanged.
  - AI GP with Embassy or purchased land: For each GP–Minor/Tribe war declaration:
    - Every AI-controlled GP that has an Embassy with the attacked Minor/Tribe, or has any purchased land in that Minor’s or Tribe’s provinces, independently evaluates whether to intervene against the declaring Great Power.
    - The **probability to intervene** is a monotonic function of the GP–Minor relation score; default values for current product are: relation score 0–25 → 0% chance, 26–50 → 25% chance, 51–75 → 50% chance, 76–100 → 80% chance.
    - On **AI Intervene**, the AI GP immediately enters a war state with the declaring Great Power; this war state is used for all Movement and Combat validation in that turn and subsequent turns. Embassy and overture state with the Minor remain unchanged.
    - On **AI Do Nothing**, the AI GP does not change relation or war state with the declaring Great Power but **loses its Embassy** (all overtures) with the attacked Minor/Tribe, matching the human Do Nothing outcome. Purchased land remains recorded until province conquest rules apply.
    - current product does not implement an AI **Protest** choice; AI either intervenes or does nothing.
  - Turn timing and scope: Intervention is evaluated **once per war declaration** during the Diplomacy phase, before Movement and Combat. There are **no additional intervention prompts tied to later battles** in that war; once the war state has been updated (or not) based on Intervention choices, subsequent combats proceed with that fixed war/peace state.
- **Peace:** Minors never refuse peace offers.
 - **War and overtures:** When a GP declares war on a Minor (relationState becomes `AT_WAR`), any existing overture state between that GP and that Minor (Trade Consulate, Embassy, NAP, or Join Empire) is **cleared to `none`**. While `AT_WAR`, the GP cannot establish any new overtures with that Minor; after peace, the overture chain must be rebuilt from `none` if the player wants renewed consulate/embassy status.

### GP–Tribe Rules

- **War before hostile action:** Same as Minors — see **War required for hostile actions** above (military invasion and naval blockade require `AT_WAR` or same-turn `Declare War` on the Tribe as province owner).
- **Overture chain:** Same as Minor but Join Empire creates a **colony** (provinces don't count toward victory; profit share and colonial government).
- **Join Empire → colony (Refs #3753 R5):** When a GP resolves an `Establish Overture` at stage `Join Empire` against a **Tribe**, the Tribe does **not** leave the game and its provinces/units/fleets are **not** transferred. Instead the Tribe becomes a **colony** of that GP: a `ColonyState { tribeId, colonyOfGpId, sinceTurn }` is recorded on the `Game` (one per Tribe; re-resolution replaces the prior record), the Tribe **remains** in `tribes`, and overtures/relations with the Tribe are preserved. Only the Join Empire **cost** is deducted from the GP treasury. The colonizing GP is the Tribe's favoured trading partner while the colony stands. This differs from **GP–Minor** Join Empire, which keeps full **absorption** (province/unit/fleet transfer and faction removal). The colony relationship ends if the colonizing GP is removed from the game.
- **Purchase land (Merchant):** Same as GP–Minor: requires **embassy** with that Tribe and **not at war**.
- **Boycott (colony trade embargo) (Refs #3753 R6):** A GP that holds at least one colony (R5) may issue a **Boycott** diplomatic order against **another** Great Power. While the boycott is active, **all trade is blocked between the boycotted target GP and every Tribe that is a colony of the issuing GP** (world-market sales where the target GP buys goods a colony Tribe is selling; Merchant `purchase_land`, Grant Aid, and Set Subsidy from the target GP toward a colony Tribe). The boycott is keyed by the `(issuerGpId, targetGpId)` pair and recorded as a `BoycottState { gpId, targetGpId, sinceTurn }` on the `Game` (one active record per pair). Because a GP may hold multiple colonies, a single boycott against a target GP applies to all of the issuer's colonies; the affected Tribe set is derived from `ColonyState` at enforcement time (rather than pinned to one Tribe at order time).
  - **Subsidy cancellation on apply (R6.2):** When a Boycott is applied, any active `SubsidyState` from the **target GP** to a Tribe that is a colony of the **issuing GP** is immediately cancelled (a `subsidyCancelled` event is appended).
  - **Lifecycle (R6.4):** A boycott persists until (a) the issuer issues a **Revoke Boycott** for that pair (a `boycottRevoked` event is appended), or (b) the issuer and the target GP enter `AT_WAR` with each other — at which point the boycott is **auto-cancelled** during the same Diplomacy phase (a `boycottRevoked` event is appended) because the war rules already block trade. A boycott is one-sided (opt-in from the issuer); the target GP and colony Tribes have no accept/reject step.
- Tribes react to nearby conquest (relation/trade effects).
- **Intervention:** Same **Intervention** rules as for Minors (Embassy or purchased land; Diplomacy phase when a GP declares war on the Tribe).
- **War and overtures:** If relationState becomes `AT_WAR` between a GP and a Tribe, any existing overture state between that GP and that Tribe is **cleared to `none`** and cannot be re-established while they remain at war. After peace, the GP must rebuild the overture chain from `none` if it wants to regain consulate/embassy/colony-level relations.

### GP AI policy for war vs. relations (Full AI only)

This policy applies only to **Phase 6 Full AI**. It does not apply to Phase 4 simple AI.

- For every candidate target faction (GP, Minor, or Tribe), Full AI computes a **war desire score** per `(gpId, targetFactionId)` each turn.
- Full AI computes an **improve-relations desire score** as `100 - warDesireScore`.
- The diplomacy planner uses these scores to prioritize `Declare War`, `Offer Peace`, and `Establish Overture`.
- Full AI keeps the existing relation gate for war declarations (high positive relations can block war declarations even if war desire is high).

#### War desire score (0..100)

`warDesireScore` is clamped to integer range `0..100`, starts at base `50`, then applies factors:

- **Relative power score (primary factor):** uses the same power formula as Great Power power score (military + province + naval):
  - `relativePower = attackerPowerScore / max(1, targetPowerScore)`
  - `relativePower >= 1.35` => `+30`
  - `0.85 <= relativePower < 1.35` => `+5`
  - `relativePower < 0.85` => `-25`
- **Relation pressure factor:**
  - relation score `>= 70` => `-40`
  - relation score `50..69` => `-20`
  - relation score `<= 25` => `+10`

For **Minor/Tribe targets**, add:

- **Resource need bonus:** for each distinct target-owned resource that the GP currently has zero stockpile of, `+5`, capped at `+15`.
- **Intervention-risk penalty:** for each *other GP* with embassy on that Minor/Tribe, `-8`, capped at `-24`.
- **Invasion capacity adjustment:**
  - if GP regiment count is too low to stage invasion (`ownRegiments < max(2, targetRegiments/2 floored)`), `-20`
  - else if `ownRegiments > targetRegiments`, `+10`
  - if target requires overseas invasion (target has provinces in regions where attacker has none) and attacker has no ships, `-25`
  - if attacker is already in 2+ active wars, `-15`

#### Cooldowns (per GP-target pair)

- **War declaration cooldown:** after AI initiates `Declare War` on target, AI must wait `4` turns before re-scoring that pair for a new war declaration.
- **Improve-relations cooldown:** after AI overture accept/reject outcome for target, AI must wait `2` turns before attempting another overture-driven improve-relations action for that same pair.

#### War goals and in-war reassessment

- Before selecting `Declare War`, Full AI derives a **desired territory objective**:
  - `desiredTerritory = clamp(round(warDesireScore / 25), 1, targetProvinceCount)`
- While at war, each turn Full AI recomputes `warDesireScore` for that pair:
  - high war desire lowers `Offer Peace` preference (continue war),
  - low war desire raises `Offer Peace` preference (de-escalate / adjust down goals).
- current product stores war goals as planner output (deterministic logs and action scoring), not as a separate persistent war-goal state object.

### Diplomatic Order Types

- **Declare War** — target faction; valid if AT_PEACE.
- **Offer Peace** — target faction; valid if AT_WAR.
- **Alliance** — target GP; propose, accept, or refuse (forms a formal alliance).
- **Break Alliance** — target GP; valid only when a **formal alliance** currently exists with that GP. Voluntarily ends the alliance and applies the unified alliance-break penalty (see **Breaking an alliance**). Valid at peace **or** at war; not tech-gated; no treasury cost. At most one Break Alliance per (player, target GP) per turn.
- **Establish Overture** — target Minor/Tribe **or** Great Power, overture type; valid if previous step achieved and costs met. **At most one Establish Overture per (player, target faction) per turn.** The overture is a **two-way agreement**: at turn resolution the **target** accepts or rejects. For Minor/Tribe targets the decision is applied by rule during the Diplomacy phase. For GP targets: if the target is human-controlled, turn resolution suspends and the app must prompt the human and resume with the decision; if AI-controlled, the decision is made during the phase. Validation rejects any second Establish Overture order for the same target.
- **Grant Aid** — target faction, **amount**: a **positive integer** in pounds (£). Valid if Embassy exists, treasury ≥ amount, and other diplomacy preconditions hold. Resolves as a **one-time** transfer: treasury deduction and relation update per resolver rules.
- **Set Subsidy** — target faction, **amount**: a **positive integer** in pounds (£) **per turn** (ongoing subsidy until updated or cancelled). Valid if an **Embassy** exists and treasury meets validation (see resolver) — a Trade Consulate alone is **not** sufficient (Refs #3753 R2: economic/treaty actions require an Embassy). **current product** is **amount in £/turn only**; there is **no** percentage-based subsidy mode in orders or resolution.
- **Boycott** — target **Great Power** only; valid only when the **issuing GP holds at least one colony** (a `ColonyState` with `colonyOfGpId == issuer` exists), the target is **another** Great Power **at peace** with the issuer, and **no** active boycott already exists for the `(issuer, target)` pair. Not tech-gated; no treasury cost. At most one Boycott per (issuer, target GP) per turn. See **Boycott (colony trade embargo)** below.
- **Revoke Boycott** — target **Great Power**; valid only when an **active boycott** for the `(issuer, target)` pair exists. Removes the boycott. Not tech-gated; no treasury cost. At most one Revoke Boycott per (issuer, target GP) per turn.

**Amount parameters (current product):** Both orders use the same **order field model**: a single integer `amount` in diplomatic orders. **Grant Aid:** `amount` must be a **positive multiple of £1000** (minimum £1000). **Set Subsidy:** `amount` must be a **positive multiple of £100** (minimum £100). Validation and diplomacy resolution enforce these steps. Defaults in UI steppers and AI suggestions use **£1000** for both unless the ruleset changes; defaults are **not** an exclusive list of legal values.

### Turn Sequence

Diplomacy phase runs before Movement. Declarations and peace take effect for the same turn's movement and combat.

---

## Acceptance Criteria

The following Given–When–Then criteria are testable conditions for diplomacy behaviour. Implementation: [diplomacy-resolution.md](../program/diplomacy-resolution.md); phase ordering: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

- Given a new game has started with at least two Great Powers  
  When the system initializes diplomatic relations at turn index 0  
  Then the system sets each unordered Great Power pair to relation state `AT_PEACE`, relation score `50`, relation level `Neutral`, and records `sinceTurn = 0` and `lastInteractionTurn = 0`.

- Given a new game has started with Great Powers, Minor Nations, and Tribes  
  When the system initializes diplomatic relations at turn index 0  
  Then the system sets diplomatic relations **only between factions in the same region**:
  - Old World: all pairs among Great Powers and Minor Nations (GP↔GP, GP↔Minor, Minor↔Minor) at `AT_PEACE`, score `50`
  - New World: all pairs among Tribes (Tribe↔Tribe) at `AT_PEACE`, score `50`
  - Cross-region pairs (GP/Minor ↔ Tribe) are **not initialized** (undiscovered/unknown)

- Given the Player is a Great Power at relation state `AT_PEACE` with a target Great Power and the current turn index is an integer `t ≥ 0`  
  When the Player issues a `Declare War` diplomatic order targeting that Great Power in the Diplomacy phase of turn `t` and the order is valid  
  Then the system changes the relation state between the two Great Powers to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t`, and uses this `AT_WAR` state for all Movement and Combat validation during turn `t`.

- Given the Player is a Great Power at relation state `AT_WAR` with a target Great Power and the current turn index is `t`  
  When both sides have accepted a peace offer between those two Great Powers in the Diplomacy phase of turn `t`  
  Then the system changes the relation state between the two Great Powers to `AT_PEACE` with `sinceTurn = t`, updates `lastInteractionTurn = t`, leaves all province ownership unchanged, and uses `AT_PEACE` for Movement and Combat validation during turn `t`.

- Given the Player controls a Great Power with a valid treasury balance in pounds as a non-negative integer and has no existing consulate or embassy with a target Minor Nation  
  When the Player issues an `Establish Overture` order for a `Consulate` with that Minor and the treasury is greater than or equal to `Consulate cost` for the active ruleset  
  Then the system deducts exactly the `Consulate cost` from the Player treasury, records a Consulate overture between the Great Power and that Minor, and unlocks the ability for the Player to offer an Embassy to that same Minor in later turns.

- Given the Player controls a Great Power that already has an Embassy with a target Minor Nation or Tribe, is not at relation state `AT_WAR` with that faction, and has a Merchant unit assigned a `purchase_land` work order targeting a tile in that Minor or Tribe province  
  When the system validates the `purchase_land` work order during turn resolution  
  Then the system accepts the work order for execution and does not reject it for missing diplomatic prerequisites.

- Given the Player controls a Great Power that holds only a Trade Consulate (no Embassy) with a target Minor Nation, is at relation state `AT_PEACE` with that Minor, and has treasury greater than or equal to the subsidy amount (Refs #3753 R2)  
  When the Player issues a `Set Subsidy` order against that Minor  
  Then the system rejects the order at validation with a reason indicating an Embassy is required, and creates no `SubsidyState` for that pair.

- Given the Player controls a Great Power that holds an Embassy with a target Minor Nation, is at relation state `AT_PEACE` with that Minor, and has treasury greater than or equal to the subsidy amount (a positive multiple of £100) (Refs #3753 R2)  
  When the Player issues a `Set Subsidy` order against that Minor  
  Then the system accepts the order at validation (subject to the amount-step and treasury rules).

- Given the Player controls a Great Power with an Embassy with a Minor Nation or Tribe, a different Great Power has a valid `Declare War` order against that Minor or Tribe in the Diplomacy phase of turn index `t`, and war between aggressor and that Minor/Tribe is applied in that phase  
  When the system presents the Player with an Intervention choice and the Player selects **Intervene**  
  Then the system changes the relation state between the Player’s Great Power and the declaring Great Power to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t`, and uses this `AT_WAR` state for all Movement and Combat validation later in turn `t`.

- Given the same context as the previous criterion (Embassy with the Minor/Tribe under attack by another GP’s declaration in turn `t`)  
  When the system presents the Player with an Intervention choice and the Player selects **Do Nothing**  
  Then the system does not change the relation state or relation score between the Player’s Great Power and the declaring Great Power at that moment, and clears all overture state (Consulate, Embassy, NAP, Join Empire) between the Player’s Great Power and that Minor/Tribe from the game state.

- Given the same context as the previous criterion  
  When the system presents the Player with an Intervention choice and the Player selects **Diplomatic Protest**  
  Then the system leaves the relation state between the Player’s Great Power and the declaring Great Power as `AT_PEACE`, decreases the relation score with the declaring Great Power by a fixed penalty of 10 points (clamped between 0 and 100 inclusive), updates `lastInteractionTurn = t`, and does not change any overture or Embassy state with the attacked Minor/Tribe.

- Given the system controls an AI Great Power that has an Embassy with a Minor Nation or Tribe and another Great Power declares war on that Minor/Tribe in the Diplomacy phase of turn `t`  
  When the system evaluates whether that AI Great Power will intervene against the aggressor  
  Then the system computes a probability to intervene based solely on the current relation score between the AI Great Power and that Minor/Tribe, using the default mapping 0–25 → 0%, 26–50 → 25%, 51–75 → 50%, 76–100 → 80% unless overridden by a ruleset, and samples a single Bernoulli trial with that probability to decide whether to intervene (otherwise **Do Nothing**; AI does not choose **Protest** in current product).

- Given Full AI controls a Great Power and has legal diplomacy candidates against a target faction in turn `t`  
  When the AI diplomacy planner scores candidates for that `(gpId, targetFactionId)` pair  
  Then the system computes `warDesireScore` from the strength ratio and relation factors defined in `GP AI policy for war vs. relations` and computes improve-relations desire as `100 - warDesireScore`.

- Given Full AI controls a Great Power and a Minor/Tribe target has at least one target-owned resource that the GP has zero stockpile of, while no additional constraints change  
  When the AI computes `warDesireScore` for that target  
  Then the system increases war desire by `+5` per missing distinct resource up to `+15`.

- Given Full AI controls a Great Power and one or more other Great Powers have embassy overtures with a Minor/Tribe target  
  When the AI computes `warDesireScore` for war against that target  
  Then the system applies an intervention-risk penalty of `-8` per such GP up to `-24`.

- Given Full AI controls a Great Power and a `(gpId, targetFactionId)` pair has a prior AI-initiated `Declare War` event at turn `t0`  
  When the AI evaluates that same pair at turn `t` where `t - t0 < 4`  
  Then the system treats war declaration for that pair as on cooldown and does not select `Declare War` for that pair in that evaluation.

- Given Full AI controls a Great Power and a `(gpId, targetFactionId)` pair has an overture accept/reject event at turn `t0`  
  When the AI evaluates improve-relations overture actions for that pair at turn `t` where `t - t0 < 2`  
  Then the system treats overture-driven improve-relations for that pair as on cooldown and does not select those actions for that pair in that evaluation.

- Given Full AI controls a Great Power and is evaluating a legal `Declare War` candidate against target faction `X` with `targetProvinceCount >= 1`  
  When the AI computes `warDesireScore` for `X` in that turn  
  Then the system computes `desiredTerritory = clamp(round(warDesireScore / 25), 1, targetProvinceCount)` and uses that objective to bias wartime continuation/de-escalation scoring in subsequent turns.

- Given the same AI intervention context and the Bernoulli trial results in **intervene**  
  When the Diplomacy phase applies that outcome  
  Then the system changes the relation state between that AI Great Power and the declaring Great Power to `AT_WAR` with `sinceTurn = t`, updates `lastInteractionTurn = t`, and leaves Embassy and overture state between the AI Great Power and the Minor/Tribe unchanged.

- Given the same AI intervention context and the Bernoulli trial results in **do nothing**  
  When the Diplomacy phase applies that outcome  
  Then the system does not change the relation state or relation score between that AI Great Power and the declaring Great Power, and clears all overture state between that AI Great Power and that Minor/Tribe from the game state.
- Given the Player controls a Great Power with a Non-Aggression Pact overture with a target **Minor Nation**, relation score between that GP and that faction is at least 51 (Friendly or Allied), the target owns at least one province, and the Player’s treasury is at least the Join Empire cost (base cost + per-province cost × number of provinces owned by the target)  
  When the Player issues an `Establish Overture` order with overture stage `Join Empire` targeting that Minor Nation in the Diplomacy phase and the order is valid  
  Then the system deducts exactly that Join Empire cost from the Player’s treasury, transfers ownership of all provinces owned by the target to the Player’s Great Power, transfers all units and fleets owned by the target to the Player’s Great Power, removes the target Minor Nation from the game, removes all overture state and diplomacy relations involving that target, and logs the outcome with the `logic:` prefix.

- Given the Player controls Great Power `A` with a Non-Aggression Pact overture with a target **Tribe** `T`, relation score between `A` and `T` is at least 51, `T` owns at least one province, and `A`'s treasury is at least the Join Empire cost  
  When the Player issues an `Establish Overture` order with overture stage `Join Empire` targeting `T` in the Diplomacy phase and the order is valid  
  Then the system deducts exactly that Join Empire cost from `A`'s treasury, records a `ColonyState { tribeId: T, colonyOfGpId: A, sinceTurn: t }` on `Game.colonyStates`, does **not** transfer ownership of `T`'s provinces, units, or fleets, keeps `T` listed in `tribes`, and preserves all overture state and diplomacy relations involving `T`.

- Given Tribe `T` is already a colony of Great Power `A` (a `ColonyState` for `T` exists)  
  When a Tribe Join Empire overture for `T` resolves again (for the same or a different Great Power)  
  Then `Game.colonyStates` contains exactly one `ColonyState` whose `tribeId` is `T` (the prior record is replaced, not duplicated).

- Given the Player controls a Great Power that currently has a Consulate or Embassy overture stage recorded with a target Minor Nation or Tribe and the current relation state between those two factions changes from `AT_PEACE` to `AT_WAR` in turn `t`  
  When the Diplomacy phase for turn `t` completes  
  Then the system removes any overture state between that Great Power and that Minor or Tribe so that subsequent state inspection reports `overtureStage = none` for that pair, and later peace between them does **not** restore the previous overture stage.

- Given the Player controls a Great Power at relation state `AT_WAR` with a target Minor Nation or Tribe in turn `t` and the Player has at least the Consulate or Embassy cost in treasury  
  When the Player issues an `Establish Overture` diplomatic order targeting that Minor or Tribe in the Diplomacy phase of turn `t`  
  Then the system treats that order as **invalid** for the current turn, does **not** create or advance any overture state between those factions, and does **not** deduct any overture cost from the Player’s treasury for that order.
- Given the Player controls a Great Power A and there is a target Great Power B such that B currently owns three or fewer provinces in total, B does **not** own its original capital province (its `capitalProvinceId` in world state is owned by some other faction), and A has unlocked the `empire_building` tech and is not at war with B  
  When the Player issues a `Join Empire` diplomatic order targeting B in the Diplomacy phase and all other Join Empire preconditions are satisfied  
  Then the system treats B as **nearly defeated**, accepts the `Join Empire` order as valid, and resolves it per the Join Empire rules (absorbing B’s remaining provinces, units, and fleets into A and removing B from the game).

- Given the Player controls a Great Power and has already submitted one `Establish Overture` diplomatic order targeting a Minor Nation or Tribe in the current turn  
  When the Player submits a second `Establish Overture` order targeting the same Minor or Tribe in the same turn  
  Then the system rejects the second order at validation (e.g. reason: already have an Establish Overture order for this faction this turn) and does **not** apply it at resolution.

- Given a Great Power has submitted an `Establish Overture` order targeting a Minor Nation or Tribe and preconditions (previous stage, cost, not at war) are met at resolution  
  When the Diplomacy phase processes that overture  
  Then the system applies the target’s accept/reject decision per rules (e.g. Minor/Tribe accept Consulate/Embassy/NAP by rule); only when the decision is **accept** does the system deduct cost and advance overture stage.

- Given a Great Power has submitted an `Establish Overture` order whose **target is a human-controlled Great Power** and preconditions are met at resolution  
  When the Diplomacy phase reaches that overture  
  Then the system does **not** apply it immediately; it suspends turn resolution and returns a **pending overture decision** for that target. The app must prompt the human target to accept or reject; when the app supplies the decision and resumes resolution, the system applies the decision (deduct cost and advance stage if accept, else leave state unchanged) and continues the turn.

- Given Great Powers A and B are at peace with relation score ≥ 76 (`RelationLevel.allied`) but **no** formal alliance at the end of turn `t−1`  
  When another Great Power declares war on B during the Diplomacy phase of turn `t`  
  Then the system does **not** add a pending Call to Arms for A and does **not** change A's war state with the aggressor.

- Given Great Powers A and B are at peace with a **formal alliance** at the end of turn `t−1`  
  When another Great Power declares war on B during the Diplomacy phase of turn `t`  
  Then the system adds exactly one pending Call to Arms for A when A is human, or resolves A's join/refuse by the AI score rule when A is AI.

- Given Great Power A holds a formal alliance with Great Power B and A **refuses** a Call to Arms (defending B against aggressor D) in turn `t`  
  When the Diplomacy phase completes  
  Then the system clears the A–B formal alliance flag, records an `allianceBroken` event for the A–B pair, subtracts 50 from A's relation with B (clamped 0–100), subtracts 10 from A's relation with every other Great Power for which A holds a relation **except** B and the aggressor D (each clamped 0–100), and leaves A's relation with D unchanged by this rule.

- Given Great Powers A and B hold a **formal alliance** (`formalAlliance = true`) and A issues a `Break Alliance` diplomatic order targeting B in the Diplomacy phase of turn `t`  
  When the Diplomacy phase resolves the order  
  Then the system sets `formalAlliance = false` for the A–B pair, records an `allianceBroken` event for that pair, subtracts 50 from A's relation with B (clamped 0–100), and subtracts 10 from A's relation with every other Great Power for which A holds a relation at the time of the break, excluding B (each clamped 0–100).

- Given Great Powers A and B do **not** hold a formal alliance (`formalAlliance = false`) and A issues a `Break Alliance` diplomatic order targeting B  
  When the order is validated  
  Then the system rejects the order with a reason indicating there is no formal alliance to break, does not change any relation score, and does not record an `allianceBroken` event.

- Given Great Power A holds a colony (a `ColonyState` with `colonyOfGpId == A` exists), Great Power B is another GP at peace with A, and no boycott for the `(A, B)` pair exists  
  When A issues a `Boycott` diplomatic order targeting B and the Diplomacy phase resolves it  
  Then the system records exactly one `BoycottState { gpId: A, targetGpId: B, sinceTurn: t }` on `Game.boycottStates` and appends a `boycottSet` event for the `(A, B)` pair.

- Given Great Power A holds **no** colony (no `ColonyState` with `colonyOfGpId == A`)  
  When A issues a `Boycott` diplomatic order targeting Great Power B  
  Then the system rejects the order at validation with a reason indicating a colony is required, and records no `BoycottState`.

- Given Great Power A holds a colony and is **at war** with Great Power B (relation state `AT_WAR`)  
  When A issues a `Boycott` diplomatic order targeting B  
  Then the system rejects the order at validation with a reason indicating the pair must be at peace, and records no `BoycottState`.

- Given an active boycott `BoycottState { gpId: A, targetGpId: B }` exists and Great Power B has an active `SubsidyState { payerId: B, targetId: T }` where Tribe `T` is a colony of A  
  When A issues a `Boycott` order targeting B and the Diplomacy phase resolves it (or the boycott is already applied this same phase)  
  Then the system removes that `SubsidyState` and appends a `subsidyCancelled` event for the `(B, T)` pair.

- Given an active boycott `BoycottState { gpId: A, targetGpId: B }` exists  
  When A issues a `Revoke Boycott` diplomatic order targeting B and the Diplomacy phase resolves it  
  Then the system removes the `(A, B)` `BoycottState` and appends a `boycottRevoked` event for that pair.

- Given there is **no** active boycott for the `(A, B)` pair  
  When A issues a `Revoke Boycott` diplomatic order targeting B  
  Then the system rejects the order at validation with a reason indicating there is no active boycott to revoke, and changes no `BoycottState`.

- Given an active boycott `BoycottState { gpId: A, targetGpId: B }` exists at the start of turn `t` and A and B enter `AT_WAR` during turn `t`  
  When the Diplomacy phase of turn `t` completes  
  Then the system removes the `(A, B)` `BoycottState` (auto-cancelled by war) and appends a `boycottRevoked` event for that pair.

- Given Great Powers A and B have **no** formal alliance at the start of turn `t` and A issues an `Alliance` order targeting B in turn `t`  
  When another Great Power declares war on B in the same Diplomacy phase of turn `t`  
  Then the system forms the A–B formal alliance but does **not** add a Call to Arms for A for that same-turn war.

- **Relation thresholds and config:** Relation level (Hostile, Neutral, Friendly, Allied) is derived from relation score using the thresholds in Configurable Values; the table in this document is the source of truth for default values; ruleset overrides apply when specified.
- **Implementation:** Order validation and resolution flow: [diplomacy-resolution.md](../program/diplomacy-resolution.md). Phase order: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

- Given a legacy save file in which a faction-pair relation stored its score as the integer `50`  
  When the system loads that save  
  Then the system represents that pair's relation score as the decimal `50.0` (integer × 1.0) and uses that decimal value directly in all subsequent threshold comparisons.

- Given a faction-pair relation whose decimal score is `73.5`  
  When the system serializes that relation to a save and loads it back  
  Then the restored relation score equals `73.5` exactly (decimal round-trip, no rounding).

- Given a faction-pair relation whose decimal score is `50.6`  
  When the system derives the relation level from the score  
  Then the system derives `Friendly` (because `50.6` is strictly above the Neutral band maximum of `50`), with no rounding of the score to `51`.

- Given the user views the diplomacy panel for a discovered faction with a diplomatic relation  
  When the panel displays the current relation  
  Then the system shows the **one-word relation state** drawn from the 10-word ladder keyed by the relation-meter step (see § Player-facing relation display — for example a score of `22.4` is step 3 → `Distrustful`), renders the 10-step gradient meter with its indicator on that step, and does **not** display the numeric relation score.

- Given a relation score of `22.4`  
  When the system derives the 10-step relation meter step via `relationScoreToMeterStep`  
  Then the system returns step `3` (the band `[20, 30)` per the 10-step relation meter table).

- Given a relation score of exactly `10`  
  When the system derives the 10-step relation meter step  
  Then the system returns step `2`, because each band is half-open `[low, high)` and the boundary value maps to the higher step (a score of `9.9` returns step `1`).

- Given a relation score of exactly `100`  
  When the system derives the 10-step relation meter step  
  Then the system returns step `10`, because the final band `[90, 100]` is fully closed and includes the maximum score (a score of `90` also returns step `10`, and a score of `0` returns step `1`).

- Given a relation score outside the valid range (for example `-5` or `105`)  
  When the system derives the 10-step relation meter step  
  Then the system clamps the score to `[0, 100]` first and returns step `1` for values below `0` and step `10` for values above `100`.

- Given the user views the diplomacy panel and the list includes at least one other Great Power  
  When the panel displays each Great Power row  
  Then the system derives that GP’s strength from the Great Power power score formula (province count, regiment strength, ship count with default weights) and presents it as a **relative power line** comparing the GP to the human player. The presentation (signed percentage, tier word, red/green semantic, placement) is defined by [SPEC/ui/diplomacy-panel.md](../ui/diplomacy-panel.md) § Relative power line: a GP stronger than the human player is shown in **red**, a GP at or below the human player in **green**. The underlying power score formula here remains authoritative; the tier buckets are a display-only refinement and do not feed war-desire logic.

## Configurable Values

| Parameter | Default | Notes |
|---|---|---|
| Initial GP–GP relation score | 50 | |
| Hostile threshold | 0–25 | |
| Neutral threshold | 26–50 | |
| Friendly threshold | 51–75 | |
| Allied threshold | 76–100 | |
| Consulate cost | £500 | |
| Embassy cost | £1000 | |
| Join Empire base cost | £5000 | One-time cost when enacting Join Empire. |
| Join Empire per-province cost | £2000 | Added for each province owned by the target Minor/Tribe. Total cost = base + (province count × per-province). |
| Alliance break penalty (broken-with ally) | 50 | Subtracted from the breaker's relation with the broken-with ally on any alliance break (voluntary `Break Alliance` or call-to-arms refusal); alliance flag cleared. |
| Alliance break penalty (every other GP) | 10 | Subtracted from the breaker's relation with every other Great Power it has a relation with on any alliance break (excludes the broken-with ally; for refusal also excludes the aggressor). |
| Call to arms AI join threshold | 50 | AI ally joins the war if relation score with the defended ally is ≥ this value. |
| Full AI war declaration cooldown (per GP-target pair) | 4 turns | Applies to AI-initiated `Declare War` re-attempts. |
| Full AI improve-relations cooldown (per GP-target pair) | 2 turns | Applies to AI overture-driven relation improvement retries. |

### Player-facing relation display

The **relation score** (0–100) is a **hidden variable**: it is not shown to the player in the diplomacy UI. Validation and game logic continue to use the internal score and relation level (Hostile/Neutral/Friendly/Allied) per the thresholds above.

The diplomacy panel shows instead a **one-word relation state** drawn from the 10-word ladder keyed by the relation-meter step (§ 10-step relation meter). `relationScoreToDisplayLabel(score)` returns `relationMeterStepLabel(relationScoreToMeterStep(score))` — i.e. the word for the step the hidden score falls in (Refs #3753 R13.6). The legacy 4-band table is superseded by this decimal-aware 10-band ladder. Game logic (e.g. Join Empire ≥ 51, Alliance ≥ 76) uses the internal score and level; only the displayed label and meter use these bands.

#### 10-step relation meter

For the diplomacy panel and detail screen, the hidden relation score additionally maps to a **10-step meter** (Refs #3753 R13). The score range `[0, 100]` is divided into **10 equal half-open bands** `[low, high)`; each boundary value maps to the **higher** step, and the final step is fully closed so the maximum score `100` is included:

| Step | Score band | Ladder label |
|------|------------|--------------|
| 1 | `[0, 10)` | Hostile |
| 2 | `[10, 20)` | Antagonistic |
| 3 | `[20, 30)` | Distrustful |
| 4 | `[30, 40)` | Unfriendly |
| 5 | `[40, 50)` | Wary |
| 6 | `[50, 60)` | Neutral |
| 7 | `[60, 70)` | Cordial |
| 8 | `[70, 80)` | Amicable |
| 9 | `[80, 90)` | Friendly |
| 10 | `[90, 100]` | Devoted |

The step is derived by `relationScoreToMeterStep(score)` (`colonizethis_diplomacy`), operating on the **raw** score with no intermediate rounding; the score is first clamped to `[0, 100]`, so a value below `0` maps to step 1 and a value above `100` maps to step 10. The numeric step boundaries above are fixed by this rule. The **per-step label ladder** (10 distinct words, ordered hostile → friendly) is returned by `relationMeterStepLabel(step)` and drives `relationScoreToDisplayLabel`. The red→green gradient **colors** for the meter (and the matching word color) are a UI concern documented in [SPEC/ui/components/relation-meter.md](../ui/components/relation-meter.md); the meter and ladder are delivered on the diplomacy panel row and detail screen (Refs #3753 R13).

### Great Power power score

An **absolute power score** is computed for each Great Power for display on the diplomacy panel. It reflects territorial, land, and naval strength.

- **Formula:** `powerScore = provinceCount × W_province + round(regimentStrength) × W_regiment + shipCount × W_ship`
- **Definitions:** `provinceCount` = number of provinces owned by that GP (Old + New World). `regimentStrength` = same aggregation as [military-strength](../program/military-strength.md) (FPN+FPM, era downgrade, medal multiplier). `shipCount` = total number of ships (sum of `shipTypeIds.length` over all fleets owned by that GP).
- **Default weights:** W_province = 10, W_regiment = 1, W_ship = 5. So one province = 10, one point of army strength = 1, one ship = 5.
- **Display:** The diplomacy panel shows this score for each GP. If the GP’s score is **higher** than the human player’s score, the value is shown in **red**; otherwise in **green**.
- **Calendar campaign end:** When summarizing a finished campaign without military victory, the same formula ranks GPs for a **declared winner**; ties yield **no-one** per [victory.md](victory.md) § Calendar campaign end.

### Where defined (current product)

Default values for the parameters above are given in this table; the table is the **source of truth** for design defaults. In the current (current product) implementation, the program does **not** read these from the ruleset. Relation thresholds (Hostile/Neutral/Friendly/Allied bands) and overture costs (Consulate, Embassy) are implemented as **code constants** in `colonizethis_logic` (see `diplomacy_resolver.dart`: `overtureConsulateCost`, `overtureEmbassyCost`, and the thresholds used in `scoreToLevel`). Ruleset-driven override for diplomacy parameters is **deferred**; when added, the key path and loader contract will be specified in this document and in [ruleset-config.md](ruleset-config.md); program loading: [ruleset-config.md](../program/ruleset-config.md).

---

## Interactions

- Tech gates: [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md), [tech-tree.md](tech-tree.md)
- Turn sequence: see program/turn-resolution-phases.md
- Combat validation: [combat.md](combat.md)
- Province identity (prefixed ids, region-scoped lookup in state and orders): [world-model-identity.md](world-model-identity.md)

---

## Diplomatic History

The game maintains a **diplomatic history log** for each Great Power, consisting of **structured events** involving that GP and any other faction (GP, Minor, or Tribe). Events are stored in game state as data and rendered as **human-readable** entries by the UI.

- **Scope (who logs what):**
  - Only **Great Powers** initiate diplomatic actions, but the history log records all events where any Great Power is a **party**: GP–GP, GP–Minor, GP–Tribe.
  - For a given Great Power `A`, the **per-faction history view** in the diplomacy panel shows only events where `A` and the selected faction `B` are both parties.
- **Event types (what is recorded):**
  - **State changes:** Declarations of war, transitions to peace, alliances formed or broken, Join Empire/Colony resolutions (including removal of a Minor/Tribe), intervention outcomes (Intervene, Do Nothing, Protest).
  - **Overtures and treaties:** Consulate established, Embassy established, NAP signed, Join Empire/Colony overture accepted. Failed overtures (rejected by human/AI GP, or rejected for validation reasons) are recorded as **attempted but not applied** if they reach diplomacy resolution.
  - **War side-effects:** Overtures cleared due to war, subsidies cancelled due to war.
  - **Economic diplomacy:** GrantAid applications and SetSubsidy creations, updates, and cancellations that successfully apply.
  - **AI vs human symmetry:** Events are recorded for both **human** and **AI-controlled** Great Powers; the history is a world-level log, not per-controller.
- **Time and ordering:**
  - Each event stores the **turn number** when it occurred (integer, same as `worldState.turnState.turnNumber`).
  - Events are **ordered** by (turn, within-turn index) in a way that preserves resolution order; the history is effectively append-only.
  - UI displays events grouped and sorted by **newest first**, using a **year label** derived from turn via the game calendar mapping (e.g. `Year 1505 (Turn 12)`), per the program-level time mapping spec.
- **Visibility and “unknown faction”:**
  - The underlying history is a **global** world log (all Great Power events), but **PlayerView-safe** projections for a given human player **substitute undiscovered factions** with `Unknown faction`:
    - If a faction in an event is not yet discovered by the viewing player (no relation and outside visibility rules), the UI renders that party as `Unknown faction` while keeping the rest of the event text intact.
    - When the same event involves the viewing player’s GP directly, the viewing player is always allowed to see their **own** identity; only other, still-undiscovered factions are substituted.
  - All human players see the **same underlying event list**, but with party names filtered/substituted per their own discovery state.
- **Retention:**
  - Diplomatic history is **unbounded** within a campaign: there is no cap on the number of events persisted in a save.
  - Old saves created before this feature may have an empty or partial history; the game shows **whatever history exists** in the saved Game state without backfilling from current relations.
