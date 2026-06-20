// Shared fixture helpers for `non_gp_extraction_part*_test.dart`.
//
// Kept here (rather than inlined per file) so the suite stays inside the
// 400-line `repo.logic_test_file_size` lint budget while still using the same
// minimal-Game fixtures across the part-1 (positive / SPEC-AC) and part-2
// (negative / boundary / aggregation) suites. Refs #2991 C2.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// A capital-province row with sane defaults for non-GP extraction tests:
/// town dev = 1 (matches starting developed tile level), region inferred from
/// the prefixed [provinceId].
Province capitalProvinceForNonGpExtractionTest({
  required String provinceId,
  int townDev = 1,
}) {
  final regionId = provinceId.split('|').first;
  final factionId = provinceId.split('|').last;
  return Province(
    id: provinceId,
    regionId: regionId,
    ownerId: factionId,
    townDevelopmentLevel: townDev,
  );
}

/// Square tile map of size [width] × [height] where every cell belongs to the
/// same prefixed [provinceId] and resources are read from [resources].
TileMapResult tileMapAllInProvinceForNonGpExtractionTest({
  required String provinceId,
  required int width,
  required int height,
  required List<List<Resource?>> resources,
}) {
  final localId = provinceId.split('|').last;
  final grid = List<List<String>>.generate(
    height,
    (_) => List<String>.filled(width, localId),
  );
  return TileMapResult(
    width: width,
    height: height,
    grid: grid,
    resourceGrid: resources,
  );
}

/// Builds a minimal [Game] hosting the supplied non-GP factions. Used by the
/// test suite to keep each scenario's setup local and readable.
Game gameForNonGpExtractionTest({
  required List<Province> provinces,
  TileMapState? tileState,
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  int capitalTileGrainBonusPerTurn = 0,
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g_test',
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    worldState: WorldState(
      turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileState: tileState ?? TileMapState(),
    ),
    players: const [],
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// A standard one-tile minor nation in `oldWorld|m1` with capital at (0,0),
/// used by part-1 and part-2 suites to keep boilerplate down.
MinorNation testMinor({
  String id = 'm1',
  String provinceId = 'oldWorld|m1',
  int capitalX = 0,
  int capitalY = 0,
}) {
  return MinorNation(
    id: id,
    capitalProvinceId: provinceId,
    capitalTile: CapitalTile(
      regionId: provinceId.split('|').first,
      provinceId: provinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}

/// A standard one-tile tribe in `newWorld|t1` with capital at (0,0).
Tribe testTribe({
  String id = 't1',
  String provinceId = 'newWorld|t1',
  int capitalX = 0,
  int capitalY = 0,
}) {
  return Tribe(
    id: id,
    capitalProvinceId: provinceId,
    capitalTile: CapitalTile(
      regionId: provinceId.split('|').first,
      provinceId: provinceId,
      x: capitalX,
      y: capitalY,
    ),
  );
}
