// SPEC/game/capital-choice-phase — Class A/B/C tile classification
// (Refs #4086 Slice B de-part; extracted to break tile_scan ↔ root cycle).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'capital_choice_port_road_geometry.dart';

/// Capital tile class per SPEC/game/capital-choice-phase:
/// - A: coastal and not adjacent to another province
/// - B: interior and not adjacent to another province
/// - C: all remaining tiles
enum CapitalTileClass { a, b, c }

/// Classifies a province tile according to capital-choice class A/B/C.
CapitalTileClass classifyCapitalTile({
  required int x,
  required int y,
  required TileMapResult tileMap,
  required MapTopology topology,
  required String localProvinceId,
  Set<String>? provinceIds,
}) {
  final knownProvinceIds = provinceIds ?? provinceNodeIds(topology);
  final coastal = isTileAdjacentToSea(
    x,
    y,
    tileMap,
    topology,
    provinceIds: knownProvinceIds,
  );
  final adjacentOtherProvince = isTileAdjacentToOtherProvince(
    x,
    y,
    tileMap,
    knownProvinceIds,
    localProvinceId,
  );
  if (coastal && !adjacentOtherProvince) return CapitalTileClass.a;
  if (!coastal && !adjacentOtherProvince) return CapitalTileClass.b;
  return CapitalTileClass.c;
}
