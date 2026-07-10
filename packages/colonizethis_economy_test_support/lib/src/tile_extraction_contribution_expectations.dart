// Compact tile extraction contribution assertions (Refs #3939 phase 3 slice 33).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';
import 'tile_extraction_contribution_scenarios.dart';

const _tileKey = 'oldWorld|p1|0|0';
const _provinceId = 'oldWorld|p1';

/// Pins for connected-tile extraction contribution rows.
typedef TileContributionConnectedPin = ({
  String commodityId,
  int units,
  bool verifyProvinceIndexParity,
});

/// Pins for disconnected-tile extraction contribution rows.
typedef TileContributionDisconnectedPin = ();

void runTileContributionConnectedPin({
  required TileMapResult grainTileMap,
  required TileContributionConnectedPin pins,
}) {
  const connected = {_tileKey};
  final player = spainPl1Player(capitalProvinceId: _provinceId);
  final game = TestFixtures.minimalGame(
    id: 'g1',
    capitalTileGrainBonusPerTurn: 5,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    tileState: tileStateFromSpecs(const [
      TileImprovementSpec(_tileKey, 1, 1),
    ]),
    players: [player],
  );
  final contribution = computeTileExtractionContributionForPlayer(
    game: game,
    tileMapByRegion: {'oldWorld': grainTileMap},
    player: player,
    tileKey: _tileKey,
    connectedTileKeys: connected,
    pathTransportCap: const {},
    connectedByRoadRule: connected,
    portTileKeys: const {},
    prospectedTileKeys: connected,
    capitalRegionId: 'oldWorld',
    techCapForPlayer: (_) => 4,
  );
  expect(contribution, isNotNull);
  expect(contribution!.commodityId, pins.commodityId);
  expect(contribution.units, pins.units);

  if (pins.verifyProvinceIndexParity) {
    final provincesByFullId = {
      for (final p in game.worldState.oldWorld.provinces) p.id: p,
      for (final p in game.worldState.newWorld.provinces) p.id: p,
    };
    final withIndex = computeTileExtractionContributionForPlayer(
      game: game,
      tileMapByRegion: {'oldWorld': grainTileMap},
      player: player,
      tileKey: _tileKey,
      connectedTileKeys: connected,
      pathTransportCap: const {},
      connectedByRoadRule: connected,
      portTileKeys: const {},
      prospectedTileKeys: connected,
      capitalRegionId: 'oldWorld',
      techCapForPlayer: (_) => 4,
      provincesByFullId: provincesByFullId,
    );
    expect(withIndex, isNotNull);
    expect(withIndex!.commodityId, contribution.commodityId);
    expect(withIndex.units, contribution.units);
  }
}

void runTileContributionDisconnectedPin({
  required TileMapResult grainTileMap,
}) {
  final player = spainPl1Player(capitalProvinceId: _provinceId);
  final game = TestFixtures.minimalGame(
    id: 'g1',
    oldWorld: RegionData(
      provinces: [
        Province(
          id: _provinceId,
          regionId: 'oldWorld',
          ownerId: 'pl1',
          townDevelopmentLevel: 4,
        ),
      ],
    ),
    tileState: TileMapState(),
    players: [player],
  );
  final contribution = computeTileExtractionContributionForPlayer(
    game: game,
    tileMapByRegion: {'oldWorld': grainTileMap},
    player: player,
    tileKey: _tileKey,
    connectedTileKeys: const {},
    pathTransportCap: const {},
    connectedByRoadRule: const {},
    portTileKeys: const {},
    prospectedTileKeys: const {},
    capitalRegionId: 'oldWorld',
    techCapForPlayer: (_) => 4,
  );
  expect(contribution, isNull);
}

enum TileExtractionContributionPin {
  connectedGrainExcludesCapitalBonus,
  disconnectedNull,
}

TileExtractionContributionScenario tileExtractionContributionScenario({
  required String label,
  required TileExtractionContributionPin pin,
  TileContributionConnectedPin? connectedPins,
  TileMapResult? grainTileMap,
}) =>
    TileExtractionContributionScenario(
      label: label,
      run: () {
        final tileMap = grainTileMap ?? singleResourceTileMap(Resource.grain);
        switch (pin) {
          case TileExtractionContributionPin.connectedGrainExcludesCapitalBonus:
            runTileContributionConnectedPin(
              grainTileMap: tileMap,
              pins: connectedPins!,
            );
          case TileExtractionContributionPin.disconnectedNull:
            runTileContributionDisconnectedPin(grainTileMap: tileMap);
        }
      },
    );
