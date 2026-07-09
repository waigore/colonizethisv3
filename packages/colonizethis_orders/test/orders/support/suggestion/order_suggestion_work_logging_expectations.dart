// Compact suggestWorkOrders logging assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_work_logging_fixtures.dart';
import 'work_suggestion_pipeline_fixtures.dart';

/// Pins for [orderSuggestionWorkLoggingScenarios] rows.
enum OrderSuggestionWorkLoggingTarget {
  emitsSummariesForCivilianTypes,
  loggerLinesNeverEmitUnboundedFullListPayload,
}

void runOrderSuggestionWorkLoggingExpectation(
  OrderSuggestionWorkLoggingTarget target,
) {
  switch (target) {
    case OrderSuggestionWorkLoggingTarget.emitsSummariesForCivilianTypes:
      withWspLogCapture((events) {
        final fixture = osgwFourCivilianUnitsGame();
        suggestWorkOrders(
          fixture.view,
          fixture.game,
          fixture.topology,
          const Orders(),
        );

        final lines = wspSuggestWorkLines(events);
        expect(lines, isNotEmpty);
        expect(
          lines.any(
            (m) =>
                m.contains('unitId=u_explorer') &&
                m.contains('target=explore') &&
                m.contains('outcome='),
          ),
          isTrue,
        );
        expect(
          lines.any(
            (m) =>
                m.contains('unitId=u_builder') &&
                m.contains('target=build_improvement') &&
                m.contains('outcome=') &&
                m.contains('reason='),
          ),
          isTrue,
        );
        expect(
          lines.any(
            (m) =>
                m.contains('unitId=u_spy') &&
                m.contains('target=counter_spy') &&
                m.contains('outcome='),
          ),
          isTrue,
        );
        expect(
          lines.any(
            (m) =>
                m.contains('unitId=u_merchant') &&
                m.contains('target=purchase_land') &&
                m.contains('outcome=') &&
                m.contains('reason='),
          ),
          isTrue,
        );
        expect(lines.length, lessThan(80), reason: 'summary-only, no tile spam');
      });

    case OrderSuggestionWorkLoggingTarget
        .loggerLinesNeverEmitUnboundedFullListPayload:
      withWspLogCapture((events) {
        final fixture = osgwSingleExplorerGame();
        suggestWorkOrders(
          fixture.view,
          fixture.game,
          fixture.topology,
          const Orders(),
        );

        for (final e in events) {
          if (e.message.contains('suggestWorkOrders')) {
            expect(
              e.message,
              isNot(contains('full list')),
              reason: 'bounded preview only (Refs #2133)',
            );
          }
        }
      });
  }
}
