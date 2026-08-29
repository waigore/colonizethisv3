// Tail case bodies for
// `colonial_phase_planner_colonial_lite_naval_suppression_cases.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerColonialLiteNavalSuppressionTailCases() {
  test('input order shuffled -> ascending sort recovers', () {
    final game = buildColonialLiteNavalGame(
      newWorldProvinces: const [
        Province(
          id: 'newWorld|tribe1_a',
          regionId: 'newWorld',
          ownerId: kColonialPhaseTribe1,
        ),
        Province(
          id: 'newWorld|tribe1_b',
          regionId: 'newWorld',
          ownerId: kColonialPhaseTribe1,
        ),
        Province(
          id: 'newWorld|minor1_a',
          regionId: 'newWorld',
          ownerId: kColonialPhaseMinor1,
        ),
      ],
      tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      minorNations: const [
        MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
      ],
    );
    final snapshot = buildColonialLiteNavalSnapshot(
      invadableNw: const [
        'newWorld|tribe1_b',
        'newWorld|tribe1_a',
        'newWorld|minor1_a',
      ],
    );
    final plan = planColonialLiteNaval(game: game, snapshot: snapshot);
    expect(
      plan.priorityNwProvinceIdsSorted,
      const <String>[
        'newWorld|minor1_a',
        'newWorld|tribe1_a',
        'newWorld|tribe1_b',
      ],
      reason: 'Trailing sort recovers ascending order across reversed input.',
    );
    expect(
      plan.priorityTargetOwnerFactionIdsSorted,
      const <String>[kColonialPhaseMinor1, kColonialPhaseTribe1],
      reason: 'Owner list also sorted ascending across the dedup set.',
    );
  });

  test('ColonialLiteNavalPlan value equality + defaultPlan equals explicit '
      'all-empty instance', () {
    const planA = ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
      priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
    );
    const planB = ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
      priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
    );
    expect(planA, equals(planB));
    expect(planA.hashCode, equals(planB.hashCode));

    const explicitDefault = ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>[],
      priorityTargetOwnerFactionIdsSorted: <String>[],
    );
    expect(
      ColonialLiteNavalPlan.defaultPlan,
      equals(explicitDefault),
      reason:
          'defaultPlan compares equal to a fresh all-empty const '
          'instance; orchestrator wiring tests can assert against '
          'either form.',
    );

    expect(
      planA.toString(),
      equals(
        'ColonialLiteNavalPlan('
        'priorityNwProvinceIdsSorted: [newWorld|tribe1_a], '
        'priorityTargetOwnerFactionIdsSorted: [tribe1])',
      ),
    );
  });
}
