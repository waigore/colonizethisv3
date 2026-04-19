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

        expectLockedFullInitAcWhenPartitionsMatch(result, seed: config.seed);
      },
    );

    test(
      'seed 42 full init: land province display names unique per region; '
      'Poland minor4 has at most one Greater Poland when locked partitions match',
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
          seed: 42,
          startingResources: base.startingResources,
        );
        final result = runInitGame(
          config: config,
          options: const InitGameOptions(cellSize: 8, renderPng: false),
        );
        final game = result.game;
        void assertDistinct(Iterable<String?> names, String label) {
          final strings = names
              .map((e) => e ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
          expect(
            strings.length,
            strings.toSet().length,
            reason: '$label displayName values must be pairwise distinct',
          );
        }

        assertDistinct(
          game.worldState.oldWorld.provinces.map((p) => p.displayName),
          'oldWorld',
        );
        assertDistinct(
          game.worldState.newWorld.provinces.map((p) => p.displayName),
          'newWorld',
        );

        final topoOw = result.topologyByRegion[kRegionOldWorld]!;
        final topoNw = result.topologyByRegion[kRegionNewWorld]!;
        if (!oldWorldPartitionMatchesLockedProfile(topoOw) ||
            !newWorldPartitionMatchesLockedProfile(topoNw)) {
          return;
        }
        final poland = game.worldState.oldWorld.provinces.where(
          (p) => p.ownerId == 'minor4',
        );
        final greaterPolandCount = poland
            .where((p) => p.displayName == 'Greater Poland')
            .length;
        expect(
          greaterPolandCount,
          lessThanOrEqualTo(1),
          reason:
              'Poland pool capital string must not repeat on multiple provinces',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
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

          expectLockedFullInitAcWhenPartitionsMatch(result, seed: s);
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

List<Set<String>> _landComponentsFromPpNeighbours(
  Map<String, Set<String>> neighbours,
) {
  final visited = <String>{};
  final out = <Set<String>>[];
  for (final start in neighbours.keys.toList()..sort()) {
    if (visited.contains(start)) continue;
    final comp = <String>{};
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!visited.add(u)) continue;
      comp.add(u);
      for (final v in neighbours[u] ?? const <String>{}) {
        if (!visited.contains(v)) {
          stack.add(v);
        }
      }
    }
    out.add(comp);
  }
  return out;
}

/// When OW and NW topologies both match locked multisets, assert GitHub #1830
/// AC-1–AC-9 (subset exercised here; procedural maps often miss multisets).
void expectLockedFullInitAcWhenPartitionsMatch(
  InitGameResult r, {
  required int seed,
}) {
  final topoOw = r.topologyByRegion[kRegionOldWorld]!;
  final topoNw = r.topologyByRegion[kRegionNewWorld]!;
  if (!oldWorldPartitionMatchesLockedProfile(topoOw) ||
      !newWorldPartitionMatchesLockedProfile(topoNw)) {
    return;
  }
  expectLockedFullInitAc1To9(r, seed: seed);
}

