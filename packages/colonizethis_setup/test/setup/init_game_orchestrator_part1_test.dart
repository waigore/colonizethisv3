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
        List<int>? continentProvinceSizes,
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
          continentProvinceSizes: continentProvinceSizes,
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

      final owSeed = seedsByRegion[kRegionOldWorld];
      final nwSeed = seedsByRegion[kRegionNewWorld];
      expect(owSeed, isNotNull);
      expect(nwSeed, owSeed! + 1);
      // Freeform pipeline may retry with mapSeed = effectiveSeed + attempt * 100003.
      expect((owSeed - k) % 100003, 0);
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
        List<int>? continentProvinceSizes,
      }) {
        callCount++;
        final forcedSizes =
            continentProvinceSizes ??
            (numContinents == 4 &&
                    numProvinces == 60 &&
                    regionId == kRegionOldWorld
                ? const [13, 13, 17, 17]
                : numContinents == 4 &&
                      numProvinces == 30 &&
                      regionId == kRegionNewWorld
                ? const [6, 6, 9, 9]
                : null);
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
          continentProvinceSizes: forcedSizes,
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
  });
}
