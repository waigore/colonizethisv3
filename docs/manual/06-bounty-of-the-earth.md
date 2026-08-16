# Bounty of the Earth

## Purpose

Tiles feed your warehouses only when people on the map improve them, bind them with roads and ports, and keep them linked to your **capital** (your home city). An **improvement** is a farm, mine, or similar site on a resource tile. **Extraction** is the goods that reach you after you confirm **Next turn**. A **decree** is an action you choose on your turn. This chapter shows how to send **civilians** (map workers such as Builders and Engineers) to raise those sites, what the work costs, and why a rich-looking tile can still send you nothing.

## How it is done

These paths are not the same tap sequence. Use the one that matches the screen you are on.

### Assign from the civilian panel (pick a tile on the map)

1. On `GAME10001` **Game screen**, tap the **Civilian Units** icon on the left of the map to open `UNIT10001` **Civilian units panel**.
2. Tap **Assign** on an idle civilian (no pending work).
3. Choose the printed work name from the menu (**Build improvement**, **Upgrade town**, **Build road**, and the rest that unit can do). Greyed names have no legal tile this turn.
4. The map marks legal tiles with a flashing yellow outline. The tile you rest on uses an orange outline. The banner at the top reads **Select a tile, or click cancel**. While you rest on a legal tile, that banner also shows the material or treasury cost and whether you can still pay it after other work you already staged this turn (**Can afford**, or a short shortfall). Free work (**Explore**, **Prospect**) shows no cost chips.
5. Tap a legal tile to stage the work — you do not need a second confirm. You see the result after you confirm **Next turn**, not when you tap.

If the civilian is not already on the work tile, the game moves them first after you confirm **Next turn**, then they do the work. New goods do not arrive the moment you tap. The warehouse updates on a **later** turn, after the work finishes and the land is still linked to your capital.

### Assign from a province (the tile is already chosen)

1. Tap a province to open `MAP20001` **Province sea-zone overlay**.
2. Use a printed shortcut when it is shown: **Build improvement**, **Build road**, **Build port**, **Build railroad**, **Purchase land** on the Tile rows; **Build fort** on the Military row when the town tile is selected; **Upgrade town** on the Political row when your province can still rise.
3. That opens `UNIT10001` **Civilian units panel** filtered to the matching unit type. Tap **Assign** on an idle unit. The work is staged on the **exact tile you already selected**. Do not pick a tile on the map after this shortcut.

Shortcut hints use the same cost preview when the control is enabled, or a materials/treasury shortfall when it is disabled because you cannot pay.

**Upgrade town** on `MAP20001` is for **your** provinces only (**Town development** **N of 4**, and a short gist of manufacturing thresholds at levels 2 and 4). From **Assign** on a Builder you can still name a foreign Minor Nation or Tribe town when you are at peace and have an embassy there — that path is the menu, not a button on `MAP20001`. Ownership does not change.

### Assign from the tile ring

1. Right-click a tile on `MAP10001` **Empire overview / map area** (or press and hold on a touch screen) to open `MAP30001` **Tile context radial**.
2. On a small screen, or after **More**, `MAP30002` **More tile actions** opens instead.
3. Enabled **Explore**, **Prospect**, or **Build improvement** uses the same civilian-panel shortcut as `MAP20001`: you still tap **Assign** on a unit; you do not pick the tile again.

### Assign from Development (one tap, no map pick)

1. Tap the **Development** icon on the left of the map to open `GAME80001` **Development screen**.
2. Use **Old World** / **New World** tabs. The overview shows extraction totals, idle Builder and Engineer counts, and assigned civilians (Builders and Engineers with pending or in-progress work in the active region, with the same remaining-turns wording as `UNIT10001`).
3. Tap **Assign** on an improvable resource row. That stages improve-work itself. **Assign** is disabled when you have no idle Builder, the target is not valid, or materials are short (the overview also warns of a shortage).
4. The first idle Builder in a fixed list order is used. Among eligible tiles, the game prefers land still linked to your capital, then a lower improvement level, then a fixed tile order.
5. When the chosen tile is not linked to your capital, a warn dialog offers **Improve anyway** (improve only), **Road first** (one Engineer **Build road** step toward the capital — no automatic improve), or **Cancel**.

Unrevealed tiles stay hidden. Fogged tiles look faded. Counts and **Assign** use only tiles you already know about.

The header **Counsel** opens `GAME90001` **Counsel screen** on the **Development** tab. **Agree** on a **Build port** card stages one Engineer **Build port** when it is still legal.

### Tile labels on `MAP20001`

The default Tile surface shows **Road / railroad: transport level N** plus the shortcut icons. Tap the transport text, or **Tile details**, for `Port: None` or `Port: Present`, the road caption, and whether the tile is linked to your capital. Do not look for a line named “Port status.”

