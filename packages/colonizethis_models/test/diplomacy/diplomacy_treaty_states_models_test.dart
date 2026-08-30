import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Concern-split densify from diplomacy_treaty_order_event_models_test (Refs #4571).

void main() {
  group('SubsidyState (percent model, Refs #3753 R3)', () {
    const subsidy = SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10);

    test('toJson/fromJson round-trips', () {
      expect(SubsidyState.fromJson(subsidy.toJson()), subsidy);
      expect(subsidy.toJson()['percent'], 10);
    });

    test('copyWith and equality', () {
      final updated = subsidy.copyWith(percent: 15);
      expect(updated.percent, 15);
      expect(subsidy, isNot(updated));
      expect(
        subsidy,
        const SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10),
      );
    });

    test('legacy £/turn save decodes to percent 0 (dropped by migration)', () {
      final legacy = SubsidyState.fromJson(const {
        'payerId': 'gp1',
        'targetId': 'mn1',
        'amountPerTurn': 500,
      });
      expect(legacy.percent, 0);
      expect(isValidSubsidyPercent(legacy.percent), isFalse);
    });

    test('isValidSubsidyPercent enforces 5-20 step 5', () {
      for (final percent in [5, 10, 20]) {
        expect(isValidSubsidyPercent(percent), isTrue, reason: '$percent');
      }
      for (final percent in [0, 7, 25]) {
        expect(isValidSubsidyPercent(percent), isFalse, reason: '$percent');
      }
    });
  });
  group('ColonyState and BoycottState', () {
    test('ColonyState toJson/fromJson and defaults', () {
      const colony = ColonyState(
        tribeId: 'tribe1',
        colonyOfGpId: 'gp1',
        sinceTurn: 4,
      );
      expect(ColonyState.fromJson(colony.toJson()), colony);
      expect(
        ColonyState.fromJson(const {
          'tribeId': 'tribe1',
          'colonyOfGpId': 'gp1',
        }).sinceTurn,
        0,
      );
      expect(colony.copyWith(colonyOfGpId: 'gp2').colonyOfGpId, 'gp2');
    });

    test('BoycottState toJson/fromJson and defaults', () {
      const boycott = BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 5);
      expect(BoycottState.fromJson(boycott.toJson()), boycott);
      expect(
        BoycottState.fromJson(const {
          'gpId': 'gp1',
          'targetGpId': 'gp2',
        }).sinceTurn,
        0,
      );
      expect(boycott.copyWith(targetGpId: 'gp3').targetGpId, 'gp3');
    });
  });
}
