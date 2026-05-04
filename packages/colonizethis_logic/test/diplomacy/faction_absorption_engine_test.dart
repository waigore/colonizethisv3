import 'package:colonizethis_logic/src/diplomacy/faction_absorption_engine.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('FactionAbsorptionEngine', () {
    test('absorbGreatPowerIntoGp is a no-op when absorber or target is missing', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'only', displayName: 'Solo', isHuman: true),
        ],
      );
      expect(
        identical(
          game,
          FactionAbsorptionEngine.absorbGreatPowerIntoGp(
            game,
            'gpA',
            'gpB',
          ),
        ),
        isTrue,
      );
    });
  });
}
