import 'dart:io';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/economy_planner_labour_input.dart';
import 'package:colonizethis_ai/src/planning/full_ai_planner_merge.dart'
    show orderedFullAiPlayerIds;
import 'package:colonizethis_ai/src/planning/strategic_ai_goal_prep.dart';
import 'package:colonizethis_ai/src/planning/strategic_planning_input.dart';
import 'package:colonizethis_ai/src/planning/treasury_planner_emit_input_lock_recovery_seller_flags.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import '../support/full_ai_planner_test_support.dart';

void main() {
  final planningDir = Directory(
    p.join(Directory.current.path, 'lib', 'src', 'planning'),
  );

  group('phase-15 planner seams (Refs #4530 Slice A)', () {
    test('full_ai_planner façade re-exports setup and merge siblings', () {
      final facade = File(p.join(planningDir.path, 'full_ai_planner.dart'));
      final source = facade.readAsStringSync();
      expect(source, contains("export 'full_ai_planner_player_setup.dart';"));
      expect(
        source,
        contains(
          "export 'full_ai_planner_merge.dart' hide orderedFullAiPlayerIds;",
        ),
      );
      expect(source, isNot(contains("part '")));
      expect(source, isNot(contains('part of ')));
      expect(
        facade.readAsLinesSync().length,
        lessThanOrEqualTo(270),
        reason: 'former 273-line host keeps ≥30 lines of headroom under 300',
      );
    });

    test('labour input types are not co-located with allocateLabour', () {
      final labour = File(
        p.join(planningDir.path, 'economy_planner_labour.dart'),
      ).readAsStringSync();
      final input = File(
        p.join(planningDir.path, 'economy_planner_labour_input.dart'),
      ).readAsStringSync();
      expect(labour, contains("import 'economy_planner_labour_input.dart';"));
      expect(labour, isNot(contains('final class LabourAllocationInput')));
      expect(input, contains('final class LabourAllocationInput'));
      expect(input, contains('missingCheapestRegimentBuildInputIds'));
      expect(labour, isNot(contains("part '")));
    });

    test('seller flags are not co-located with emit-context shaping', () {
      final emit = File(
        p.join(
          planningDir.path,
          'treasury_planner_emit_input_lock_recovery.dart',
        ),
      ).readAsStringSync();
      final flags = File(
        p.join(
          planningDir.path,
          'treasury_planner_emit_input_lock_recovery_seller_flags.dart',
        ),
      ).readAsStringSync();
      expect(
        emit,
        contains(
          "import 'treasury_planner_emit_input_lock_recovery_seller_flags.dart';",
        ),
      );
      expect(
        emit,
        isNot(contains('final class TreasuryLockRecoverySellerFlags')),
      );
      expect(flags, contains('final class TreasuryLockRecoverySellerFlags'));
      expect(emit, contains('TreasuryEmitLockRecoveryContext'));
      expect(emit, isNot(contains("part '")));
    });

    test('strategic_ai dispatches after extracted goal/army prep', () {
      final strategic = File(
        p.join(planningDir.path, 'strategic_ai.dart'),
      ).readAsStringSync();
      expect(strategic, contains("import 'strategic_ai_goal_prep.dart';"));
      expect(strategic, contains('prepareStrategicAiGoalAndArmy'));
      expect(strategic, isNot(contains("part '")));
    });
  });

  group('orderedFullAiPlayerIds', () {
    test('turn 0 with six GPs starts at gp3 (Refs #2509 rotation)', () {
      const ids = ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6'];
      expect(orderedFullAiPlayerIds(aiPlayerIds: ids, turn: 0), [
        'gp3',
        'gp4',
        'gp5',
        'gp6',
        'gp1',
        'gp2',
      ]);
    });

    test('empty roster stays empty', () {
      expect(orderedFullAiPlayerIds(aiPlayerIds: const [], turn: 5), isEmpty);
    });
  });

  group('missingCheapestRegimentBuildInputIds', () {
    test('empty stockpile reports every peasant-levy input', () {
      final missing = missingCheapestRegimentBuildInputIds(const Stockpile());
      expect(
        missing,
        RegimentEconomyCatalog.peasantLevies.buildInputs.keys.toSet(),
      );
      expect(missing, isNotEmpty);
    });

    test('stockpile covering every levy input reports none missing', () {
      var stockpile = const Stockpile();
      for (final entry
          in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
        stockpile = stockpile.applyDelta(entry.key, entry.value);
      }
      expect(missingCheapestRegimentBuildInputIds(stockpile), isEmpty);
    });
  });

  group('resolveTreasuryLockRecoverySellerFlags', () {
    test('minimal GP is not a lock-recovery seller', () {
      final game = fullAiPlannerMinimalGame(
        players: const [Player(id: 'gp1', displayName: 'AI', isHuman: false)],
      );
      final flags = resolveTreasuryLockRecoverySellerFlags(
        game: game,
        playerId: 'gp1',
      );
      expect(flags.isLockRecoverySeller, isFalse);
      expect(flags.isRegimentBuildInputMarketSupplier, isFalse);
    });
  });

  group('prepareStrategicAiGoalAndArmy', () {
    test('selects a primary goal before phase dispatch', () {
      final game = fullAiPlannerMinimalGame(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final prep = prepareStrategicAiGoalAndArmy(
        StrategicPlanningInput(
          game: game,
          topology: topology,
          nationId: 'gp1',
          view: view,
          config: const AIConfig(
            leaderId: 'victoria',
            personalityId: 'victoria',
            hiddenAgendaId: 'peacemaker',
          ),
          seeds: AISeedBundle.fromTurnSeed(999),
          suggestionAPI: const DefaultOrderSuggestionAPI(),
        ),
      );
      expect(prep.primaryGoal, isA<StrategicGoal>());
      expect(prep.goalScores, isNotEmpty);
      expect(prep.planningGame.id, game.id);
    });
  });
}
