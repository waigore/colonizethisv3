import 'dart:typed_data';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('runInitGame', () {
    const kFastInitNoMapView = InitGameOptions(
      cellSize: 8,
      renderPng: false,
      buildMapViewData: false,
      enforceLockedOldWorldProfile: false,
    );
    const kLockedInitNoMapView = InitGameOptions(
      cellSize: 8,
      renderPng: false,
      buildMapViewData: false,
      enforceLockedOldWorldProfile: true,
    );
    GameSetupConfig smallUnlockedConfig({
      int seed = 42,
      bool enforceFairAssignment = false,
    }) {
      final base = GameSetupConfig.defaultConfig;
      final selectedGreatPowerIds = base.selectedGreatPowerIds.take(2).toList();
      return GameSetupConfig(
        selectedGreatPowerIds: selectedGreatPowerIds,
        leaderVariantByGpId: {
          for (final id in selectedGreatPowerIds)
            if (base.leaderVariantByGpId[id] != null)
              id: base.leaderVariantByGpId[id]!,
        },
        continentCount: 2,
        minorNationCount: 0,
        tribeCount: 2,
        numProvincesOldWorld: 20,
        numProvincesNewWorld: 20,
        minProvincesPerMinor: 3,
        seed: seed,
        startingResources: base.startingResources,
        enforceFairAssignment: enforceFairAssignment,
      );
    }

    test(
      'renderPng=false skips PNG bytes but still returns game and view data',
      () {
        final config = smallUnlockedConfig();

        final result = runInitGame(config: config, options: kFastInitNoMapView);

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
        final config = smallUnlockedConfig();

        const overrideSemanticId = 'england';
        const overrideColor = (200, 10, 150);

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(
            cellSize: 8,
            renderPng: false,
            buildMapViewData: false,
            enforceLockedOldWorldProfile: false,
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
      final config = smallUnlockedConfig();
      final result = runInitGame(config: config, options: kFastInitNoMapView);
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
      final config = smallUnlockedConfig();
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: false,
          buildMapViewData: false,
          skipFillLakes: true,
          enforceLockedOldWorldProfile: false,
        ),
      );
      expect(result.game, isNotNull);
      expect(result.markdown, isNotEmpty);
    });

    test(
      'result includes warpLinks and combinedTopology has prefixed node ids',
      () {
        final config = smallUnlockedConfig();
        final result = runInitGame(config: config, options: kFastInitNoMapView);
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
      final config = smallUnlockedConfig(seed: 0);
      final result = runInitGame(config: config, options: kFastInitNoMapView);
      expect(result.game, isNotNull);
      expect(result.game.globalGameSeed, isNonZero);
    });

    test('non-zero seed: globalGameSeed matches config.seed', () {
      const k = 900_001;
      final config = smallUnlockedConfig(seed: k);
      final result = runInitGame(config: config, options: kFastInitNoMapView);
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
        final config = smallUnlockedConfig(seed: k);
        const options = InitGameOptions(
          cellSize: 8,
          renderPng: false,
          buildMapViewData: false,
          enforceLockedOldWorldProfile: false,
        );
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
      final config = smallUnlockedConfig(seed: k);

      runInitGame(
        config: config,
        options: kFastInitNoMapView,
        generateRegion: captureSeeds,
      );

      final owSeed = seedsByRegion[kRegionOldWorld]!;
      final nwSeed = seedsByRegion[kRegionNewWorld]!;
      expect(
        owSeed,
        greaterThanOrEqualTo(k),
        reason: 'OW retry seed should be deterministic and >= base seed',
      );
      expect(
        nwSeed,
        greaterThanOrEqualTo(k + 1),
        reason: 'NW retry seed should be deterministic and >= base seed + 1',
      );
    });

    test('after runInitGame worldState.turnState is orders at turn 0', () {
      final result = runInitGame(
        config: smallUnlockedConfig(),
        options: kFastInitNoMapView,
      );
      expect(result.game.worldState.turnState.phase, TurnPhase.orders);
      expect(result.game.worldState.turnState.turnNumber, 0);
    });

    test('renderPng=true returns non-empty map PNG bytes', () {
      final config = smallUnlockedConfig();
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: true,
          enforceLockedOldWorldProfile: false,
        ),
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

      final config = smallUnlockedConfig();
      final result = runInitGame(
        config: config,
        options: kFastInitNoMapView,
        generateRegion: countingGen,
      );

      expect(callCount, greaterThanOrEqualTo(2));
      expect(result.game, isNotNull);
    });

    test(
      'locked profile enforces OW/NW quotas and role split without fair-repair mode',
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
          enforceFairAssignment: false,
        );

        final result = runInitGame(
          config: config,
          options: kLockedInitNoMapView,
        );
        _expectLockedAssignmentInvariants(result, seed: base.seed);
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
          options: kLockedInitNoMapView,
        );
        expect(result.game.worldState.oldWorld.provinces.length, 60);
        expect(result.game.worldState.newWorld.provinces.length, 30);
      },
    );

    test('buildMapViewData=false is incompatible with renderPng=true', () {
      expect(
        () => runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: const InitGameOptions(
            cellSize: 8,
            renderPng: true,
            buildMapViewData: false,
          ),
        ),
        throwsA(isA<SetupConfigConstraintException>()),
      );
    });

    test(
      '20 locked seeds satisfy OW/NW topology, quotas, and contiguity invariants',
      () {
        const seeds = [
          42,
          73,
          101,
          211,
          307,
          503,
          809,
          911,
          1201,
          1453,
          1601,
          1907,
          2203,
          2503,
          2801,
          3203,
          3607,
          4001,
          5003,
          7001,
        ];
        for (final seed in seeds) {
          final result = runInitGame(
            config: GameSetupConfig(seed: seed, enforceFairAssignment: false),
            options: kLockedInitNoMapView,
          );
          _expectLockedAssignmentInvariants(result, seed: seed);
        }
      },
    );

    test('same locked seed yields identical owner maps', () {
      const seed = 42;
      final first = runInitGame(
        config: GameSetupConfig(seed: seed, enforceFairAssignment: false),
        options: kLockedInitNoMapView,
      );
      final second = runInitGame(
        config: GameSetupConfig(seed: seed, enforceFairAssignment: false),
        options: kLockedInitNoMapView,
      );
      expect(
        _ownersByProvinceId(first.game.worldState.oldWorld.provinces),
        _ownersByProvinceId(second.game.worldState.oldWorld.provinces),
      );
      expect(
        _ownersByProvinceId(first.game.worldState.newWorld.provinces),
        _ownersByProvinceId(second.game.worldState.newWorld.provinces),
      );
    });
  });
}

