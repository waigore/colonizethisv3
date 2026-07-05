# Advanced Starts

## Overview

Two fixed **advanced start** presets let players begin a campaign at turn **50** (calendar ~1598) or turn **100** (~1698) with Great Powers already progressed in tech, economy, and (at higher tier) New World presence. Default start remains turn **0**. Authoritative tier tables and tech lists live here; setup wiring is in [game-setup-pipeline.md](../program/game-setup-pipeline.md).

## Config

- **`GameSetupConfig.advancedStart`:** `AdvancedStartType` enum — `none` (default), `turns50`, `turns100`. Chosen in DLG10001; immutable after game creation.
- **`Game.advancedStartType`:** Persisted copy; **null** for turn-0 games and legacy saves.
- **Profile gate:** Advanced start applies only when `GameSetupConfig.isLockedFullInitProfile` is true (6 GPs, 6 minors, 4 continents, 10 tribes, 60 OW / 30 NW provinces). Non-locked configs log a warning and leave the turn-0 game unchanged.

## Tier tables

| Field | 50-turn (`turns50`) | 100-turn (`turns100`) |
|---|---|---|
| Start turn | 50 | 100 |
| Treasury (ducats) | 20,000 | 40,000 |
| Workforce | 16 peasants | 16 peasants + 4 apprentices |
| Tech count | 23 | 45 |
| NW GP provinces | 0 (turn-0 ownership) | 6 contiguous per GP |
| NW revealed | 50–75% contiguous | 100% contiguous |
| NW prospected | ≥50% of prospectable tiles in revealed provinces | ≥75% |
| Player development | 25% developable tiles → level 1 + roads | 50% |
| Minor development | 25% purchased + level 1 | 50% |
| Diplomacy | Consulates (OW minors + encountered tribes) | Embassies |
| Civilians | Explorer×3, Builder×3, Engineer×2, Spy×1, Merchant×1 | +1 each type, RailBuilder×1 |
| Regiments | 6 (best available types) | 12 |
| Cargo ships | 1 Galleon minimum per GP | `ceil(extractionVolume / shipCargo × 1.15)` from NW dev |

Constants: `advancedStartCivilianCounts`, `advancedStartRegimentCount`, `advancedStartCargoShipCount`, `advancedStartRegimentTypeIds` in `colonizethis_data`.

50-turn cargo ships use a **fixed minimum of one Galleon** per GP (head start for planned colonization; no GP-owned NW provinces at this tier).

50-turn NW reveal uses **62.5%** (`kAdvancedStart50TurnNwRevealFraction = 0.625`), the midpoint of the 50–75% SPEC range, applied deterministically per GP.

## Fixed technology lists

Same unlocked set for every Great Power. Discovery techs are set directly (synthetic NW exploration). Prerequisites must be satisfied within each list.

**50-turn (23):** `crop_rotation`, `saw_mill`, `land_enclosure`, `mine_engineering`, `iron_mining`, `sheep_ranching`, `wind_saw_mill`, `road_construction`, `printing_press`, `money_lending`, `diplomatic_expertise`, `merchant_companies`, `superior_hull_design`, `navigation`, `convoying`, `improved_sail_design`, `organised_regiments`, `improved_iron_weapons`, `recruit_steppe_horsemen`, `animal_husbandry`, `improved_cavalry_tactics`, `discovery_of_sugar`, `discovery_of_tobacco`.

**100-turn additions (22):** all 50-turn ids plus `copper_and_tin_mining`, `coal_mining`, `seed_drill`, `square_set_timbering`, `steam_in_mining`, `early_steam_engine`, `sugar_refining`, `cigar_production`, `apprentice_workers`, `national_bureaucracy`, `privateering_companies`, `large_hulls`, `improved_infantry_tactics`, `crucible_process`, `hussars`, `horse_artillery`, `siege_engineering`, `weapon_craftsmanship`, `discovery_of_cotton`, `discovery_of_furs`, `discovery_of_spices`, `discovery_of_gold_or_silver`.

Constants: `colonizethis_data` (`advanced_start_tables.dart`).

## Bootstrap

Entry point: `applyAdvancedStartBootstrap(game, config)` in `colonizethis_setup`. Called after standard init (`createGameFromGeneratedMaps` path) and before map-view build / persist.

Ordered steps (full issue #3895):

1. Set `turnState.turnNumber` and `Game.advancedStartType`.
2. Unlock fixed tech list per tier.
3. Set treasury and workforce per tier table.
4. Assign civilian units (tier table).
5. Assign upgraded regiments (best buildable type per military branch from unlocked techs; highest era, tie-break highest FPN+FPM; balanced across infantry/cavalry/artillery).
6. Assign cargo ships per tier rule (Galleon; fixed minimum until NW dev step supplies extraction volume).
7. Pre-establish consulates / embassies (OW minors + tribes encountered in step 8).
8. NW exploration (contiguous flood-fill from warp-link entry).
9. NW prospecting (% of prospectable tiles).
10. NW colonization (100-turn only).
11. Player + minor tile development and roads.
12. NW province town → OW capital connectivity.

**Implementation status:** Steps **1–12** are implemented (turn through NW roads). Save/load integration ACs remain follow-up on #3895.

## Acceptance criteria (partial — foundation + units slice)

- Given advanced start `none`, when init completes, then `Game.advancedStartType` is null and `turnNumber` is 0.
- Given advanced start `turns50` on the locked profile, when init completes, then every GP has exactly 23 listed techs unlocked, 16 peasants, 20,000 treasury, tier civilian counts, 6 upgraded regiments, at least 1 Galleon in the home fleet, and `turnNumber` is 50.
- Given advanced start `turns50` on the locked profile, when init completes, then every GP has consulates with all OW minors, at least `kAdvancedStart50TurnNwRevealFraction` of NW provinces fully visible (contiguous from warp entry), ≥50% of prospectable tiles in those provinces prospected, and 25% of developable tiles at improvement level 1 in owned provinces with road links to town or capital.
- Given advanced start `turns50` on the locked profile, when init completes, then 25% of developable tiles in each OW minor province are purchased by a GP (round-robin) at improvement level 1 and recorded in `purchasedTilesByTileKey`.
- Given advanced start `turns100` on the locked profile, when init completes, then every GP has exactly 45 listed techs unlocked, 16 peasants and 4 apprentices, 40,000 treasury, tier civilian counts including Rail Builder, 12 upgraded regiments, at least 6 Galleons in the home fleet, and `turnNumber` is 100.
- Given advanced start `turns100` on the locked profile, when init completes, then every GP has embassies with all OW minors and encountered tribes, 100% NW provinces visible, ≥75% of prospectable tiles prospected, 6 contiguous NW provinces owned per GP (tribes retain ≥1 province each), 50% of developable tiles at improvement level 1 in owned provinces (OW + NW) with road links, and 50% of minor developable tiles purchased and developed.
- Given advanced start ≠ `none` on a non-locked profile, when bootstrap runs, then the System returns the turn-0 game unchanged and logs a warning.
- Given an advanced-start game is saved and reloaded, when loaded, then `advancedStartType`, turn, techs, treasury, and workforce match the saved state.
