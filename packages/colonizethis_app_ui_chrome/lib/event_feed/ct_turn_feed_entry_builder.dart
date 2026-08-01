import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/foundation.dart';

import '../widgets/ct_event_feed_entries_list.dart';
import 'ct_event_feed_text.dart';

/// App-supplied label and navigation hooks for [buildCtTurnFeedEntries].
class CtTurnFeedEntryContext {
  const CtTurnFeedEntryContext({
    required this.mapPlayerId,
    required this.factionLabel,
    required this.provinceLabel,
    required this.seaZoneLabel,
    required this.diplomacyOutcomeLine,
    required this.isCatalogTech,
    required this.researchCompleteLine,
    required this.navigateToTechnologyScreen,
    required this.workTargetLabel,
    required this.overtureStageLabel,
    required this.locateProvinceById,
    required this.locateSeaZoneTile,
    required this.counterpartFactionId,
    required this.overtureCounterpartFactionId,
    required this.spyCounterpartFactionId,
    required this.diplomacyDetailTapForFaction,
    required this.provinceOverlayTapForProvince,
    required this.navalCombatTapForSeaZone,
    required this.workOrderCompletedTap,
    required this.overseasProfitCreditedTap,
    required this.orderRejectedTapForKind,
  });

  final String mapPlayerId;
  final String Function(String id) factionLabel;
  final String Function(String fullProvinceId) provinceLabel;
  final String Function(String seaZoneId) seaZoneLabel;
  final String Function({
    required String actorId,
    required String targetId,
    required String changeType,
  }) diplomacyOutcomeLine;
  final bool Function(String techId) isCatalogTech;
  final String Function(String techId) researchCompleteLine;
  final VoidCallback navigateToTechnologyScreen;
  final String Function(String workTarget) workTargetLabel;
  final String Function(String stage) overtureStageLabel;
  final void Function(String provinceId) locateProvinceById;
  final void Function(String seaZoneId) locateSeaZoneTile;
  final String? Function({
    required String actorId,
    required String targetId,
  }) counterpartFactionId;
  final String? Function({
    required String offererGpId,
    required String targetFactionId,
  }) overtureCounterpartFactionId;
  final String? Function({
    required String spyOwnerId,
    required String territoryOwnerId,
  }) spyCounterpartFactionId;
  final VoidCallback? Function(String factionId) diplomacyDetailTapForFaction;
  final VoidCallback? Function(String provinceId) provinceOverlayTapForProvince;
  final VoidCallback? Function(String seaZoneId) navalCombatTapForSeaZone;
  final VoidCallback? Function({
    required String unitId,
    required String targetTileKey,
  }) workOrderCompletedTap;
  final VoidCallback? overseasProfitCreditedTap;
  final VoidCallback? Function(ct_models.OrderKind orderKind)
      orderRejectedTapForKind;
}

