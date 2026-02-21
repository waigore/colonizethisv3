import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('leaderCombatBonusMultiplier', () {
    test('null returns 1.0', () {
      expect(leaderCombatBonusMultiplier(null), 1.0);
    });

    test('empty string returns 1.0', () {
      expect(leaderCombatBonusMultiplier(''), 1.0);
    });

    test('napoleon returns 1.25 (SPEC +25% melee)', () {
      expect(leaderCombatBonusMultiplier('napoleon'), 1.25);
    });

    test('frederick returns 1.15 (SPEC +15% melee)', () {
      expect(leaderCombatBonusMultiplier('frederick'), 1.15);
    });

    test('reserve returns 1.0', () {
      expect(leaderCombatBonusMultiplier('reserve'), 1.0);
    });

    test('unknown key returns 1.0', () {
      expect(leaderCombatBonusMultiplier('unknown_leader'), 1.0);
    });

    test('variant id containing napoleon returns 1.25', () {
      expect(leaderCombatBonusMultiplier('france_napoleon_leader'), 1.25);
    });

    test('variant id containing frederick returns 1.15', () {
      expect(leaderCombatBonusMultiplier('prussia_frederick_leader'), 1.15);
    });
  });
}
