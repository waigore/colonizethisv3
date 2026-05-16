import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ai_victory_config', () {
    test('provincesToVictoryFromOldWorldOwned matches 31 threshold', () {
      expect(provincesToVictoryFromOldWorldOwned(7), 24);
      expect(provincesToVictoryFromOldWorldOwned(31), 0);
      expect(provincesToVictoryFromOldWorldOwned(40), 0);
    });

    test('GP declare-war and build pace constants are configured', () {
      expect(kDeclareWarGpWeakNeighborBonus, greaterThan(0));
      expect(kBuildRegimentBonusWhenBehindVictoryPace, greaterThan(0));
    });
  });
}
