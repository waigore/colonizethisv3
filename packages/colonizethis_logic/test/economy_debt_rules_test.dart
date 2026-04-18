import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('maxDebtForPlayer', () {
    Player player(Map<String, bool>? techUnlocked) => Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          techUnlocked: techUnlocked,
        );

    test('returns 0 when money_lending is absent', () {
      expect(maxDebtForPlayer(player(null)), 0);
      expect(maxDebtForPlayer(player(const {})), 0);
      expect(maxDebtForPlayer(player(const {'banking': true})), 0);
    });

    test('returns 500 when money_lending is unlocked', () {
      expect(
        maxDebtForPlayer(player(const {'money_lending': true})),
        500,
      );
    });

    test('banking without money_lending does not extend debt cap', () {
      expect(
        maxDebtForPlayer(player(const {'banking': true, 'trade_fairs': true})),
        0,
      );
    });

    test('returns 1000 when money_lending and banking are unlocked', () {
      expect(
        maxDebtForPlayer(
          player(const {'money_lending': true, 'banking': true}),
        ),
        1000,
      );
    });
  });
}
