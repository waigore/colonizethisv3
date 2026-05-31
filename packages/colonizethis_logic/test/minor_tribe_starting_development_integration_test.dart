// SPEC/game/factions.md § Starting developed resources (Minor Nations and Tribes)
// — end-to-end via createGameFromGeneratedMaps.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Minor/Tribe starting developed resources (integration)', () {
    const seeds = [42, 123, 7777];

    for (final seed in seeds) {
      test('seed $seed: every minor and tribe with a capital has up to K '
          'developed tiles in its capital province', () {
        final config = GameSetupConfig(
          selectedGreatPowerIds: const ['england', 'france'],
          continentCount: 2,
          minorNationCount: 4,
          tribeCount: 3,
          numProvincesOldWorld: 16,
          numProvincesNewWorld: 10,
          minProvincesPerMinor: 1,
          seed: seed,
        );
        final owParams = TileMapParams(
          width: 44,
          height: 34,
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
          width: 30,
          height: 26,
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
          gameId: 'minor-tribe-dev-$seed',
          namingSeed: seed,
        );

        final ws = setup.game.worldState;
        final forbidden = collectTownAndCapitalTileKeys(setup.game);

        bool tileInProvince(String tileKey, String fullProvId) {
          final parts = tileKey.split('|');
          if (parts.length != 4) return false;
          return '${parts[0]}|${parts[1]}' == fullProvId;
        }

        void verifyFaction({
          required String factionId,
          required CapitalTile? cap,
          required String? capProvId,
          required TileMapResult expectedRegionMap,
        }) {
          if (cap == null || capProvId == null) {
            // Setup did not assign a capital; rule must not develop anything.
            return;
          }
          final pred = selectMinorTribeStartingDevelopmentTileKeys(
            map: expectedRegionMap,
            capital: cap,
            tileState: TileMapState(),
            forbiddenTileKeys: forbidden,
            maxTiles: kMinorTribeStartingDevelopedTilesPerCapital,
          );

          // For each predicted developed tile, improvement level must be 1
          // after setup (rule applied end-to-end).
          for (final k in pred) {
            expect(
              ws.tileState.improvementLevel(k),
              1,
              reason:
                  'seed=$seed faction=$factionId tile=$k should be developed',
            );
            expect(
              tileInProvince(k, capProvId),
              isTrue,
              reason:
                  'seed=$seed faction=$factionId developed tile $k must lie in '
                  'capital province $capProvId',
            );
            expect(
              forbidden.contains(k),
              isFalse,
              reason:
                  'seed=$seed faction=$factionId developed tile $k must not be '
                  'capital or town',
            );
          }

          // Cap and town tiles for this faction must remain non-developed.
          expect(
            ws.tileState.improvementLevel(cap.toTileKey()),
            0,
            reason: 'seed=$seed $factionId capital must not be developed',
          );
        }

        for (final m in setup.game.minorNations) {
          verifyFaction(
            factionId: m.id,
            cap: m.capitalTile,
            capProvId: m.capitalProvinceId,
            expectedRegionMap: setup.tileMapByRegion[kRegionOldWorld]!,
          );
        }
        for (final t in setup.game.tribes) {
          verifyFaction(
            factionId: t.id,
            cap: t.capitalTile,
            capProvId: t.capitalProvinceId,
            expectedRegionMap: setup.tileMapByRegion[kRegionNewWorld]!,
          );
        }

        // Sanity: total developed tiles for minors/tribes is at most
        // K * (minors + tribes that have capitals).
        var totalDeveloped = 0;
        for (final m in setup.game.minorNations) {
          final cap = m.capitalTile;
          if (cap == null) continue;
          final pred = selectMinorTribeStartingDevelopmentTileKeys(
            map: setup.tileMapByRegion[kRegionOldWorld]!,
            capital: cap,
            tileState: TileMapState(),
            forbiddenTileKeys: forbidden,
            maxTiles: kMinorTribeStartingDevelopedTilesPerCapital,
          );
          totalDeveloped += pred.length;
        }
        for (final t in setup.game.tribes) {
          final cap = t.capitalTile;
          if (cap == null) continue;
          final pred = selectMinorTribeStartingDevelopmentTileKeys(
            map: setup.tileMapByRegion[kRegionNewWorld]!,
            capital: cap,
            tileState: TileMapState(),
            forbiddenTileKeys: forbidden,
            maxTiles: kMinorTribeStartingDevelopedTilesPerCapital,
          );
          totalDeveloped += pred.length;
        }
        expect(totalDeveloped, greaterThan(0),
            reason: 'at least one developed minor/tribe tile expected seed=$seed');
        expect(
          totalDeveloped,
          lessThanOrEqualTo(
            kMinorTribeStartingDevelopedTilesPerCapital *
                (setup.game.minorNations.length + setup.game.tribes.length),
          ),
        );
      });
    }

    test('GP starting grain bootstrap is unaffected by minor/tribe '
        'development step', () {
      final config = GameSetupConfig(
        selectedGreatPowerIds: const ['england', 'france'],
        continentCount: 2,
        minorNationCount: 2,
        tribeCount: 2,
        numProvincesOldWorld: 14,
        numProvincesNewWorld: 10,
        minProvincesPerMinor: 1,
        seed: 42,
      );
      final owParams = TileMapParams(
        width: 40,
        height: 32,
        seed: 42,
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
        width: 30,
        height: 24,
        seed: 43,
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
        gameId: 'gp-grain-with-minors-42',
        namingSeed: 42,
      );

      // Regression guard: every GP retains exactly four grain bootstrap farms
      // with improvement level 1 after the minor/tribe development step runs.
      final forbidden = collectTownAndCapitalTileKeys(setup.game);
      for (final p in setup.game.players) {
        final cap = p.capitalTile;
        expect(cap, isNotNull);
        final pred = selectGreatPowerBootstrapGrainTileKeysLandOnly(
          map: setup.tileMapByRegion[cap!.regionId]!,
          capital: cap,
          forbiddenTileKeys: forbidden,
        );
        expect(pred.length, 4);
        for (final k in pred) {
          expect(setup.game.worldState.tileState.improvementLevel(k), 1);
          expect(setup.game.worldState.resourceByTileKey[k], 'grain');
        }
      }
    });
  });
}
