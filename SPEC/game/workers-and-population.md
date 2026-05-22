# Workers and Population

**SPEC/game** — Industrial labour model, distinct from civilian units. Derived from GDD 04, TDD 04. Reference: Imperialism II 02-economy (GDD).

---

## Workers as Separate Population Model

**Workers are a separate population model** — they are not map units. Civilian units (Explorer, Builder, Engineer, etc.) deploy, move, and work on terrain; workers are industrial labour in the capital, assigned to production, and never appear on the map.

Per Imperialism II 02-economy: workers "in your city" supply labour for industry. They consume food and luxuries directly from the player's stockpile.

---

## Worker Tiers

| Tier | Labour/turn | Food | Luxury (trained only) |
|------|-------------|------|------------------------|
| **Peasant** | 1 | 1 grain or meat | None |
| **Apprentice** | 4 | 1 grain + 1 meat | Refined sugar |
| **Journeyman** | 6 | 1 grain + 1 meat | Cigars |
| **Master** | 8 | 1 grain + 1 meat | Fur hats |

---

## Recruiting, Training, and Disbanding

Source of truth for worker pool changes outside of military / naval builds and consumption strikes. Values below are the **authoritative SPEC** values for v1; the program-level worker action catalog (`colonizethis_data`) MUST match them exactly.

### Costs (v1, program-level catalog, authoritative)

| Target tier | Action(s) | Stockpile / treasury cost | Worker pool cost |
|-------------|-----------|---------------------------|------------------|
| Peasant | Recruit | `fabric` × 2 | — |
| Apprentice | Recruit or train | treasury **200** + `paper` × 2 | 1 peasant consumed |
| Journeyman | Recruit or train | treasury **500** + `paper` × 5 | 1 peasant consumed |
| Master | Recruit or train | treasury **1000** + `paper` × 10 | 1 peasant consumed |

**Treasury** values are **ducats** (integer), the same treasury field used by `BuildUnitOrder` costs. For non-peasant tiers, **recruit and train share this exact cost row** — there is no separate "recruit non-peasant" cost row.

### Recruit

- **Peasant:** Pay `fabric` × 2 from the stockpile; add **+1 peasant** to the pool. No worker consumed.
- **Apprentice / Journeyman / Master:** Pay the treasury + paper amounts above and consume **1 peasant** from the pool; add **+1** of the target tier. Requires the tech gate for that tier to be unlocked (see Tech gates).

### Train (peasant → higher tier only)

- Converts exactly **one peasant** into **one** worker of a higher tier (apprentice, journeyman, or master) per queued order.
- **No direct tier-to-tier training.** To upgrade a journeyman to master, the player must **disband** that journeyman to a peasant (immediate, see Disband) and then queue **train master** for that peasant.
- **Model-layer note:** at the model layer, "train" is expressed as a `RecruitWorkerOrder` with `targetTier ∈ {apprentice, journeyman, master}` (a peasant is consumed per the cost row); there is **no** separate `TrainWorkerOrder` type. UI may render "Recruit" and "Train" as distinct controls per tier but emits the same order type.

### Disband

- Immediately decrements the chosen trained tier by **1** and increments **peasants** by **1**. Strict per-tier demotion to peasant (journeyman → peasant, apprentice → peasant, master → peasant). Disband does not skip tiers in any other way.
- **Not queued in Build / work;** applies on player action during the **Orders** phase.
- **No refund** of prior train / recruit costs (treasury, paper, fabric).

### Phase placement

