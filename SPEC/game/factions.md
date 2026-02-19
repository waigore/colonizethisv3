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

**Timing:** At the start of each Combat phase (see [turn-resolution-phases.md](../program/turn-resolution-phases.md)), compute `maxGreatPowerMilitaryLevel` from all Great Powers. For every Minor Nation and Tribe, set `effectiveMilitaryLevel = maxGreatPowerMilitaryLevel`. The combat resolver reads this when computing defender strength. Parity affects **defence and recruitment quality**, not army count caps or general bonuses.

> **REQUIRES CLARIFICATION:** How "upgraded in-place" works. Imp2 does not have minor parity upgrades. Specifically: (a) Do existing regiment units transform to higher-era equivalents within their category, or is only the combat stat lookup changed? (b) If units transform, what happens to partially damaged units? (c) Are recruit templates regenerated each Combat phase or cached?

---

## Tribe

- **Region:** New World only. Their provinces **do not count toward victory**.
- **Can:** Own provinces; have capital (assigned at game setup; must be located for diplomacy); have **primitive** military (no firearms, cavalry, or artillery in baseline; no forts); **defend** when invaded; participate in **trade**; be **targets** of diplomacy (overtures, Join Empire / colony). Reactive only.
- **Cannot:** Win the game; submit orders; initiate attacks; build units or research; own ships. Can be invaded without declaration of war by Great Powers (unless another GP has invested in the province).
- **Capital:** Assigned at game setup (any owned province; sea-bound not required).

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

Extraction and ownership apply per faction; only Great Powers have stockpiles and receive extraction in the economy phase. Minors and Tribes' production may feed trade/market per economy spec.
