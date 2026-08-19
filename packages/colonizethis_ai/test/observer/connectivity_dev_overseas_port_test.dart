// Overseas port linkage end-to-end pin (Refs #4176 AC-D3).
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/connectivity_dev_multi_turn_harness.dart';
import '../support/connectivity_dev_overseas_fixture.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('AC-D3 Engineer builds overseas port then in-province roads connect '
      'improved resource', () {
    final scenario = ConnectivityDevOverseasFixture.overseasPortLinkage();
    final resourceTile = scenario.resourceTile;
    var game = scenario.game;
    var sawPortOrder = false;

    final startConnected = connectedTilesForPlayer(
      game: game,
      playerId: kConnectivityDevOverseasPlayerId,
      topology: scenario.topology,
      tileMapByRegion: scenario.tileMapByRegion,
    );
    expect(startConnected, isNot(contains(resourceTile)));

    for (var turn = 0; turn < 8; turn++) {
      final connected = connectedTilesForPlayer(
        game: game,
        playerId: kConnectivityDevOverseasPlayerId,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
      );
      if (connected.contains(resourceTile)) {
        expect(sawPortOrder, isTrue, reason: 'resource connected without port');
        return;
      }

      final selection = selectConnectivityDevCivilianWork(
        game: game,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
        playerId: kConnectivityDevOverseasPlayerId,
      );
      final portOrder = engineerWorkOrderForTarget(
        selection,
        kWorkTargetBuildPort,
        engineerId: kConnectivityDevOverseasEngineerId,
      );
      if (portOrder != null) {
        expect(portOrder.targetTileKey, scenario.portTile);
        sawPortOrder = true;
      }

      game = resolveConnectivityDevSelectionTurn(
        game: game,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
        playerId: kConnectivityDevOverseasPlayerId,
      );
    }

    final finalConnected = connectedTilesForPlayer(
      game: game,
      playerId: kConnectivityDevOverseasPlayerId,
      topology: scenario.topology,
      tileMapByRegion: scenario.tileMapByRegion,
    );
    expect(
      finalConnected,
      contains(resourceTile),
      reason: 'resource tile $resourceTile not connected after 8 turns',
    );
  });
}
