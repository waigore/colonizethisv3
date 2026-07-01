// Shared tile-map builders for economy test suites (Refs #3661, #3823).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// A 1×1 [TileMapResult] for [province] (local id, default `p1`) carrying
/// [resource] (`null` for an empty/no-resource tile).
TileMapResult singleTileMap(Resource? resource, {String province = 'p1'}) =>
    TileMapResult(
      width: 1,
      height: 1,
      grid: [
        [province],
      ],
      resourceGrid: [
        [resource],
      ],
    );

/// 1×1 [TileMapResult] keyed to [province] carrying [resource].
TileMapResult singleResourceTileMap(
  Resource resource, {
  String province = 'M1',
}) =>
    singleTileMap(resource, province: province);

/// Builds a single-region `tileMapByRegion` map for [regionId] placing
/// [resource] at coordinates `(0, 0)` of [province].
Map<String, TileMapResult> tileMapByRegionForResource(
  Resource resource, {
  String regionId = 'oldWorld',
  String province = 'M1',
}) {
  return {regionId: singleResourceTileMap(resource, province: province)};
}
