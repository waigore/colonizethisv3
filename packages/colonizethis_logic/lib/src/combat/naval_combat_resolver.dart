// Naval combat: conflict detection, BattleContextSea, resolve. SPEC/program/naval-combat-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// One side in a sea battle: owner and ship type ids (counts by type).
class NavalBattleSide {
  const NavalBattleSide({
    required this.ownerId,
    required this.shipTypeIds,
  });

  final String ownerId;
  final List<String> shipTypeIds;
}

/// Sea battle context for one zone. SPEC/program/naval-combat-resolution.md.
class BattleContextSea {
  const BattleContextSea({
    required this.seaZoneId,
    required this.side1,
    required this.side2,
  });

  final String seaZoneId;
  final NavalBattleSide side1;
  final NavalBattleSide side2;
}

/// Conflict detection: returns contested sea zones with two hostile sides.
List<BattleContextSea> detectNavalConflicts(Game game) {
  final atWar = <String, Set<String>>{};
  for (final rel in game.diplomacyRelations) {
    if (rel.state != RelationState.atWar) continue;
    atWar.putIfAbsent(rel.factionId1, () => <String>{}).add(rel.factionId2);
    atWar.putIfAbsent(rel.factionId2, () => <String>{}).add(rel.factionId1);
  }
  final byZone = <String, Map<String, List<String>>>{};
  for (final f in game.worldState.fleets) {
    byZone.putIfAbsent(f.seaZoneId, () => {});
    byZone[f.seaZoneId]!.putIfAbsent(f.ownerId, () => []).addAll(f.shipTypeIds);
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
        result.add(BattleContextSea(
          seaZoneId: zoneId,
          side1: NavalBattleSide(ownerId: a, shipTypeIds: List.from(owners[a]!)),
          side2: NavalBattleSide(ownerId: b, shipTypeIds: List.from(owners[b]!)),
        ));
        added = true;
      }
    }
  }
  return result;
}

/// Compute naval strength from ship type list (firepower + range weighted).
double navalStrength(List<String> shipTypeIds) {
  var total = 0.0;
  for (final typeId in shipTypeIds) {
    final s = NavalStatsCatalog.get(typeId);
    total += s.firepower * (1 + s.range * 0.2) + (s.armour + s.hull) * 0.5;
  }
  return total;
}

/// Result of resolving one sea battle: updated fleet lists (sunk ships removed).
class NavalBattleResult {
  const NavalBattleResult({
    required this.survivingShipTypeIdsSide1,
    required this.survivingShipTypeIdsSide2,
    this.side1Retreated = false,
    this.side2Retreated = false,
  });

  final List<String> survivingShipTypeIdsSide1;
  final List<String> survivingShipTypeIdsSide2;
  final bool side1Retreated;
  final bool side2Retreated;
}

/// Resolve one sea battle deterministically. Seed from game + zone for RNG.
NavalBattleResult resolveSeaBattle(BattleContextSea battle, int seed) {
  final rng = _SeededRng(seed);
  final str1 = navalStrength(battle.side1.shipTypeIds);
  final str2 = navalStrength(battle.side2.shipTypeIds);
  final total = str1 + str2;
  if (total <= 0) {
    return NavalBattleResult(
      survivingShipTypeIdsSide1: List.from(battle.side1.shipTypeIds),
      survivingShipTypeIdsSide2: List.from(battle.side2.shipTypeIds),
    );
  }
  final ratio1 = str1 / total;
  final casualties1 = (battle.side1.shipTypeIds.length * (1 - ratio1) * 0.5).round().clamp(0, battle.side1.shipTypeIds.length);
  final casualties2 = (battle.side2.shipTypeIds.length * (1 - (1 - ratio1)) * 0.5).round().clamp(0, battle.side2.shipTypeIds.length);
  final list1 = List<String>.from(battle.side1.shipTypeIds);
  final list2 = List<String>.from(battle.side2.shipTypeIds);
  for (var i = 0; i < casualties1 && list1.isNotEmpty; i++) {
    list1.removeAt(rng.nextInt(list1.length));
  }
  for (var i = 0; i < casualties2 && list2.isNotEmpty; i++) {
    list2.removeAt(rng.nextInt(list2.length));
  }
  return NavalBattleResult(
    survivingShipTypeIdsSide1: list1,
    survivingShipTypeIdsSide2: list2,
  );
}

class _SeededRng {
  _SeededRng(this._seed);
  int _seed;
  int nextInt(int max) {
    if (max <= 0) return 0;
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed % max;
  }
}

/// Apply naval battle results to game: replace all fleets of both sides in zone with surviving fleets.
Game applyNavalBattleResults(
  Game game,
  BattleContextSea battle,
  NavalBattleResult result,
  String regionIdForZone,
) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final zone = battle.seaZoneId;
  final owner1 = battle.side1.ownerId;
  final owner2 = battle.side2.ownerId;

  fleets = fleets.where((f) => f.seaZoneId != zone || (f.ownerId != owner1 && f.ownerId != owner2)).toList();
  if (result.survivingShipTypeIdsSide1.isNotEmpty) {
    fleets.add(Fleet(
      id: 'naval_${owner1}_$zone',
      ownerId: owner1,
      seaZoneId: zone,
      regionId: regionIdForZone,
      shipTypeIds: result.survivingShipTypeIdsSide1,
    ));
  }
  if (result.survivingShipTypeIdsSide2.isNotEmpty) {
    fleets.add(Fleet(
      id: 'naval_${owner2}_$zone',
      ownerId: owner2,
      seaZoneId: zone,
      regionId: regionIdForZone,
      shipTypeIds: result.survivingShipTypeIdsSide2,
    ));
  }
  return game.copyWith(
    worldState: game.worldState.copyWith(fleets: fleets),
  );
}