void _expectLockedAssignmentInvariants(
  InitGameResult result, {
  required int seed,
}) {
  final game = result.game;
  expect(game.worldState.oldWorld.provinces.length, 60);
  expect(game.worldState.newWorld.provinces.length, 30);
  expect(game.players.length, 6);
  expect(game.minorNations.length, 6);
  expect(game.tribes.length, 10);

  final owTopology = result.topologyByRegion[kRegionOldWorld]!;
  final nwTopology = result.topologyByRegion[kRegionNewWorld]!;
  _expectPartitionSizes(
    topology: owTopology,
    expectedSortedSizes: [13, 13, 17, 17],
    reason: 'seed=$seed Old World partition mismatch',
  );
  _expectPartitionSizes(
    topology: nwTopology,
    expectedSortedSizes: [6, 6, 9, 9],
    reason: 'seed=$seed New World partition mismatch',
  );

  final owOwners = <String, String>{
    for (final p in game.worldState.oldWorld.provinces)
      ProvinceId.localIdFrom(p.id): p.ownerId ?? '',
  };
  final nwOwners = <String, String>{
    for (final p in game.worldState.newWorld.provinces)
      ProvinceId.localIdFrom(p.id): p.ownerId ?? '',
  };
  expect(
    owOwners.values.where((id) => id.isNotEmpty).length,
    60,
    reason: 'seed=$seed all Old World provinces must be owned',
  );
  expect(
    nwOwners.values.where((id) => id.isNotEmpty).length,
    30,
    reason: 'seed=$seed all New World provinces must be owned',
  );

  final gpIds = ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6'];
  final minorIds = ['minor1', 'minor2', 'minor3', 'minor4', 'minor5', 'minor6'];
  final tribeIds = [
    'tribe1',
    'tribe2',
    'tribe3',
    'tribe4',
    'tribe5',
    'tribe6',
    'tribe7',
    'tribe8',
    'tribe9',
    'tribe10',
  ];
  for (final gpId in gpIds) {
    expect(
      owOwners.values.where((owner) => owner == gpId).length,
      7,
      reason: 'seed=$seed $gpId should own exactly 7 OW provinces',
    );
  }
  for (final minorId in minorIds) {
    expect(
      owOwners.values.where((owner) => owner == minorId).length,
      3,
      reason: 'seed=$seed $minorId should own exactly 3 OW provinces',
    );
  }
  for (final tribeId in tribeIds) {
    expect(
      nwOwners.values.where((owner) => owner == tribeId).length,
      3,
      reason: 'seed=$seed $tribeId should own exactly 3 NW provinces',
    );
  }

  final owNeighbours = _provincePpNeighboursForInitGameTest(owTopology);
  final nwNeighbours = _provincePpNeighboursForInitGameTest(nwTopology);
  for (final gpId in gpIds) {
    expect(
      factionProvincesAreLandConnected(gpId, owOwners, owNeighbours),
      isTrue,
      reason: 'seed=$seed $gpId should be contiguous',
    );
  }
  for (final minorId in minorIds) {
    expect(
      factionProvincesAreLandConnected(minorId, owOwners, owNeighbours),
      isTrue,
      reason: 'seed=$seed $minorId should be contiguous',
    );
  }
  for (final tribeId in tribeIds) {
    expect(
      factionProvincesAreLandConnected(tribeId, nwOwners, nwNeighbours),
      isTrue,
      reason: 'seed=$seed $tribeId should be contiguous',
    );
  }

  final owLandmassByProvince = _landmassIdsForTopology(owTopology);
  _expectLockedRoleSplit(
    owners: owOwners,
    landmassByProvince: owLandmassByProvince,
  );
  final nwLandmassByProvince = _landmassIdsForTopology(nwTopology);
  _expectLockedNewWorldRoleSplit(
    owners: nwOwners,
    landmassByProvince: nwLandmassByProvince,
  );

  final owTileMap = result.tileMapByRegion[kRegionOldWorld]!;
  expect(
    _hasEnclosedSeaPocket(owTileMap, owTopology),
    isFalse,
    reason: 'seed=$seed should not contain enclosed lakes',
  );
}

