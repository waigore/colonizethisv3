import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_choice_capital_tile_scan.dart';

export 'package:colonizethis_world/colonizethis_world.dart'
    show
        applyGreatPowerCapitalProvinceTownDevelopment,
        pickCapitalProvinceIdForReassignment,
        setCapitalForMinorReassignment,
        setCapitalForReassignment,
        setCapitalForTribeReassignment;

export 'package:colonizethis_data/colonizethis_data.dart'
    show isProvinceSeaBound;

export 'capital_choice_classify.dart';
export 'capital_choice_mutators.dart';

/// Capital-choice phase stub. SPEC/game/capital-choice-phase.
///
/// setCapital validates province is sea-bound, sets player capital, and
/// auto-builds port (on capital if coastal, else nearest coastal tile) and road.

/// Picks a capital province and tile for a faction. SPEC/game/capital-choice-phase#auto-choice-game-setup.
/// [ownedProvinceIds] and [regionId] come from assignment; [topology] and [tileMap] are for that region.
/// Returns (provinceId, CapitalTile). When [requireSeaBound] is true (GPs), throws if no sea-bound province.
/// When [requireSeaBound] is false (minors/tribes), falls back to first owned province if none are sea-bound.
(String provinceId, CapitalTile tile) pickCapitalForFaction(
  List<String> ownedProvinceIds,
  String regionId,
  MapTopology topology,
  TileMapResult tileMap, {
  bool requireSeaBound = true,
}) {
  final provinceId = capitalProvinceIdFromSeaBoundOrFallback(
    ownedProvinceIds,
    topology,
    requireSeaBound: requireSeaBound,
  );

  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  // Tile choice with border-avoidance heuristic:
  // Class A: coastal tiles not adjacent to other provinces.
  // Class B: interior tiles not adjacent to other provinces.
  // Class C: remaining tiles.
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();

  final c = scanCapitalTileCandidates(
    tileMap: tileMap,
    topology: topology,
    localProvinceId: localProvinceId,
    provinceIds: provinceIds,
  );

  final (x, y) = capitalTileXYFromScan(
    requireSeaBound: requireSeaBound,
    provinceId: provinceId,
    regionId: regionId,
    classAx: c.classAx,
    classAy: c.classAy,
    classAPlainsX: c.classAPlainsX,
    classAPlainsY: c.classAPlainsY,
    classBx: c.classBx,
    classBy: c.classBy,
    classBPlainsX: c.classBPlainsX,
    classBPlainsY: c.classBPlainsY,
    classCx: c.classCx,
    classCy: c.classCy,
    classCPlainsX: c.classCPlainsX,
    classCPlainsY: c.classCPlainsY,
    classCCoastalX: c.classCCoastalX,
    classCCoastalY: c.classCCoastalY,
    classCCoastalPlainsX: c.classCCoastalPlainsX,
    classCCoastalPlainsY: c.classCCoastalPlainsY,
  );
  final tile = CapitalTile(
    regionId: regionId,
    provinceId: provinceId,
    x: x,
    y: y,
  );
  return (provinceId, tile);
}
