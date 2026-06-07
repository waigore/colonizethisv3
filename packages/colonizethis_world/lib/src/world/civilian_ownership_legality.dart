import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../game_player_lookup.dart';
import 'faction_membership.dart';
import 'civilian_tile_occupancy.dart';
import 'province_lookup.dart';

CapitalTile? capitalTileForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  if (player?.capitalTile != null) {
    return player!.capitalTile;
  }
  for (final minor in game.minorNations) {
    if (minor.id == factionId) {
      return minor.capitalTile;
    }
  }
  for (final tribe in game.tribes) {
    if (tribe.id == factionId) {
      return tribe.capitalTile;
    }
  }
  return null;
}

/// Runs ownership-change civilian legality normalization for [changedProvinceIds].
///
/// For civilians in changed provinces:
/// - keep in place when [civilianMayOccupyLandTileKey] says current tile is legal.
/// - relocate to owner capital tile when current tile is illegal.
/// - fail hard if relocation is required but owner capital tile cannot be resolved.
Game relocateIllegalCiviliansInChangedProvinces(
  Game game, {
  required Set<String> changedProvinceIds,
}) {
  if (changedProvinceIds.isEmpty) return game;

  final factionMembership = DiplomacyFactionMembership.from(game);

  Unit normalizeIllegalCivilian(Unit unit) {
    if (!changedProvinceIds.contains(unit.locationProvinceId)) {
      return unit;
    }
    final currentTileKey = unit.tileKey;
    if (currentTileKey == null || currentTileKey.isEmpty) {
      return unit;
    }
    if (civilianMayOccupyLandTileKey(
      game: game,
      playerId: unit.ownerId,
      unitType: unit.type,
      destinationTileKey: currentTileKey,
      factionMembership: factionMembership,
    )) {
      return unit;
    }

    final capitalTileKey = capitalTileForFaction(game, unit.ownerId)?.toTileKey();
    if (capitalTileKey == null || capitalTileKey.isEmpty) {
      throw StateError(
        'Cannot relocate illegal civilian ${unit.id}: missing capital tile for owner ${unit.ownerId}',
      );
    }
    final capitalProvinceId = Unit.provinceIdFromTileKey(capitalTileKey);
    if (capitalProvinceId == null ||
        tryGetProvince(game.worldState, capitalProvinceId) == null) {
      throw StateError(
        'Cannot relocate illegal civilian ${unit.id}: unresolved capital province for owner ${unit.ownerId}',
      );
    }

    worldLog.d(
      'civilian legality relocation unit=${unit.id} owner=${unit.ownerId} from=${unit.tileKey} to=$capitalTileKey',
    );
    return unit.copyWith(
      locationProvinceId: capitalProvinceId,
      tileKey: capitalTileKey,
      status: UnitStatus.idle,
      clearCurrentWork: true,
      clearOriginTileKey: true,
      clearAssignedTileKey: true,
    );
  }

  bool isCivilian(Unit u) =>
      !canUnitInitiateCombat(u.type) && !isShipUnitType(u.type);

  return game.copyWith(
    worldState: game.worldState.mapBothRegionUnits(
      (_, units) => units
          .map((u) => isCivilian(u) ? normalizeIllegalCivilian(u) : u)
          .toList(growable: false),
    ),
  );
}
