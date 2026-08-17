# The Pursuit of Knowledge

## Purpose

Technology raises what your land can produce, opens better roads and railroads, unlocks new regiments and ships, adds civilians such as the Merchant, deepens diplomacy, and can open a fourth research seat. A **research slot** (also called a **seat** — same thing) is one place that can work on a single technology at a time. **Funding** is how much gold that seat spends each turn to earn research points (**RP**). An **extraction cap** is the highest improvement level your current knowledge allows on a resource tile. **University** is the labour technology that opens the fourth seat. Research is how a small realm catches a larger one — or how a rich realm keeps its lead. This chapter covers seats, funding, prerequisites, the Tree’s category colours and icons, and University.

## How it is done

### Open Technology

1. On `GAME10001` **Game screen**, tap the **Technology** icon on the left of the map. That opens `GAME40001` **Technology screen**.
2. Use the top-bar **Slots** / **Tree** toggle: **Slots** assigns work; **Tree** shows the full chart of technologies and which ones must be finished before others can start.

### Research slots

- The Slots tab always shows **four** cards. You begin with **three** active seats. Until you unlock **University**, the fourth card is locked: header **Slot 4 (University)**, footnote **Requires University tech**, and no **Cancel** or **Choose tech**. After University, that card is a normal **Slot 4**.
- Slots opens on **Researched Techs** first (chips for what you already know), then **Research Slots** below the divider.
- Each active seat holds at most one technology (or is empty) with a **funding** preset:

| Preset | Gold / turn | RP / turn |
|--------|-------------|-----------|
| None | 0 | 0 |
| Low | 50 | 100 |
| Medium | 150 | 300 |
| High | 400 | 800 |
| Maximum | 1000 | 2500 |

Efficiency is exactly **2.0** RP per gold at Low, Medium, and High, and **2.5** at Maximum. Once **Industrial Funding of Research** is unlocked, **every** military or naval technology gains **+20%** RP (rounded down) on top of the funding preset.

- **RP costs** by tier are exactly **1800 / 2400 / 3000 / 3600** (about **6 / 8 / 10 / 12** turns at Medium’s 300 RP per turn). Progress is per technology. When research finishes, you see the unlock after you confirm **Next turn** — spend, RP, and unlocks apply in the Research step of that turn, after production, consumption, diplomacy, and spy work. There is no extra “apply effects” tap once that turn finishes.
- **Choose tech** on an empty or reassigned seat lists only technologies you can research now (all listed prerequisites finished), that you have not unlocked yet, and that are not already in another seat. Each row shows the name, era/category/RP cost, and **1–2** plain-language effect lines. Tap **Details** for prerequisites and the full effect list; tap the row body to assign. A new assignment starts at **Medium**. Five funding toggles print **None, Low, Medium, High, Maximum**. If nothing qualifies, the list shows **No techs available to research**. A technology cannot start the same turn its prerequisite finishes.
- **Cancel** clears the seat and **forfeits all progress** on that technology. The game asks for confirm only when that technology already has progress.
- Seat assignments stay across turns until unlock or cancel. The Tree has no goal-highlight control for the player to use.
- **Empty seats and funding None are legal.** You may leave a seat empty or set funding to **None** when gold is needed for builds, recruits, diplomacy, or the market. That is a treasury choice, not a mistake. Ending the turn does **not** warn about unused research seats the way it may list idle civilians — review seats on `GAME40001` when you mean to invest again.
- **Research this turn:** On `GAME40001` **Slots**, under **Research Slots**, read **Research this turn: −£X · +Y RP** for the empire-wide gold and RP the next **Next turn** will apply across all funded seats (seats spend in order). When nothing will spend, the panel shows **Research this turn: no spend**. Tap the green **+N RP** control when it is shown to open the per-seat breakdown. That control is hidden when funding is **None** or the spend is blocked. When a later seat is blocked because earlier seats already used the treasury, read the greyed gold row’s plain-language hint and the header totals. If stationed Spies will speed a seat, that bonus is already inside **+Y RP** and the per-seat **+N RP** number.
- Research spend may use a debt floor: treasury may not go below **0** with no qualifying labour tech, **−500** with **Money Lending**, or **−1000** with **Money Lending** and **Banking**. A later seat can show no RP when the walk would push past that floor.

### Categories on the Tree

The Tree is one scrollable chart. Nodes are colour-coded and show a category icon. There are **no** category filter controls. Tap any node (including locked ones) for name, era, category, RP cost, prerequisites, and effects. When a technology is ready to research and you have an empty seat, tap **Research this** on that dialog to seat it at **Medium** without leaving the Tree. If every seat is full, choose which seat to replace (the same forfeit warning as **Cancel** appears when that seat already has progress). Funding and **Cancel** still live on **Slots**.

The Tree’s colours and icons mark these groups (civilian and diplomacy use separate icons on the chart; the catalog docs also name seven research groups that cover the same unlocks):