Map<String, String> _ownersByProvinceId(List<Province> provinces) {
  final out = <String, String>{};
  for (final province in provinces) {
    out[province.id] = province.ownerId ?? '';
  }
  return out;
}

void _expectPartitionSizes({
  required MapTopology topology,
  required List<int> expectedSortedSizes,
  required String reason,
}) {
  final landmassByProvince = _landmassIdsForTopology(topology);
  final counts = <int, int>{};
  for (final landmassId in landmassByProvince.values) {
    counts[landmassId] = (counts[landmassId] ?? 0) + 1;
  }
  final sortedSizes = counts.values.toList()..sort();
  expect(sortedSizes, expectedSortedSizes, reason: reason);
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

Map<String, int> _landmassIdsForTopology(MapTopology topology) {
  final neighbours = _provincePpNeighboursForInitGameTest(topology);
  final landmassByProvince = <String, int>{};
  var landmassId = 0;
  final provinceIds = neighbours.keys.toList()..sort();
  for (final provinceId in provinceIds) {
    if (landmassByProvince.containsKey(provinceId)) continue;
    final stack = <String>[provinceId];
    landmassByProvince[provinceId] = landmassId;
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final next in neighbours[current] ?? const <String>{}) {
        if (landmassByProvince.containsKey(next)) continue;
        landmassByProvince[next] = landmassId;
        stack.add(next);
      }
    }
    landmassId++;
  }
  return landmassByProvince;
}