### Reading Extraction on `MAP20001`

When the Economic section on `MAP20001` **Province sea-zone overlay** shows real numbers (not `???`):

- **Extraction** lists projected goods in a fixed list order (icons + quantities).
- **Available** below it counts improvable resource tiles in that province — not the same as transported yield or warehouse totals on `GAME20001` **Production screen**.
- **Full yield** — a commodity shows a single number (for example `5 Grain`) when the goods that can reach you equal the tile’s full production under current rules.
- **Partial yield** — when the path or link is weaker than full production, the quantity shows **`effective (full)`** brackets (for example `1 (5) Grain`). Rest on a segment to highlight its tiles on `MAP10001`.
- **Partial-yield reason** — when **any** commodity is partial, one short reason line appears under Extraction: improved tiles are not linked to your capital, or the road/port path is too weak. This is a connectivity cue — not a gathering-tech bug. When all commodities are full-yield or Extraction is empty (`—`), no reason line appears.
- **Capital grain bonus** — when configured, grain may include a separate `incl. +N capital grain bonus` note; that bonus is not tile extraction and does not trigger the partial-yield reason by itself.

Those **Extraction** and **Available** rows **project** what this province would yield from the **current** world — visible immediately on a new game (including starting grain farms). Staging improve, road, or town work mid-turn does **not** change those numbers until after you confirm **Next turn**. Capital link, roads, rails, ports, and town rules that decide the link are Chapter 3; gold and brown discs and the **Highlight land not bound to the capital** hatch stay in Chapter 3.

### Warehouse vs civilian jobs

`GAME20001` **Production screen** shows warehouse amounts and a projected change this turn, including materials already promised to staged work. It is not a list of civilian jobs — those stay on `UNIT10001` **Civilian units panel** and `GAME80001` **Development screen**.

### Work targets by unit

| Work | Unit | Cost and notes |
|------|------|----------------|
| **Build improvement** | Builder | Raises the site by 1 (cap 4) on a tile **with a resource**. Next step costs lumber + cast iron **1 / 4 / 8 / 16**. Next level must respect your gathering-tech limit and terrain hard caps (scrub-forest timber stays at **1**). Minerals must already be prospected. The first improve on some timber or iron tiles can cost less (or nothing) until you already hold lumber and cast iron; the usual pair returns once you can pay it. |
| **Upgrade town** | Builder | Raises **town development** by 1 (cap 4) on the town tile. Overlay **Upgrade town** is owned land only. See Counsel for the National Bureaucracy gate. |
| **Build road** | Engineer | **1 lumber + 1 cast iron**. Level 2 needs **Road Construction**. |
| **Build port** | Engineer | **5 lumber + 5 cast iron**. One port per seaboard (each coast that faces one sea). Shortcut only on a seaboard tile that can still take a port. |
| **Build fort** | Engineer | Town tile only; levels 1–3. **3 lumber + 3 bronze**; then **4 lumber + 4 bronze** plus **Mine Engineering**; then **5 steel + 5 lumber** plus **Modern Forts**. Higher levels take extra turns. Overlay **Build fort** only when the town tile is selected. |
| **Build railroad** | Rail Builder | Needs a primitive or improved road (transport **1** or **2**), **2 lumber + 2 steel**, and rail technology. Sets railroad transport level **4**. |
| **Purchase land** | Merchant | On Minor Nation or Tribe resource tiles: embassy, not at war, not already bought by any playable nation. Treasury ≥ **15 × resource base price** at assign; coins leave and the purchase is recorded when the work finishes (**1 turn**). Minerals must be prospected. A tile already bought cannot be bought again. |
| **Explore** / **Prospect** | Explorer | Covered in Chapter 4 (free; completion-timed effects). |

Rejected assigns surface **Insufficient treasury** or **Insufficient materials**.

Pending rows on `UNIT10001` show required cost chips and how many turns remain (pending: total turns; in-progress: remaining / total). Most work takes one or more turns; duration can rise with the target level and terrain. Forts take extra turns at higher levels. **Purchase land** takes **1 turn**. Finishing the last work turn still does not fill the warehouse until a **later** turn’s extraction. **Cancel** of in-progress work sends the civilian back to the tile they left.

### Limits you must respect

- Each civilian may have only **one** pending work decree this turn.
- Two of your Builders, Engineers, or Merchants may not work the same tile at once — the refusal reads **Tile already has development or purchase work for this player**.
- **Cancel** on the civilian panel (confirm first) clears the work; materials already spent are not returned.
- How much a tile **produces** is the smaller of its improvement level and your gathering-tech (and terrain) limit. Those goods **reach you** only if the tile is still linked to your capital. Town development limits yield only in named cases: always in the capital province; elsewhere only when there is no road or rail path, **and** the town is a port linked to the capital. A road or rail path to the capital does **not** apply the town cap. Disconnected improved land sends nothing (Chapter 3 for the hatch). Default gathering limit is often **1** until you research a cap tech; horses stay at 1 and wool at 3.
- On `MAP10001` **Empire overview / map area**, when **Show improvements** is on, your owned, revealed, already-improved tiles can show **1 of 1** (already at the limit) or **1 of 2** (room to raise). Unrevealed tiles show no mark. The marks are not always visible.

