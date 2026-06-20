import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_turn/src/turn/turn_resolution_helpers.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_seeds.dart';

/// Unit coverage for the shared turn-resolution helpers extracted in Refs #3565:
/// the province-capture predicate, the `[0, 1]` clamp, and the deterministic
/// turn sub-seed mix. These dedup previously inlined logic, so the tests pin the
/// exact boundary/branch behavior the call sites relied on.
void main() {
  Game gameWithSeed(int? seed) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'h1', displayName: 'Human', isHuman: true)],
    globalGameSeed: seed,
  );

  group('isProvinceOwnershipCaptured', () {
    test('true when ownership changes between two non-empty factions', () {
      expect(isProvinceOwnershipCaptured('gp1', 'gp2'), isTrue);
    });

    test('false when owner is unchanged', () {
      expect(isProvinceOwnershipCaptured('gp1', 'gp1'), isFalse);
    });

    test('false when previous owner is null (frontier colonization)', () {
      expect(isProvinceOwnershipCaptured(null, 'gp2'), isFalse);
    });

    test('false when new owner is null (abandonment)', () {
      expect(isProvinceOwnershipCaptured('gp1', null), isFalse);
    });

    test('false when either owner is the empty string', () {
      expect(isProvinceOwnershipCaptured('', 'gp2'), isFalse);
      expect(isProvinceOwnershipCaptured('gp1', ''), isFalse);
    });
  });

  group('clamp01', () {
    test('returns the value unchanged when already within [0, 1]', () {
      expect(clamp01(0.4), 0.4);
    });

    test('preserves exact boundary values', () {
      expect(clamp01(0.0), 0.0);
      expect(clamp01(1.0), 1.0);
    });

    test('clamps values below 0 up to 0', () {
      expect(clamp01(-0.25), 0.0);
    });

    test('clamps values above 1 down to 1', () {
      expect(clamp01(1.75), 1.0);
    });
  });

  group('mixTurnSeed', () {
    test('matches the canonical seed mix for a known global seed', () {
      final game = gameWithSeed(12345);
      expect(mixTurnSeed(game, 7), 12345 ^ (7 * kTurnResolutionSeedMix));
    });

    test('treats a null global seed as 0', () {
      final game = gameWithSeed(null);
      expect(mixTurnSeed(game, 7), 0 ^ (7 * kTurnResolutionSeedMix));
    });

    test('is deterministic for identical inputs', () {
      final game = gameWithSeed(999);
      expect(mixTurnSeed(game, 3), mixTurnSeed(game, 3));
    });

    test('differs across turns for the same global seed', () {
      final game = gameWithSeed(999);
      expect(mixTurnSeed(game, 3), isNot(mixTurnSeed(game, 4)));
    });
  });
}