int _singleOwnedLandmass(
  String factionId,
  Map<String, String> owners,
  Map<String, int> landmassByProvince,
) {
  final ownedLandmasses = owners.entries
      .where((entry) => entry.value == factionId)
      .map((entry) => landmassByProvince[entry.key])
      .whereType<int>()
      .toSet();
  expect(
    ownedLandmasses.length,
    1,
    reason: '$factionId should own one landmass',
  );
  return ownedLandmasses.single;
}

void _expectLockedRoleSplit({
  required Map<String, String> owners,
  required Map<String, int> landmassByProvince,
}) {
  final gpLandmassById = {
    for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6'])
      gpId: _singleOwnedLandmass(gpId, owners, landmassByProvince),
  };
  final minorLandmassById = {
    for (final minorId in [
      'minor1',
      'minor2',
      'minor3',
      'minor4',
      'minor5',
      'minor6',
    ])
      minorId: _singleOwnedLandmass(minorId, owners, landmassByProvince),
  };
  final factionCountByLandmass = <int, ({int gp, int minor})>{};
  for (final lm in landmassByProvince.values.toSet()) {
    factionCountByLandmass[lm] = (gp: 0, minor: 0);
  }
  for (final lm in gpLandmassById.values) {
    final counts = factionCountByLandmass[lm]!;
    factionCountByLandmass[lm] = (gp: counts.gp + 1, minor: counts.minor);
  }
  for (final lm in minorLandmassById.values) {
    final counts = factionCountByLandmass[lm]!;
    factionCountByLandmass[lm] = (gp: counts.gp, minor: counts.minor + 1);
  }
  final observedSplit = factionCountByLandmass.values.toList()
    ..sort((a, b) {
      final gpCmp = b.gp.compareTo(a.gp);
      if (gpCmp != 0) return gpCmp;
      return b.minor.compareTo(a.minor);
    });
  expect(observedSplit, [
    (gp: 2, minor: 1),
    (gp: 2, minor: 1),
    (gp: 1, minor: 2),
    (gp: 1, minor: 2),
  ]);
}

void _expectLockedNewWorldRoleSplit({
  required Map<String, String> owners,
  required Map<String, int> landmassByProvince,
}) {
  final tribeLandmassById = {
    for (final tribeId in [
      'tribe1',
      'tribe2',
      'tribe3',
      'tribe4',
      'tribe5',
      'tribe6',
      'tribe7',
      'tribe8',
      'tribe9',
      'tribe10',
    ])
      tribeId: _singleOwnedLandmass(tribeId, owners, landmassByProvince),
  };
  final tribesByLandmass = <int, int>{};
  for (final landmassId in tribeLandmassById.values) {
    tribesByLandmass[landmassId] = (tribesByLandmass[landmassId] ?? 0) + 1;
  }
  final observed = tribesByLandmass.values.toList()..sort((a, b) => b - a);
  expect(observed, [3, 3, 2, 2]);
}

bool _hasEnclosedSeaPocket(TileMapResult map, MapTopology topology) {
  final provinceIds = {
    for (final node in topology.nodes)
      if (node.type == TopologyNodeType.province) node.id,
  };
  final isSea = List.generate(
    map.height,
    (y) =>
        List.generate(map.width, (x) => !provinceIds.contains(map.cell(x, y))),
  );
  final visited = <String>{};
  final stack = <(int x, int y)>[];
  void pushIfSea(int x, int y) {
    if (x < 0 || x >= map.width || y < 0 || y >= map.height) return;
    if (!isSea[y][x]) return;
    final key = '$x|$y';
    if (!visited.add(key)) return;
    stack.add((x, y));
  }

  for (var x = 0; x < map.width; x++) {
    pushIfSea(x, 0);
    pushIfSea(x, map.height - 1);
  }
  for (var y = 0; y < map.height; y++) {
    pushIfSea(0, y);
    pushIfSea(map.width - 1, y);
  }
  while (stack.isNotEmpty) {
    final (x, y) = stack.removeLast();
    pushIfSea(x - 1, y);
    pushIfSea(x + 1, y);
    pushIfSea(x, y - 1);
    pushIfSea(x, y + 1);
  }

  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (!isSea[y][x]) continue;
      if (!visited.contains('$x|$y')) return true;
    }
  }
  return false;
}
