import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'pre_combat_index.dart';

/// Applies immediate province flips when a Great Power army moves into an
/// enemy-owned province that has no defending combat units (and no third-party
/// combat presence). SPEC/game/combat.md § Unopposed capture.
///
/// Runs at the start of the combat phase, before [detectConflicts].
Game applyUnopposedProvinceCaptures(Game game, Orders orders) {
  final index = PreCombatMovementIndex.build(game, orders);
  var state = game;

  void processRegion(RegionData region) {
    final provinceById = provincesByIdIndex(region);
    final unitsByProvince = unitsByProvinceIndex(region);

    final movedGpIdsByProvince = <String, Set<String>>{};
    for (final move in index.greatPowerArmyMoves) {
      final destFull = move.destinationProvinceId;
      if (!provinceById.containsKey(destFull)) continue;
      movedGpIdsByProvince
          .putIfAbsent(destFull, () => <String>{})
          .add(move.factionId);
    }

    final sortedProvinceIds = movedGpIdsByProvince.keys.toList()..sort();
    for (final provinceId in sortedProvinceIds) {
      final province = provinceById[provinceId];
      if (province == null) continue;
      final ownerId = province.ownerId;
      if (ownerId == null || ownerId.isEmpty) continue;

      final movers = movedGpIdsByProvince[provinceId]!;
      final eligibleAttackers =
          movers
              .where(
                (fid) => fid != ownerId && factionsAtWar(state, fid, ownerId),
              )
              .toList()
            ..sort();
      if (eligibleAttackers.isEmpty) continue;

      final unitsInProvince = unitsByProvince[provinceId] ?? const <Unit>[];
      final ownerCombatCount = unitsInProvince
          .where((u) => u.ownerId == ownerId && canUnitInitiateCombat(u.type))
          .length;
      if (ownerCombatCount > 0) continue;

      final attackerSet = eligibleAttackers.toSet();
      final thirdPartyCombat = unitsInProvince.any(
        (u) =>
            canUnitInitiateCombat(u.type) &&
            u.ownerId != ownerId &&
            !attackerSet.contains(u.ownerId),
      );
      if (thirdPartyCombat) continue;

      final capturerId = eligibleAttackers.first;
      state = applyCanonicalSingleProvinceOwnershipTransfer(
        state,
        targetProvinceId: provinceId,
        oldOwnerId: ownerId,
        newOwnerId: capturerId,
      );
    }
  }

  state.worldState.forEachRegion((_, region) => processRegion(region));
  return state;
}