/// Maps resolved player turn events into scrollable feed rows.
List<CtEventFeedEntry> buildCtTurnFeedEntries({
  required List<ct_models.GameToUIEvent> events,
  required CtTurnFeedEntryContext context,
}) {
  return events
      .map((ct_models.GameToUIEvent event) {
        return switch (event) {
          ct_models.AppCombatResultEvent(
            :final provinceId,
            :final winnerId,
            :final attackerId,
            :final defenderId,
          ) =>
            _feedEntry(
              context: context,
              text:
                  '${context.provinceLabel(provinceId)} battle resolved! ${context.factionLabel(winnerId)} defeated ${context.factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
              onTap: context.provinceOverlayTapForProvince(provinceId),
            ),
          ct_models.AppProvinceCapturedEvent(
            :final provinceId,
            :final newOwnerId,
          ) =>
            _feedEntry(
              context: context,
              text:
                  '${context.provinceLabel(provinceId)} captured! ${context.factionLabel(newOwnerId)} now controls it!',
              onTap: context.provinceOverlayTapForProvince(provinceId),
            ),
          ct_models.AppNavalCombatResultEvent(
            :final seaZoneId,
            :final outcomeName,
          ) =>
            _feedEntry(
              context: context,
              text:
                  '${context.seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
              onTap: context.navalCombatTapForSeaZone(seaZoneId),
            ),
          ct_models.AppDiplomacyChangeEvent(
            :final actorId,
            :final targetId,
            :final changeType,
          ) =>
            _diplomacyFeedEntry(
              context: context,
              factionId: context.counterpartFactionId(
                actorId: actorId,
                targetId: targetId,
              ),
              text: context.diplomacyOutcomeLine(
                actorId: actorId,
                targetId: targetId,
                changeType: changeType,
              ),
            ),
          ct_models.AppResearchCompleteEvent(:final techId) =>
            context.isCatalogTech(techId)
                ? CtEventFeedEntry(
                    text: context.researchCompleteLine(techId),
                    linkAffordance: true,
                    onTap: context.navigateToTechnologyScreen,
                  )
                : CtEventFeedEntry(text: context.researchCompleteLine(techId)),
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
              text:
                  '${context.provinceLabel(provinceId)} work completed! ${context.workTargetLabel(workTarget)} finished!',
            ),
          ct_models.AppOverseasProfitCreditedEvent(
            :final totalTreasuryCredit,
            :final creditCount,
          ) =>
            CtEventFeedEntry(
              text: CtEventFeedText.overseasProfitCreditedLine(
                totalTreasuryCredit,
                creditCount,
              ),
              linkAffordance: context.overseasProfitCreditedTap != null,
              onTap: context.overseasProfitCreditedTap,
            ),
          ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
            _feedEntry(
              context: context,
              text: '${context.provinceLabel(provinceId)} discovered!',
              onTap: () => context.locateProvinceById(provinceId),
            ),
          ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
            _feedEntry(
              context: context,
              text: '${context.seaZoneLabel(seaZoneId)} discovered!',
              onTap: () => context.locateSeaZoneTile(seaZoneId),
            ),
          ct_models.AppOvertureAdvancedEvent(
            :final offererGpId,
            :final targetFactionId,
            :final newStage,
          ) =>
            _diplomacyFeedEntry(
              context: context,
              factionId: context.overtureCounterpartFactionId(
                offererGpId: offererGpId,
                targetFactionId: targetFactionId,
              ),
              text:
                  'Overture advanced! ${context.factionLabel(offererGpId)} with ${context.factionLabel(targetFactionId)}: ${context.overtureStageLabel(newStage)}!',
            ),
          ct_models.AppSpyCaughtEvent(
            :final provinceId,
            :final spyOwnerId,
            :final territoryOwnerId,
          ) =>
            _diplomacyFeedEntry(
              context: context,
              factionId: context.spyCounterpartFactionId(
                spyOwnerId: spyOwnerId,
                territoryOwnerId: territoryOwnerId,
              ),
              text: context.mapPlayerId == territoryOwnerId
                  ? '${context.provinceLabel(provinceId)} — enemy spy from ${context.factionLabel(spyOwnerId)} caught and eliminated!'
                  : 'Spy caught in ${context.provinceLabel(provinceId)}! ${context.factionLabel(territoryOwnerId)} eliminated your agent!',
            ),
          ct_models.AppSpyDefectedEvent(
            :final provinceId,
            :final previousOwnerId,
            :final newOwnerId,
          ) =>
            _diplomacyFeedEntry(
              context: context,
              factionId: context.mapPlayerId == newOwnerId
                  ? previousOwnerId
                  : newOwnerId,
              text: context.mapPlayerId == newOwnerId
                  ? '${context.provinceLabel(provinceId)} — enemy spy from ${context.factionLabel(previousOwnerId)} defected to your side!'
                  : 'Spy defected in ${context.provinceLabel(provinceId)}! Agent joined ${context.factionLabel(newOwnerId)}!',
            ),
          _ => const CtEventFeedEntry(text: 'Event resolved!'),
        };
      })
      .toList(growable: false);
}

CtEventFeedEntry _feedEntry({
  required CtTurnFeedEntryContext context,
  required String text,
  VoidCallback? onTap,
}) {
  return CtEventFeedEntry(
    text: text,
    onTap: onTap,
  );
}

CtEventFeedEntry _diplomacyFeedEntry({
  required CtTurnFeedEntryContext context,
  required String? factionId,
  required String text,
}) {
  final VoidCallback? onTap = factionId == null
      ? null
      : context.diplomacyDetailTapForFaction(factionId);
  return CtEventFeedEntry(
    text: text,
    linkAffordance: onTap != null,
    onTap: onTap,
  );
}

CtEventFeedEntry _workOrderFeedEntry({
  required CtTurnFeedEntryContext context,
  required String unitId,
  required String targetTileKey,
  required String text,
}) {
  final VoidCallback? onTap = context.workOrderCompletedTap(
    unitId: unitId,
    targetTileKey: targetTileKey,
  );
  return CtEventFeedEntry(
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
  final VoidCallback? onTap = context.orderRejectedTapForKind(orderKind);
  return CtEventFeedEntry(
    text: text,
    linkAffordance: onTap != null,
    onTap: onTap,
  );
}
