// Scenario run tear-offs for orderValidationPhasePlan (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_engine_validation.dart';
import 'package:colonizethis_test/test.dart';

void oevppRunDeclaresCanonicalPerCategoryPhaseOrder() {
  expect(orderValidationPhasePlan.map((p) => p.name).toList(), <String>[
    'move',
    'army-move',
    'recruit-worker',
    'build',
    'work',
    'diplomatic',
    'naval',
    'trade',
  ]);
}

void oevppRunPhaseNamesAreUnique() {
  final names = orderValidationPhasePlan.map((p) => p.name).toList();
  expect(
    names.toSet().length,
    names.length,
    reason: 'duplicate phase name in $names',
  );
}

void oevppRunMoveArmyMoveShareInitialBundleResourcePhasesRefreshTradeReuses() {
  final refreshByName = <String, bool>{
    for (final p in orderValidationPhasePlan) p.name: p.refreshBundleBefore,
  };
  expect(refreshByName['move'], isFalse);
  expect(refreshByName['army-move'], isFalse);
  for (final name in const [
    'recruit-worker',
    'build',
    'work',
    'diplomatic',
    'naval',
  ]) {
    expect(
      refreshByName[name],
      isTrue,
      reason: '$name must refresh the validator bundle',
    );
  }
  expect(refreshByName['trade'], isFalse);
}
