import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../widgets/ct_event_feed_entries_list.dart';
import 'ct_event_feed_text.dart';
import 'ct_turn_feed_entry_context.dart';
import 'ct_turn_feed_entry_factory.dart';

/// Maps diplomacy, overture, and spy events to feed rows.
CtEventFeedEntry? mapCtTurnFeedDiplomacySpyEvent({
  required ct_models.GameToUIEvent event,
  required CtTurnFeedEntryContext context,
}) {
  return switch (event) {
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
        text: CtEventFeedText.overtureAdvancedLine(
          offererLabel: context.factionLabel(offererGpId),
          targetLabel: context.factionLabel(targetFactionId),
          stageLabel: context.overtureStageLabel(newStage),
        ),
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
        text: CtEventFeedText.spyCaughtLine(
          mapPlayerId: context.mapPlayerId,
          provinceLabel: context.provinceLabel(provinceId),
          spyOwnerLabel: context.factionLabel(spyOwnerId),
          territoryOwnerLabel: context.factionLabel(territoryOwnerId),
          territoryOwnerId: territoryOwnerId,
        ),
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
        text: CtEventFeedText.spyDefectedLine(
          mapPlayerId: context.mapPlayerId,
          provinceLabel: context.provinceLabel(provinceId),
          previousOwnerLabel: context.factionLabel(previousOwnerId),
          newOwnerLabel: context.factionLabel(newOwnerId),
          newOwnerId: newOwnerId,
        ),
      ),
    _ => null,
  };
}

CtEventFeedEntry _diplomacyFeedEntry({
  required CtTurnFeedEntryContext context,
  required String? factionId,
  required String text,
}) {
  final onTap = factionId == null
      ? null
      : context.diplomacyDetailTapForFaction(factionId);
  return ctTurnFeedEntry(
    text: text,
    linkAffordance: onTap != null,
    onTap: onTap,
  );
}
