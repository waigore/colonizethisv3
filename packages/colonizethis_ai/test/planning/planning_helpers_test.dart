// Smoke coverage for the `planning_helpers.dart` barrel (Refs #3941).
// Topic unit contracts live in `planning_*_test.dart` siblings; this file only
// pins that the barrel re-exports remain resolvable after the topic split.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('barrel re-exports topic helpers', () {
    expect(clampPhaseWeightUpperUnit(2.0), 1.0);
    expect(planningListEquals(const ['a'], const ['a']), isTrue);
    expect(resolvePhaseColonialPressureActive, isNotNull);
    expect(gpFactionIdsAtWarWith, isNotNull);
  });
}
