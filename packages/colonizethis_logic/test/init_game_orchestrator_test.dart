import 'dart:typed_data';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('runInitGame', () {
    test(
      'renderPng=false skips PNG bytes but still returns game and view data',
      () {
        final config = GameSetupConfig.defaultConfig;

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );

        expect(result.game, isNotNull);
        expect(result.mapViewData, isNotNull);
        expect(result.markdown, isNotEmpty);
        expect(result.mapPngBytes, isA<Uint8List>());
        expect(result.mapPngBytes, isEmpty);
      },
    );

    test(
      'greatPowerColorOverride from semantic ids is applied to runtime player ids',
      () {
        // Use default config so selectedGreatPowerIds and players are created
        // in a consistent order; the first selected GP becomes the first Player.
        final config = GameSetupConfig.defaultConfig;

        const overrideSemanticId = 'england';
        const overrideColor = (200, 10, 150);

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(
            cellSize: 8,
            renderPng: false,
            greatPowerColorOverride: {overrideSemanticId: overrideColor},
          ),
        );

        final game = result.game;

        // Find the player that corresponds to the overridden semantic id by
        // using the resolved display name from naming (e.g. "England").
        final overriddenPlayer = game.players.firstWhere(
          (p) =>
              p.displayName ==
              defaultNamingConfig.gpById(overrideSemanticId)!.countryName,
          orElse: () => game.players.first,
        );

        final gpOverride = game.greatPowerColorOverride;
        expect(gpOverride, isNotNull);
        expect(gpOverride![overriddenPlayer.id], [
          overrideColor.$1,
          overrideColor.$2,
          overrideColor.$3,
        ]);

        final viewOverride = result.greatPowerColorOverride;
        expect(viewOverride, isNotNull);
        expect(viewOverride![overriddenPlayer.id], overrideColor);
      },
    );

    test('markdown contains Faction Setup and Starting State tables', () {
      final config = GameSetupConfig.defaultConfig;
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      expect(result.markdown, contains('## Faction Setup'));
      expect(result.markdown, contains('## Faction Starting State'));
      expect(
        result.markdown,
        contains('| Faction | Type | Capital Province | Provinces Owned |'),
      );
      expect(
        result.markdown,
        contains('| Faction | Stockpile | Workers | Treasury | Units |'),
      );
    });

    test('skipFillLakes=true runs without throwing', () {
      final config = GameSetupConfig.defaultConfig;
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: false,
          skipFillLakes: true,
        ),
      );
      expect(result.game, isNotNull);
      expect(result.markdown, isNotEmpty);
    });

    test(
      'result includes warpLinks and combinedTopology has prefixed node ids',
      () {
        final config = GameSetupConfig.defaultConfig;
        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        expect(result.warpLinks, isA<List<WarpLink>>());
        final combined = result.combinedTopology;
        expect(combined.nodes, isNotEmpty);
        for (final n in combined.nodes) {
          expect(
            n.id.contains('|'),
            isTrue,
            reason:
                'combined topology node id must be prefixed (regionId|localId)',
          );
        }
        if (result.warpLinks.isNotEmpty) {
          expect(
            result.warpLinks.first.regionId,
            anyOf('oldWorld', 'newWorld'),
          );
          expect(
            result.warpLinks.first.otherRegionId,
            anyOf('oldWorld', 'newWorld'),
          );
        }
      },
    );

    test('seed=0 uses time-based effective seed', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds:
            GameSetupConfig.defaultConfig.selectedGreatPowerIds,
        numProvincesOldWorld:
            GameSetupConfig.defaultConfig.numProvincesOldWorld,
        numProvincesNewWorld:
            GameSetupConfig.defaultConfig.numProvincesNewWorld,
        seed: 0,
      );
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      expect(result.game, isNotNull);
      expect(result.game.globalGameSeed, isNonZero);
    });

    test('non-zero seed: globalGameSeed matches config.seed', () {
      const k = 900_001;
      final base = GameSetupConfig.defaultConfig;
      final config = GameSetupConfig(
        selectedGreatPowerIds: base.selectedGreatPowerIds,
        leaderVariantByGpId: base.leaderVariantByGpId,
        continentCount: base.continentCount,
        minorNationCount: base.minorNationCount,
        tribeCount: base.tribeCount,
        numProvincesOldWorld: base.numProvincesOldWorld,
        numProvincesNewWorld: base.numProvincesNewWorld,
        minProvincesPerMinor: base.minProvincesPerMinor,
        seed: k,
        startingResources: base.startingResources,
        enforceFairGpOldWorldAssignment: base.enforceFairGpOldWorldAssignment,
      );
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      expect(result.game.globalGameSeed, k);
    });

    test(
      'same positive seed: seaZoneDisplayNameById matches across two '
      'runInitGame calls (province-like repeatability, not label distinctness)',
      () {
        // End-to-end guard: full procedural OW+NW generation + topology + naming.
        // Pairwise distinct sea-zone strings on one map are not required; stability
        // of (regionId|localSeaZoneId) → displayName for a fixed seed is.
        const k = 900_002;
        final base = GameSetupConfig.defaultConfig;
        final config = GameSetupConfig(
          selectedGreatPowerIds: base.selectedGreatPowerIds,
          leaderVariantByGpId: base.leaderVariantByGpId,
          continentCount: base.continentCount,
          minorNationCount: base.minorNationCount,
          tribeCount: base.tribeCount,
          numProvincesOldWorld: base.numProvincesOldWorld,
          numProvincesNewWorld: base.numProvincesNewWorld,
          minProvincesPerMinor: base.minProvincesPerMinor,
          seed: k,
          startingResources: base.startingResources,
          enforceFairGpOldWorldAssignment: base.enforceFairGpOldWorldAssignment,
        );
        const options = InitGameOptions(cellSize: 8, renderPng: false);
        final first = runInitGame(config: config, options: options);
        final second = runInitGame(config: config, options: options);
        expect(
          first.game.worldState.seaZoneDisplayNameById,
          second.game.worldState.seaZoneDisplayNameById,
        );
      },
    );

    test('NW tile map uses effectiveSeed + 1 (OW uses effective seed)', () {
      final seedsByRegion = <String, int>{};
      (TileMapResult, MapTopology) captureSeeds({
        required TileMapParams params,
        required int numProvinces,
        required int numContinents,
        required String regionId,
        String seaZoneId = 's1',
        ResourceRules? resourceRules,
        void Function(String)? onLog,
        void Function(
          List<(int x, int y)> landSeeds,
          List<int> continentIndices,
        )?
        onLandSeedsPlaced,
        void Function(List<(int x, int y)> continentSeeds)?
        onContinentSeedsPlaced,
      }) {
        seedsByRegion[regionId] = params.seed;
        return defaultTileMapRegionGenerator(
          params: params,
          numProvinces: numProvinces,
          numContinents: numContinents,
          regionId: regionId,
          seaZoneId: seaZoneId,
          resourceRules: resourceRules,
          onLog: onLog,
          onLandSeedsPlaced: onLandSeedsPlaced,
          onContinentSeedsPlaced: onContinentSeedsPlaced,
        );
      }

      const k = 77_777;
      final base = GameSetupConfig.defaultConfig;
      final config = GameSetupConfig(
        selectedGreatPowerIds: base.selectedGreatPowerIds,
        leaderVariantByGpId: base.leaderVariantByGpId,
        continentCount: base.continentCount,
        minorNationCount: base.minorNationCount,
        tribeCount: base.tribeCount,
        numProvincesOldWorld: base.numProvincesOldWorld,
        numProvincesNewWorld: base.numProvincesNewWorld,
        minProvincesPerMinor: base.minProvincesPerMinor,
        seed: k,
        startingResources: base.startingResources,
        enforceFairGpOldWorldAssignment: base.enforceFairGpOldWorldAssignment,
      );

      runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
        generateRegion: captureSeeds,
      );

      final owSeed = seedsByRegion[kRegionOldWorld]!;
      final nwSeed = seedsByRegion[kRegionNewWorld]!;
      expect(nwSeed, k + 1);
      expect(owSeed, greaterThanOrEqualTo(k));
    });

    test('after runInitGame worldState.turnState is orders at turn 0', () {
      final result = runInitGame(
        config: GameSetupConfig.defaultConfig,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
      );
      expect(result.game.worldState.turnState.phase, TurnPhase.orders);
      expect(result.game.worldState.turnState.turnNumber, 0);
    });

    test('renderPng=true returns non-empty map PNG bytes', () {
      final config = GameSetupConfig.defaultConfig;
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: true),
      );
      expect(result.mapPngBytes, isA<Uint8List>());
      expect(result.mapPngBytes.length, greaterThan(0));
    });

    test('generateRegion injection is used for OW and NW map generation', () {
      var callCount = 0;
      (TileMapResult, MapTopology) countingGen({
        required TileMapParams params,
        required int numProvinces,
        required int numContinents,
        required String regionId,
        String seaZoneId = 's1',
        ResourceRules? resourceRules,
        void Function(String)? onLog,
        void Function(
          List<(int x, int y)> landSeeds,
          List<int> continentIndices,
        )?
        onLandSeedsPlaced,
        void Function(List<(int x, int y)> continentSeeds)?
        onContinentSeedsPlaced,
      }) {
        callCount++;
        return defaultTileMapRegionGenerator(
          params: params,
          numProvinces: numProvinces,
          numContinents: numContinents,
          regionId: regionId,
          seaZoneId: seaZoneId,
          resourceRules: resourceRules,
          onLog: onLog,
          onLandSeedsPlaced: onLandSeedsPlaced,
          onContinentSeedsPlaced: onContinentSeedsPlaced,
        );
      }

      final config = GameSetupConfig.defaultConfig;
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
        generateRegion: countingGen,
      );

      expect(callCount, greaterThanOrEqualTo(2));
      expect(result.game, isNotNull);
    });

    test(
      'default config locks 60 OW, 6 GPs, 6 minors with 21/21/18 partition',
      () {
        final base = GameSetupConfig.defaultConfig;
        expect(base.numProvincesOldWorld, 60);
        expect(base.greatPowerCount, 6);
        expect(base.minorNationCount, 6);
        expect(base.minProvincesPerMinor, 3);

        final config = GameSetupConfig(
          selectedGreatPowerIds: base.selectedGreatPowerIds,
          leaderVariantByGpId: base.leaderVariantByGpId,
          continentCount: base.continentCount,
          minorNationCount: base.minorNationCount,
          tribeCount: base.tribeCount,
          numProvincesOldWorld: base.numProvincesOldWorld,
          numProvincesNewWorld: base.numProvincesNewWorld,
          minProvincesPerMinor: base.minProvincesPerMinor,
          seed: base.seed,
          startingResources: base.startingResources,
          enforceFairGpOldWorldAssignment: true,
        );

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        final game = result.game;
        expect(game.worldState.oldWorld.provinces.length, 60);
        expect(game.players.length, 6);
        expect(game.minorNations.length, 6);
        final owLocalOwners = {
          for (final p in game.worldState.oldWorld.provinces)
            ProvinceId.localIdFrom(p.id): p.ownerId ?? '',
        };
        for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
          expect(
            owLocalOwners.values.where((owner) => owner == gpId).length,
            7,
            reason: '$gpId should own exactly 7 OW provinces',
          );
        }
        for (final minorId in [
          'minor1',
          'minor2',
          'minor3',
          'minor4',
          'minor5',
          'minor6',
        ]) {
          expect(
            owLocalOwners.values.where((owner) => owner == minorId).length,
            3,
            reason: '$minorId should own exactly 3 OW provinces',
          );
        }
        final topo = result.topologyByRegion[kRegionOldWorld]!;
        final nbr = _provincePpNeighboursForInitGameTest(topo);
        final owners = <String, String>{
          for (final p in game.worldState.oldWorld.provinces)
            if (p.ownerId != null) ProvinceId.localIdFrom(p.id): p.ownerId!,
        };
        for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
          expect(
            gpProvincesAreLandConnected(gpId, owners, nbr),
            isTrue,
            reason: '$gpId OW territory must be one P–P component',
          );
        }
      },
    );

    test(
      'runInitGame normalizes OW config and does not fail on tiny OW request',
      () {
        final config = GameSetupConfig(
          selectedGreatPowerIds:
              GameSetupConfig.defaultConfig.selectedGreatPowerIds,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 5,
        );
        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        expect(result.game.worldState.oldWorld.provinces.length, 60);
      },
    );

    test('20 random seeds satisfy locked faction province counts', () {
      const seeds = [
        101,
        203,
        307,
        401,
        509,
        601,
        709,
        809,
        907,
        1009,
        1103,
        1201,
        1303,
        1409,
        1511,
        1601,
        1709,
        1801,
        1907,
        2003,
      ];
      for (final seed in seeds) {
        final result = runInitGame(
          config: GameSetupConfig(seed: seed),
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        final owners = <String, String>{
          for (final p in result.game.worldState.oldWorld.provinces)
            ProvinceId.localIdFrom(p.id): p.ownerId ?? '',
        };
        for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
          expect(
            owners.values.where((owner) => owner == gpId).length,
            7,
            reason: 'seed=$seed $gpId count',
          );
        }
        for (final minorId in [
          'minor1',
          'minor2',
          'minor3',
          'minor4',
          'minor5',
          'minor6',
        ]) {
          expect(
            owners.values.where((owner) => owner == minorId).length,
            3,
            reason: 'seed=$seed $minorId count',
          );
        }
      }
    });
  });
}

Map<String, Set<String>> _provincePpNeighboursForInitGameTest(
  MapTopology topology,
) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }
  return neighbours;
}
