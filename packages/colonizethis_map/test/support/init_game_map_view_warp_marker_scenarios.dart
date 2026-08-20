import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_map_view_fixture_scenarios.dart';
import 'init_game_map_view_fixtures.dart';

/// Warp marker scenario helpers for view-builder marker tests. Refs #4561.
void expectBidirectionalWarpMarkersFromLinks() {
  final game = minimalGame(id: 'warp');
  final warpLinks = [
    WarpLink(
      regionId: 'oldWorld',
      seaZoneId: 's1',
      otherRegionId: 'newWorld',
      otherSeaZoneId: 's3',
    ),
    WarpLink(
      regionId: 'oldWorld',
      seaZoneId: 's2',
      otherRegionId: 'newWorld',
      otherSeaZoneId: 's2',
    ),
  ];
  final viewData = buildViewDataForScenario(
    dualRegionScenario(
      game: game,
      oldWorldGrid: const [
        ['s1', 's2', 's3'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        seaZoneIds: const ['s1', 's2', 's3'],
      ),
      newWorldGrid: const [
        ['s1', 's2', 's3'],
      ],
      newWorldTopology: regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s1', 's2', 's3'],
      ),
    ),
    warpLinks: warpLinks,
  );

  expect(viewData.oldWorld.warpMarkers, hasLength(2));
  final s1Marker = viewData.oldWorld.warpMarkers.singleWhere(
    (m) => m.seaZoneId == 's1',
  );
  expect(s1Marker.x, 0);
  expect(s1Marker.y, 0);
  expect(s1Marker.otherRegionId, 'newWorld');
  expect(s1Marker.otherSeaZoneId, 's3');

  final s2Marker = viewData.oldWorld.warpMarkers.singleWhere(
    (m) => m.seaZoneId == 's2',
  );
  expect(s2Marker.x, 1);
  expect(s2Marker.y, 0);
  expect(s2Marker.otherRegionId, 'newWorld');
  expect(s2Marker.otherSeaZoneId, 's2');

  expect(viewData.newWorld.warpMarkers, hasLength(2));
  final nwS3Marker = viewData.newWorld.warpMarkers.singleWhere(
    (m) => m.seaZoneId == 's3',
  );
  expect(nwS3Marker.x, 2);
  expect(nwS3Marker.y, 0);
  expect(nwS3Marker.otherRegionId, 'oldWorld');
  expect(nwS3Marker.otherSeaZoneId, 's1');

  final nwS2Marker = viewData.newWorld.warpMarkers.singleWhere(
    (m) => m.seaZoneId == 's2',
  );
  expect(nwS2Marker.x, 1);
  expect(nwS2Marker.y, 0);
  expect(nwS2Marker.otherRegionId, 'oldWorld');
  expect(nwS2Marker.otherSeaZoneId, 's2');
}

void expectEmptyWarpMarkersWhenLinksNull() {
  final viewData = buildViewDataForScenario(
    dualRegionScenario(
      game: minimalGame(id: 'no-warp'),
      oldWorldGrid: const [
        ['s1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        seaZoneIds: const ['s1'],
      ),
      newWorldGrid: const [
        ['s1'],
      ],
      newWorldTopology: regionTopology(
        regionId: 'newWorld',
        seaZoneIds: const ['s1'],
      ),
    ),
    warpLinks: null,
  );

  expect(viewData.oldWorld.warpMarkers, isEmpty);
  expect(viewData.newWorld.warpMarkers, isEmpty);
}
