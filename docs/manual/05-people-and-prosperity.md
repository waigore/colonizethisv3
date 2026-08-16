# People and Prosperity

## Purpose

**Workers** are people in your capital who run industry. They are not pieces on the map. The work they give each turn is **labour**. The **labour pool** is that capital count — not civilians you place on the map. A **decree** is an action you choose on your turn. This chapter separates that capital labour pool from **civilian units** on the map, then shows how to recruit, train, and disband workers on `GAME20001` **Production screen** and how to raise civilians from `UNIT10001` **Civilian units panel**. Empty factories and hungry trained workers lose you goods; rivals who train Explorers and Builders while you do not will map and improve land first.

## How it is done

### Worker tiers (not map units)

1. On `GAME10001` **Game screen**, tap the **Production** icon on the left of the map to open `GAME20001` **Production screen**.
2. Use the worker grid and **Labour Controls** there.

Workers live only in the labour pool on `GAME20001` **Production screen**. They never appear on the map. The four ranks, from cheapest labour to most, are **Peasant**, **Apprentice**, **Journeyman**, and **Master**.

| Tier | Labour / turn | Food | Luxury (trained workers) |
|------|---------------|------|--------------------------|
| Peasant | 1 | 1 grain **or** meat | — |
| Apprentice | 4 | 1 grain + 1 meat | refined sugar |
| Journeyman | 6 | 1 grain + 1 meat | cigars |
| Master | 8 | 1 grain + 1 meat | fur hats |

Higher ranks eat more. Trained workers (Apprentice, Journeyman, Master) also need their luxury in full. After you confirm **Next turn**, armies and fleets eat before workers do. Only workers who were fed (and, if trained, given their luxury) add labour that turn. Unfed workers, or trained workers who miss their luxury, **do not work** that turn (they stay in the pool). When food is short, Masters eat first and Peasants last. A trained worker who missed food does not take a luxury that turn.

The **Labour this turn** line under the worker grid shows how much labour you will have after everyone eats. It counts food and luxuries that arrive this turn, not only what you already have stored. When some workers will not work, a short reason names the main shortage (food, or a luxury). Tap **Labour details** for working vs not-working counts on each rank. The line only informs; it does not buy food, change Allocation, or disband anyone for you.

### Recruit, train, and disband

On `GAME20001`, use **Labour Controls** under that labour line. Each row shows the printed cost (peasant **Fabric ×2**; trained rows **£… + Paper ×N + 1 peasant**), how much labour that worker gives, and what food or luxury they eat. If **+** will not press, rest on it (pointer) to read why — treasury, materials, peasants already promised, or technology. New workers add labour on a **later** turn, not the turn you queue them.

1. Tap **+** on **Recruit peasant** or on a trained-tier **Train** row. That queues the training. After you confirm **Next turn**, the game carries it out. There is **no** direct promotion from apprentice to journeyman or journeyman to master: training always consumes **one peasant**. Tap **−** to take back the last queued hire of that rank. When a rank has queued hires, the row shows **Queued: N**.
2. Printed costs:

| Target | Cost |
|--------|------|
| Peasant (Recruit) | Fabric ×2 |
| Apprentice | £200 + Paper ×2 (consumes 1 peasant) |
| Journeyman | £500 + Paper ×5 (consumes 1 peasant) |
| Master | £1000 + Paper ×10 (consumes 1 peasant) |

3. Locked trained rows need both technologies: Apprentice needs Apprentice Workers and Sugar Refining; Journeyman needs Trained Journeymen and Cigar Production; Master needs Master Artisans and Hat Production. Locked rows print **Requires:** with those names until you research them.
4. Peasants already promised to queued worker training or to army/navy training are not free to spend again. Training a civilian (Explorer, Builder, and the rest) does **not** spend a peasant.
5. **Disband** on a trained row happens as soon as you tap it: that tier −1, peasants +1, **no refund**. It is not queued for later. Peasant rows have no **Disband**.

Reject reasons you may see: **Insufficient workers**, **Insufficient materials**, **Insufficient treasury**, **Required technology not unlocked**.

**Timing note:** New workers you queue this turn do not staff factories on the same **Next turn**. Plan one turn ahead.

### Civilian roster and training

Civilians are people you place on the map. They explore, improve land, and post Spies. Workers decide how much you can make this turn; civilians are how you work the map.

1. On `GAME10001` **Game screen**, tap the **Civilian Units** icon on the left of the map to open `UNIT10001` **Civilian units panel**.
2. Tap **Train** to open `UNIT40001` **Train civilians dialog**. Each row shows a short role line under the type name:

