// Compact BuildOrderValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/stateful_validator.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [buildOrderValidatorScenarios] rows.
enum BuildOrderValidatorTarget {
  validateRejectedWhenPreviousRejected,
  civilianBuildRejectedNoCapitalTile,
}

void runBuildOrderValidatorExpectation(BuildOrderValidatorTarget target) {
  switch (target) {
    case BuildOrderValidatorTarget.validateRejectedWhenPreviousRejected:
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

    case BuildOrderValidatorTarget.civilianBuildRejectedNoCapitalTile:
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
  }
}
