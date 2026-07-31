# People and Prosperity

## Purpose

Labour is the quiet engine of empire. **Workers** in your capital labour pool staff Production; **civilian units** on the map explore, build, spy, trade, and lay rail. This chapter separates those two populations, teaches Recruit/Train and Disband, and shows how to raise the civilian roster from the units panel.

## How it is done

### Worker tiers (not map units)

Workers live only in the labour pool shown on **Production screen**. They never appear as map tokens.

| Tier | Labour / turn | Food | Luxury (all-or-nothing) |
|------|---------------|------|-------------------------|
| Peasant | 1 | 1 grain **or** meat | — |
| Apprentice | 4 | 1 grain + 1 meat | refined sugar |
| Journeyman | 6 | 1 grain + 1 meat | cigars |
| Master | 8 | 1 grain + 1 meat | fur hats |

Higher tiers eat more and demand luxuries. Unfed or luxury-starved workers may **strike** (0 labour that turn) but remain in the pool. Consumption runs in the resolved turn **before** Production uses idle labour.

### Recruit, train, and disband

On **Production screen**, use **Labour Controls**:

1. **Recruit peasant** or **Train** a higher tier — both queue a recruit or train worker decree for **Build/work**. There is **no** direct tier-to-tier promotion: train always consumes **one peasant** from the reserved pool.
2. Costs (v1 catalog — treat as fixed until a ruleset ships otherwise):

| Target | Cost |
|--------|------|
| Peasant (Recruit) | fabric ×2 |
| Apprentice | £200 + paper ×2 (consumes 1 peasant) |
| Journeyman | £500 + paper ×5 (consumes 1 peasant) |
| Master | £1000 + paper ×10 (consumes 1 peasant) |

3. **Tech gates** (both techs required): Apprentice → `apprentice_workers` + `sugar_refining`; Journeyman → `trained_journeymen` + `cigar_production`; Master → `master_artisans` + `hat_production`. Locked tiers show as locked in the panel until researched.
4. **Peasant reservation:** available peasants = pool peasants minus pending consumes from recruit/train **and** military/naval builds. Civilian unit builds do **not** consume peasants.
5. **Disband** a trained worker is an **immediate Orders-phase** action: that tier −1, peasants +1, **no refund**. It is not queued for Build/work.

Reject reasons you may see: **Insufficient workers**, **Insufficient materials**, **Insufficient treasury**, **Required technology not unlocked**.

**Timing note:** Recruits that complete in Build/work do **not** feed the same turn’s Production labour — Consumption and Production already ran earlier in that resolved turn. Plan one turn ahead.

### Civilian roster and training

Civilians are map units. Open **Civilian units panel** from the left empire rail, then **Train** to open **Train civilians dialog**.

| Unit | Train cost (approx.) | Unlock notes |
|------|----------------------|--------------|
| Explorer, Builder, Engineer | £1000 + 2 paper | Available from the start |
| Spy, Merchant, Rail Builder | £2000 + 4 paper | Spy/Merchant/Rail Builder need their starting or tech unlocks (e.g. Merchant Companies, Early Steam Engine) |

Training queues a build decree. Units appear at the **capital tile** after **Build/work** resolves (after recruit/train workers in that phase). Use the panel thereafter to select units, assign work (Chapters 4 and 6), or relocate Spies.

**Spies — station and relocate.** On **Civilian units panel**, an idle Spy shows **Relocate** to pick a legal foreign (or own) land tile on the map; **Assign** still offers **counter-espionage** on owned provinces only. While a Spy holds a foreign province, status reads **Holding intel**; leaving when yours is the last Spy there warns that full intel will fog after the turn ends. End-turn confirmation does **not** nag idle Spies — stationing is strategic portfolio, not wasted capacity.

## Counsel

**Counsel.** Hark, my liege: peasants are coin and fabric made flesh — spend them on Masters only when food, luxuries, and paper already flow.

**Tip.** Disband before a lean turn if luxuries will fail; a striking Master contributes nothing and still eats.

**Warning.** Military and naval training compete for the same peasant reservation as labour training. A parade of regiments can starve your Production queue of peasants even when the pool looks full.

## The other courts

AI economies allocate production labour and may recruit peasants when cast-iron labour bottlenecks appear . Growth-stage planners raise worker-growth pressure when labour sits below maturity targets, which boosts fabric-related production and feedstock Builder routing . Civilian build planners keep Explorer/Builder/Engineer floors and phase-bias the roster (colonial Explorer+Merchant; develop Engineer+Rail Builder) . They respect the same peasant reservation rules you do.

## Consequences

- Under-recruiting peasants caps Production even with rich recipes unlocked.
- Over-training Masters without food/luxury chains creates strikes and wasted treasury.
- Ignoring civilian training leaves exploration and improvements to rivals who did not.
- Same-turn expectation that new recruits staff factories leads to empty Production surprises.
