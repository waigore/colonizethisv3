// Seed-42 Full-AI observer connectivity closure gate (Refs #4176 AC-F1).
//
// After connectivity-aware civilian-work ordering lands, every improved resource
// tile that is geographically reachable over owned land from the capital network
// must be extraction-connected. Overseas tiles separated by sea (not reachable
// via owned-land BFS from the OW network) are exempt per AC-F1.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/connectivity_dev_observer_verify.dart';
import 'support/seed42_observer_campaign.dart';

/// Turn count for the late-game connectivity closure pin.
const int kConnectivityClosureTurns = 60;

const Set<String> kConnectivityClosureGreatPowerIds = {
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
};

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn $kConnectivityClosureTurns: improved resource tiles '
    'reachable over owned land are capital-connected (AC-F1)',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final campaign = runSeed42ObserverCampaign(
        turns: kConnectivityClosureTurns,
      );
      final game = campaign.finalGame;

      final allViolations = <String, List<String>>{};
      for (final gpId in kConnectivityClosureGreatPowerIds) {
        final violations = connectivityClosureViolations(
          game: game,
          playerId: gpId,
          topology: topo,
          tileMapByRegion: tileMap,
        );
        if (violations.isNotEmpty) {
          allViolations[gpId] = violations;
        }
      }

      expect(
        allViolations,
        isEmpty,
        reason: 'connectivity closure violations at turn '
            '$kConnectivityClosureTurns: $allViolations',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
