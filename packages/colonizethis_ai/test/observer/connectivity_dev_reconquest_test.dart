// Reconquest reconnection pin for connectivity-aware civilian work (Refs #4176 AC-F2).
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/connectivity_dev_chain_fixture.dart';
import '../support/connectivity_dev_multi_turn_harness.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'AC-F2 Engineer extends network to reconnect pre-built improvements',
    () {
      final scenario = ConnectivityDevChainFixture.reconquestImprovements();
      final resourceTile = scenario.resourceTiles.single;
      var game = scenario.game;
      final startConnected = connectedTilesForPlayer(
        game: game,
        playerId: kConnectivityDevChainPlayerId,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
      );
      expect(startConnected, isNot(contains(resourceTile)));

      for (var turn = 0; turn < 4; turn++) {
        final connected = connectedTilesForPlayer(
          game: game,
          playerId: kConnectivityDevChainPlayerId,
          topology: scenario.topology,
          tileMapByRegion: scenario.tileMapByRegion,
        );
        if (connected.contains(resourceTile)) {
          return;
        }
        game = resolveConnectivityDevSelectionTurn(
          game: game,
          topology: scenario.topology,
          tileMapByRegion: scenario.tileMapByRegion,
          playerId: kConnectivityDevChainPlayerId,
        );
      }
      fail('resource tile $resourceTile never reconnected within 4 turns');
    },
  );
}
