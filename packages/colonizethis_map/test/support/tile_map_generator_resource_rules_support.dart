import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void expectResourcesRespectRules(TileMapResult result, String regionId) {
  final rules = ResourceRules.defaultRules;
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final t = result.terrainAt(x, y);
      final r = result.resourceAt(x, y);
      if (t != null && r != null) {
        expect(rules.isAllowedOnTerrain(r, t), isTrue);
        expect(rules.isAllowedInRegion(r, regionId), isTrue);
      }
    }
  }
}

void expectTerrainGridDimensions(TileMapResult result) {
  expect(result.terrainGrid, isNotNull);
  expect(result.resourceGrid, isNotNull);
  expect(result.terrainGrid!.length, result.height);
  expect(result.resourceGrid!.length, result.height);
  for (var i = 0; i < result.height; i++) {
    expect(result.terrainGrid![i].length, result.width);
    expect(result.resourceGrid![i].length, result.width);
  }
}
