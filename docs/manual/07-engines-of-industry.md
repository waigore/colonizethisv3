# The Engines of Industry

## Purpose

A **Great Power** is a playable nation. The **New World** is the colonial map. **Extraction** is the raw goods that reach your warehouse after you confirm **Next turn**. **Production** is the screen and the later step that turns those raw goods into finished goods. A **recipe** is one finished good and the inputs it needs. Without industry, armies lack arms and the New World stays a quarry without a forge. This chapter covers the one shared warehouse, the recipes you can run, and `GAME20001` **Production screen**.

## How it is done

### The warehouse of the realm

1. Every Great Power has **one central warehouse**. Goods are not stored separately in each province. Extraction and later trade fills land there; feeding people and industry draw from there.
2. After you confirm **Next turn**, the game first brings in new goods, then turns gold and similar riches into treasury, then feeds people, then runs industry. Riches become treasury before industry runs. During feeding, armies eat first, then fleets, then workers. Only workers who were fed (and trained workers who also received their luxury) can staff industry that turn, so **Labour this turn** is honest. **Idle labour** means workers who were fed (and, if trained, given their luxury) and can staff industry that turn.
3. Warehouse storage has **no upper limit**. Overseas **cargo** still limits how much arrives by sea in a turn — that is a shipping limit, not a shed limit.

Two design notes disagree on preview timing: one lists **Extraction → Riches-to-treasury → Consumption → Production**; the player-facing **Breakdown** table starts with **Pending build costs**, then those same later steps. This handbook does not invent a third order. Do not treat the four-step list as the **Breakdown** column order until those notes are reconciled.

### Opening Production

1. On `GAME10001` **Game screen**, tap the **Production** icon on the left of the map to open `GAME20001` **Production screen**.
2. **Available** is on the left on a wide screen and above **Allocation** on a phone.
3. Food, **Raw Materials**, **Manufactured**, and **Workers** show amounts: for tradeable goods, the painted number is what you can still sell (warehouse minus industry reservations and offers already staged on Trade — Chapter 8). Rest on a tradeable cell (or press and hold) to read that meaning. Tap a tradeable good to open `GAME60001` **Trade screen** on **Market**, focused on that good, without placing a bid or offer for you. **Riches** and **Workers** show the warehouse / pool amount and do not open Trade. A green **+N** or red **−N** appears only when the projected end-of-turn change is not zero.
4. **Labour this turn** sits under the worker ranks.
5. Tap **Labour details** for working vs not-working counts.
6. **Labour Controls** is the hire/train block under that. For hire, train, **Queued: N**, **Disband**, and when new workers staff industry, see Chapter 5 — this chapter only points you to that block.
7. When you have armies or fleets, the forces-food line and **Forces food details** follow.
8. Tap **Breakdown** to open `PROD20001` **Production commodity breakdown dialog**. The title is **Commodity breakdown**. Columns are **Commodity**, **Pending build costs**, **Extraction**, **Riches to treasury**, **Consumption**, **Production**, and **Total**, grouped under Food / Raw materials / Manufactured. Tap **Close** to dismiss. Changing Allocation or **Reset** refreshes an open dialog. The **Total** matches the Available **+N** / **−N** (or hides the change when the net is zero).
9. **Allocation** (right on a wide screen, below **Available** on a phone): one row per recipe. Set **desired output** with the slider or − / + / maximize / clear. Each unlocked row states how many whole batches you can still ask for this turn and what limits that cap (for example, “Up to 12, limited by Timber”). Locked recipes show `(locked)` and omit the cap line. Hover or long-press the cap line for a note that the number is what remains after other recipes, not your whole warehouse. Labour warnings appear when idle labour or materials cannot cover the ask.
10. After you confirm **Next turn**, the game tries to make that many whole batches from the warehouse and from workers who can work that turn. Tap **Reset** to clear every recipe. While the game is carrying out the turn, do not edit Allocation, **Reset**, **Breakdown**, or **Labour Controls**. You may still open `GAME90001` **Counsel screen** to read advice; Apply / Agree stay hidden until edits are allowed again.

### Industry Counsel (`GAME90001`)

1. From Production Allocation, tap **Counsel** in the header or a starred row’s counsel star to open `GAME90001` **Counsel screen** on the Industry tab. Counsel also has **Military** and **Development** tabs; Industry is the tab you land on from Production.
2. The vizier lists up to three ranked cards: make a good, train workers, or send you to improve land that supplies a missing input. The advice uses the same everyday industry signals rivals use for ordinary production — not the extra wartime shortcuts only they get.
3. On a make-a-good card, tap **Apply recommended industry allocation** to write that full set of desired outputs; recipes not in that set keep the numbers you already set.
4. On a train card, tap **Agree** to queue one hire of that rank when you can still afford it.
5. On a missing-input card, tap **Open Development** to open `GAME80001` **Development screen**; that tap does not assign improve work.
6. Empty counsel shows **No pressing industry advice this turn.**

