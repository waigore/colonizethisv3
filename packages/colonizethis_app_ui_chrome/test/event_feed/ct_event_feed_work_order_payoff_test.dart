import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_work_order_payoff.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('workOrderCompletedLine payoff clauses (Refs #4778)', () {
    test('Explore is fully visible, not job finished', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Explore',
        workTarget: CtEventFeedText.exploreWorkTarget,
      );
      expect(
        line,
        'Lisbon work completed! This province is now fully visible.',
      );
      expect(line, isNot(contains('Explore finished!')));
      expect(line, isNot(contains('Prospect found')));
    });

    test('Build improvement names display goods, not commodity id', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build improvement',
        workTarget: EventFeedWorkTargets.buildImprovement,
        payoffKind: WorkOrderPayoffKind.yieldRaise,
        payoffCommodityDisplayName: 'Grain',
      );
      expect(line, contains('Grain'));
      expect(line, isNot(contains('grain')));
      expect(line, isNot(contains('warehouse')));
      expect(line, isNot(contains('finished!')));
    });

    test('Build improvement road limit does not claim warehouse fill', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build improvement',
        workTarget: EventFeedWorkTargets.buildImprovement,
        payoffKind: WorkOrderPayoffKind.roadLimit,
        payoffCommodityDisplayName: 'Grain',
      );
      expect(line, contains('The road still limits what Grain arrives.'));
      expect(line, isNot(contains('warehouse')));
    });

    test('Build improvement town limit names goods without warehouse fill', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build improvement',
        workTarget: EventFeedWorkTargets.buildImprovement,
        payoffKind: WorkOrderPayoffKind.townLimit,
        payoffCommodityDisplayName: 'Grain',
      );
      expect(
        line,
        contains('Town development still limits what Grain arrives.'),
      );
      expect(line, isNot(contains('warehouse')));
      expect(line, isNot(contains('finished!')));
    });

    test('Build improvement unbound does not name a job finished', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build improvement',
        workTarget: EventFeedWorkTargets.buildImprovement,
        payoffKind: WorkOrderPayoffKind.unbound,
      );
      expect(line, contains('This tile is still unbound.'));
      expect(line, isNot(contains('finished!')));
    });

    test('Upgrade town pause gist uses post-work level', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Upgrade town',
        workTarget: EventFeedWorkTargets.upgradeTown,
        payoffKind: WorkOrderPayoffKind.workshopsPause,
        payoffLevel: 2,
      );
      expect(line, contains('Town workshops pause until level 4.'));
      expect(line, isNot(contains('finished!')));
    });

    test('Build port uses port-present clause', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build port',
        workTarget: EventFeedWorkTargets.buildPort,
        payoffKind: WorkOrderPayoffKind.portPresent,
      );
      expect(line, 'Lisbon work completed! This coast now has a port.');
    });

    test('Build fort names wood posture without soak percents', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Build fort',
        workTarget: EventFeedWorkTargets.buildFort,
        payoffKind: WorkOrderPayoffKind.fortWood,
        payoffLevel: 1,
      );
      expect(line, contains('Siege posture is now wood.'));
      expect(line, isNot(contains('%')));
      expect(line, isNot(contains('soak')));
    });

    test('Purchase land tradeable does not claim ownership change', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Purchase land',
        workTarget: EventFeedWorkTargets.purchaseLand,
        payoffKind: WorkOrderPayoffKind.purchaseTradeable,
        payoffCommodityDisplayName: 'Grain',
      );
      expect(line, contains('First bid and gold'));
      expect(line, contains('The land stays the court’s.'));
      expect(line, isNot(contains('owner')));
      expect(line, isNot(contains('finished!')));
    });

    test('Prospect still names mineral display name', () {
      final line = CtEventFeedText.workOrderCompletedLine(
        provinceLabel: 'Lisbon',
        workTargetLabel: 'Prospect',
        workTarget: CtEventFeedText.prospectWorkTarget,
        prospectFoundDisplayName: 'Iron',
      );
      expect(line, 'Lisbon work completed! Prospect found Iron');
    });
  });
}
