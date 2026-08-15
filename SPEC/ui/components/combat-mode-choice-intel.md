# Combat mode choice intel (component)

**SPEC/ui/components** — Pure force/fort snapshot for `CMPT10001`. Implementation: `app/lib/features/game/widgets/combat/combat_mode_choice_intel.dart`. Not a screen. Counts use the **pre-battle** `Game` in `OpenDialogEvent` params (after movement and unopposed captures, before `runOneLandBattle`). Never `currentGameProvider`. Never `draftOrders` for regiment `N`.

## Province id

1. If `provinceId` is a prefixed `regionId|localId` that `tryGetProvince` finds, use it.
2. Else unique match of `provinceName` to `Province.displayName` on that snapshot.
3. Zero or ≥2 name matches, missing `game` / `humanPlayerId` / `topology`, or unknown id → return null (dialog omits force/fort/Details).

If `playerView` is omitted, call `buildPlayerView(game, topology, humanPlayerId)` on the params snapshot.

## Role and counts

Role is **defender** iff `province.ownerId == humanPlayerId`; otherwise **attacker**. Do not treat a leftover human garrison in a foreign province as defender (no `BattleContext` / mover flag).

Combat-capable means `canUnitInitiateCombat`. Own force (both roles): those units owned by the human whose `locationProvinceId` is the contested province. Include leftover garrison plus same-turn arrivals already in the province. Exclude ignored `ArmyMoveOrder` armies still elsewhere.

Enemy:

| Role | Intel | Enemy line |
|------|-------|------------|
| Attacker | unknown (`provincePanelShowsFullTileDerivedIntel` false) | `moveArmy_defendersUnknown`; omit fort and enemy types |
| Attacker | full, owner combat count `D > 0` | `moveArmy_defendersRegiments(D)` for `province.ownerId` units only (not co-attackers or the human) |
| Attacker | full, owner empty or `ownerId` empty | omit enemy line and enemy types (no `Defenders: 0`) |
| Defender | owned province | `combatMode_attackersRegiments(N)` for all non-human combat-capable units, including co-attackers and non-moving third parties |

Fort: attacker uses `computeMoveArmyInvasionIntelSummary` **intelLevel and fortLevel only** (never `unopposed`, never that helper’s defender totals). Defender uses `province.fortLevel`. Labels: `moveArmyFortLabelForLevel`.

Details types: `unit.type` counts over the same sets as own/enemy `N`, labeled with `regimentTypeDisplayLabel` + `provinceOverlay_indentedCount`. When the enemy line is omitted, Details shows own types only.

## Acceptance criteria

- Given a unique `provinceName` match and no `provinceId`, when the helper runs, then it uses that prefixed id; given 0 or ≥2 matches, then it returns null.
- Given params omit `playerView` but include `game` / `topology` / `humanPlayerId`, when the helper runs, then it calls `buildPlayerView` on that snapshot.
- Given the human is attacker, full intel, owner combat count `D > 0` plus co-attacker `C > 0`, when the helper runs, then enemy `N` is `D` not `D+C`.
- Given the human is defender, attackers `A` and `C` plus non-moving third party `T`, when the helper runs, then enemy `N` is `A+C+T`.
- Given attacker owner combat 0 with third-party garrison `T > 0`, when the helper runs, then enemy count is omitted.
- Given leftover human `H` in a foreign province with owner combat 0 and mover `G > 0`, when the helper runs, then role is attacker, own is `H`, enemy is omitted.
- Given ignored `ArmyMoveOrder` with `I` regiments not in the province and in-province human `H`, when the helper runs, then own is `H` not `H+I`.
- Given defender garrison `G` plus applied arrivals `R` already in the province, when the helper runs, then own is `G+R`.
