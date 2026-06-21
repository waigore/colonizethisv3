import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('terrain prospectability classification', () {
    test('defines prospectability for every terrain type', () {
      expect(kProspectableByTerrainType.keys.toSet(), TerrainType.values.toSet());
    });

    test('matches canonical mineral prospecting terrain rules', () {
      expect(kProspectableByTerrainType[TerrainType.plains], isFalse);
      expect(kProspectableByTerrainType[TerrainType.hardwoodForest], isFalse);
      expect(kProspectableByTerrainType[TerrainType.scrubForest], isFalse);
      expect(kProspectableByTerrainType[TerrainType.hills], isTrue);
      expect(kProspectableByTerrainType[TerrainType.mountain], isTrue);
      expect(kProspectableByTerrainType[TerrainType.swamp], isTrue);
      expect(kProspectableByTerrainType[TerrainType.desert], isTrue);
    });
  });
}
