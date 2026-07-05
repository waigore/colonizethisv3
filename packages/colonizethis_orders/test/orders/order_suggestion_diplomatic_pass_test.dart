import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_diplomatic_pass.dart';

void main() {
  group('order_suggestion_diplomatic_pass', () {
    test('isIndependentDiplomaticCandidate flags economic and boycott types', () {
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.grantAid),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.setSubsidy),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.boycott),
        isTrue,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.alliance),
        isFalse,
      );
      expect(
        isIndependentDiplomaticCandidate(DiplomaticOrderType.declareWar),
        isFalse,
      );
    });

    test('playerOverturesByTargetIdForPlayer keeps first row per target', () {
      final game = TestFixtures.minimalGame(
        overtureStates: [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.tradeConsulate,
            sinceTurn: 0,
          ),
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 1,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );

      final map = playerOverturesByTargetIdForPlayer(game, 'gp1');

      expect(map.keys, ['minor1']);
      expect(map['minor1']!.stage, OvertureStage.tradeConsulate);
    });
  });
}
