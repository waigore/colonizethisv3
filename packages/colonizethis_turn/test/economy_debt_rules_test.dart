import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';

/// Debt rules for labour/economy techs. SPEC/game/tech-tree-labour-economy.md.
/// Ported from logic orphan suite (Refs #4090 Slice A).
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
      expect(maxDebtForPlayer(player(const {kTechIdBanking: true})), 0);
    });

    test('returns 500 when money_lending is unlocked', () {
      expect(maxDebtForPlayer(player(const {kTechIdMoneyLending: true})), 500);
    });

    test('banking without money_lending does not extend debt cap', () {
      expect(
        maxDebtForPlayer(
          player(const {kTechIdBanking: true, kTechIdTradeFairs: true}),
        ),
        0,
      );
    });

    test('returns 1000 when money_lending and banking are unlocked', () {
      expect(
        maxDebtForPlayer(
          player(const {kTechIdMoneyLending: true, kTechIdBanking: true}),
        ),
        1000,
      );
    });
  });
}
