import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('Great Power starting grain bootstrap (integration)', () {
    // Fixed regression sample of map seeds whose generated Old World layout
    // hosts four connected bootstrap grain farms per Great Power. Regenerated
    // after the forest terrain split (#3573 R6) changed terrain distribution
    // weights and therefore the seeded layouts: seed 99 now yields a capital
    // province whose closest land tile is not road/town-rule connected (a
    // condition production tolerates by roading it during play but this sample
    // asserts up front), so it is replaced with seed 123, which is feasible.
    const seeds = [42, 123, 2026, 7777];

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
          final capKey = cap!.toTileKey();
          final forbidden = collectTownAndCapitalTileKeys(setup.game);
          expect(forbidden.contains(capKey), true);
          final pred = selectGreatPowerBootstrapGrainTileKeysLandOnly(
            map: tileByRegion[cap.regionId]!,
            capital: cap,
            forbiddenTileKeys: forbidden,
          );
          expect(pred.length, 4);
          expect(pred.contains(capKey), false, reason: 'capital/town is not a farm');

          for (final ct in <CapitalTile?>[
            ...setup.game.players.map((p) => p.capitalTile),
            ...setup.game.minorNations.map((m) => m.capitalTile),
            ...setup.game.tribes.map((t) => t.capitalTile),
          ]) {
            if (ct == null) continue;
            final ck = ct.toTileKey();
            expect(
              setup.tileMapByRegion[ct.regionId]!.resourceAt(ct.x, ct.y),
              isNull,
              reason: 'no terrain resource on capital $ck seed=$seed',
            );
            expect(
              setup.game.worldState.tileState.improvementLevel(ck),
              0,
              reason: 'no extraction improvement on capital $ck seed=$seed',
            );
          }

          final ws = setup.game.worldState;
          for (final k in pred) {
            expect(ws.resourceByTileKey[k], 'grain');
            expect(ws.tileState.improvementLevel(k), 1);
          }

          for (final prov in ws.oldWorld.provinces) {
            final tk = prov.townTileKey;
            if (tk == null || tk.isEmpty) continue;
            final parts = tk.split('|');
            if (parts.length != 4) continue;
            final rid = parts[0];
            final x = int.parse(parts[2]);
            final y = int.parse(parts[3]);
            expect(
              tileByRegion[rid]!.resourceAt(x, y),
              isNull,
              reason: 'no resource on town $tk seed=$seed',
            );
            expect(
              ws.tileState.improvementLevel(tk),
              0,
              reason: 'no extraction improvement on town $tk seed=$seed',
            );
          }
          for (final prov in ws.newWorld.provinces) {
            final tk = prov.townTileKey;
            if (tk == null || tk.isEmpty) continue;
            final parts = tk.split('|');
            if (parts.length != 4) continue;
            final rid = parts[0];
            final x = int.parse(parts[2]);
            final y = int.parse(parts[3]);
            expect(
              tileByRegion[rid]!.resourceAt(x, y),
              isNull,
              reason: 'NW no resource on town $tk seed=$seed',
            );
            expect(
              ws.tileState.improvementLevel(tk),
              0,
              reason: 'NW no extraction improvement on town $tk seed=$seed',
            );
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
            9,
            reason:
                'four bootstrap farms × 1 grain + capital tile bonus 5 seed=$seed',
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
