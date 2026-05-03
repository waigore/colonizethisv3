import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/stateful_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../test_fixtures.dart';

void main() {
  group('BuildOrderValidator', () {
    test('validate returns rejected when previousRejected is true', () {
      final game = TestFixtures.gameWithSingleOwnedProvince(id: 'g1');
      final validator = BuildOrderValidator(
        game: game,
        player: game.players.first,
      );
      expect(validator, isA<StatefulValidator>());
      final order = BuildUnitOrder(
        unitType: kUnitTypeBuilder,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = validator.validate(order, previousRejected: true);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test('civilian build is rejected when capital tile cannot be resolved', () {
      final game = TestFixtures.gameWithSingleOwnedProvince(
        id: 'g2',
        treasury: 999,
      );
      final validator = BuildOrderValidator(
        game: game,
        player: game.players.first,
      );
      final order = BuildUnitOrder(
        unitType: kUnitTypeBuilder,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );

      final result = validator.validate(order, previousRejected: false);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'No capital tile to spawn civilian unit');
    });
  });
}
