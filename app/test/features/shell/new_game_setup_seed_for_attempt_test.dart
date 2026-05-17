import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'package:colonizethis_app/features/shell/new_game_setup_seed_for_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  group('newGameSetupConfigSeedForAttempt', () {
    test('dialog seed 0 keeps config seed 0 on every attempt index', () {
      for (final n in [0, 1, 2, 10]) {
        expect(
          newGameSetupConfigSeedForAttempt(
            dialogChosenSeed: 0,
            attemptIndex: n,
          ),
          0,
        );
      }
    });

    test('dialog seed K uses K plus attempt index', () {
      expect(
        newGameSetupConfigSeedForAttempt(
          dialogChosenSeed: 42,
          attemptIndex: 0,
        ),
        42,
      );
      expect(
        newGameSetupConfigSeedForAttempt(
          dialogChosenSeed: 42,
          attemptIndex: 1,
        ),
        43,
      );
      expect(
        newGameSetupConfigSeedForAttempt(
          dialogChosenSeed: 42,
          attemptIndex: 3,
        ),
        45,
      );
    });

    test('K == 1 increments from first retry', () {
      expect(
        newGameSetupConfigSeedForAttempt(dialogChosenSeed: 1, attemptIndex: 0),
        1,
      );
      expect(
        newGameSetupConfigSeedForAttempt(dialogChosenSeed: 1, attemptIndex: 1),
        2,
      );
    });

    test('throws when attemptIndex is negative', () {
      expect(
        () => newGameSetupConfigSeedForAttempt(
          dialogChosenSeed: 0,
          attemptIndex: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when dialogChosenSeed is negative', () {
      expect(
        () => newGameSetupConfigSeedForAttempt(
          dialogChosenSeed: -1,
          attemptIndex: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
