# Military Units (Land)

**SPEC/game** — Full Imperialism II regiment roster. Tactical stats for combat. Reference: Imperialism II 05-units-military. Combat: [combat.md](combat.md). Siege: [siege-mechanics.md](siege-mechanics.md). Civilian units: [civilian-units.md](civilian-units.md). Naval: [ships-and-naval.md](ships-and-naval.md). Generals and armies: [military-generals.md](military-generals.md).

---

## Overview

Land military forces consist of **regiments** grouped into **armies**, and **generals**. Every regiment belongs to exactly one army; armies are first-class containers ([military-armies.md](military-armies.md)). Regiments are organized into 8 categories across 4 eras. Each regiment has tactical stats (FPN, FPM, RNG, DEF, MVR) used for auto-resolve and Quick Battle. Tech unlocks determine which types a Great Power can build; older types are replaced within their category.

**Regiment buildability:** A regiment type is **buildable** iff the player has researched the **tech that unlocks that regiment** (per [tech-tree-military.md](tech-tree-military.md)). There is **no era gate**: if the unlocking tech is in the player's techUnlocked set, that regiment can be built regardless of era. Build validation (order engine) and recruitment UI must consult the tech catalog.

**Debug spawn exception (`/spawn_regiment`):** Debug-console regiment spawn is a debug-only path and does **not** consult normal affordability or tech unlock checks. It spawns only for the active human player at their capital, appends each spawned regiment to Home Army through `appendMilitaryRegimentToArmy`, and mints canonical regiment unit ids in global sequence form `unit_<n>` (never `debug_*`).

**Debug regiment hard-fail matrix:** Debug spawn hard-fails with no mutation and deterministic error when any of these checks fails: unknown `humanPlayerId`; targeted player is not human; unknown regiment id (not in catalog); missing `capitalProvinceId`; invalid capital province id region segment; invalid requested count (`<1`).

**Minor military parity:** `maxGreatPowerMilitaryLevel` is derived from the set of **land regiment** types any Great Power can build (e.g. the highest era among those types). In the turn-resolution **Minor Regiment Upgrade** phase (after Movement; before all combat phases), each **Old World Minor Nation** `effectiveMilitaryLevel` is set to this maximum and minor land regiments are upgraded in place; **Tribes** do not receive parity and remain `effectiveMilitaryLevel = 1` (see [factions.md](factions.md)).

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

**UI display labels:** Player-facing regiment names mirror the first column of this table via `regimentTypeDisplayName` in `colonizethis_data/lib/src/regiment_type_display_name.dart`. When adding or renaming a regiment type, update `regimentCatalog`, `RegimentEconomyCatalog`, and that display map together (tests enforce catalog coverage).

---

## Training Costs

Each regiment type has training costs defined in program-level config (`colonizethis_data/lib/src/regiment_economy.dart`). Costs include commodities consumed from stockpile and food upkeep per turn.

### Cavalry Input Requirements

Cavalry regiments require **horses** as input in addition to other commodities:

| Regiment | Fabric | Cast Iron | Lumber | Horses | Food Upkeep |
|----------|--------|-----------|--------|--------|-------------|
| Squires | 1 | 1 | - | 2 | 3 |
| Knights | 1 | 2 | - | 2 | 3 |
| Cossacks | 1 | 2 | - | 2 | 3 |
| Lancers | 1 | 2 | - | - | 3 |
| Harquebusiers | 1 | 2 | - | - | 3 |
| Hussars | 1 | 2 | - | - | 3 |
| Cuirassiers | 1 | 2 | - | - | 3 |
| Scouts | 1 | 2 | - | - | 3 |
| Carbine Cavalry | 1 | 2 | - | - | 3 |

Note: Horses are a raw material commodity (see [commodity-catalog.md](commodity-catalog.md)) that must be extracted from provinces with suitable terrain (plains) or acquired through trade.

---

## Acceptance Criteria

- Given the regiment table in this document and the global unit catalog in the implementation  
  When the System loads or validates regiment definitions at startup  
  Then the System ensures that each regiment id or type has exactly one entry with FPN, FPM, RNG, DEF, MVR, category, and era matching this table, and rejects any configuration that omits a listed regiment or defines duplicate regiment entries.

- Given a player’s `techUnlocked` set on the Player object and the military tech table in [tech-tree-military.md](tech-tree-military.md) that maps tech ids to regiment unlocks  
  When the System evaluates which regiment types the player may build during the build phase  
  Then a regiment type is considered buildable if and only if its unlocking tech id is present in `techUnlocked` (or requires no tech), regardless of era, and regiment types whose unlocking tech is not in `techUnlocked` are not buildable.

- Given a combat resolution or Quick Battle needs to compute land combat strength for a side using this regiment table and medal levels per unit  
  When the System aggregates strength per side as described in [combat.md](combat.md) and [quick-battle.md](quick-battle.md)  
  Then the System uses each regiment’s FPN and FPM values from this table, multiplies them by the appropriate medal multiplier, and never assumes or infers stats that contradict the values specified here.

- Given debug console is enabled and active human state is valid for capital placement  
  When `/spawn_regiment peasant_levies 3` is applied  
  Then exactly three new units with `type=peasant_levies`, `tileKey=null`, `medals=0`, `status=idle`, and `currentWork=null` are persisted in the capital region `RegionData.units` list and appended to Home Army, without tech or affordability checks.

- Given each hard-fail branch in the debug regiment matrix  
  When `/spawn_regiment` is submitted in that branch  
  Then no world mutation occurs (no new units, no army changes) and a deterministic error message is returned.
