# Factions

**SPEC/game** — Faction types and capabilities. Baseline: Imperialism II. World model: [world-model.md](world-model.md). Turn resolution: [turn-resolution-phases.md](../program/turn-resolution-phases.md).

---

## Faction

A **faction** is an entity that owns provinces (in any region) and has a defined role. There are three types: **Great Power**, **Minor Nation**, and **Tribe**. Only Great Powers submit orders and can win the game.

---

## Great Power

- **Count:** Configurable per game (default 6). Human players only ever play Great Powers.
- **Can:** Win the game; submit all orders (movement, build, research, diplomacy, trade, etc.); initiate attacks; conduct great-power diplomacy (e.g. absorb Minor Nations and Tribes); expand territory; own provinces in Old World and New World; have capital (set in capital-choice phase), stockpile, workers, military, navy; research technology.
- **Cannot:** (Nothing within the rules.)
- **Capital:** Chosen in capital-choice phase (sea-bound province + tile). See [capital-choice-phase.md](capital-choice-phase.md).

---

## Minor Nation

- **Region:** Old World only. Their provinces **count toward victory** (for whoever controls them).
- **Can:** Own provinces; have capital (assigned at game setup); have military and forts; **defend** when their provinces are attacked; participate in **trade** (offer connected resources); be **targets** of diplomacy (overtures, Join Empire). Reactive only — they do not submit orders.
- **Cannot:** Win the game; submit orders; initiate attacks or declare war; build units or research (no order phase); own ships (no navy).
- **Capital:** Assigned during game setup (any owned province; sea-bound not required), not by player choice.

**Minor military parity:** Old World minor nations are difficult to conquer and automatically keep pace with the most advanced Great Power. Define a global **military level** (1–4) as the highest regiment era currently available to **any** Great Power (from [military-units.md](military-units.md) and tech). A minor nation's **effective military level** is set to this maximum, not the average.

**Timing:** In the **Minor Regiment Upgrade** phase (see [turn-resolution-phases.md](../program/turn-resolution-phases.md)), which runs after Movement and before all combat phases, compute `maxGreatPowerMilitaryLevel` from all Great Powers using post-Research buildable land regiment tiers. For every **Old World Minor Nation**, set `effectiveMilitaryLevel = maxGreatPowerMilitaryLevel`. Tribes do **not** receive parity (see Tribe section). Parity affects **defence and recruitment quality**, not army count caps or general bonuses.

**Upgrading in place:** If minor nations' **land regiments** are eligible for upgrade due to change in **effective military level**, their existing regiments become higher-tier versions in place. Damaged regiments stay damaged. This phase is distinct from combat resolution and has no combat effects other than ensuring parity-adjusted regiment tiers are in place before naval and land combat.

---

## Tribe

- **Region:** New World only. Their provinces **do not count toward victory**.
- **Can:** Own provinces; have capital (assigned at game setup; must be located for diplomacy); have **primitive** military (no firearms, cavalry, or artillery in baseline; no forts); **defend** when invaded; participate in **trade**; be **targets** of diplomacy (overtures, Join Empire / colony). Reactive only.
- **Cannot:** Win the game; submit orders; initiate attacks; build units or research; own ships. Can be invaded without declaration of war by Great Powers (unless another GP has invested in the province).
- **Capital:** Assigned at game setup (any owned province; sea-bound not required).
- **Military level:** Tribes have **no military parity**. They are meant to be easily conquered by Great Powers. Their **effective military level** is always **1** (capped). During the Minor Regiment Upgrade phase, the System sets each Tribe's `effectiveMilitaryLevel` to 1, regardless of Great Power tech.

---

## Summary

| Capability        | Great Power | Minor Nation | Tribe   |
|-------------------|-------------|--------------|--------|
| Can win           | Yes         | No           | No     |
| Submit orders     | Yes         | No           | No     |
| Own provinces     | Yes (OW+NW) | Yes (OW)     | Yes (NW) |
| Capital           | Choice phase| Setup        | Setup  |
| Initiate attack   | Yes         | No           | No     |
| Defend            | Yes         | Yes          | Yes    |
| Provinces count to victory | OW yes | Yes (for controller) | No |

Extraction and ownership apply per faction. Great Powers extract into their `Player.stockpile` via `computeExtraction` in the Extraction phase. Minor Nations and Tribes do not have a `Player.stockpile`; their extraction is computed by a parallel non-GP function whose per-faction totals feed the World Market phase as system-authored offers (see [extraction-and-improvements.md](extraction-and-improvements.md) § Non-Great-Power extraction (Minor Nations and Tribes) and [world-market.md](world-market.md) § Minor and tribe auto-sell).

---

## Starting developed resources (Minor Nations and Tribes)

To allow Minors and Tribes to participate in the world market from turn 1 (see [world-market.md](world-market.md) and [program/game-setup-pipeline.md](../program/game-setup-pipeline.md)), the System pre-develops a small fixed number of resource tiles in each Minor Nation's and Tribe's **capital province** during game setup.

**Rule.** For every Minor Nation and Tribe `F` whose capital tile is set:

- Let `R` be `F`'s capital region (`oldWorld` for Minor Nations, `newWorld` for Tribes).
- Let `P` be `F`'s capital province in `R` (i.e. `F.capitalProvinceId`).
- Let `K` be the per-capital developed-tile count. **Default `K = 2`**; rulesets may override (see [ruleset-config.md](ruleset-config.md)).
- The System selects up to `K` **eligible** tiles in `P` and sets each tile's extraction improvement level to **1** (improvement level after setup).

