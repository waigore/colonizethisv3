import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('pickUniqueGreatPowerLeaderByPowerScore', () {
    test('returns sole leader when scores differ', () {
      final game = twoGpGameWithFleets(
        shipTypesGp1: const ['carrack'],
        shipTypesGp2: const ['carrack', 'carrack', 'carrack'],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), 'gp2');
    });

    test('returns null on tie', () {
      final game = twoGpGameWithFleets(
        shipTypesGp1: const ['carrack', 'carrack'],
        shipTypesGp2: const ['carrack', 'carrack'],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), isNull);
    });
  });
}
