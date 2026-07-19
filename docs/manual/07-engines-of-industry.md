# The Engines of Industry

## Purpose

Extraction fills your warehouse only with raw plenty. **Production** turns timber into lumber, wool into fabric, and iron into the cast iron that builds roads and ships. Without industry, armies starve of arms and the New World stays a quarry without a forge. This chapter covers your central stockpile, the recipe pipeline, and the Production screen where you set how hard the realm works each turn.

## How it is done

### The warehouse of the realm

1. Every Great Power has **one central stockpile** — commodities are not stored per province. Extraction (and later trade fills) land there; Consumption and Production draw from there.
2. Phase order that shapes next-turn previews: **Extraction → Riches-to-treasury → Consumption → Production**. Gold, silver, gems, diamonds, and spices convert to treasury before industry runs; food and luxuries feed workers first so **idle labour** for crafts is honest.
3. Stockpile storage is **unbounded** by design (no warehouse-full dump). Overseas **cargo** still limits how much arrives by sea in a turn — that is a shipping limit, not a shed limit.

### Opening Production

1. From `GAME10001` **Game screen**, open Production via the empire rail / toolbar route to `GAME20001` **Production screen**.
2. **Available** (left on wide layouts): food, raw materials, manufactured goods, and worker tiers, with projected signed deltas when net change is non-zero. Tap **Breakdown** to open `PROD20001` **Production commodity breakdown dialog** for a read-only deeper view.
3. **Allocation** (right / below): one row per recipe. Set **desired output** with the slider or − / + / maximize / clear. The row shows inputs in parentheses, `max · bottleneck`, and labour warnings when idle labour or materials cannot cover the ask.
4. Desired output is converted to labour assignments for the resolver (`desired × labour per unit`). **Reset** clears allocations. While turn resolution is blocking, treat the panel as read-only.

### Recipes you can run (current product)

| Output | Typical inputs | Labour / unit | Notes |
|--------|----------------|---------------|--------|
| Lumber | timber ×2 | 2 | Roads, ports, builds |
| Fabric (wool) | wool ×2 | 2 | Always available |
| Fabric (cotton) | cotton ×2 | 2 | Needs `cotton_weaving` unlocked |
| Cast iron | iron ×2 | 2 | Civilian builds |
| Steel | iron ×1, coal ×1 | 2 | Rails and later industry |
| Paper | timber ×2 | 2 | |
| Bronze | copper ×1, tin ×1 | 3 | Catalogue exception (labour 3) |
| Refined sugar / cigars / fur hats | cane / tobacco / furs ×2 | 2 | Luxuries / trade goods |

Whole runs only — if materials or labour run short, industry completes as many full batches as possible and stops. Worker tiers supply labour points (Peasant 1, Apprentice 4, Journeyman 6, Master 8 per turn, subject to luxury caps). Production uses idle labour; it does **not** remove workers from the pool.

## Counsel

**Counsel.** Hark, my liege: lumber without timber is a decree written on water — improve and connect feedstock tiles before you crank the Allocation sliders to the stop.

**Tip.** Read the Available deltas after you set Allocation. If Consumption will eat your food, Production labour collapses next turn even when the warehouse looks full today.

**Warning.** Tech-gated recipes (cotton fabric) stay silent until researched. Do not plan a cotton empire on the wool row alone.

## The other courts

Rival Great Powers run an **economy planner** that assigns labour to feasible recipes under the same effective-labour cap, biased by personality and growth stage (`SPEC/ai/economy-planner.md`, `SPEC/ai/growth-stage-planner.md`). Expect industrial rivals to lock feedstock early and to prefer cargo when their agendas lean trader.

## Consequences

- Ignoring Production while expanding extraction floods the stockpile with raw goods that never become build materials.
- Over-allocating past idle labour or inputs wastes the turn’s craft window; under-allocating leaves Workers idle while rivals forge ahead.
- Disconnecting improved tiles (Chapter 6) starves Extraction first, then starves industry — the Production screen cannot invent timber that never arrives.

## Acceptance criteria for this chapter

- [ ] Explains central unbounded stockpile and Extraction → Riches → Consumption → Production order.
- [ ] Documents `GAME20001` / `PROD20001` flows: Available, Allocation, desired output, bottleneck, Reset.
- [ ] Lists current-product recipes with tech gate on cotton fabric.
- [ ] States whole-run rule and labour tiers without WorkerPool headcount drain.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/stockpiles-and-production.md`
- `SPEC/game/production-recipes.md`
- `SPEC/game/commodity-catalog.md`
- `SPEC/game/workers-and-population.md`
- `SPEC/program/orders.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/economy-models.md`
- `SPEC/program/order-projections.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/production-commodity-breakdown-dialog.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/economy-planner.md`
- `SPEC/ai/growth-stage-planner.md`
