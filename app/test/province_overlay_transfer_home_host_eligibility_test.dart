// Eligibility unit pins for MAP20001 Transfer host (Refs #4625, #4734).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_transfer_home.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/home_fleet_transfer_eligibility.dart'
    show overlayTransferToHomeSourceFleets;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'naval_units_panel_test_support.dart';
import 'province_overlay_transfer_home_host_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('eligibility: in-port at capital qualifies; empty does not', () {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_el',
      displayName: 'Cap',
      peerFleets: [inPortPeerForTransferHome(playerId, 'peer1')],
    );
    final sources = overlayTransferToHomeSourceFleets(
      game: capitalGame,
      humanPlayerId: playerId,
      displayId: 'oldWorld|cap1',
      isSeaZone: false,
      topology: const MapTopology(),
    );
    expect(sources.map((f) => f.id), ['peer1']);
  });

  test('eligibility: at-sea requires topology adjacency', () {
    const playerId = 'gp_cap';
    final atSea = Fleet(
      id: 'sea_peer',
      ownerId: playerId,
      regionId: 'oldWorld',
      seaZoneId: 'sea1',
      ships: const [ShipInstance(id: 'ss', typeId: 'carrack')],
    );
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_sea',
      displayName: 'Cap',
      peerFleets: [atSea],
    );
    const topology = MapTopology(
      edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'oldWorld|sea1')],
    );
    expect(
      overlayTransferToHomeSourceFleets(
        game: capitalGame,
        humanPlayerId: playerId,
        displayId: 'oldWorld|sea1',
        isSeaZone: true,
        topology: topology,
      ).map((f) => f.id),
      ['sea_peer'],
    );
    expect(
      overlayTransferToHomeSourceFleets(
        game: capitalGame,
        humanPlayerId: playerId,
        displayId: 'oldWorld|sea_other',
        isSeaZone: true,
        topology: topology,
      ),
      isEmpty,
    );
  });
}
