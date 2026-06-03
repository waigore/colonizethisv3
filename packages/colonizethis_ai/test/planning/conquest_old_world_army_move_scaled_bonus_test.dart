// Unit tests for `conquestOldWorldArmyMoveScaledBonus` — Phase 3 conquest
// OW-invasion wiring (Refs #2847).
//
// Contract under test (SPEC/ai/phase-planner-architecture.md § Phase 3
// consumer wiring — conquest OW invasion):
//
//   - `oldWorldInvasionWeight == 1.0` is identity-equal to the legacy
//     full-magnitude addend.
//   - `oldWorldInvasionWeight <= 0.0` returns `0` (hard-suppress equivalent).
//   - Intermediate weights scale linearly with clamping to `[0.0, 1.0]`.
//   - Early-sprint default (`0.95`) retains 95% of legacy OW bias so the
//     gp1/gp2 +6 OW baseline is preserved.

import 'package:colonizethis_ai/src/planning/conquest_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('conquestOldWorldArmyMoveScaledBonus', () {
    test('weight 1.0 is identity-equal to base bonus', () {
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 50,
          oldWorldInvasionWeight: 1.0,
        ),
        50,
      );
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: kConquestArmyMoveAdjacentInvadableBonus.toDouble(),
          oldWorldInvasionWeight: 1.0,
        ),
        kConquestArmyMoveAdjacentInvadableBonus.toDouble(),
      );
    });

    test('weight <= 0.0 returns zero', () {
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 50,
          oldWorldInvasionWeight: 0.0,
        ),
        0.0,
      );
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 50,
          oldWorldInvasionWeight: -0.1,
        ),
        0.0,
      );
    });

    test('early-sprint default 0.95 retains 95% OW bias', () {
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 10,
          oldWorldInvasionWeight: 0.95,
        ),
        9.5,
      );
    });

    test('OW=9 curve row 0.80 scales linearly', () {
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 10,
          oldWorldInvasionWeight: 0.80,
        ),
        8.0,
      );
    });

    test('weights above 1.0 clamp to identity at 1.0', () {
      expect(
        conquestOldWorldArmyMoveScaledBonus(
          baseBonus: 10,
          oldWorldInvasionWeight: 1.5,
        ),
        10,
      );
    });

    test('is deterministic for identical inputs (Refs #2509 Must-have #7)', () {
      final first = conquestOldWorldArmyMoveScaledBonus(
        baseBonus: 8,
        oldWorldInvasionWeight: 0.80,
      );
      final second = conquestOldWorldArmyMoveScaledBonus(
        baseBonus: 8,
        oldWorldInvasionWeight: 0.80,
      );
      expect(second, first);
    });
  });
}
