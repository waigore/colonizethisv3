// sortNavalMissionsForColonialPressure tier cases for naval mission ranking pins.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_mission_ranking_support.dart';

void registerPhasePlannerNavalMissionRankingSortCases() {
  group('sortNavalMissionsForColonialPressure (phase-priority tier)', () {
    test('phase-priority NW-port mission ranks ahead of unrelated NW-port '
        'mission even with smaller fleetId on the unrelated candidate', () {
      final ranked = sortNavalMissionsForColonialPressure([
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
      ], phasePriorityNwProvinceIdsSorted: phasePriorityIds);
      expect(ranked.first.fleetId, 'fB');
      expect(ranked.first.targetPortId, 'newWorld|phaseColony');
      expect(ranked.last.fleetId, 'fA');
    });

    test('null phasePriorityNwProvinceIdsSorted falls back to legacy ordering '
        '(both NW-port missions score 160; fleetId asc dominates)', () {
      final ranked = sortNavalMissionsForColonialPressure([
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
      ]);
      expect(ranked.first.fleetId, 'fA');
      expect(ranked.last.fleetId, 'fB');
    });

    test('deterministic sort for identical inputs (Must-have #7)', () {
      List<String> fingerprint(List<NavalMissionOrder> missions) => <String>[
        for (final m in missions)
          '${m.fleetId}|${m.targetPortId ?? ''}|${m.targetProvinceId ?? ''}',
      ];
      final input = <NavalMissionOrder>[
        const NavalMissionOrder(
          fleetId: 'fA',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        ),
        const NavalMissionOrder(
          fleetId: 'fB',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        ),
      ];
      final first = sortNavalMissionsForColonialPressure(
        input,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final second = sortNavalMissionsForColonialPressure(
        input,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(fingerprint(second), fingerprint(first));
    });
  });
}