- **`RecruitWorkerOrder` resolves in Build / work (phase 12)** **before** `BuildUnitOrder` (military, naval, civilian) per [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Build / work.
- **Same-turn labour:** Build-phase worker actions affect **next turn** Production only (Consumption → Production already ran earlier in the turn). The phase sequence is **not** reordered to support same-turn labour from new recruits.
- **Disband** is not a queued order; it applies immediately on player action during the Orders phase. After disband, the player may queue `RecruitWorkerOrder(targetTier: …)` for the new peasant in the same Orders phase.

### Peasant reservation

At order validation and UI affordance, the System MUST reject any new recruit / train / military build / naval build order that would exceed the **available** peasants computed from:

`availablePeasants = pool.peasants − sum(pending peasant consumes from queued worker actions + queued military / naval builds)`

**Civilian builds do not consume peasants.** Order suggestion APIs and AI planners MUST respect the same reservation rule.

### Tech gates

| Target tier | Required techs |
|-------------|----------------|
| Peasant | — |
| Apprentice | `apprentice_workers` and `sugar_refining` |
| Journeyman | `trained_journeymen` and `cigar_production` |
| Master | `master_artisans` and `hat_production` |

Tech ids reference [tech-tree-labour-economy.md](tech-tree-labour-economy.md) and [tech-tree-new-world.md](tech-tree-new-world.md). Locked tiers cannot be recruited or trained.

### Strike workers

Workers on food or luxury strike may still be **recruited** or **trained** if the cost row is met. **Rationale:** strike is a per-turn labour state (not a worker-state flag); recruit / train acts on **pool counts**, not on individual worker objects, so adding a strike gate would require new per-worker tracking and would surface no v1 gameplay benefit (matches Imperialism II behaviour).

### Order rejection reasons (validation)

`RecruitWorkerOrder` may be rejected with one of:

- `Insufficient workers` — not enough peasants given the reservation ledger above.
- `Insufficient materials` — insufficient fabric or paper in the stockpile.
- `Insufficient treasury` — insufficient ducats for the tier's treasury cost.
- `Required technology not unlocked` — the target tier's tech gate is not satisfied.

### Military and naval construction

Regiments and ships continue to consume **1 peasant** per build (headcount, not idle labour) as specified in [military-units.md](military-units.md) and [ships-and-naval.md](ships-and-naval.md). These peasant consumes count toward the reservation ledger above.

---

## Consumption and Production

- **Phase order:** Consumption runs **before** Production in turn resolution (after Extraction and Riches-to-treasury). Production uses the stockpile **after** food and luxury deductions, and labour from **idle** workers only (see below).
- Workers consume food and luxuries from the player stockpile during the Consumption phase (implementation: central stockpile; transported-then-warehouse ordering is not modelled separately).
- **Food strike:** If a worker’s required food cannot be met, that worker **stays in the WorkerPool** but is **on strike** for labour that turn (no partial labour for a shortfall). There is no grace period and **no removal** from the pool for missing food.
- **Worker food priority (high to low):** Masters → Journeymen → Apprentices → Peasants. Within a tier, workers are fed in full units only: as many as possible receive a full ration; the rest are on strike for food.
- **Luxury strike:** A trained worker who did **not** receive food consumes **no** luxury that turn. Among food-fed trained workers, luxury is assigned and deducted **all-or-nothing** per worker (up to one unit per worker per tier, capped by stockpile). Workers who are food-fed but do not receive a luxury unit are **on strike** for labour (same as food strike for productivity).
- **Idle (labour):** A worker who is food-fed and, if trained, received their tier luxury assignment for that turn. Only idle workers count toward **available labour** for Production.
- Production uses labour: one labour per resource input consumed by a recipe (e.g. 2 timber → 1 lumber = 2 labour).
- **Military/naval build costs** that consume a peasant from the pool use **headcount**, not idle labour (food strikers remain draftable).
- Total food demand = workers + navy + army.
- **Navy food:** Each ship in the player's fleets consumes **2 food units** per turn (same grain/meat abstraction as military upkeep; see [ships-and-naval.md](ships-and-naval.md) § Ship food upkeep). Deduction order for the Consumption phase: **land military regiments first**, then **navy (all owned ships in all fleets)**, then **workers** (with worker starvation and luxury deduction unchanged). Any `ship_type_id` present in fleet state that is **not** in `ShipEconomyCatalog` is invalid data: the System **must fail** turn resolution (session error) rather than ignore or silently skip.
- **Naval combat:** Navy feeding shortfall uses the **same morale multipliers** as land military feeding shortfall for that player (see [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Consumption): effective naval strength in sea battles is scaled by that multiplier derived from `fullyFedShips / totalShips` for the turn.

---

## Relations

- **Player** → **WorkerPool** (or Population): per-player worker counts by tier.
- Workers consume from Player stockpile. Workers supply labour to production.

---

## Implementation

Data structures in [economy-models.md](../program/economy-models.md). Worker model distinct from Unit; workers live in economy (TDD 04), not unit model (TDD 05). Config is program-level (no JSON rulesets).

**Current scope:** Food and luxury consumption, land military and navy upkeep order, and worker **strike** rules (no removal for missing food) are implemented in `economy_consumption.dart` and `worker_economy.dart` (peasant 1 food unit, trained 2 food units; grain then meat; order land military → navy → workers; worker food priority Masters→Peasants; `WorkerIdleCounts` / `ConsumptionResult.idleLabour`; `resolveProduction` takes post-consumption `idleLabour`). Navy: 2 food units per ship per turn from catalog after land military, before workers. **Luxury consumption:** trained workers deduct tier luxury only when food-fed and assigned a unit; shortage of luxury zeros labour for that tier for that turn.

**Recruit / train / disband (v1):** Costs and semantics in the § Recruiting, Training, and Disbanding section above are authoritative; the worker action cost catalog lives in `colonizethis_data` at program level (no JSON rulesets in v1). `RecruitWorkerOrder` is a new order type validated in the order engine and applied in Build / work **before** `BuildUnitOrder`. Disband is not a queued order; it is applied immediately during the Orders phase by `GameService` (or equivalent) and persists with the player's `WorkerPool`.

---

## Luxury consumption (in scope)

- **Commodity per tier:** Apprentice → 1 refinedSugar; Journeyman → 1 cigars; Master → 1 furHats. Commodity ids per [commodity-catalog.md](commodity-catalog.md).
- **Deduction:** After worker food allocation, the System deducts luxury only for workers who become **idle** (food-fed and assigned a unit). Count per tier = min(food-fed count for that tier, stockpile quantity). Food-unfed trained workers incur **no** luxury deduction.
- **Order:** Masters, then Journeymen, then Apprentices (each tier uses its own commodity).
- **Labour effect:** Effective labour for Production is derived from `WorkerIdleCounts` after Consumption (see Implementation). UI/AI preview uses `effectiveLabourForWorkers` / `previewWorkerIdleLabour` with the same rules, including land military and navy food first when regiment and ship counts are provided.

---

## Acceptance Criteria

- Given a player owns one or more fleets whose `shipTypeIds` entries are all present in `ShipEconomyCatalog` and the player has a non-negative integer quantity of grain and meat in the central stockpile  
  When the System executes the Consumption phase for that player after land military upkeep  
  Then the System deducts **2 food units per ship** (from grain and meat per the same rules as military upkeep) for every ship in those fleets before deducting worker food, and does not reduce any stockpile commodity quantity below zero except by those deductions.

- Given a player's fleet lists a `ship_type_id` that is not a key in `ShipEconomyCatalog`  
  When the System executes the Consumption phase for that player  
  Then the System fails turn resolution with an error (invalid fleet data).

- Given a player has a WorkerPool with non-negative integer counts for each worker tier and a central stockpile as described in [stockpiles-and-production.md](stockpiles-and-production.md)  
  When the System executes the Consumption phase for that player  
  Then the System deducts food from the stockpile for military upkeep first (when applicable), then allocates worker food in priority order **Masters, Journeymen, Apprentices, Peasants**, assigns full rations only (no fractional workers fed), leaves all worker headcounts unchanged, and records **idle** vs **on strike** for labour per the food and luxury rules above.

- Given a player has at least one food-fed trained worker in a tier and a non-negative stockpile quantity of that tier's luxury commodity (refinedSugar, cigars, or furHats respectively)  
  When the System executes the Consumption phase for that player  
  Then the System deducts up to one unit of that luxury per food-fed worker of that tier, not exceeding the food-fed count or the stockpile quantity (e.g. 2 food-fed apprentices and 1 refinedSugar → deduct 1 refinedSugar), and deducts **no** luxury for workers who were not food-fed.

- Given a worker remains in the WorkerPool after Consumption but is **on strike** (insufficient food for a full ration for that worker, or for trained tiers insufficient luxury assignment after food)  
  When the System executes the Production phase for that player  
  Then the System counts that worker's labour contribution as **zero** for that turn while the WorkerPool headcount is unchanged, and Production uses the post-Consumption stockpile and **WorkerIdleCounts** (or equivalent) for the labour budget.

- Given a Great Power player has at least `2` fabric in the stockpile  
  When the System resolves a queued `RecruitWorkerOrder(targetTier: peasant)` for that player in the Build / work phase  
  Then the System deducts `2` fabric from the stockpile, increments `pool.peasants` by `1`, and no stockpile quantity or worker pool count becomes negative.

- Given a Great Power player has at least `1` peasant in `pool.peasants`, `apprentice_workers` and `sugar_refining` in `techUnlocked`, treasury ≥ `200` ducats, and `paper` ≥ `2` in the stockpile  
  When the System resolves a queued `RecruitWorkerOrder(targetTier: apprentice)` for that player in the Build / work phase before any `BuildUnitOrder`  
  Then the System deducts `200` ducats from treasury, deducts `2` paper from the stockpile, decrements `pool.peasants` by `1`, and increments `pool.apprentices` by `1`.

- Given a Great Power player has at least `1` peasant, `trained_journeymen` and `cigar_production` in `techUnlocked`, treasury ≥ `500` ducats, and `paper` ≥ `5` in the stockpile  
  When the System resolves a queued `RecruitWorkerOrder(targetTier: journeyman)` for that player in the Build / work phase  
  Then the System deducts `500` ducats from treasury, deducts `5` paper from the stockpile, decrements `pool.peasants` by `1`, and increments `pool.journeymen` by `1`.

- Given a Great Power player has at least `1` peasant, `master_artisans` and `hat_production` in `techUnlocked`, treasury ≥ `1000` ducats, and `paper` ≥ `10` in the stockpile  
  When the System resolves a queued `RecruitWorkerOrder(targetTier: master)` for that player in the Build / work phase  
  Then the System deducts `1000` ducats from treasury, deducts `10` paper from the stockpile, decrements `pool.peasants` by `1`, and increments `pool.masters` by `1`.

- Given a Great Power player has `pool.peasants == P` and a set of pending orders in `currentOrders` that would consume `R` peasants in total (worker recruit / train + military / naval builds, excluding civilian builds) such that `R == P`  
  When the player attempts to queue another order that consumes a peasant  
  Then the System rejects the new order with reason `Insufficient workers` and `pool.peasants` is unchanged.

- Given a Great Power player has `pool.journeymen ≥ 1`  
  When the player applies a disband action for one journeyman during the Orders phase  
  Then the System immediately decrements `pool.journeymen` by `1`, increments `pool.peasants` by `1`, does not enqueue any order in `currentOrders`, and does not refund any prior treasury, paper, or fabric cost.

- Given a Great Power player is in the Orders phase, holds `pool.journeymen ≥ 1`, has `master_artisans` and `hat_production` in `techUnlocked`, treasury ≥ `1000` ducats, and `paper` ≥ `10` in the stockpile  
  When the player applies disband on one journeyman and then queues `RecruitWorkerOrder(targetTier: master)`, then ends the turn  
  Then after Orders the journeyman count is `−1` and peasants `+1` (immediate), and after Build / work the master count is `+1`, peasants is `−1` (returning to its pre-disband value), treasury is `−1000` ducats, and paper is `−10`.

- Given a Great Power player does not have the target tier's required techs in `techUnlocked`  
  When the player or AI attempts to queue or suggest a `RecruitWorkerOrder` targeting that tier  
  Then the System rejects the order with reason `Required technology not unlocked` and does not modify treasury, stockpile, or worker pool.
