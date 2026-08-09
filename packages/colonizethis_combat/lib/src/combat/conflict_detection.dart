import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'battle_context.dart';
import 'pre_combat_index.dart';

export 'battle_context.dart';

/// Conflict detection after movement. SPEC/program/combat-resolution.md.
///
/// Returns BattleContexts for provinces with opposing factions.
/// Attackers are attacking armies (not faction-aggregated sides).
List<BattleContext> detectConflicts(Game game, Orders orders) {
  final contexts = <BattleContext>[];
  final index = PreCombatMovementIndex.build(game, orders);
  final armyById = index.armiesById;
  final gpIds = index.greatPowerIds;
  final armiesByOwnerAndProvince = _indexArmiesByOwnerAndProvince(
    game.worldState.armies,
  );
  final unitById = game.worldState.allUnitsById;

  void processRegion(RegionData region) {
    if (region.units.isEmpty) return;

    final unitsByProvince = unitsByProvinceIndex(region);

    final movedArmyIdsByProvince = <String, List<String>>{};
    final movedIntoByFaction = <String, Set<String>>{};
    for (final entry in orders.moveOrdersByPlayerId.entries) {
      final factionId = entry.key;
      if (!gpIds.contains(factionId)) continue;
      for (final order in entry.value) {
        final unit = unitById[order.unitId];
        if (unit == null || !canUnitInitiateCombat(unit.type)) continue;
        final destProvince = Unit.provinceIdFromTileKey(
          order.destinationTileKey,
        );
        if (destProvince == null) continue;
        movedIntoByFaction
            .putIfAbsent(destProvince, () => <String>{})
            .add(factionId);
      }
    }
    for (final move in index.greatPowerArmyMoves) {
      final destFull = move.destinationProvinceId;
      movedArmyIdsByProvince
          .putIfAbsent(destFull, () => <String>[])
          .add(move.army.id);
      movedIntoByFaction.putIfAbsent(destFull, () => {}).add(move.factionId);
    }

    final provinceById = provincesByIdIndex(region);

    for (final entry in unitsByProvince.entries) {
      final provinceId = entry.key;
      final units = entry.value;

      // Only combat-capable units participate in conflict detection.
      final combatUnits = units
          .where((u) => canUnitInitiateCombat(u.type))
          .toList();
      final combatUnitsByFaction = <String, List<Unit>>{};
      for (final unit in combatUnits) {
        combatUnitsByFaction.putIfAbsent(unit.ownerId, () => []).add(unit);
      }
      final factionsPresent = combatUnitsByFaction.keys.toSet();
      if (factionsPresent.length < 2) continue;

      final province = provinceById[provinceId];
      if (province == null) continue;
      final factionsMovedIntoProvince =
          movedIntoByFaction[provinceId] ?? const <String>{};
      final ownerId = province.ownerId;

      String defenderFactionId;
      if (ownerId != null &&
          ownerId.isNotEmpty &&
          factionsPresent.contains(ownerId)) {
        defenderFactionId = ownerId;
      } else {
        final movers = factionsMovedIntoProvince;
        final nonMovers = factionsPresent.difference(movers);
        if (nonMovers.isEmpty) {
          defenderFactionId = factionsPresent.reduce(
            (a, b) => a.compareTo(b) < 0 ? a : b,
          );
        } else {
          defenderFactionId = nonMovers.reduce(
            (a, b) => a.compareTo(b) < 0 ? a : b,
          );
        }
      }

      final attackerFactionIds = factionsMovedIntoProvince
          .where((f) => f != defenderFactionId && gpIds.contains(f))
          .toList();
      final attackerFactionIdSet = attackerFactionIds.toSet();

      if (attackerFactionIds.isEmpty) continue;

      final defenderUnits =
          combatUnitsByFaction[defenderFactionId] ?? const <Unit>[];
      if (defenderUnits.isEmpty) continue;

      final attackers = <AttackingSide>[];
      final movedArmies =
          movedArmyIdsByProvince[provinceId] ?? const <String>[];
      for (final armyId in movedArmies) {
        final army = armyById[armyId];
        if (army == null) continue;
        final fid = army.ownerId;
        if (!attackerFactionIdSet.contains(fid)) continue;
        final attackerUnits = <Unit>[];
        for (final unitId in army.regimentUnitIds) {
          final u = unitById[unitId];
          if (u == null) continue;
          if (u.ownerId != fid) continue;
          if (u.locationProvinceId != provinceId) continue;
          if (!canUnitInitiateCombat(u.type)) continue;
          attackerUnits.add(u);
        }
        if (attackerUnits.isEmpty) continue;
        attackers.add(
          AttackingSide(
            factionId: fid,
            armyId: armyId,
            unitIds: attackerUnits.map((u) => u.id).toList(),
          ),
        );
      }
      if (attackers.isEmpty) {
        for (final fid in attackerFactionIds) {
          final attackerUnits = combatUnitsByFaction[fid] ?? const <Unit>[];
          if (attackerUnits.isEmpty) continue;
          attackers.add(
            AttackingSide(
              factionId: fid,
              armyId: 'adhoc|$fid|$provinceId',
              unitIds: attackerUnits.map((u) => u.id).toList(growable: false),
            ),
          );
        }
      }

      if (attackers.isEmpty) continue;

      final defenderUnitIdSet = defenderUnits.map((u) => u.id).toSet();
      final defenderArmies =
          [...?armiesByOwnerAndProvince[defenderFactionId]?[provinceId]]
            ..retainWhere(
              (army) => army.regimentUnitIds.any(defenderUnitIdSet.contains),
            )
            ..sort((a, b) {
              final countCmp = b.regimentUnitIds.length.compareTo(
                a.regimentUnitIds.length,
              );
              if (countCmp != 0) return countCmp;
              return a.id.compareTo(b.id);
            });
      String? primaryDefenderArmyId;
      if (defenderArmies.isNotEmpty) {
        primaryDefenderArmyId = defenderArmies.first.id;
      }

      final fortLevel = province.fortLevel;
      final terrain = province.terrain;
      final regionId = province.regionId;

      contexts.add(
        BattleContext(
          provinceId: provinceId,
          regionId: regionId,
          defenderFactionId: defenderFactionId,
          defenderUnitIds: defenderUnits.map((u) => u.id).toList(),
          defenderArmyIds: defenderArmies
              .map((a) => a.id)
              .toList(growable: false),
          primaryDefenderArmyId: primaryDefenderArmyId,
          attackers: attackers,
          fortLevel: fortLevel,
          terrain: terrain,
        ),
      );
    }
  }

  game.worldState.forEachRegion((_, region) => processRegion(region));

  contexts.sort((a, b) {
    final regionCompare = a.regionId.compareTo(b.regionId);
    if (regionCompare != 0) return regionCompare;
    return a.provinceId.compareTo(b.provinceId);
  });

  return contexts;
}

Map<String, Map<String, List<Army>>> _indexArmiesByOwnerAndProvince(
  List<Army> armies,
) {
  final armiesByOwnerAndProvince = <String, Map<String, List<Army>>>{};
  for (final army in armies) {
    final byProvince = armiesByOwnerAndProvince.putIfAbsent(
      army.ownerId,
      () => <String, List<Army>>{},
    );
    byProvince.putIfAbsent(army.stationedProvinceId, () => <Army>[]).add(army);
  }
  return armiesByOwnerAndProvince;
}