| Unit | Role line | Train cost | Unlock |
|------|-----------|------------|--------|
| Explorer | Explores provinces · Prospects minerals | £1,000 + 2 paper | Available from the start |
| Builder | Improves tiles · Upgrades towns | £1,000 + 2 paper | Available from the start |
| Engineer | Builds roads, ports, and forts | £1,000 + 2 paper | Available from the start |
| Spy | Holds foreign intel · Counter-espionage at home | £2,000 + 4 paper | Available from the start |
| Merchant | Purchases land in Minor/Tribe provinces | £2,000 + 4 paper | **Requires: Merchant Companies** |
| Rail Builder | Upgrades roads to railroad | £2,000 + 4 paper | **Requires: Early Steam Engine** |

Set the **+** counts, then close the dialog (tap outside, or go back). There is no **Confirm** button. **Reset** (if shown) clears the counts. The remaining treasury and paper line updates as you change the counts. Locked rows show **Requires:** with the technology name.

Training queues civilian training. After you confirm **Next turn** and the game finishes that turn, the new units appear on your **capital** tile (worker training is carried out first, then civilians appear). Use the panel thereafter to select units, assign work (Chapters 4 and 6), or relocate Spies.

**Spies — station and relocate.** Tap a province to open `MAP20001` **Province sea-zone overlay**. In the **Civilian** section, tap **Station spy** when it is enabled, then tap **Relocate** on an idle Spy. That queues the Spy to walk to the tile you already selected, without picking again on the map. The Spy arrives after you confirm **Next turn**. You can still open `UNIT10001` and tap **Relocate** to pick any legal land tile.

**Station spy** is hidden on a sea zone, on an unrevealed (`???`) tile, when you cannot act, or when your Spy is already on that tile and no other Spy can move there. It is visible but disabled when no idle Spy can take the tile, or the tile cannot be occupied (the hints distinguish those). It is enabled when at least one idle Spy can occupy the selected tile.

**Assign** still offers **Counter-espionage** on owned provinces only. An idle Spy on foreign land shows **Holding intel: {province}**. An idle Spy on land you own shows **Reserve**. Leaving when yours is the last Spy there warns that full intel will fog after the turn ends. `DLG60001` **Next turn confirmation** does not list idle Spies — stationing is a chosen post, not wasted capacity.

## Counsel

**Counsel.** Hark, my liege: peasants are coin and fabric made flesh — spend them on Masters only when food, luxuries, and paper already flow.

**Tip.** Disband before a lean turn if luxuries will fail; a Master who does not work that turn contributes no labour and still eats.

**Warning.** Military and naval training compete for the same promised peasants as labour training. A parade of regiments can leave your Production queue short of peasants even when the pool looks full.

## The other courts

Rival courts assign labour and raise peasants when they can pay the cost, and they honour the same peasant-promise rule you do. They keep enough Explorers, Builders, and Engineers to keep working the map, and they train more Merchants when they are grabbing land or more Engineers and Rail Builders when they are improving roads. They do not get a secret labour rule.

## Consequences

- Under-recruiting peasants caps Production even with rich recipes unlocked.
- Over-training Masters without food and luxury chains leaves trained workers who do not work that turn, and wasted treasury.
- Ignoring civilian training leaves exploration and improvements to rivals who did not.
- Same-turn expectation that new recruits staff factories leads to empty Production surprises.

## Acceptance criteria for this chapter

- [ ] Distinguishes worker pool (`GAME20001`) from civilian map units (`UNIT10001`).
- [ ] Documents peasant→master tiers, food/luxury, recruit/train costs and tech gates.
- [ ] Documents immediate disband (no refund) vs queued Recruit / Train (results after **Next turn**).
- [ ] Documents peasant reservation vs military/naval builds.
- [ ] Documents `UNIT40001` civilian train roster and capital spawn timing.
- [ ] Documents `MAP20001` **Station spy** then `UNIT10001` **Relocate**, plus map Relocate pick and that `DLG60001` **Next turn confirmation** does not list idle Spies.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/workers-and-population.md`
- `SPEC/game/civilian-units.md`
- `SPEC/game/stockpiles-and-production.md`
- `SPEC/program/orders.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/turn-resolution-phase-details.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/train-civilians-dialog.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/next-turn-confirmation.md`
- `SPEC/ai/economy-planner.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/civilian-build-planner.md`