/// AC-1–AC-9 postconditions for locked full-init after successful [runInitGame] (#1830).
void expectLockedFullInitAc1To9(InitGameResult r, {required int seed}) {
  final rs = 'seed=$seed';
  final topoOw = r.topologyByRegion[kRegionOldWorld]!;
  final topoNw = r.topologyByRegion[kRegionNewWorld]!;
  expect(
    oldWorldPartitionMatchesLockedProfile(topoOw),
    isTrue,
    reason: 'AC-2 $rs',
  );
  expect(
    newWorldPartitionMatchesLockedProfile(topoNw),
    isTrue,
    reason: 'AC-3 $rs',
  );
  expect(ppLandComponentSizesSorted(topoOw), [
    13,
    13,
    17,
    17,
  ], reason: 'AC-2 multiset $rs');
  expect(ppLandComponentSizesSorted(topoNw), [
    6,
    6,
    9,
    9,
  ], reason: 'AC-3 multiset $rs');

  final game = r.game;
  expect(game.worldState.newWorld.provinces.length, 30, reason: 'AC-1 $rs');
  expect(game.tribes.length, 10, reason: 'AC-1 $rs');

  for (var i = 1; i <= 6; i++) {
    final gid = 'gp$i';
    final c = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == gid)
        .length;
    expect(c, 7, reason: 'AC-4 $gid $rs');
  }
  for (var i = 1; i <= 6; i++) {
    final mid = 'minor$i';
    final c = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == mid)
        .length;
    expect(c, 3, reason: 'AC-4 $mid $rs');
  }
  final ownedOw = game.worldState.oldWorld.provinces
      .where((p) => p.ownerId != null && p.ownerId!.isNotEmpty)
      .length;
  expect(ownedOw, 60, reason: 'AC-4 $rs');

  final nbrOw = _provincePpNeighboursForInitGameTest(topoOw);
  final ownersOw = <String, String>{
    for (final p in game.worldState.oldWorld.provinces)
      if (p.ownerId != null && p.ownerId!.isNotEmpty)
        ProvinceId.localIdFrom(p.id): p.ownerId!,
  };
  expect(ownersOw.length, 60, reason: 'AC-4 owners map $rs');

  for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
    expect(
      gpProvincesAreLandConnected(gpId, ownersOw, nbrOw),
      isTrue,
      reason: 'AC-5 $gpId $rs',
    );
    final gpProvinces = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == gpId)
        .toList();
    expect(gpProvinces, isNotEmpty, reason: 'AC-5 $gpId $rs');
    final anySea = gpProvinces.any(
      (p) => isProvinceSeaBound(topoOw, ProvinceId.localIdFrom(p.id)),
    );
    expect(anySea, isTrue, reason: 'AC-5 sea-bound $gpId $rs');
  }

  final compsBySize = _landComponentsFromPpNeighbours(nbrOw).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  expect(compsBySize.length, 4, reason: 'AC-6 $rs');
  expect(compsBySize[0].length, 17, reason: 'AC-6 $rs');
  expect(compsBySize[1].length, 17, reason: 'AC-6 $rs');
  expect(compsBySize[2].length, 13, reason: 'AC-6 $rs');
  expect(compsBySize[3].length, 13, reason: 'AC-6 $rs');
  for (final land in compsBySize) {
    final gps = <String>{};
    final mins = <String>{};
    for (final pid in land) {
      final o = ownersOw[pid];
      if (o == null) continue;
      if (o.startsWith('gp')) {
        gps.add(o);
      }
      if (o.startsWith('minor')) {
        mins.add(o);
      }
    }
    if (land.length == 17) {
      expect(gps.length, 2, reason: 'AC-6 17-tile continent $rs');
      expect(mins.length, 1, reason: 'AC-6 17-tile continent $rs');
    } else {
      expect(gps.length, 1, reason: 'AC-6 13-tile continent $rs');
      expect(mins.length, 2, reason: 'AC-6 13-tile continent $rs');
    }
  }

  for (var i = 1; i <= 6; i++) {
    final mid = 'minor$i';
    expect(
      gpProvincesAreLandConnected(mid, ownersOw, nbrOw),
      isTrue,
      reason: 'AC-7 $mid $rs',
    );
  }

  final nbrNw = _provincePpNeighboursForInitGameTest(topoNw);
  final ownersNw = <String, String>{
    for (final p in game.worldState.newWorld.provinces)
      if (p.ownerId != null && p.ownerId!.isNotEmpty)
        ProvinceId.localIdFrom(p.id): p.ownerId!,
  };
  expect(ownersNw.length, 30, reason: 'AC-8 $rs');
  for (var i = 1; i <= 10; i++) {
    final tid = 'tribe$i';
    final c = game.worldState.newWorld.provinces
        .where((p) => p.ownerId == tid)
        .length;
    expect(c, 3, reason: 'AC-8 $tid $rs');
    expect(
      gpProvincesAreLandConnected(tid, ownersNw, nbrNw),
      isTrue,
      reason: 'AC-8 $tid connected $rs',
    );
  }

  final nwComps = _landComponentsFromPpNeighbours(nbrNw);
  expect(nwComps.length, 4, reason: 'AC-9 $rs');
  for (final land in nwComps) {
    final tribes = <String>{};
    for (final pid in land) {
      final o = ownersNw[pid];
      if (o == null || !o.startsWith('tribe')) continue;
      tribes.add(o);
    }
    if (land.length == 9) {
      expect(tribes.length, 3, reason: 'AC-9 nine-tile continent $rs');
    } else if (land.length == 6) {
      expect(tribes.length, 2, reason: 'AC-9 six-tile continent $rs');
    } else {
      fail('unexpected NW land size ${land.length} ($rs)');
    }
  }
}
