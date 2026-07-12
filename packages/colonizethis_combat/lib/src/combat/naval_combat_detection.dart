// Naval conflict detection and attacker-side normalization.
// SPEC/program/naval-combat-resolution.md; SPEC/game/ships-and-naval.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
import 'naval_combat_types.dart';

bool _ownerHadMovingFleetInZone(
  Game game,
  String seaZoneId,
  String ownerId,
  Set<String> movedFleetIds,
) {
  if (movedFleetIds.isEmpty) return false;
  return game.worldState.fleets.any(
    (f) =>
        f.isAtSea &&
        f.seaZoneId == seaZoneId &&
        f.ownerId == ownerId &&
        movedFleetIds.contains(f.id),
  );
}

bool _isInterceptorMission(FleetMission m) =>
    m == FleetMission.patrol || m == FleetMission.blockade;

bool _navalBattleShouldSwapAttackerSides({
  required bool m1,
  required bool m2,
  required bool int1,
  required bool int2,
  required String s1OwnerId,
  required String s2OwnerId,
}) {
  if (m1 && !m2 && int2) return true;
  if (m2 && !m1 && int1) return false;
  if (m1 && !m2) return false;
  if (m2 && !m1) return true;
  return s1OwnerId.compareTo(s2OwnerId) > 0;
}

/// Orders [battle] so [side1] is the attacker and [side2] is the defender per SPEC/program/naval-combat-resolution.md.
///
/// Precedence: (1) If exactly one faction moved into the zone and the other is on Patrol or Blockade, the interceptor is the attacker. (2) Else if exactly one faction moved, the mover is the attacker. (3) Else (both moved, or neither) use lexicographically smaller `ownerId` as attacker for deterministic ordering.
BattleContextSea normalizeNavalBattleSidesForAttacker(
  BattleContextSea battle,
  Game game,
  Set<String> movedFleetIds,
) {
  final s1 = battle.side1;
  final s2 = battle.side2;
  final m1 = _ownerHadMovingFleetInZone(
    game,
    battle.seaZoneId,
    s1.ownerId,
    movedFleetIds,
  );
  final m2 = _ownerHadMovingFleetInZone(
    game,
    battle.seaZoneId,
    s2.ownerId,
    movedFleetIds,
  );
  final int1 = _isInterceptorMission(s1.mission);
  final int2 = _isInterceptorMission(s2.mission);

  final swap = _navalBattleShouldSwapAttackerSides(
    m1: m1,
    m2: m2,
    int1: int1,
    int2: int2,
    s1OwnerId: s1.ownerId,
    s2OwnerId: s2.ownerId,
  );

  if (!swap) {
    return battle;
  }
  return BattleContextSea(seaZoneId: battle.seaZoneId, side1: s2, side2: s1);
}

/// Conflict detection: returns contested sea zones with two hostile sides.
/// Populates mission per side from fleet state for retreat aggression.
List<BattleContextSea> detectNavalConflicts(Game game) {
  final atWar = hostileFactionsByFaction(game);
  final byZone = <String, Map<String, List<ShipInstance>>>{};
  final missionByZoneOwner = <String, Map<String, FleetMission>>{};
  for (final f in game.worldState.fleets) {
    if (!f.isAtSea || f.seaZoneId == null)
      continue; // Naval combat only in sea zones. SPEC/game/ships-and-naval.md.
    final zoneId = f.seaZoneId!;
    byZone.putIfAbsent(zoneId, () => {});
    byZone[zoneId]!.putIfAbsent(f.ownerId, () => []).addAll(f.ships);
    missionByZoneOwner.putIfAbsent(zoneId, () => {});
    missionByZoneOwner[zoneId]!.putIfAbsent(f.ownerId, () => f.mission);
  }
  final result = <BattleContextSea>[];
  for (final entry in byZone.entries) {
    final zoneId = entry.key;
    final owners = entry.value;
    if (owners.length < 2) continue;
    final ownerList = owners.keys.toList();
    bool added = false;
    for (var i = 0; i < ownerList.length && !added; i++) {
      for (var j = i + 1; j < ownerList.length && !added; j++) {
        final a = ownerList[i];
        final b = ownerList[j];
        if (atWar[a]?.contains(b) != true) continue;
        final missionA = missionByZoneOwner[zoneId]?[a] ?? FleetMission.none;
        final missionB = missionByZoneOwner[zoneId]?[b] ?? FleetMission.none;
        result.add(
          BattleContextSea(
            seaZoneId: zoneId,
            side1: NavalBattleSide(
              ownerId: a,
              ships: copyNavalShips(owners[a]!),
              mission: missionA,
            ),
            side2: NavalBattleSide(
              ownerId: b,
              ships: copyNavalShips(owners[b]!),
              mission: missionB,
            ),
          ),
        );
        added = true;
      }
    }
  }
  return result;
}
