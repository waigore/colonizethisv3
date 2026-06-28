// Seed-42 integration pin: `planExpandDeclareWar` arm 2 after treasury collapse.
//
// PR #2823's 10-turn trace on `origin/dev` showed gp1/gp4/gp5 returning
// `null` from turn 4 onward once `treasury < cheapestRegimentBuildTreasuryCost`
// despite at-war minors still owning invadable OW provinces — the function-level
// treasury hoist suppressing arm 2. PR #2825 scopes the gate to arms 1 and 3;
// this test pins the corrected live-AI behavior across the same 10-turn window.
//
// References: issue #2509 § EXPAND § planExpandDeclareWar (arm 2 skip clause).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost, planExpandDeclareWar;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show observerGoalPhaseFor;
import 'package:colonizethis_data/colonizethis_data.dart'
    show GameSetupConfig, kObserverConquestMinOwProvincesPerGp;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

const int _kTurnsToResolve = 10;

/// True when [snapshot] has at least one at-war minor owning an invadable OW
/// province (arm-2 predicate inputs from issue #2509 § planExpandDeclareWar).
bool _hasAtWarMinorOnInvadableOw({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final minorIds = <String>{for (final m in game.minorNations) m.id};
  final provinceOwner = getProvinceOwnerMap(game);
  final atWar = snapshot.threats.atWarWith.toSet();
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner != null && minorIds.contains(owner) && atWar.contains(owner)) {
      return true;
    }
  }
  return false;
}

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42 turns 1..11: below-quota GP with at-war minor on invadable OW '
      'still gets declare-war target when treasury is below regiment cost '
      '(arm 2, not function-level treasury hoist)', () {
    final init = runInitGame(
      config: GameSetupConfig(seed: 42),
      options: const InitGameOptions(
        cellSize: 24,
        renderPng: false,
        skipFillLakes: false,
      ),
    );
    var game = init.game.copyWith(
      aiControlByGpId: {for (final p in init.game.players) p.id: true},
    );
    final topo = init.combinedTopology;
    final tileMap = init.tileMapByRegion;
    final cheapest = cheapestRegimentBuildTreasuryCost();
    final minorIds = <String>{for (final m in init.game.minorNations) m.id};

    final violations = <String>[];

    for (var turn = 1; turn <= _kTurnsToResolve + 1; turn++) {
      for (var i = 1; i <= 6; i++) {
        final gpId = 'gp$i';
        final view = buildPlayerView(game, topo, gpId);
        final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topo);
        final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
        if (phase != ObserverGoalPhase.expand) {
          continue;
        }
        if (snapshot.conquest.oldWorldProvincesOwned >=
            kObserverConquestMinOwProvincesPerGp) {
          continue;
        }
        final player = game.playerById(gpId)!;
        if (player.treasury >= cheapest) {
          continue;
        }
        if (!_hasAtWarMinorOnInvadableOw(game: game, snapshot: snapshot)) {
          continue;
        }

        final target = planExpandDeclareWar(game: game, snapshot: snapshot);
        if (target == null) {
          violations.add(
            'turn=$turn $gpId treasury=${player.treasury} '
            'atWar=${snapshot.threats.atWarWith} '
            'invadable=${snapshot.conquest.invadableProvinceIdsSorted.length} '
            '-> declareWarTarget=null (expected at-war minor, arm 2)',
          );
          continue;
        }
        if (!minorIds.contains(target)) {
          violations.add(
            'turn=$turn $gpId declareWarTarget=$target '
            '(expected at-war minor factionId, arm 2)',
          );
        }
      }

      if (turn > _kTurnsToResolve) {
        break;
      }

      final fullAi = generateOrdersForGameFullAI(
        game,
        topo,
        tileMapByRegion: tileMap,
      );
      final merged = mergeOrderLists(
        humanOrders: const Orders(),
        aiOrders: fullAi.orders,
      );
      final assignments = fullAi.economyPlansByPlayerId.map(
        (pid, plan) => MapEntry(pid, plan.productionAssignments),
      );
      final result = validateOrdersAndResolveTurnFromTrustedOrders(
        game: fullAi.game,
        topology: topo,
        orders: merged,
        tileMapByRegion: tileMap,
        defaultAssignmentsByPlayerId: assignments,
      );
      expect(
        result,
        isA<TurnResolutionComplete>(),
        reason: 'Turn $turn resolution failed.',
      );
      game = (result as TurnResolutionComplete).game;
    }

    expect(
      violations,
      isEmpty,
      reason:
          'planExpandDeclareWar arm-2 regression on seed-42 first '
          '$_kTurnsToResolve turns (treasury below $cheapest with at-war '
          'minor on invadable OW must return that minor):\n'
          '${violations.join('\n')}',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
