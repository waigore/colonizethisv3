# The Pursuit of Knowledge

## Purpose

Technology unlocks better extraction caps, roads and rails, new regiments and ships, civilians such as the Merchant, deeper diplomacy, and even a fourth research seat. Research is how a small realm catches a larger one — or how a rich realm solidifies its lead. This chapter covers research slots, funding, prerequisites, the eight tech branches, and the University bonus.

## How it is done

### Open Technology

1. From **Game screen**, open the Technology route to **Technology screen**.
2. Use the top-bar **Slots** / **Tree** toggle: **Slots** assigns work; **Tree** browses the DAG of prerequisites and effects.

### Research slots

- **Default:** 3 parallel slots. Unlock **University** for a **4th** slot.
- Each slot holds at most one tech (or is empty) with a **funding** preset:

| Preset | Gold / turn | RP / turn |
|--------|-------------|-----------|
| None | 0 | 0 |
| Low | 50 | 100 |
| Medium | 150 | 300 |
| High | 400 | 800 |
| Maximum | 1000 | 2500 |

Efficiency is about 2 RP per gold except Maximum (~2.5). Some military/naval techs gain an extra **Industrial Funding of Research** RP bonus when applicable.

- **RP costs** scale by era/tier roughly 1800 → 3600 (about 6–12 turns at Medium funding per slot). Progress is per tech; completing a tech unlocks its effects immediately into `techUnlocked`.
- **Choose tech** on an empty or reassigned slot lists only **researchable** techs (all prerequisites unlocked). Each row shows the tech name, era/category/RP cost, and **1–2 plain-language effect lines** (what the tech unlocks or improves). Tap **Details** on a row for prerequisites and the full effect list without leaving the picker; tap the row body to assign. A tech cannot start the same turn its prerequisite finishes.
- **Cancel** clears the slot; **all progress on that tech is forfeited** (confirm when progress > 0).
- Slot assignments persist across turns until unlock or cancel. An optional **goal** highlight may sort the Tree for you — it is UI-only and is **not** part of the research order payload.
- **Empty seats and funding None are legal.** You may leave a slot empty or set funding to **None** when gold is needed for builds, recruits, diplomacy, or the market. That is a treasury choice, not a failed order. Ending the turn does **not** warn about unused research seats the way it may list idle civilians — review slots on **Technology screen** when you mean to invest again.
- **Research this turn:** On **Technology screen**, read the line under **Research Slots** — **Research this turn: −£X · +Y RP** — for the empire-wide gold and RP the next End Turn will apply across all funded seats (slots spend in order, so later seats may show no RP when earlier ones already consumed your treasury). When nothing will spend, the panel shows **Research this turn: no spend**. Tap a blocked slot’s gold row or RP delta for the per-slot breakdown. If stationed Spies will speed a seat, that bonus is already inside **+Y RP** and the per-seat **+N RP** number.

### Eight branches (categories)

Browse the Tree by category (filters do not replace prerequisites):

| Branch | Why it matters |
|--------|----------------|
| Gathering / production | Extraction caps and industry-facing unlocks |
| Transport / infrastructure | Higher roads, ports, rails |
| Labour / economy | Worker economy, trade fairs, University slot |
| Diplomacy / civilian | Embassies, Join Empire options, civilian unlocks |
| Naval | Merchant and warship types |
| Military | Infantry, cavalry, artillery unlocks |
| New World | Resource-linked techs; some need Explorer revelations / prospecting first |

Eras (Renaissance → Industrial) are flavour for the chart; they do **not** hard-gate research order beyond each tech’s listed prerequisites. The full catalog is large (~113 techs); chase the unlocks your victory path needs rather than every node.

### Spy insight (optional boost)

Station Spies in rival Great Power provinces from the selected tile’s province panel (**Province sea-zone overlay**) with **Station spy**, then **Relocate** on **Civilian units panel** (Chapter 5), or pick a tile from the units panel **Relocate** path. Presence intel holds while they stay. When a research seat is funded at **Low** or higher, and that rival has already unlocked the tech you are researching, the next End Turn adds about **+15% RP** per such rival (two rivals stack). On **Technology screen**, the green **+N RP** line already includes that bonus. Tap it to open the breakdown; a **Spy insight** line names those courts in plain words (for example **Spy insight — France already knows this (+15%)**). The number uses Spies still in place now — if a Spy is caught before research is applied this turn, the live gain can be a little lower. Counter-espionage on home soil is separate (**Assign** → counter-spy). Do not bet a whole plan on spies alone.

## Counsel

**Counsel.** Hark, my liege: gold spent on research is gold not spent on timber, regiments, or quiet gifts. When the purse is thin, empty seats or funding at **None** are thrift, not shame — but do not sleep forever while rivals climb the tree.

**Tip.** Extraction-cap techs multiply every improved tile you already paid for. Pair Chapter 6 builds with Gathering research.

**Tip.** After a technology completes, open **Technology screen** when you next mean to spend; the court will not interrupt **Next turn** to fill empty seats for you. A funded project you already assigned can appear under **Staged this turn** on **Next turn confirmation**; unused seats still are not listed.

**Warning.** Cancel is permanent for that progress. Re-choosing the same tech starts from zero.

## The other courts

AI research planners fill slots toward military, naval, or economic unlocks matching personality and growth stage . Expect EXPAND-focused rivals to prioritise regiment unlocks and DEVELOP rivals to chase transport and University. Do not assume they research in ToC order.

## Consequences

- Neglecting research freezes extraction caps at defaults while rivals dig deeper on the same terrain.
- Spreading Maximum funding across empty prerequisites wastes gold; deep-funding one critical unlock often wins the decade.
- University’s fourth slot is a force multiplier once the tree fans out — plan labour/economy techs before the mid-game sprawl.
- Pausing research to protect treasury is valid; long pauses still cede relative tech position to rivals who keep funding.
