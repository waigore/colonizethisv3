# Bounty of the Earth

## Purpose

Tiles feed the realm only when civilians improve them, bind them with roads and ports, and keep them inside your capital’s reach. This chapter covers assigning **WorkOrder** targets from the map and civilian panel, cost checks at assign time, exclusivity rules, cancelling work, and the tech caps that limit how much a tile may yield.

## How it is done

### Where you assign work

1. Open `UNIT10001` **Civilian units panel** and select a civilian, **or** select a province on `MAP10001` / `MAP20001` and use Economic / tile shortcuts (e.g. **Build improvement**, **Build road** / **Build port** on the Road / transport row — Port status **None** or **Present** is under **Tile details**, not the default Tile column — **Build fort** on the Military fort row when the town tile is selected, **Purchase land** on the Tile **Resource** row for Minor/Tribe tiles), **or** use **Upgrade town** on the Political **Town development** row when your province can still rise (opens `UNIT10001` in Builder-only shortcut mode), **or** open `GAME80001` **Development** from the empire rail for empire-wide improvable tiles and one-tap **Assign**.
2. Choose a work target; the map highlights valid tiles (flashing selection affordances on `MAP10001`). While you hover a valid tile, the selection banner shows **material or treasury cost** and whether you **can afford** it after other pending work already staged this turn. **`MAP20001` Build improvement**, **Build road**, **Build port**, **Build fort**, **Purchase land**, and **Upgrade town** shortcut tooltips include the same cost hint when enabled, or a plain materials/treasury shortfall when disabled for affordability. The Political row also shows **N of 4** and a short gist of manufacturing thresholds (bonus at levels 2 and 4).
3. Confirm the assignment in the Orders phase. Materials and treasury affordability are checked **at assign**; pending rows on `UNIT10001` show required costs and a **muted shortfall line** when that order cannot be afforded after earlier pending work (orders are not auto-cancelled). For most builds, stockpile materials are reserved/deducted when Build/work applies the order. Rejected assigns surface messages such as **Insufficient treasury** or **Insufficient materials**.
4. The unit may need to **move** to the work tile in **Movement**; work then ticks in **Build/work**. New extraction yields appear in later turns’ **Extraction** phase once improvements exist and connectivity allows.

`GAME20001` **Production** shows your empire stockpile, queued recipes, and pending material costs for work you have staged. `GAME80001` **Development screen** lists improvable resource tiles across your owned provinces and purchased land (Old World / New World tabs), with an extraction overview and idle Builder/Engineer counts. The header **Counsel** opens `GAME90001` on the **Development** tab for ranked **Build port** advice aligned with the same Engineer scoring the courts use — tap **Agree** to stage one Engineer port work order when it is still legal. The panel map respects fog of war (unrevealed tiles stay hidden; fogged tiles are muted) and outlines your land territory; commodity counts and **Assign** only consider tiles you have seen. The overview also lists **assigned civilians** — Builders and Engineers with pending or in-progress work in the active region, with the same turn-progress wording as the Civilian units panel. **Assign** commits a pending `build_improvement` on the best eligible tile (connected tiles preferred). When the chosen tile is not linked to your capital, a warn dialog offers **Improve anyway**, **Road first** (commits one Engineer `build_road` step toward the capital — no automatic improve), or **Cancel**. **`MAP20001` Economic** **Extraction** and **Available** rows are different: they **project** what this province would yield from the **current post-resolution world state** — visible immediately on a new game (including bootstrap grain farms), not only after an Extraction phase has run. Staging improve, road, or town draft orders mid-turn does **not** change Extraction or Available until turn resolution applies them. Display-only: your stockpile still receives commodities when the Extraction phase runs (see `SPEC/ui/province-economic-extraction-available.md`).

### Reading Extraction on `MAP20001`

When Economic full intel is available on `MAP20001`, the **Extraction** condensed line lists projected commodity yields in fixed catalog order (icons + quantities). **Available** below it counts improvable resource tiles in that province — not the same as transported yield or empire stockpile totals on `GAME20001`.

- **Full yield** — a commodity shows a single number (e.g. `5 Grain`) when effective extraction equals full tile production under current rules.
- **Partial yield** — when path or connectivity caps effective below full production, the quantity shows **`effective (full)`** brackets (e.g. `1 (5) Grain`). Hover a segment to highlight its contributing tiles on `MAP10001`.
- **Partial-yield reason** — when **any** commodity is partial, one **muted reason line** appears immediately under the Extraction line: improved tiles are not linked to your capital, or the road/port path is too weak. This is a connectivity and transport cue — not a tech-cap bug. When all commodities are full-yield or Extraction is empty (`—`), no reason line appears.
- **Capital grain bonus** — when configured, grain may include a separate muted `incl. +N capital grain bonus` annotation; that bonus is not tile extraction and does not trigger the partial-yield reason by itself.

Capital link, roads, rails, ports, and town rules that decide connectivity are Chapter 3; map **gold vs brown extraction discs** on `MAP10001` are Chapter 3 as well.

### Work targets by unit

