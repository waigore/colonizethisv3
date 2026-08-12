import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Barrel / concern-split smoke for Refs #4068 Slice B.
void main() {
  group('diplomacy concern split barrel', () {
    test('positive: relation, order, subsidy, event construct via barrel', () {
      const relation = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
      );
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'gp2',
      );
      const subsidy = SubsidyState(
        payerId: 'gp1',
        targetId: 'mn1',
        percent: kSubsidyPercentDefault,
      );
      const event = DiplomaticEvent(
        turn: 1,
        intraTurnIndex: 0,
        type: DiplomaticEventType.declareWar,
        participants: {'gp1', 'gp2'},
      );

      expect(relation.atPeace, isTrue);
      expect(order.type, DiplomaticOrderType.declareWar);
      expect(isValidSubsidyPercent(subsidy.percent), isTrue);
      expect(event.participants, {'gp1', 'gp2'});
      expect(DebugDiplomacyActionTokens.fromKeyword('war'), DebugDiplomacyAction.war);
    });

    test('negative: invalid subsidy percent rejected; unknown debug keyword null', () {
      expect(isValidSubsidyPercent(7), isFalse);
      expect(isValidSubsidyPercent(0), isFalse);
      expect(DebugDiplomacyActionTokens.fromKeyword('not_a_token'), isNull);
    });
  });
}
