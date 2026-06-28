import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/seed42_observer_campaign.dart';

/// Smoke coverage for the shared seed-42 observer campaign harness (Refs #3749
/// step 2).
///
/// The migrated `seed42_observer_*` regressions that consume
/// [runSeed42ObserverCampaign] are skipped by default (multi-minute Full-AI
/// runs), so this fast 2-turn campaign is the executing check that the harness
/// drives the init -> handoff -> generate -> resolve loop and invokes the
/// observation callbacks in turn order.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'runSeed42ObserverCampaign drives turns in order and advances the game',
    () {
      final beforeTurns = <int>[];
      final afterTurns = <int>[];

      final campaign = runSeed42ObserverCampaign(
        turns: 2,
        onBeforeResolve: (turn, fullAi, game) {
          beforeTurns.add(turn);
          // Orders are generated before resolution; the start-of-turn game is
          // the same instance the harness will resolve.
          expect(fullAi.game.players, isNotEmpty);
        },
        onAfterResolve: (turn, game) {
          afterTurns.add(turn);
        },
      );

      expect(beforeTurns, [0, 1]);
      expect(afterTurns, [0, 1]);
      expect(
        campaign.finalGame.worldState.turnState.turnNumber,
        greaterThan(campaign.initialGame.worldState.turnState.turnNumber),
      );
      // Faithful Full-AI handoff: every player is AI-controlled.
      expect(
        campaign.initialGame.players.every((p) => !p.isHuman),
        isTrue,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