| Target | Unit | Player notes |
|--------|------|----------------|
| `build_improvement` | Builder | Raises improvement level by 1 (cap 4) on a tile **with a resource**; lumber + cast iron cost rises with level (pairs such as 1/4/8/16 — ruleset-backed). Next level must respect **tech extraction cap** and terrain hard caps (e.g. scrub timber max 1). Minerals must already be prospected. |
| `upgrade_town` | Builder | Raises province **town development** by 1 (cap 4) on the town tile. Requires **National Bureaucracy** at assign. Use **Upgrade town** on `MAP20001` Political when shown, or Assign from `UNIT10001`. |
| `build_road` | Engineer | Lumber + cast iron; higher road levels need Road Construction tech. |
| `build_port` | Engineer | Larger lumber + cast iron cost; one port per seaboard province rules apply. |
| `build_fort` | Engineer | Fortification build per siege/military improvement rules. |
| `build_rail` | Rail Builder | Needs appropriate road level; consumes lumber + steel; raises transport level. |
| `purchase_land` | Merchant | On Minor/Tribe resource tiles: embassy, not at war, not already purchased; treasury ≥ **15 × resource base price** checked at assign; **debit and purchase record at completion** (1 turn). Minerals must be prospected. |
| `explore` / `prospect` | Explorer | Covered in Chapter 4 (free; completion-timed effects). |

### Limits you must respect

- **One pending WorkOrder per civilian unit per turn.**
- **Per-tile exclusivity:** at most one of your Builder/Engineer/Merchant development or purchase works (pending or in progress) on a given tile — else **Tile already has development or purchase work for this player**.
- **Cancel** in-progress or pending work from the civilian panel (confirm dialog): the order clears; **materials already spent are not refunded**.
- Extraction yield is bounded by `min(improvement level, tech cap, transport/town caps where applicable)`, connectivity to the capital, and prospecting for minerals. Default tech cap is often **1** until cap techs unlock; design exceptions include horses (cap 1) and wool (cap 3) — see `SPEC/game/tech-and-extraction-cap.md`. Capital grain may include a scenario **+5 grain/turn** bonus when configured.

Work completes in **Build/work**; do not expect the improvement to extract on the same click.

## Counsel

**Counsel.** Hark, my liege: a mine without a road is a jewel in a locked chest — connect before you celebrate the yield. When the courts would raise a seaboard port this season, Development Counsel on `GAME90001` names the coast in plain speech; Agree only when you mean the Engineer to dig.

**Tip.** Assign costs bite at commit time. If lumber or cast iron is short, cancel other builds or wait a Production turn rather than scattering half-finished sites.

**Warning.** Cancel is not a loan. Materials spent on abandoned work are gone; plan exclusivity so two Builders do not fight over one tile.

## The other courts

AI **civilian-work-planner** scores Builder improvement/town work, Engineer road/port/fort, Merchant purchases, and Rail Builder jobs in one pass, with feedstock and mineral prospect boosts (`SPEC/ai/civilian-work-planner.md`). Growth-stage routing sends Builders toward wool/cotton/timber/iron feedstock tiles (`SPEC/ai/growth-stage-planner.md`). Civilian build planners keep Builder/Engineer floors while DEVELOP phases favor Engineer and Rail Builder (`SPEC/ai/civilian-build-planner.md`). Economy planners push domestic lumber and cast iron when improvement demand rises (`SPEC/ai/economy-planner.md`).

## Consequences

- Building past the tech extraction cap wastes materials for no extra yield.
- Ignoring exclusivity and one-work-per-unit rules floods the panel with rejected orders.
- Purchasing land without embassy or while at war fails at assign; waiting until completion to check treasury causes surprise shortfalls if you spend elsewhere the same turn.
- Disconnecting improved tiles from the capital starves Extraction even when the map looks developed.
- Partial Extraction brackets with a reason line under `MAP20001` mean improved tiles exist but capital link or road/port transport limits block full yield toward your stockpile — build connectivity before you blame the tech cap.

## Acceptance criteria for this chapter

- [ ] Documents assign flows via `UNIT10001`, `MAP20001` / `MAP10001`, and `GAME80001` Development.
- [ ] Covers work targets: improvement, town, road, port, fort, rail, purchase_land (explore/prospect cross-ref Ch. 4).
- [ ] States assign-time Insufficient treasury/materials checks and one-order / per-tile exclusivity.
- [ ] Documents cancel without material refund; purchase_land debit-at-completion.
- [ ] Explains extraction caps / tech caps and connectivity dependency at player level.
- [ ] Explains `MAP20001` Extraction/Available as post-resolution projection from current world state (new-game visibility, mid-turn draft orders unchanged until resolution).
- [ ] Distinguishes province-overlay Extraction/Available from stockpile-centric `GAME20001` Production.
- [ ] Explains `MAP20001` Extraction `effective (full)` brackets, capital grain bonus annotation, and the muted partial-yield reason line when connectivity or path limits apply (cross-ref Chapter 3).
- [ ] Notes current-product deferral of `national_bureaucracy` for `upgrade_town`.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/extraction-and-improvements.md`
- `SPEC/game/tech-and-extraction-cap.md`
- `SPEC/game/civilian-units.md`
- `SPEC/game/capital-and-connectivity.md`
- `SPEC/game/fog-and-exploration.md`
- `SPEC/program/orders.md`
- `SPEC/program/development-resolution.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/province-extraction-snapshot.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/province-economic-extraction-available.md`
- `SPEC/ui/map-widget.md`
- `SPEC/ui/development-panel.md`
- `SPEC/ui/counsel-panel.md`
- `SPEC/program/development-counsel-ranking.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/civilian-build-planner.md`
- `SPEC/ai/economy-planner.md`
