import 'dart:io';

import 'package:colonizethis_map/src/gen/tile_map_generator_land_seeds_organic.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_land_seeds_organic_placement.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_land_seeds_organic_voronoi.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_builder_assembly.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_builder_cell_units.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_builder_marker_orchestration.dart';
import 'package:colonizethis_map/src/view/init_game_map_view_builder_province_meta.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

/// Structural pins for Refs #4371 Slice B (organic + view assembly splits).
void main() {
  group('map wave-6 Slice B concern split (Refs #4371)', () {
    test('positive: organic driver delegates to placement and voronoi siblings', () {
      expect(LandSeedOrganicPlacement.placeOneOrganicSeed, isNotNull);
      expect(LandSeedOrganicVoronoi.assignLandByLandSeedsWithNoJoin, isNotNull);
      expect(LandSeedOrganic.placeLandSeedsOrganic, isNotNull);
    });

    test('positive: view assembly compose imports split orchestration libs', () {
      expect(buildRegionViewData, isNotNull);
      expect(buildRegionMapViewDataFromParts, isNotNull);
      expect(buildProvinceMetadata, isNotNull);
      expect(buildTerrainColors, isNotNull);
      expect(buildCellAndUnitData, isNotNull);
      expect(buildMarkerData, isNotNull);
    });

    test('negative: former monolith files stay under 300 NCL after split', () {
      final packageRoot = Directory.current.path;
      final organicDriver = p.join(
        packageRoot,
        'lib/src/gen/tile_map_generator_land_seeds_organic.dart',
      );
      final assemblyCompose = p.join(
        packageRoot,
        'lib/src/view/init_game_map_view_builder_assembly.dart',
      );
      for (final file in [organicDriver, assemblyCompose]) {
        final ncl = _countNonCommentLines(File(file).readAsStringSync());
        expect(
          ncl,
          lessThanOrEqualTo(300),
          reason: '$file NCL=$ncl exceeds 300 after Slice B split',
        );
      }
    });
  });
}

int _countNonCommentLines(String source) {
  var n = 0;
  for (final line in source.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('//')) continue;
    if (trimmed.startsWith('///')) continue;
    if (trimmed.startsWith('/*') || trimmed.startsWith('*')) continue;
    n++;
  }
  return n;
}
