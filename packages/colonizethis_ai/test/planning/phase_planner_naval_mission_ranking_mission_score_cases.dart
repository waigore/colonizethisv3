// colonialNavalMissionScore tier cases for phase_planner_naval_mission_ranking pins.

import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_mission_ranking_support.dart';

void registerPhasePlannerNavalMissionRankingMissionScoreCases() {
  group('colonialNavalMissionScore (phase-priority port tier)', () {
    test(
      'phase-priority NW port returns the new tier (200) above legacy (160)',
      () {
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'newWorld|phaseColony',
        );
        final score = colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(score, kColonialNavalMissionPhasePriorityNwPortScore);
        expect(
          score,
          greaterThan(kColonialNavalMissionNwPortScore),
          reason:
              'Phase-priority NW-port tier must rank strictly above the '
              'legacy NW-port tier so missions toward the phase-active '
              'frontier outrank unrelated NW-port missions on the same '
              'turn.',
        );
      },
    );

    test(
      'non-priority NW port still returns the legacy NW-port tier (160)',
      () {
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'newWorld|otherColony',
        );
        final score = colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        );
        expect(
          score,
          kColonialNavalMissionNwPortScore,
          reason:
              'Non-phase NW-port missions must remain in the legacy NW-port '
              'tier; the new top tier only fires for phase-active provinces.',
        );
      },
    );

    test(
      'null phasePriorityNwProvinceIdsSorted preserves legacy NW-port tier',
      () {
        for (final portId in const <String>[
          'newWorld|phaseColony',
          'newWorld|otherColony',
        ]) {
          expect(
            colonialNavalMissionScore(
              NavalMissionOrder(
                fleetId: 'f1',
                mission: 'patrol',
                targetPortId: portId,
              ),
            ),
            kColonialNavalMissionNwPortScore,
          );
        }
      },
    );

    test(
      'empty phasePriorityNwProvinceIdsSorted preserves legacy NW-port tier',
      () {
        for (final portId in const <String>[
          'newWorld|phaseColony',
          'newWorld|otherColony',
        ]) {
          expect(
            colonialNavalMissionScore(
              NavalMissionOrder(
                fleetId: 'f1',
                mission: 'patrol',
                targetPortId: portId,
              ),
              phasePriorityNwProvinceIdsSorted: const <String>[],
            ),
            kColonialNavalMissionNwPortScore,
          );
        }
      },
    );

    test(
      'phase-priority list does not promote OW ports (legacy 0 preserved)',
      () {
        const mission = NavalMissionOrder(
          fleetId: 'f1',
          mission: 'patrol',
          targetPortId: 'oldWorld|home',
        );
        expect(
          colonialNavalMissionScore(
            mission,
            phasePriorityNwProvinceIdsSorted: phasePriorityIds,
          ),
          0,
        );
      },
    );
  });

  group('colonialNavalMissionScore (phase-priority province tier)', () {
    test('phase-priority NW province returns the new tier (170) above legacy '
        '(130)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'newWorld|phaseColony',
      );
      final score = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(score, kColonialNavalMissionPhasePriorityNwProvinceScore);
      expect(
        score,
        greaterThan(kColonialNavalMissionNwProvinceScore),
        reason:
            'Phase-priority NW-province tier must rank strictly above the '
            'legacy NW-province tier (Refs #2509 S5).',
      );
    });

    test('non-priority NW province still returns the legacy NW-province tier '
        '(130)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'newWorld|otherColony',
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMissionNwProvinceScore,
      );
    });

    test('phase-priority list does not promote OW province targets', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetProvinceId: 'oldWorld|home',
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        0,
      );
    });

    test('beachhead mission with phase-priority list still scores at beachhead '
        'tier (no priority promotion when no NW target id)', () {
      final mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: FleetMission.beachhead.name,
      );
      expect(
        colonialNavalMissionScore(
          mission,
          phasePriorityNwProvinceIdsSorted: phasePriorityIds,
        ),
        kColonialNavalMissionBeachheadScore,
      );
    });

    test('deterministic for identical inputs (Must-have #7)', () {
      const mission = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'patrol',
        targetPortId: 'newWorld|phaseColony',
      );
      final a = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      final b = colonialNavalMissionScore(
        mission,
        phasePriorityNwProvinceIdsSorted: phasePriorityIds,
      );
      expect(a, b);
    });
  });
}
