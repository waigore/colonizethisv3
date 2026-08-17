import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../widgets/ct_event_feed_entries_list.dart';
import 'ct_event_feed_text.dart';
import 'ct_turn_feed_entry_context.dart';
import 'ct_turn_feed_entry_factory.dart';

/// Maps economy, market, orders, research, and work events to feed rows.
CtEventFeedEntry? mapCtTurnFeedEconomyOrdersResearchEvent({
  required ct_models.GameToUIEvent event,
  required CtTurnFeedEntryContext context,
}) {
  return switch (event) {
    ct_models.AppResearchCompleteEvent(:final techId) =>
      context.isCatalogTech(techId)
          ? ctTurnFeedEntry(
              text: context.researchCompleteLine(techId),
              linkAffordance: true,
              onTap: context.navigateToTechnologyScreen,
            )
          : ctTurnFeedEntry(text: context.researchCompleteLine(techId)),
    ct_models.AppOrderRejectedEvent(
      :final reasonCode,
      :final orderKind,
    ) =>
      _orderRejectedFeedEntry(
        context: context,
        orderKind: orderKind,
        text: CtEventFeedText.orderRejectedLine(reasonCode),
      ),
    ct_models.AppWorkOrderCompletedEvent(
      :final workTarget,
      :final targetTileKey,
      :final provinceId,
      :final unitId,
    ) =>
      _workOrderFeedEntry(
        context: context,
        unitId: unitId,
        targetTileKey: targetTileKey,
        text: CtEventFeedText.workOrderCompletedLine(
          provinceLabel: context.provinceLabel(provinceId),
          workTargetLabel: context.workTargetLabel(workTarget),
        ),
      ),
    ct_models.AppOverseasProfitCreditedEvent(
      :final totalTreasuryCredit,
      :final creditCount,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.overseasProfitCreditedLine(
          totalTreasuryCredit,
          creditCount,
        ),
        linkAffordance: context.overseasProfitCreditedTap != null,
        onTap: context.overseasProfitCreditedTap,
      ),
    ct_models.AppMarketTurnSummaryEvent(
      :final totalSpent,
      :final totalReceived,
      :final carryForwardOrderCount,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.marketTurnSummaryLine(
          totalSpent: totalSpent,
          totalReceived: totalReceived,
          carryForwardOrderCount: carryForwardOrderCount,
        ),
        linkAffordance: context.overseasProfitCreditedTap != null,
        onTap: context.overseasProfitCreditedTap,
      ),
    ct_models.AppEconomyTurnSummaryEvent(
      :final treasuryDelta,
      :final stockpileDeltas,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.economyTurnSummaryLine(
          treasuryDelta: treasuryDelta,
          stockpileDeltas: stockpileDeltas,
          commodityDisplayName: context.commodityDisplayName,
        ),
        linkAffordance: context.economyTurnSummaryTap != null,
        onTap: context.economyTurnSummaryTap,
      ),
    _ => null,
  };
}

CtEventFeedEntry _workOrderFeedEntry({
  required CtTurnFeedEntryContext context,
  required String unitId,
  required String targetTileKey,
  required String text,
}) {
  final onTap = context.workOrderCompletedTap(
    unitId: unitId,
    targetTileKey: targetTileKey,
  );
  return ctTurnFeedEntry(
    text: text,
    linkAffordance: onTap != null,
    onTap: onTap,
  );
}

CtEventFeedEntry _orderRejectedFeedEntry({
  required CtTurnFeedEntryContext context,
  required ct_models.OrderKind orderKind,
  required String text,
}) {
  final onTap = context.orderRejectedTapForKind(orderKind);
  return ctTurnFeedEntry(
    text: text,
    linkAffordance: onTap != null,
    onTap: onTap,
  );
}
