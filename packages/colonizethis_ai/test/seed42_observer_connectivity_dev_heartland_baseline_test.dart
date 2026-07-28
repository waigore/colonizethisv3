// Seed-42 heartland connectivity baseline pin (Refs #4176 AC-F3).
//
// Pins per-GP connected-tile counts after 10 resolved turns so connectivity-
// aware civilian-work changes cannot silently regress early-game network growth.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/connectivity_dev_observer_verify.dart';
import 'support/seed42_observer_campaign.dart';

const int kHeartlandBaselineTurns = 10;

/// Connected-tile counts per GP after seed-42 turn [kHeartlandBaselineTurns].
/// Captured on `dev` after PR #4178 merged (connectivity-aware civilian work).
const Map<String, int> kSeed42Turn10ConnectedTileCounts = {
  'gp1': 203,
  'gp2': 202,
  'gp3': 144,
  'gp4': 207,
  'gp5': 117,
  'gp6': 169,
};

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn $kHeartlandBaselineTurns: connected tile counts match '
    'post-connectivity baseline (AC-F3)',
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

      final campaign = runSeed42ObserverCampaign(turns: kHeartlandBaselineTurns);
      final game = campaign.finalGame;

      final actual = <String, int>{};
      for (final gpId in kSeed42Turn10ConnectedTileCounts.keys) {
        actual[gpId] = connectedTileCountForPlayer(
          game: game,
          playerId: gpId,
          topology: topo,
          tileMapByRegion: tileMap,
        );
      }

      expect(actual, kSeed42Turn10ConnectedTileCounts);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
