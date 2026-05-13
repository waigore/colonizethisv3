import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/diplomacy/overture_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_resolver_phase_test_support.dart';

void main() {
  group('processOverturePayments', () {
    test('deducts treasury when AI accepts establishOverture to minor', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final membership = DiplomacyFactionMembership.from(game);
      final result = processOverturePayments(
        game,
        {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.tradeConsulate,
            ),
          ],
        },
        1,
        factionMembership: membership,
      );
      expect(result.pendingOvertures, isNull);
      expect(result.game.playerById('gp1')!.treasury, lessThan(2000));
    });

    test('ignores diplomatic buckets keyed to absent player ids', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final membership = DiplomacyFactionMembership.from(game);
      final beforeTreasury = game.playerById('gp1')!.treasury;
      final result = processOverturePayments(
        game,
        {
          'not-a-player': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.tradeConsulate,
            ),
          ],
          'gp1': const [],
        },
        1,
        factionMembership: membership,
      );
      expect(result.game.playerById('gp1')!.treasury, beforeTreasury);
    });
  });
}