| Group (Tree colour / icon) | Why it matters |
|--------|----------------|
| Gathering | Higher extraction caps and related production unlocks |
| Transport | Higher roads and railroads (and the Rail Builder); ports are not unlocked by this branch |
| Labour | Worker economy, trade fairs, University’s fourth seat |
| Civilian | Civilian unlocks such as Merchant paths |
| Diplomacy | Embassies, Join Empire options, and related court unlocks |
| Naval | Merchant and warship types |
| Military | Infantry, cavalry, artillery unlocks |
| New World | Resource-linked techs; some need Explorer revelations or prospecting first |

Eras (Renaissance through Industrial) label the chart. They do not block research by themselves; each technology still waits only on the prerequisites listed on it. The full catalog has exactly **113** technologies; chase the unlocks your victory path needs rather than every node.

### Spy insight (optional boost)

A **Great Power** is a playable nation. **New World** is the second map (colonies and new resources).

To station a Spy in a rival Great Power’s land: select a rival land tile → on `MAP20001` **Province sea-zone overlay**, Civilian **Station spy** → on `UNIT10001` **Civilian units panel**, tap **Relocate** (that shortcut commits that tile), **or** use **Relocate** on the units panel then pick a tile. While a Spy stays in foreign land, status shows **Holding intel**.

When a research seat is funded at **Low** or higher, and that rival has already unlocked the technology you are researching, the next **Next turn** adds about **+15% RP** per such rival (two rivals stack). On `GAME40001` **Slots**, the green **+N RP** line already includes that bonus. Tap it for the breakdown; a **Spy insight** line names those courts (for example **Spy insight — France already knows this (+15%)**). The number uses Spies still in place after spy work that turn — if a Spy is caught before research applies, the live gain can be a little lower.

Home **Counter-espionage** is separate: on **owned** land, **Assign** then the **Counter-espionage** work. It does not grant the research bonus. Do not bet a whole plan on spies alone.

## Counsel

**Counsel.** Hark, my liege: gold spent on research is gold not spent on timber, regiments, or quiet gifts. When the purse is thin, empty seats or funding at **None** are thrift, not shame — but do not sleep forever while rivals climb the tree.

**Tip.** Extraction-cap techs multiply every improved tile you already paid for. Pair Chapter 6 builds with Gathering research.

**Tip.** After a technology completes, open `GAME40001` **Slots** when you next mean to spend; the court will not interrupt **Next turn** to fill empty seats for you. A funded project you already assigned can appear under **Staged this turn** on `DLG60001` **Next turn confirmation**; unused seats still are not listed.

**Warning.** Cancel is permanent for that progress. Re-choosing the same technology starts from zero.

## The other courts

Rival courts also fill research seats and spend gold on funding. They keep work already started (they may set funding to **None** if they cannot afford more). They spread new work across naval and transport, military, gathering and labour, and New World and diplomacy rather than climbing the catalog from top to bottom. They tend to use one funding level across seats, and they spend less when at war or when Old World expansion is stalled.

## Consequences

- Neglecting research freezes extraction caps at defaults while rivals dig deeper on the same terrain.
- Putting **Maximum** on several seats that still wait on unfinished prerequisites burns gold without finishing work.
- University’s fourth seat matters more once many technologies are open at once — labour techs that unlock it repay attention before the chart fans out widely.
- Pausing research to protect treasury is valid; long pauses still cede relative tech position to rivals who keep funding.

## Acceptance criteria for this chapter

- [x] Documents `GAME40001` Slots/Tree, four slot cards with Slot 4 locked until University, funding presets, Choose tech rules, and cancel forfeiture.
- [x] Explains listed prerequisites, researchable-only choose list, and exact RP cost tiers (1800 / 2400 / 3000 / 3600) at player level.
- [x] Summarizes Tree colour/icon category groups (no filters) and New World discovery prerequisites without inventing a single branch count that fights the SPECs.
- [x] Does not document an unavailable Tree goal control; mentions spy insight on the Slots **+N RP** preview and RP breakdown.
- [x] States that empty seats / funding None are legal strategic thrift and that end-turn does not warn about unused research capacity.
- [x] Explains the **Research this turn** header on Slots, **+N RP** breakdown entry, sequential multi-seat funding honesty, and the research debt floor.
- [x] Sources match the chapter coverage map.

## Sources

- `SPEC/game/tech-tree.md`
- `SPEC/game/tech-tree-gathering.md`
- `SPEC/game/tech-tree-transport.md`
- `SPEC/game/tech-tree-labour-economy.md`
- `SPEC/game/tech-tree-diplomacy-civilian.md`
- `SPEC/game/tech-tree-naval.md`
- `SPEC/game/tech-tree-military.md`
- `SPEC/game/tech-tree-new-world.md`
- `SPEC/game/research-state.md`
- `SPEC/game/tech-and-extraction-cap.md`
- `SPEC/program/orders.md`
- `SPEC/program/research-resolution.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/ui/technology-panel.md`
- `SPEC/ui/tech-tree-widget.md`
- `SPEC/ui/next-turn-confirmation.md`
- `SPEC/ui/ux-design-decisions.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ui/civilian-units-panel.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/empire-buttons.md`
- `SPEC/ai/ai-architecture.md`
