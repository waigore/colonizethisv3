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

        final result = runInitGame(
          config: config,
          options: kFastInitNoMapView,
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
        final config = smallUnlockedConfig();

        const overrideSemanticId = 'england';
        const overrideColor = (200, 10, 150);

        final result = runInitGame(
          config: config,
          options: const InitGameOptions(
            cellSize: 8,
            renderPng: false,
            buildMapViewData: false,
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
      final result = runInitGame(
        config: config,
        options: kFastInitNoMapView,
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
      final config = smallUnlockedConfig();
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(
          cellSize: 8,
          renderPng: false,
          buildMapViewData: false,
          skipFillLakes: true,
        ),
      );
      expect(result.game, isNotNull);
      expect(result.markdown, isNotEmpty);
    });

    test(
      'result includes warpLinks and combinedTopology has prefixed node ids',
      () {
        final config = smallUnlockedConfig();
        final result = runInitGame(
          config: config,
          options: kFastInitNoMapView,
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
      final config = smallUnlockedConfig(seed: 0);
      final result = runInitGame(
        config: config,
        options: kFastInitNoMapView,
      );
      expect(result.game, isNotNull);
      expect(result.game.globalGameSeed, isNonZero);
    });

    test('non-zero seed: globalGameSeed matches config.seed', () {
      const k = 900_001;
      final config = smallUnlockedConfig(seed: k);
      final result = runInitGame(
        config: config,
        options: kFastInitNoMapView,
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
        final config = smallUnlockedConfig(seed: k);
        const options = InitGameOptions(
          cellSize: 8,
          renderPng: false,
          buildMapViewData: false,
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
      expect(nwSeed, k + 1);
      expect(owSeed, greaterThanOrEqualTo(k));
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
      'default config locks 60 OW, 6 GPs, 6 minors with strict 4-continent role split',
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
          enforceFairAssignment: true,
        );

        final result = runInitGame(
          config: config,
          options: kLockedInitNoMapView,
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
        for (final minorId in [
          'minor1',
          'minor2',
          'minor3',
          'minor4',
          'minor5',
          'minor6',
        ]) {
          expect(
            factionProvincesAreLandConnected(minorId, owners, nbr),
            isTrue,
            reason: '$minorId OW territory must be one P–P component',
          );
        }
        final nwTopo = result.topologyByRegion[kRegionNewWorld]!;
        final nwNbr = _provincePpNeighboursForInitGameTest(nwTopo);
        final nwOwners = <String, String>{
          for (final p in game.worldState.newWorld.provinces)
            if (p.ownerId != null) ProvinceId.localIdFrom(p.id): p.ownerId!,
        };
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
        ]) {
          if (!nwOwners.containsValue(tribeId)) continue;
          expect(
            factionProvincesAreLandConnected(tribeId, nwOwners, nwNbr),
            isTrue,
            reason: '$tribeId NW territory must be one P–P component',
          );
        }
        final landmassByProvince = _landmassIdsForTopology(topo);
        _expectLockedRoleSplit(
          owners: owners,
          landmassByProvince: landmassByProvince,
        );
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
      },
    );

    test(
      'buildMapViewData=false is incompatible with renderPng=true',
      () {
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
      },
    );

    test(
      'five seeds keep strict continent split and fair-assignment province '
      'connectivity (no enclosed OW lakes)',
      () {
        const seeds = [42, 809, 1907];
        for (final seed in seeds) {
          final result = runInitGame(
            config: GameSetupConfig(seed: seed, enforceFairAssignment: true),
            options: kLockedInitNoMapView,
          );
          final owners = <String, String>{
            for (final p in result.game.worldState.oldWorld.provinces)
              ProvinceId.localIdFrom(p.id): p.ownerId ?? '',
          };
          for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
            expect(
              owners.values.where((owner) => owner == gpId).length,
              7,
              reason: 'seed=$seed $gpId should own exactly 7 provinces',
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
              reason: 'seed=$seed $minorId should own exactly 3 provinces',
            );
          }
          final landmassByProvince = _landmassIdsForTopology(
            result.topologyByRegion[kRegionOldWorld]!,
          );
          final owNeighbours = _provincePpNeighboursForInitGameTest(
            result.topologyByRegion[kRegionOldWorld]!,
          );
          for (final gpId in ['gp1', 'gp2', 'gp3', 'gp4', 'gp5', 'gp6']) {
            expect(
              factionProvincesAreLandConnected(gpId, owners, owNeighbours),
              isTrue,
              reason: 'seed=$seed $gpId should be contiguous',
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
              factionProvincesAreLandConnected(minorId, owners, owNeighbours),
              isTrue,
              reason: 'seed=$seed $minorId should be contiguous',
            );
          }
          final nwOwners = <String, String>{
            for (final p in result.game.worldState.newWorld.provinces)
              if (p.ownerId != null) ProvinceId.localIdFrom(p.id): p.ownerId!,
          };
          final nwNeighbours = _provincePpNeighboursForInitGameTest(
            result.topologyByRegion[kRegionNewWorld]!,
          );
          for (final tribeId in result.game.tribes.map((t) => t.id)) {
            expect(
              factionProvincesAreLandConnected(tribeId, nwOwners, nwNeighbours),
              isTrue,
              reason: 'seed=$seed $tribeId should be contiguous',
            );
          }
          _expectLockedRoleSplit(
            owners: owners,
            landmassByProvince: landmassByProvince,
          );
          final owTileMap = result.tileMapByRegion[kRegionOldWorld]!;
          final owTopology = result.topologyByRegion[kRegionOldWorld]!;
          expect(
            _hasEnclosedSeaPocket(owTileMap, owTopology),
            isFalse,
            reason: 'seed=$seed should not contain enclosed lakes',
          );
        }
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
