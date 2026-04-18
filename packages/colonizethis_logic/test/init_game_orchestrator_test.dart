import 'dart:typed_data';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/setup/locked_topology_gates.dart';
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
      );

      runInitGame(
        config: config,
        options: const InitGameOptions(cellSize: 8, renderPng: false),
        generateRegion: captureSeeds,
      );

      expect(seedsByRegion[kRegionOldWorld], k);
      expect(seedsByRegion[kRegionNewWorld], k + 1);
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

      expect(callCount, 2);
      expect(result.game, isNotNull);
    });

    test(
      'locked full-init profile: 60 OW / 30 NW, 6 GPs, 6 minors; init succeeds and GPs are P–P connected',
      () {
        final base = GameSetupConfig.defaultConfig;
        final config = GameSetupConfig(
          selectedGreatPowerIds: base.selectedGreatPowerIds,
          leaderVariantByGpId: base.leaderVariantByGpId,
          continentCount: 4,
          minorNationCount: 6,
          tribeCount: 10,
          numProvincesOldWorld: 60,
          numProvincesNewWorld: 30,
          minProvincesPerMinor: 3,
          seed: base.seed,
          startingResources: base.startingResources,
        );

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        final game = result.game;
        expect(game.worldState.oldWorld.provinces.length, 60);
        expect(game.players.length, 6);
        expect(game.minorNations.length, 6);

        final topo = result.topologyByRegion[kRegionOldWorld]!;
        if (oldWorldPartitionMatchesLockedProfile(topo)) {
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
        }
      },
    );

    test(
      'throws setup config exception when OW provinces fewer than Great Powers',
      () {
        // Config with 6 GPs but only 2 OW provinces: createGameFromGeneratedMaps throws
        // (either "provinces" or "sea-bound provinces" check). Accept either message.
        final config = GameSetupConfig(
          selectedGreatPowerIds:
              GameSetupConfig.defaultConfig.selectedGreatPowerIds,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 5,
        );
        expect(
          () => runInitGame(
            config: config,
            options: const InitGameOptions(cellSize: 8, renderPng: false),
          ),
          throwsA(
            isA<SetupConfigConstraintException>()
                .having(
                  (e) => e.code,
                  'code',
                  'insufficient_old_world_provinces_for_great_powers',
                )
                .having((e) => e.message, 'message', contains('Great Powers')),
          ),
        );
      },
    );

    GameSetupConfig lockedFullInitConfig({required int seed}) {
      final base = GameSetupConfig.defaultConfig;
      return GameSetupConfig(
        selectedGreatPowerIds: base.selectedGreatPowerIds,
        leaderVariantByGpId: base.leaderVariantByGpId,
        continentCount: 4,
        minorNationCount: 6,
        tribeCount: 10,
        numProvincesOldWorld: 60,
        numProvincesNewWorld: 30,
        minProvincesPerMinor: 3,
        seed: seed,
        startingResources: base.startingResources,
      );
    }

    test(
      'AC-11 locked full-init profile: twenty fixed seeds complete setup',
      () {
        const seeds = <int>[
          101,
          257,
          509,
          1009,
          2003,
          3001,
          4001,
          5003,
          6007,
          7001,
          8011,
          9001,
          10007,
          11003,
          12007,
          13001,
          14009,
          15013,
          16001,
          17011,
        ];
        expect(seeds.length, 20);
        expect(seeds.toSet().length, 20);

        for (final s in seeds) {
          final config = lockedFullInitConfig(seed: s);
          final result = runInitGame(
            config: config,
            options: const InitGameOptions(cellSize: 8, renderPng: false),
          );
          final game = result.game;
          expect(
            game.worldState.oldWorld.provinces.length,
            60,
            reason: 'seed=$s',
          );
          expect(game.players.length, 6, reason: 'seed=$s');
          expect(game.minorNations.length, 6, reason: 'seed=$s');

          final topo = result.topologyByRegion[kRegionOldWorld]!;
          if (oldWorldPartitionMatchesLockedProfile(topo)) {
            final nbr = _provincePpNeighboursForInitGameTest(topo);
            final owners = <String, String>{
              for (final p in game.worldState.oldWorld.provinces)
                if (p.ownerId != null) ProvinceId.localIdFrom(p.id): p.ownerId!,
            };
            for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
              expect(
                gpProvincesAreLandConnected(gpId, owners, nbr),
                isTrue,
                reason:
                    '$gpId OW territory must be one P–P component (seed=$s)',
              );
            }
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'AC-12 locked full-init profile: same seed yields identical OW owners',
      () {
        const s = 900_003;
        final config = lockedFullInitConfig(seed: s);
        const options = InitGameOptions(cellSize: 8, renderPng: false);
        final a = runInitGame(config: config, options: options);
        final b = runInitGame(config: config, options: options);

        String ownerKey(Game g) {
          final parts = <String>[];
          for (final p in g.worldState.oldWorld.provinces) {
            parts.add('${p.id}=${p.ownerId ?? ''}');
          }
          parts.sort();
          return parts.join(';');
        }

        expect(ownerKey(a.game), ownerKey(b.game));
      },
    );
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
