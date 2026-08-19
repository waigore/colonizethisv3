// Multi-turn connectivity-aware civilian-work chain pins (Refs #4176 AC-A1, AC-A6).
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/connectivity_dev_chain_fixture.dart';
import '../support/connectivity_dev_multi_turn_harness.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('AC-A1 Engineer extends road frontier each turn until isolated resource '
      'connects', () {
    final scenario = ConnectivityDevChainFixture.threeTileGap();
    var game = scenario.game;
    for (var turn = 0; turn < 3; turn++) {
      final selection = selectConnectivityDevCivilianWork(
        game: game,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
        playerId: kConnectivityDevChainPlayerId,
      );
      final road = engineerBuildRoadOrder(selection);
      expect(road, isNotNull);
      expect(road!.targetTileKey, scenario.expectedFrontierRoadTiles[turn]);
      game = resolveConnectivityDevSelectionTurn(
        game: game,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
        playerId: kConnectivityDevChainPlayerId,
      );
    }
    final connected = connectedTilesForPlayer(
      game: game,
      playerId: kConnectivityDevChainPlayerId,
      topology: scenario.topology,
      tileMapByRegion: scenario.tileMapByRegion,
    );
    expect(connected, contains(scenario.resourceTiles.single));
  });

  test('AC-A6 nearer improved resource connects before farther resource', () {
    final scenario = ConnectivityDevChainFixture.dualResourceSequencing();
    final nearResource = scenario.resourceTiles.first;
    final farResource = scenario.resourceTiles.last;
    var game = scenario.game;
    var nearConnectedTurn = -1;
    var farConnectedTurn = -1;
    for (var turn = 0; turn < 8; turn++) {
      final connected = connectedTilesForPlayer(
        game: game,
        playerId: kConnectivityDevChainPlayerId,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
      );
      if (nearConnectedTurn < 0 && connected.contains(nearResource)) {
        nearConnectedTurn = turn;
      }
      if (farConnectedTurn < 0 && connected.contains(farResource)) {
        farConnectedTurn = turn;
      }
      if (nearConnectedTurn >= 0 && farConnectedTurn >= 0) break;
      game = resolveConnectivityDevSelectionTurn(
        game: game,
        topology: scenario.topology,
        tileMapByRegion: scenario.tileMapByRegion,
        playerId: kConnectivityDevChainPlayerId,
      );
    }
    expect(nearConnectedTurn, greaterThanOrEqualTo(0));
    expect(farConnectedTurn, greaterThan(nearConnectedTurn));
  });
}
