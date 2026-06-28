import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'init_game_orchestrator_test_support.dart';

void main() {
  group('runInitGame', () {
    test(
      'locked full-init profile: 60 OW / 30 NW, 6 GPs, 6 minors; init succeeds and GPs are P–P connected',
      () {
        final config = lockedFullInitConfig(
          seed: GameSetupConfig.defaultConfig.seed,
        );

        final result = runInitGame(config: config, options: defaultInitOptions);
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
        final config = lockedFullInitConfig(seed: 42);
        final result = runInitGame(config: config, options: defaultInitOptions);
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
          final result = runInitGame(config: config, options: defaultInitOptions);
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
      'freeform sim_scenarios diplomacy_initial_relations config completes',
      () {
        final config = GameSetupConfig(
          seed: 12345,
          selectedGreatPowerIds: ['england', 'france', 'spain'],
          continentCount: 4,
          minorNationCount: 4,
          tribeCount: 6,
          numProvincesOldWorld: 60,
          numProvincesNewWorld: 80,
        );
        final result = runInitGame(
          config: config,
          options: const InitGameOptions(renderPng: false),
        );
        expect(result.game.players.length, greaterThan(0));
      },
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'AC-12 locked full-init profile: same seed yields identical OW owners',
      () {
        // Must match one of the AC-11 regression seeds (#1861 / #1822).
        const s = 17011;
        final config = lockedFullInitConfig(seed: s);
        final a = runInitGame(config: config, options: defaultInitOptions);
        final b = runInitGame(config: config, options: defaultInitOptions);

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
