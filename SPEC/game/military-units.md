# Military Units (Land)

**SPEC/game** — Full Imperialism II regiment roster. Tactical stats for combat. Reference: Imperialism II 05-units-military. Combat: [combat.md](combat.md). Siege: [siege-mechanics.md](siege-mechanics.md). Civilian units: [civilian-units.md](civilian-units.md). Naval: [ships-and-naval.md](ships-and-naval.md). Generals and armies: [military-generals.md](military-generals.md).

---

## Overview

Land military forces consist of **regiments** and **generals**. Regiments are organized into 8 categories across 4 eras. Each regiment has tactical stats (FPN, FPM, RNG, DEF, MVR) used for auto-resolve and Quick Battle. Tech unlocks determine which types a Great Power can build; older types are replaced within their category.

**Regiment buildability:** A regiment type is **buildable** iff the player has researched the **tech that unlocks that regiment** (per [tech-tree-military.md](tech-tree-military.md)). There is **no era gate**: if the unlocking tech is in the player's techUnlocked set, that regiment can be built regardless of era. Build validation (order engine) and recruitment UI must consult the tech catalog.

**Minor military parity:** `maxGreatPowerMilitaryLevel` is derived from the set of regiment types any Great Power can build (e.g. the highest era among those types). Each Minor Nation and Tribe's `effectiveMilitaryLevel` is set to this maximum at the start of the Combat phase (see [factions.md](factions.md)).

---

## Tactical Stats

| Stat | Meaning |
|------|---------|
| **FPN (Firepower)** | Ranged attack strength. |
| **FPM (Melee)** | Melee attack when adjacent. |
| **RNG (Range)** | Max tiles to fire. Emplaced artillery +1. |
| **DEF (Defence)** | Durability; effect ∝ DEF/9. |
| **MVR (Movement)** | Tactical movement per turn. |

Stats are configurable per [ruleset-config.md](ruleset-config.md). Experience (medals 0-4) multiplies FPN and FPM: 1.0, 1.1, 1.2, 1.3, 1.4.

---

## Regiment Table (Imperialism II)

| Regiment | FPN | FPM | RNG | DEF | MVR | Category | Era |
|----------|-----|-----|-----|-----|-----|----------|-----|
| Peasant Levies | 0 | 3 | 1 | 3 | 3 | Light Infantry | 1 |
| Pikemen | 0 | 5 | 1 | 5 | 3 | Regular Infantry | 1 |
| Arquebusiers | 5 | 1 | 3 | 3 | 2 | Heavy Infantry | 1 |
| Bowmen | 3 | 1 | 4 | 2 | 3 | Bowmen | 1 |
| Squires | 0 | 4 | 1 | 4 | 6 | Light Cavalry | 1 |
| Knights | 0 | 6 | 1 | 6 | 4 | Spear Cavalry | 1 |
| Culverin | 8 | 1 | 5 | 2 | 2 | Heavy Artillery | 1 |
| Calivermen | 3 | 2 | 5 | 5 | 4 | Light Infantry | 2 |
| Halberdiers | 0 | 7 | 1 | 6 | 4 | Regular Infantry | 2 |
| Musketeers | 7 | 2 | 4 | 4 | 3 | Heavy Infantry | 2 |
| Cossacks | 0 | 5 | 1 | 5 | 8 | Light Cavalry | 2 |
| Lancers | 0 | 8 | 1 | 5 | 6 | Spear Cavalry | 2 |
| Harquebusiers | 2 | 6 | 3 | 5 | 6 | Heavy Cavalry | 2 |
| Horse Artillery | 5 | 2 | 7 | 2 | 3 | Light Artillery | 2 |
| Royal Artillery | 9 | 2 | 8 | 2 | 2 | Heavy Artillery | 2 |
| Skirmishers | 4 | 3 | 5 | 6 | 6 | Light Infantry | 3 |
| Regulars | 7 | 7 | 5 | 5 | 4 | Regular Infantry | 3 |
| Grenadiers | 10 | 8 | 5 | 5 | 4 | Heavy Infantry | 3 |
| Hussars | 2 | 8 | 3 | 6 | 11 | Light Cavalry | 3 |
| Cuirassiers | 5 | 13 | 3 | 5 | 9 | Heavy Cavalry | 3 |
| Light Artillery | 8 | 3 | 9 | 3 | 4 | Light Artillery | 3 |
| Heavy Artillery | 13 | 2 | 10 | 2 | 3 | Heavy Artillery | 3 |
| Sharpshooters | 5 | 4 | 7 | 7 | 7 | Light Infantry | 4 |
| Rifle Infantry | 9 | 9 | 6 | 6 | 4 | Regular Infantry | 4 |
| Guards | 12 | 10 | 6 | 6 | 4 | Heavy Infantry | 4 |
| Scouts | 5 | 11 | 5 | 6 | 11 | Light Cavalry | 4 |
| Carbine Cavalry | 7 | 17 | 5 | 5 | 9 | Heavy Cavalry | 4 |
| Field Artillery | 10 | 3 | 11 | 4 | 5 | Light Artillery | 4 |
| Siege Guns | 17 | 2 | 12 | 3 | 3 | Heavy Artillery | 4 |

Bowmen, Knights, Lancers: no upgrade path; obsolete in later eras.