## Counsel

**Counsel.** Hark, my liege: a mine without a road is a jewel in a locked chest — connect before you celebrate the yield. When the courts would raise a seaboard port this season, Development Counsel on `GAME90001` **Counsel screen** names the coast in plain speech; Agree only when you mean the Engineer to dig.

**Tip.** The first improve on some timber or iron tiles can cost less (or nothing) until lumber and cast iron sit in the warehouse; do not treat that as a permanent discount.

**Warning.** Cancel is not a loan. Materials spent on abandoned work are gone; plan exclusivity so two Builders do not fight over one tile.

**Note — town upgrade gate.** One cited rule names **National Bureaucracy** at assign for **Upgrade town**. Another cited rule says that gate is **not** enforced in the game as it ships today (all Builders may submit and complete the work). `MAP20001` may still mention the technology on a disabled **Upgrade town**. This handbook does not pick a winner until those rules agree.

**Note — pending costs on `UNIT10001`.** The civilian panel shows required cost chips on pending work. The same cited screen rule both forbids comparing those amounts to your warehouse (no extra error colour) and requires one short shortfall line when the work cannot be paid after earlier staged work. Orders are not auto-cancelled. This handbook does not pick a winner between those two claims.

## The other courts

Rival courts send the same kinds of civilians you do. They raise farms and towns, lay roads and ports, buy foreign land, and lay rail when they can pay. They try to open wool, cotton, timber, and iron sites so their factories have something to work, and they spend lumber and cast iron on improvements when demand rises. They do not get a secret work rule. When their Engineers would raise a seaboard port, the same scoring that fills Development Counsel on `GAME90001` **Counsel screen** is what they use.

## Consequences

- Building past the gathering-tech limit wastes materials for no extra yield. If the map already shows **1 of 1** with **Show improvements** on, do not send a Builder there until a gathering tech raises the cap.
- Ignoring exclusivity and one-work-per-civilian rules floods the panel with rejected orders.
- **Purchase land** refuses **Insufficient treasury** if you cannot pay now. The coins leave only when the purchase finishes, so spending the same purse on something else after you assign can still leave you short when the work completes.
- Disconnecting improved tiles from the capital starves Extraction even when the map looks developed.
- Partial Extraction brackets with a reason line under `MAP20001` mean improved tiles exist but the capital link or road/port path blocks full yield — build the link before you blame the gathering tech.

## Acceptance criteria for this chapter

- [ ] Documents assign flows via `UNIT10001` **Civilian units panel**, `MAP20001` **Province sea-zone overlay** / `MAP10001` **Empire overview / map area**, `MAP30001` **Tile context radial** / `MAP30002` **More tile actions**, and `GAME80001` **Development screen**.
- [ ] Covers printed work names: **Build improvement**, **Upgrade town**, **Build road**, **Build port**, **Build fort**, **Build railroad**, **Purchase land** (explore/prospect cross-ref Ch. 4).
- [ ] States assign-time **Insufficient treasury** / **Insufficient materials** checks and one-work-per-civilian and per-tile exclusivity.
- [ ] Documents **Cancel** without material refund; purchase debit when work finishes.
- [ ] Explains extraction caps and capital link at player level, and points to Chapter 3 for the on-map hatch of land not bound to the capital and for `{n} of {cap}` improvement marks when **Show improvements** is on.
- [ ] Explains `MAP20001` Extraction/Available as a projection from the current world (new-game visible; mid-turn staged work does not change the numbers until after **Next turn**).
- [ ] Distinguishes that line from `GAME20001` **Production screen** stockpile.
- [ ] Explains `MAP20001` Extraction `effective (full)` brackets, capital grain bonus note, and the short partial-yield reason line when connectivity or path limits apply (cross-ref Chapter 3).
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/extraction-and-improvements.md`
- `SPEC/game/tech-and-extraction-cap.md`
- `SPEC/game/civilian-units.md`
- `SPEC/game/capital-and-connectivity.md`
- `SPEC/game/fog-and-exploration.md`
- `SPEC/game/siege-mechanics.md`
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
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/tile-context-radial.md`
- `SPEC/ui/tile-more-actions-dialog.md`
- `SPEC/ai/civilian-work-planner.md`
- `SPEC/ai/growth-stage-planner.md`
- `SPEC/ai/civilian-build-planner.md`
- `SPEC/ai/economy-planner.md`
