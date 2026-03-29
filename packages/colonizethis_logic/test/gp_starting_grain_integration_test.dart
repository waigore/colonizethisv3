import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('Great Power starting grain bootstrap (integration)', () {
    const seeds = [42, 99, 2026, 7777];

    for (final seed in seeds) {
      test('seed $seed: four bootstrap farms, connected, four grain extracted', () {
        final config = GameSetupConfig(
          selectedGreatPowerIds: const ['england', 'france'],
          continentCount: 2,
          minorNationCount: 0,
          tribeCount: 0,
          numProvincesOldWorld: 14,
          numProvincesNewWorld: 8,
          minProvincesPerMinor: 0,
          seed: seed,
        );

        final owParams = TileMapParams(
          width: 40,
          height: 32,
          seed: seed,
          seaFraction: 0.55,
        );
        final (owMap, owTopo) = defaultTileMapRegionGenerator(
          params: owParams,
          numProvinces: config.numProvincesOldWorld,
          numContinents: config.continentCount,
          regionId: kRegionOldWorld,
          resourceRules: ResourceRules.defaultRules,
        );
        final nwParams = TileMapParams(
          width: 28,
          height: 24,
          seed: seed + 1,
          seaFraction: 0.55,
        );
        final (nwMap, nwTopo) = defaultTileMapRegionGenerator(
          params: nwParams,
          numProvinces: config.numProvincesNewWorld,
          numContinents: 1,
          regionId: kRegionNewWorld,
          resourceRules: ResourceRules.defaultRules,
        );

        final setup = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owMap,
          topologyOldWorld: owTopo,
          tileMapNewWorld: nwMap,
          topologyNewWorld: nwTopo,
          gameId: 'gp-grain-$seed',
          namingSeed: seed,
        );

        final tileByRegion = setup.tileMapByRegion;
        final combined = setup.combinedTopology;

        for (final p in setup.game.players) {
          final cap = p.capitalTile;
          expect(cap, isNotNull);
          final pred = selectGreatPowerBootstrapGrainTileKeysLandOnly(
            map: tileByRegion[cap!.regionId]!,
            capital: cap,
          );
          expect(pred.length, 4);

          final ws = setup.game.worldState;
          for (final k in pred) {
            expect(ws.resourceByTileKey[k], 'grain');
            expect(ws.tileState.improvementLevel(k), 1);
          }

          final connectivity = resolveConnectivity(
            game: setup.game,
            tileMapByRegion: tileByRegion,
            topology: combined,
          );
          final cr = connectivity[p.id]!;
          for (final k in pred) {
            expect(cr.connected.contains(k), true, reason: 'bootstrap $k connected seed=$seed');
            expect(
              cr.connectedByRoadRule.isEmpty || cr.connectedByRoadRule.contains(k),
              true,
              reason: 'bootstrap $k on road-rule network when used seed=$seed',
            );
          }

          final farmTotals = computeExtraction(
            game: setup.game,
            tileMapByRegion: tileByRegion,
            connectivityResult: connectivity,
            techCapForPlayer: (_) => 4,
            restrictToTileKeys: pred.toSet(),
          );
          expect(
            farmTotals[p.id]!.land['grain'] ?? 0,
            4,
            reason: 'four bootstrap farms × effective 1 grain each seed=$seed',
          );
        }
      });
    }

    test('capital province has townDevelopmentLevel 4 after setup', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: const ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 0,
        numProvincesOldWorld: 10,
        numProvincesNewWorld: 6,
        minProvincesPerMinor: 0,
        seed: 100,
      );
      final params = TileMapParams(width: 32, height: 26, seed: 100, seaFraction: 0.55);
      final (owMap, owTopo) = defaultTileMapRegionGenerator(
        params: params,
        numProvinces: config.numProvincesOldWorld,
        numContinents: 1,
        regionId: kRegionOldWorld,
        resourceRules: ResourceRules.defaultRules,
      );
      final (nwMap, nwTopo) = defaultTileMapRegionGenerator(
        params: TileMapParams(width: 24, height: 20, seed: 101, seaFraction: 0.55),
        numProvinces: config.numProvincesNewWorld,
        numContinents: 1,
        regionId: kRegionNewWorld,
        resourceRules: ResourceRules.defaultRules,
      );
      final setup = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owMap,
        topologyOldWorld: owTopo,
        tileMapNewWorld: nwMap,
        topologyNewWorld: nwTopo,
        gameId: 'town-dev-test',
      );
      for (final pl in setup.game.players) {
        final pid = pl.capitalProvinceId!;
        final local = ProvinceId.localIdFrom(pid);
        Province? prov;
        for (final x in setup.game.worldState.oldWorld.provinces) {
          if (x.id == pid || ProvinceId.localIdFrom(x.id) == local) {
            prov = x;
            break;
          }
        }
        expect(prov, isNotNull);
        expect(prov!.townDevelopmentLevel, 4);
      }
    });
  });
}
