# Bounty of the Earth

## Purpose

Tiles feed the realm only when civilians improve them, bind them with roads and ports, and keep them inside your capital’s reach. This chapter covers assigning **civilian work decree** targets from the map and civilian panel, cost checks at assign time, exclusivity rules, cancelling work, and the tech caps that limit how much a tile may yield.

## How it is done

### Where you assign work

1. Open **Civilian units panel** and select a civilian, **or** select a province on **Empire overview / map area** / **Province sea-zone overlay** and use Economic / tile shortcuts (e.g. **Build improvement**), **or** open **Development screen** from the empire rail for empire-wide improvable tiles and one-tap **Assign**.
2. Choose a work target; the map highlights valid tiles (flashing selection affordances on **Empire overview / map area**).
3. Confirm the assignment in the Orders phase. Materials and treasury affordability are checked **at assign**; for most builds, stockpile materials are reserved/deducted when Build/work applies the order. Rejected assigns surface messages such as **Insufficient treasury** or **Insufficient materials**.
4. The unit may need to **move** to the work tile in **Movement**; work then ticks in **Build/work**. New extraction yields appear in later turns’ **Extraction** phase once improvements exist and connectivity allows.

**Production screen** shows your empire stockpile, queued recipes, and pending material costs for work you have staged. ****Development screen** Development** lists improvable resource tiles across your owned provinces and purchased land (Old World / New World tabs), with an extraction overview and idle Builder/Engineer counts. The panel map respects fog of war (unrevealed tiles stay hidden; fogged tiles are muted) and outlines your land territory; commodity counts and **Assign** only consider tiles you have seen. The overview also lists **assigned civilians** — Builders and Engineers with pending or in-progress work in the active region, with the same turn-progress wording as the Civilian units panel. **Assign** commits a pending `build_improvement` on the best eligible tile (connected tiles preferred). When the chosen tile is not linked to your capital, a warn dialog offers **Improve anyway**, **Road first** (commits one Engineer `build_road` step toward the capital — no automatic improve), or **Cancel**. ****Province sea-zone overlay** Economic** **Extraction** and **Available** rows are different: they **project** what this province would yield from the **current post-resolution world state** — visible immediately on a new game (including bootstrap grain farms), not only after an Extraction phase has run. Staging improve, road, or town draft orders mid-turn does **not** change Extraction or Available until turn resolution applies them. Display-only: your stockpile still receives commodities when the Extraction phase runs .

### Reading Extraction on **Province sea-zone overlay**

When Economic full intel is available on **Province sea-zone overlay**, the **Extraction** condensed line lists projected commodity yields in fixed catalog order (icons + quantities). **Available** below it counts improvable resource tiles in that province — not the same as transported yield or empire stockpile totals on **Production screen**.

- **Full yield** — a commodity shows a single number (e.g. `5 Grain`) when effective extraction equals full tile production under current rules.
- **Partial yield** — when path or connectivity caps effective below full production, the quantity shows **`effective (full)`** brackets (e.g. `1 (5) Grain`). Hover a segment to highlight its contributing tiles on **Empire overview / map area**.
- **Partial-yield reason** — when **any** commodity is partial, one **muted reason line** appears immediately under the Extraction line: improved tiles are not linked to your capital, or the road/port path is too weak. This is a connectivity and transport cue — not a tech-cap bug. When all commodities are full-yield or Extraction is empty (`—`), no reason line appears.
- **Capital grain bonus** — when configured, grain may include a separate muted `incl. +N capital grain bonus` annotation; that bonus is not tile extraction and does not trigger the partial-yield reason by itself.

Capital link, roads, rails, ports, and town rules that decide connectivity are Chapter 3; map **gold vs brown extraction discs** on **Empire overview / map area** are Chapter 3 as well.

### Work targets by unit

| Target | Unit | Player notes |
|--------|------|----------------|
| `build_improvement` | Builder | Raises improvement level by 1 (cap 4) on a tile **with a resource**; lumber + cast iron cost rises with level (pairs such as 1/4/8/16 — ruleset-backed). Next level must respect **tech extraction cap** and terrain hard caps (e.g. scrub timber max 1). Minerals must already be prospected. |
| `upgrade_town` | Builder | Raises province **town development** by 1 (cap 4) on the town tile. Spec may later require `national_bureaucracy`; **current product** allows any Builder to submit and complete this work. |
| `build_road` | Engineer | Lumber + cast iron; higher road levels need Road Construction tech. |
| `build_port` | Engineer | Larger lumber + cast iron cost; one port per seaboard province rules apply. |
| `build_fort` | Engineer | Fortification build per siege/military improvement rules. |
| `build_rail` | Rail Builder | Needs appropriate road level; consumes lumber + steel; raises transport level. |
| `purchase_land` | Merchant | On Minor/Tribe resource tiles: embassy, not at war, not already purchased; treasury ≥ **15 × resource base price** checked at assign; **debit and purchase record at completion** (1 turn). Minerals must be prospected. |
| `explore` / `prospect` | Explorer | Covered in Chapter 4 (free; completion-timed effects). |

### Limits you must respect

- **One pending civilian work decree per civilian unit per turn.**
- **Per-tile exclusivity:** at most one of your Builder/Engineer/Merchant development or purchase works (pending or in progress) on a given tile — else **Tile already has development or purchase work for this player**.
- **Cancel** in-progress or pending work from the civilian panel (confirm dialog): the order clears; **materials already spent are not refunded**.
- Extraction yield is bounded by `min(improvement level, tech cap, transport/town caps where applicable)`, connectivity to the capital, and prospecting for minerals. Default tech cap is often **1** until cap techs unlock; design exceptions include horses (cap 1) and wool (cap 3) — see . Capital grain may include a scenario **+5 grain/turn** bonus when configured.

Work completes in **Build/work**; do not expect the improvement to extract on the same click.

## Counsel

**Counsel.** Hark, my liege: a mine without a road is a jewel in a locked chest — connect before you celebrate the yield.

**Tip.** Assign costs bite at commit time. If lumber or cast iron is short, cancel other builds or wait a Production turn rather than scattering half-finished sites.

**Warning.** Cancel is not a loan. Materials spent on abandoned work are gone; plan exclusivity so two Builders do not fight over one tile.

## The other courts

AI **civilian-work-planner** scores Builder improvement/town work, Engineer road/port/fort, Merchant purchases, and Rail Builder jobs in one pass, with feedstock and mineral prospect boosts . Growth-stage routing sends Builders toward wool/cotton/timber/iron feedstock tiles . Civilian build planners keep Builder/Engineer floors while DEVELOP phases favor Engineer and Rail Builder . Economy planners push domestic lumber and cast iron when improvement demand rises .

## Consequences

- Building past the tech extraction cap wastes materials for no extra yield.
- Ignoring exclusivity and one-work-per-unit rules floods the panel with rejected orders.
- Purchasing land without embassy or while at war fails at assign; waiting until completion to check treasury causes surprise shortfalls if you spend elsewhere the same turn.
- Disconnecting improved tiles from the capital starves Extraction even when the map looks developed.
- Partial Extraction brackets with a reason line under **Province sea-zone overlay** mean improved tiles exist but capital link or road/port transport limits block full yield toward your stockpile — build connectivity before you blame the tech cap.
