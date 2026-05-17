import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_relation_lookup.dart';
import '../world/province_ownership_transfer.dart';

/// Applies immediate province flips when a Great Power army moves into an
/// enemy-owned province that has no defending combat units (and no third-party
/// combat presence). SPEC/game/combat.md § Unopposed capture.
///
/// Runs at the start of the combat phase, before [detectConflicts].
Game applyUnopposedProvinceCaptures(Game game, Orders orders) {
  final gpIds = {for (final p in game.players) p.id};
  final armyById = {for (final a in game.worldState.armies) a.id: a};
  var state = game;

  void processRegion(RegionData region) {
    final provinceById = {for (final p in region.provinces) p.id: p};
    final unitsByProvince = <String, List<Unit>>{};
    for (final u in region.units) {
      unitsByProvince.putIfAbsent(u.locationProvinceId, () => []).add(u);
    }

    final movedGpIdsByProvince = <String, Set<String>>{};
    for (final entry in orders.armyMoveOrdersByPlayerId.entries) {
      final factionId = entry.key;
      if (!gpIds.contains(factionId)) continue;
      for (final order in entry.value) {
        final army = armyById[order.armyId];
        if (army == null || army.ownerId != factionId) continue;
        if (army.isHomeArmy) continue;
        final destFull = ProvinceId.isPrefixed(order.destinationProvinceId)
            ? order.destinationProvinceId
            : ProvinceId.full(
                ProvinceId.regionIdFrom(army.stationedProvinceId),
                order.destinationProvinceId,
              );
        if (!provinceById.containsKey(destFull)) continue;
        movedGpIdsByProvince.putIfAbsent(destFull, () => <String>{}).add(
          factionId,
        );
      }
    }

    final sortedProvinceIds = movedGpIdsByProvince.keys.toList()..sort();
    for (final provinceId in sortedProvinceIds) {
      final province = provinceById[provinceId];
      if (province == null) continue;
      final ownerId = province.ownerId;
      if (ownerId == null || ownerId.isEmpty) continue;

      final movers = movedGpIdsByProvince[provinceId]!;
      final eligibleAttackers = movers
          .where(
            (fid) =>
                fid != ownerId && factionsAtWar(state, fid, ownerId),
          )
          .toList()
        ..sort();
      if (eligibleAttackers.isEmpty) continue;

      final unitsInProvince = unitsByProvince[provinceId] ?? const <Unit>[];
      final ownerCombatCount = unitsInProvince
          .where(
            (u) => u.ownerId == ownerId && canUnitInitiateCombat(u.type),
          )
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

  processRegion(state.worldState.oldWorld);
  processRegion(state.worldState.newWorld);
  return state;
}