The same `GAME90001` **Counsel screen** also hosts a **Trade** tab when opened from `GAME60001` **Trade screen** — see Chapter 8 for Apply/Agree on trade advice.

### Recipes you can run

| Output | Typical inputs | Labour / unit | Notes |
|--------|----------------|---------------|--------|
| Lumber | timber ×2 | 2 | Roads, ports, builds |
| Fabric (wool) | wool ×2 | 2 | Always available |
| Fabric (cotton) | cotton ×2 | 2 | Needs **Cotton Weaving** (Chapter 9); the row stays visible and shows **(locked)** until then |
| Cast iron | iron ×2 | 2 | Civilian builds |
| Steel | iron ×1, coal ×1 | 2 | Rails and later industry |
| Paper | timber ×2 | 2 | |
| Bronze | copper ×1, tin ×1 | 3 | Uses 3 labour even though it has two inputs |
| Refined sugar / cigars / fur hats | Sugar Cane / tobacco / furs ×2 | 2 | Luxuries / trade goods |

Whole runs only — if materials or labour run short, industry completes as many full batches as possible and stops. Peasant 1, Apprentice 4, Journeyman 6, Master 8 labour per turn, but only if that worker was fed — and a trained worker also received refined sugar, cigars, or fur hats. Missing food or luxury means 0 labour from that worker; they stay in the pool. Production uses idle labour; it does **not** remove workers from the capital pool.

## Counsel

**Counsel.** Hark, my liege: when stars mark Allocation rows, open Industry Counsel. Tap **Apply recommended industry allocation** only when you want those recipe amounts written for you; tap **Agree** on a train card only when you mean to hire. You may still move the sliders afterward.

**Tip.** Read the Available **+N** / **−N** after you set Allocation. If feeding people will eat your food, next turn’s labour for crafts collapses even when the warehouse looks full today.

**Warning.** The cotton-fabric row stays on Allocation with **(locked)** until you research **Cotton Weaving**. Do not plan a cotton industry on the wool row alone.

## The other courts

Rival Great Powers assign work only to recipes they can actually run, under the same labour limit you see after feeding people. A chosen **leader** changes how boldly they lean toward trade goods or cargo ships — not how you win. Expect industrial rivals to improve the land that feeds their forges early, and to keep cargo ships home when they lean toward trade. They do not get extra wartime production shortcuts beyond what Industry Counsel shows you.

## Consequences

- Ignoring Production while expanding extraction floods the warehouse with raw goods that never become build materials.
- Asking for more batches than idle labour or inputs can cover wastes the turn’s craft window; asking for too little leaves workers idle while rivals forge ahead.
- Cutting improved tiles off from the capital (Chapter 6) starves Extraction first, then starves industry — the Production screen cannot invent timber that never arrives.

## Acceptance criteria for this chapter

- [x] Explains the one shared unbounded warehouse and next-turn order in player words (riches to treasury, then feeding, then industry).
- [x] Documents `GAME20001` / `PROD20001` flows: Available (sellable amount for tradeable goods, tap opens Trade Market), labour readiness, Allocation, desired output, bottleneck, Reset, Breakdown columns.
- [x] Documents `GAME90001` **Counsel screen** Industry tab: stars entry, **Apply recommended industry allocation**, **Agree** on train cards, **Open Development**.
- [x] Lists the recipes you can run now, with Cotton Weaving gating cotton fabric.
- [x] States the whole-batch rule and labour ranks without removing workers from the capital pool.
- [x] Sources match the chapter coverage map (unique path bullets; empire buttons, Cotton Weaving, industry counsel ranking included).

## Sources

- `SPEC/game/stockpiles-and-production.md`
- `SPEC/game/production-recipes.md`
- `SPEC/game/commodity-catalog.md`
- `SPEC/game/workers-and-population.md`
- `SPEC/game/tech-tree-new-world.md`
- `SPEC/program/orders.md`
- `SPEC/program/economy-models.md`
- `SPEC/program/order-projections.md`
- `SPEC/program/industry-counsel-ranking.md`
- `SPEC/program/trade-counsel-ranking.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/production-commodity-breakdown-dialog.md`
- `SPEC/ui/counsel-panel.md`
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/economy-planner.md`
- `SPEC/ai/growth-stage-planner.md`
