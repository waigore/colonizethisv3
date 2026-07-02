import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'init_game_orchestrator_test_support.dart';

/// Refs #3176 — configurable Great Power human/AI slot assignment at init_game.
///
/// SPEC: SPEC/program/game-setup-pipeline.md § Human/AI slot assignment.
void main() {
  GameSetupConfig lockedConfig({Set<int>? humanSlots}) {
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
      seed: base.seed,
      startingResources: base.startingResources,
      humanGreatPowerSlotIndices: humanSlots,
    );
  }

  group('GameSetupConfig.humanGreatPowerSlotIndices default', () {
    test('defaults to {0} when omitted', () {
      expect(GameSetupConfig.defaultConfig.humanGreatPowerSlotIndices, {0});
    });
  });

  group('runInitGame human/AI slot assignment', () {
    test(
      'default (omitted) => exactly one human (gp1) and aiControlByGpId '
      '{gp1:false, gp2..gpN:true}',
      () {
        final result = runInitGame(
          config: lockedConfig(),
          options: defaultInitOptions,
        );
        final game = result.game;

        final humans = game.players.where((p) => p.isHuman).toList();
        expect(humans, hasLength(1));
        expect(humans.single.id, 'gp1');

        expect(game.aiControlByGpId['gp1'], isFalse);
        for (final p in game.players.where((p) => p.id != 'gp1')) {
          expect(p.isHuman, isFalse, reason: '${p.id} should be AI');
          expect(
            game.aiControlByGpId[p.id],
            isTrue,
            reason: '${p.id} should be AI-controlled',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'empty set => every Great Power isHuman:false and aiControlByGpId:true',
      () {
        final result = runInitGame(
          config: lockedConfig(humanSlots: const <int>{}),
          options: defaultInitOptions,
        );
        final game = result.game;

        expect(game.players, isNotEmpty);
        for (final p in game.players) {
          expect(p.isHuman, isFalse, reason: '${p.id} should not be human');
          expect(
            game.aiControlByGpId[p.id],
            isTrue,
            reason: '${p.id} should be AI-controlled',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      '{2} => only gp3 is human and not AI-controlled; all others AI',
      () {
        final result = runInitGame(
          config: lockedConfig(humanSlots: const {2}),
          options: defaultInitOptions,
        );
        final game = result.game;

        final humans = game.players.where((p) => p.isHuman).toList();
        expect(humans, hasLength(1));
        expect(humans.single.id, 'gp3');
        expect(game.aiControlByGpId['gp3'], isFalse);

        for (final p in game.players.where((p) => p.id != 'gp3')) {
          expect(p.isHuman, isFalse, reason: '${p.id} should be AI');
          expect(game.aiControlByGpId[p.id], isTrue, reason: '${p.id} AI');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'index >= greatPowerCount throws human_slot_index_out_of_range and '
      'produces no game',
      () {
        // greatPowerCount is 6 (default selection); index 6 is out of range.
        expect(
          () => runInitGame(
            config: lockedConfig(humanSlots: const {6}),
            options: defaultInitOptions,
          ),
          throwsA(
            isA<SetupConfigConstraintException>().having(
              (e) => e.code,
              'code',
              'human_slot_index_out_of_range',
            ),
          ),
        );
      },
    );

    test(
      'negative index throws human_slot_index_out_of_range and produces no game',
      () {
        expect(
          () => runInitGame(
            config: lockedConfig(humanSlots: const {-1}),
            options: defaultInitOptions,
          ),
          throwsA(
            isA<SetupConfigConstraintException>().having(
              (e) => e.code,
              'code',
              'human_slot_index_out_of_range',
            ),
          ),
        );
      },
    );
  });
}
