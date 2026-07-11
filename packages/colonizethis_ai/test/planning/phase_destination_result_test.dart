// Pins shared PhaseDestinationResult storage for military/naval plan type
// shells (Refs #3967 step 5 / AC-5). Public type names stay distinct while
// province/owner lists and equality live on the shared base.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialMilitaryPlan, ColonialNavalPlan;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandMilitaryPlan;
import 'package:colonizethis_test/test.dart';

void main() {
  group('PhaseDestinationResult shared type shell (Refs #3967 step 5)', () {
    test(
      'ExpandMilitaryPlan and ColonialMilitaryPlan share list equality shape',
      () {
        const expand = ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|p1'],
          priorityTargetOwnerFactionIdsSorted: <String>['minor_a'],
        );
        const colonial = ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|p1'],
          priorityTargetOwnerFactionIdsSorted: <String>['minor_a'],
        );

        expect(expand.priorityProvinceIdsSorted, ['oldWorld|p1']);
        expect(colonial.priorityProvinceIdsSorted, ['oldWorld|p1']);
        expect(expand.priorityDestinationProvinceIdsSorted, ['oldWorld|p1']);
        expect(colonial.priorityDestinationProvinceIdsSorted, ['oldWorld|p1']);
        // Distinct runtime types must not compare equal even with same lists.
        expect(expand == colonial, isFalse);
        expect(expand, equals(expand));
        expect(colonial, equals(colonial));
      },
    );

    test('ColonialNavalPlan and ColonialLiteNavalPlan keep domain getters', () {
      const naval = ColonialNavalPlan(
        priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|nw1'],
        priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
      );
      const lite = ColonialLiteNavalPlan(
        priorityNwProvinceIdsSorted: <String>['newWorld|nw1'],
        priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
      );

      expect(naval.priorityInvasionTransportProvinceIdsSorted, [
        'newWorld|nw1',
      ]);
      expect(lite.priorityNwProvinceIdsSorted, ['newWorld|nw1']);
      expect(naval.priorityProvinceIdsSorted, lite.priorityProvinceIdsSorted);
      expect(naval == lite, isFalse);
    });

    test(
      'defaultPlan empty shells remain equal to explicit empty instances',
      () {
        expect(
          ExpandMilitaryPlan.defaultPlan,
          const ExpandMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>[],
            priorityTargetOwnerFactionIdsSorted: <String>[],
          ),
        );
        expect(
          ColonialNavalPlan.defaultPlan,
          const ColonialNavalPlan(
            priorityInvasionTransportProvinceIdsSorted: <String>[],
            priorityTargetOwnerFactionIdsSorted: <String>[],
          ),
        );
      },
    );

    test('negative: differing owner lists break equality', () {
      const a = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|p1'],
        priorityTargetOwnerFactionIdsSorted: <String>['minor_a'],
      );
      const b = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|p1'],
        priorityTargetOwnerFactionIdsSorted: <String>['minor_b'],
      );
      expect(a == b, isFalse);
    });
  });
}
