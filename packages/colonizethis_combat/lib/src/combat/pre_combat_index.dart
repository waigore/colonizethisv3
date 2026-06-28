// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared pre-combat movement / province indexing for the combat phase
/// (Refs #3448).
///
/// `applyUnopposedProvinceCaptures` (unopposed_province_capture.dart) and
/// `detectConflicts` (conflict_detection.dart) both run at the start of the
/// combat phase and previously rebuilt the same indexes nearly verbatim: the
/// Great Power id set, the army-by-id map, per-region units-by-province and
/// provinces-by-id maps, and the army-move destination normalization (the
/// `ProvinceId` prefixing footgun). Centralizing them here gives one source of
/// truth and keeps both consumers byte-identical for any fixed input.
///
/// SPEC/program/combat-resolution.md (conflict detection, pre-Combat indexing).
/// These helpers are pure and deterministic: same inputs always yield the same
/// outputs and the same iteration order.

/// A Great Power army move with its destination resolved to a prefixed
/// (`regionId|localId`) province id and the common eligibility guards already
/// applied (owner is a Great Power, army exists, owner matches, not a home
/// army).
class ResolvedArmyMove {
  const ResolvedArmyMove({
    required this.factionId,
    required this.army,
    required this.destinationProvinceId,
  });

  /// Owning Great Power faction id (key of `armyMoveOrdersByPlayerId`).
  final String factionId;

  /// The moving army.
  final Army army;

  /// Destination province id, always prefixed (`regionId|localId`).
  final String destinationProvinceId;
}

/// Normalizes an [ArmyMoveOrder] destination to a prefixed province id.
///
/// Already-prefixed destinations pass through unchanged; bare local ids are
/// qualified with the region of the army's stationed province. Always use a
/// prefixed (regionId, provinceId) id for province lookup — never a bare local
/// id (see `colonizethis-core-principles` province-lookup rule).
String resolveArmyMoveDestinationProvinceId(Army army, ArmyMoveOrder order) {
  return ProvinceId.isPrefixed(order.destinationProvinceId)
      ? order.destinationProvinceId
      : ProvinceId.full(
          ProvinceId.regionIdFrom(army.stationedProvinceId),
          order.destinationProvinceId,
        );
}

/// Indexes a region's combat units by their location province id.
///
/// Insertion order within each list follows `region.units` order.
Map<String, List<Unit>> unitsByProvinceIndex(RegionData region) {
  final unitsByProvince = <String, List<Unit>>{};
  for (final u in region.units) {
    unitsByProvince.putIfAbsent(u.locationProvinceId, () => []).add(u);
  }
  return unitsByProvince;
}

/// Indexes a region's provinces by their (prefixed) province id.
Map<String, Province> provincesByIdIndex(RegionData region) {
  return {for (final p in region.provinces) p.id: p};
}

/// Pre-combat movement index shared by unopposed capture and conflict
/// detection.
///
/// Holds the game-wide pieces (Great Power ids, army-by-id, and resolved Great
/// Power army moves) that are independent of any single region, so they are
/// computed once per combat-phase pass instead of per region.
class PreCombatMovementIndex {
  const PreCombatMovementIndex._({
    required this.greatPowerIds,
    required this.armiesById,
    required this.greatPowerArmyMoves,
  });

  /// All Great Power (player) faction ids.
  final Set<String> greatPowerIds;

  /// Every army keyed by its id.
  final Map<String, Army> armiesById;

  /// Great Power army moves with destinations resolved, in deterministic order
  /// (player-entry order, then per-order order within each player).
  final List<ResolvedArmyMove> greatPowerArmyMoves;

  /// Builds the index from [game] and [orders].
  factory PreCombatMovementIndex.build(Game game, Orders orders) {
    final greatPowerIds = {for (final p in game.players) p.id};
    final armiesById = {for (final a in game.worldState.armies) a.id: a};

    final moves = <ResolvedArmyMove>[];
    for (final entry in orders.armyMoveOrdersByPlayerId.entries) {
      final factionId = entry.key;
      if (!greatPowerIds.contains(factionId)) continue;
      for (final order in entry.value) {
        final army = armiesById[order.armyId];
        if (army == null || army.ownerId != factionId) continue;
        if (army.isHomeArmy) continue;
        moves.add(
          ResolvedArmyMove(
            factionId: factionId,
            army: army,
            destinationProvinceId: resolveArmyMoveDestinationProvinceId(
              army,
              order,
            ),
          ),
        );
      }
    }

    return PreCombatMovementIndex._(
      greatPowerIds: greatPowerIds,
      armiesById: armiesById,
      greatPowerArmyMoves: moves,
    );
  }
}
