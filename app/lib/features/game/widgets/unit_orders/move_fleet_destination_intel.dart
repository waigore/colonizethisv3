// Fog-respecting at-sea destination intel for DLG30001. SPEC/ui/move-fleet-dialog.md (#4573).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

enum MoveFleetDestinationIntelLevel { unknown, full }

/// Player-legal hostile-fleet gist for one sea-zone move destination.
class MoveFleetDestinationIntelSummary {
  const MoveFleetDestinationIntelSummary({
    required this.intelLevel,
    this.hostileAtSeaCount,
    this.anyHostilePatrol,
    this.anyHostileBlockade,
  });

  final MoveFleetDestinationIntelLevel intelLevel;
  final int? hostileAtSeaCount;
  final bool? anyHostilePatrol;
  final bool? anyHostileBlockade;

  bool get hasHostilePresence =>
      intelLevel == MoveFleetDestinationIntelLevel.full &&
      (hostileAtSeaCount ?? 0) > 0;
}

/// True when at least one water tile in the destination sea is not unrevealed
/// (same honesty bar as MAP20001 Naval for a sea zone).
bool moveFleetSeaZoneShowsFleetIntel({
  required Game game,
  required PlayerView view,
  required String regionId,
  required String seaZoneId,
}) {
  final bucket = canonicalSeaZoneTileBucketKey(regionId, seaZoneId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[regionId]?[bucket] ??
      const <String>[];
  for (final tk in tileKeys) {
    if (view.visibilityForTile(tk) != VisibilityLevel.unknown) return true;
  }
  return false;
}

bool _fleetMatchesDestinationSea({
  required Fleet fleet,
  required String regionId,
  required String destinationSeaZoneId,
}) {
  if (!fleet.isAtSea || fleet.seaZoneId == null || fleet.regionId != regionId) {
    return false;
  }
  final expected = canonicalSeaZoneTileBucketKey(regionId, destinationSeaZoneId);
  final actual = canonicalSeaZoneTileBucketKey(regionId, fleet.seaZoneId!);
  return expected == actual;
}

MoveFleetDestinationIntelSummary computeMoveFleetDestinationIntelSummary({
  required Game game,
  required PlayerView? playerView,
  required String humanPlayerId,
  required String regionId,
  required String destinationSeaZoneId,
}) {
  const unknown = MoveFleetDestinationIntelSummary(
    intelLevel: MoveFleetDestinationIntelLevel.unknown,
  );
  if (playerView == null ||
      !moveFleetSeaZoneShowsFleetIntel(
        game: game,
        view: playerView,
        regionId: regionId,
        seaZoneId: destinationSeaZoneId,
      )) {
    return unknown;
  }

  final enemies = enemiesOf(game, humanPlayerId);
  var hostileCount = 0;
  var anyPatrol = false;
  var anyBlockade = false;
  for (final fleet in game.worldState.fleets) {
    if (!_fleetMatchesDestinationSea(
          fleet: fleet,
          regionId: regionId,
          destinationSeaZoneId: destinationSeaZoneId,
        ) ||
        !enemies.contains(fleet.ownerId)) {
      continue;
    }
    hostileCount++;
    if (fleet.mission == FleetMission.patrol) anyPatrol = true;
    if (fleet.mission == FleetMission.blockade) anyBlockade = true;
  }

  return MoveFleetDestinationIntelSummary(
    intelLevel: MoveFleetDestinationIntelLevel.full,
    hostileAtSeaCount: hostileCount,
    anyHostilePatrol: anyPatrol,
    anyHostileBlockade: anyBlockade,
  );
}