**Tile eligibility.** A tile is **eligible** when **all** of the following hold:

- The tile lies inside `P` (grid cell equals `P`'s local id).
- The tile is **not** `F`'s capital tile and is **not** any province's `townTileKey` (see § Town/capital tile occupancy in [tile-map-and-generation.md](tile-map-and-generation.md)).
- The tile has a non-null terrain.
- The tile has a non-null **resource** id (terrain-allowed resource per [resource-terrain-region-rules.md](resource-terrain-region-rules.md); not stripped by §7d.strip).
- The tile's current extraction improvement level is `0` (no pre-existing improvement).

**Selection order (deterministic).** Eligible tiles are ranked by **Manhattan distance** from `F`'s capital tile (`|x - cap.x| + |y - cap.y|`), then **y ascending**, then **x ascending**. The System takes the first `min(K, number_of_eligible_tiles)` tiles. When fewer than `K` eligible tiles exist (small or resource-sparse provinces), the System develops every eligible tile and does not raise an error.

**Effects.**

- For each selected tile, the System sets `tileState.improvementLevel(tileKey) = 1`. **Terrain** and **resource** values on the tile are **unchanged** (the setup does not synthesize new resources or change terrain — it only develops resources already present on the map).
- The selected tiles' resource ids must be the same as the underlying tile map cell.

**Out of scope for this rule.** Connectivity from developed tiles to the Minor/Tribe capital (roads, ports), the extraction pipeline accepting non-Great-Power faction ids, and auto-offer generation onto the world market are all defined elsewhere ([capital-and-connectivity.md](capital-and-connectivity.md), [extraction-and-improvements.md](extraction-and-improvements.md), [world-market.md](world-market.md)) and tracked as separate work. This rule only ensures the starting **developed** state of Minor and Tribe resource tiles is well-defined and deterministic at game setup time.

---

## Acceptance Criteria

- Given a new game is created with at least one Great Power, one Minor Nation, and one Tribe configured in the ruleset  
  When the System runs the game-setup pipeline per [game-setup.md](game-setup.md)  
  Then the System creates Faction records for each configured Great Power, Minor Nation, and Tribe, assigns them the correct faction type, and sets their capabilities (such as ability to submit orders, own provinces in specific regions, and win the game) according to the summary table in this document.

- Given Movement has completed in turn resolution and the Minor Regiment Upgrade phase has not yet run  
  When the System runs the Minor Regiment Upgrade phase per [turn-resolution-phases.md](../program/turn-resolution-phases.md)  
  Then the System scans all Great Powers’ buildable **land regiment** types per [military-units.md](military-units.md) and current turn tech state, derives the highest available regiment era as `maxGreatPowerMilitaryLevel`, sets each **Old World Minor Nation** `effectiveMilitaryLevel` to that value, and sets each **Tribe** `effectiveMilitaryLevel` to **1** (no parity) before any naval or land combat phase starts.

- Given a Minor Nation's `effectiveMilitaryLevel` increases because `maxGreatPowerMilitaryLevel` increased during the Minor Regiment Upgrade phase  
  When the System applies parity upgrades for that faction in that phase  
  Then the System upgrades each eligible **land regiment** to the appropriate higher-tier version while preserving any existing damage on that regiment, so parity affects unit quality but not unit counts or general bonuses.

- Given a new game in which a Minor Nation `M` is assigned a capital in an Old World province `P` and `P` contains at least `K = 2` resource-bearing land tiles outside `M`'s capital tile and `P`'s `townTileKey`  
  When the System runs the game-setup pipeline per [game-setup.md](game-setup.md) and applies the § Starting developed resources rule  
  Then the System selects exactly `2` eligible tiles in `P` ranked by Manhattan distance from `M`'s capital tile (tie-break `y` ascending, then `x` ascending), sets `tileState.improvementLevel` for each selected tile to `1`, and does not modify those tiles' terrain or resource id.

- Given a new game in which a Tribe `T` is assigned a capital in a New World province `Q` and `Q` contains at least `K = 2` resource-bearing land tiles outside `T`'s capital tile and `Q`'s `townTileKey`  
  When the System runs the game-setup pipeline and applies the § Starting developed resources rule  
  Then the System selects exactly `2` eligible tiles in `Q` ranked by Manhattan distance from `T`'s capital tile (tie-break `y` ascending, then `x` ascending), sets `tileState.improvementLevel` for each selected tile to `1`, and does not modify those tiles' terrain or resource id.

- Given a Minor Nation or Tribe `F` whose capital province `P` contains **fewer than** `K = 2` eligible tiles (e.g. a small province with at most one non-town/non-capital resource tile)  
  When the System applies the § Starting developed resources rule for `F`  
  Then the System develops every eligible tile in `P` (possibly zero) by setting `tileState.improvementLevel` to `1` for each, does not raise an error, and does not develop any tile outside `P`.

- Given a Minor Nation or Tribe `F` whose `capitalTile` is `null` (e.g. setup did not assign one)  
  When the System applies the § Starting developed resources rule  
  Then the System makes no improvement-level change for any tile belonging to `F` and leaves `tileState` unchanged for those tiles.

- Given a new game where each Minor Nation and each Tribe receives `K = 2` developed tiles in its capital province per § Starting developed resources  
  When the System collects every capital tile and every `townTileKey` in both regions  
  Then **none** of those capital/town tiles is among the developed tiles selected by this rule and **none** of them has its `tileState.improvementLevel` raised above `0` by this rule.
