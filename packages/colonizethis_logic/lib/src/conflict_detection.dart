import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Battle context for one contested province. SPEC/program/combat-resolution.md.
class BattleContext {
  const BattleContext({
    required this.provinceId,
    required this.regionId,
    required this.defenderFactionId,
    required this.defenderUnitIds,
    required this.attackers,
    required this.fortLevel,
    required this.terrain,
  });

  final String provinceId;
  final String regionId;
  final String defenderFactionId;
  final List<String> defenderUnitIds;
  final List<AttackingSide> attackers;
  final int fortLevel;
  final String terrain;

  bool get isSiege => fortLevel >= 1;
}

/// One attacking army in a battle. SPEC/program/combat-resolution.md.
class AttackingSide {
  const AttackingSide({
    required this.factionId,
    required this.unitIds,
    this.generalMedals = 0,
  });

  final String factionId;
  final List<String> unitIds;
  final int generalMedals;
}

/// Conflict detection after movement. SPEC/program/combat-resolution.md.
///
/// Returns BattleContexts for provinces with opposing factions.
/// Attackers = GPs that moved in; defender = province owner or non-mover.
List<BattleContext> detectConflicts(Game game, Orders orders) {
  final contexts = <BattleContext>[];

  void processRegion(RegionData region) {
    if (region.units.isEmpty) return;

    final gpIds = {for (final p in game.players) p.id};

    final unitsByProvince = <String, List<Unit>>{};
    for (final u in region.units) {
      unitsByProvince.putIfAbsent(u.provinceId, () => []).add(u);
    }

    final movedIntoByFaction = <String, Set<String>>{};
    for (final entry in orders.moveOrdersByPlayerId.entries) {
      final factionId = entry.key;
      if (!gpIds.contains(factionId)) continue;
      for (final order in entry.value) {
        movedIntoByFaction
            .putIfAbsent(order.destinationProvinceId, () => {})
            .add(factionId);
      }
    }

    final provinceById = {for (final p in region.provinces) p.id: p};

    for (final entry in unitsByProvince.entries) {
      final provinceId = entry.key;
      final units = entry.value;

      // Only combat-capable units participate in conflict detection.
      final combatUnits =
          units.where((u) => canUnitInitiateCombat(u.type)).toList();

      final factionsPresent = combatUnits.map((u) => u.ownerId).toSet();
      if (factionsPresent.length < 2) continue;

      final province = provinceById[provinceId];
      final ownerId = province?.ownerId;

      String defenderFactionId;
      if (ownerId != null && ownerId.isNotEmpty && factionsPresent.contains(ownerId)) {
        defenderFactionId = ownerId;
      } else {
        final movers = movedIntoByFaction[provinceId] ?? {};
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

      final attackerFactionIds = (movedIntoByFaction[provinceId] ?? {})
          .where((f) => f != defenderFactionId && gpIds.contains(f))
          .toList();

      if (attackerFactionIds.isEmpty) continue;

      final defenderUnits =
          combatUnits.where((u) => u.ownerId == defenderFactionId).toList();
      if (defenderUnits.isEmpty) continue;

      final attackers = <AttackingSide>[];
      for (final fid in attackerFactionIds) {
        final attackerUnits =
            combatUnits.where((u) => u.ownerId == fid).toList();
        if (attackerUnits.isEmpty) continue;
        attackers.add(AttackingSide(
          factionId: fid,
          unitIds: attackerUnits.map((u) => u.id).toList(),
        ));
      }

      if (attackers.isEmpty) continue;

      final fortLevel = province?.fortLevel ?? 0;
      final terrain = province?.terrain ?? 'plains';
      final regionId = province?.regionId ?? 'oldWorld';

      contexts.add(BattleContext(
        provinceId: provinceId,
        regionId: regionId,
        defenderFactionId: defenderFactionId,
        defenderUnitIds: defenderUnits.map((u) => u.id).toList(),
        attackers: attackers,
        fortLevel: fortLevel,
        terrain: terrain,
      ));
    }
  }

  processRegion(game.worldState.oldWorld);
  processRegion(game.worldState.newWorld);

  contexts.sort((a, b) {
    final regionCompare = a.regionId.compareTo(b.regionId);
    if (regionCompare != 0) return regionCompare;
    return a.provinceId.compareTo(b.provinceId);
  });

  return contexts;
}
