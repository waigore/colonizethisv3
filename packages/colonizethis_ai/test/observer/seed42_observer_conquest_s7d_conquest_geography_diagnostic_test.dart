// Topical S7-D conquest-geography diagnostic contract (Refs #2847 / #3967).
//
// Pins the geography / EXPAND-arm rollup JSON helper without re-running the
// 100-turn campaign. The campaign runner remains in
// `seed42_observer_conquest_s7d_diagnostic_test.dart`.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;
import 'package:colonizethis_test/test.dart';

import 'support/s7d/diagnostic_json.dart';

void main() {
  group('buildSeed42S7dConquestGeographyDiagnosticJson', () {
    test('positive: emits required conquest-geography keys', () {
      final json = buildSeed42S7dConquestGeographyDiagnosticJson(
        gpIds: const ['gp1'],
        gains: const {'gp1': 3},
        owStart: const {'gp1': 5},
        phaseCounts: {
          'gp1': {for (final ph in ObserverGoalPhase.values) ph: 0}
            ..[ObserverGoalPhase.expand] = 100,
        },
        declareWarPicks: const {
          'gp1': {'minor1': 2},
        },
        peaceTargetPicks: const {
          'gp1': {'gp2': 4},
        },
        economyArmCounts: const {
          'gp1': {
            'forceCheapestRegimentBuild': 1,
            'boostTreasuryRecoveryCargo': 2,
          },
        },
        invadableEmptyTurns: const {'gp1': 0},
        atWarTurnsByPeer: const {
          'gp1': {'gp2': 10},
        },
        lastSnapshotFields: const {
          'gp1': {'treasury': 100},
        },
      );

      expect(json['issue'], 2847);
      expect(
        Seed42S7dDiagnosticJsonKeys.conquestGeography.every(json.containsKey),
        isTrue,
      );
      expect(json['gpOwGain'], {'gp1': 3});
      expect(
        (json['gpPhaseTurnCount'] as Map<String, Object?>)['gp1'],
        containsPair('expand', 100),
      );
    });

    test('negative: conquest-geography keys do not include feedstock keys', () {
      final json = buildSeed42S7dConquestGeographyDiagnosticJson(
        gpIds: const ['gp1'],
        gains: const {'gp1': 0},
        owStart: const {'gp1': 0},
        phaseCounts: {
          'gp1': {for (final ph in ObserverGoalPhase.values) ph: 0},
        },
        declareWarPicks: const {'gp1': <String, int>{}},
        peaceTargetPicks: const {'gp1': <String, int>{}},
        economyArmCounts: const {
          'gp1': {
            'forceCheapestRegimentBuild': 0,
            'boostTreasuryRecoveryCargo': 0,
          },
        },
        invadableEmptyTurns: const {'gp1': 0},
        atWarTurnsByPeer: const {'gp1': <String, int>{}},
        lastSnapshotFields: const {'gp1': <String, Object?>{}},
      );

      for (final key in Seed42S7dDiagnosticJsonKeys.feedstock) {
        expect(
          json.containsKey(key),
          isFalse,
          reason: 'geography payload must not embed feedstock key $key',
        );
      }
    });
  });
}
