import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../widgets/ct_event_feed_entries_list.dart';
import 'ct_event_feed_text.dart';
import 'ct_turn_feed_entry_context.dart';
import 'ct_turn_feed_entry_factory.dart';

/// Maps combat, medal, capture, naval, and discovery events to feed rows.
CtEventFeedEntry? mapCtTurnFeedCombatDiscoveryEvent({
  required ct_models.GameToUIEvent event,
  required CtTurnFeedEntryContext context,
}) {
  return switch (event) {
    ct_models.AppCombatResultEvent(
      :final provinceId,
      :final attackerId,
      :final defenderId,
      :final outcomeName,
      :final attackerCasualtyCount,
      :final defenderCasualtyCount,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.combatResolvedLine(
          provinceLabel: context.provinceLabel(provinceId),
          outcomeLabel: CtEventFeedText.landBattleOutcomeLabel(outcomeName),
          attackerLabel: context.factionLabel(attackerId),
          defenderLabel: context.factionLabel(defenderId),
          attackerLosses: attackerCasualtyCount,
          defenderLosses: defenderCasualtyCount,
        ),
        onTap: context.provinceOverlayTapForProvince(provinceId),
      ),
    ct_models.AppGeneralMedalGainedEvent(
      :final provinceId,
      :final newMedals,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.generalMedalGainedAtProvinceLine(
          context.provinceLabel(provinceId),
          newMedals,
        ),
        onTap: context.provinceOverlayTapForProvince(provinceId),
      ),
    ct_models.AppProvinceCapturedEvent(
      :final provinceId,
      :final newOwnerId,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.provinceCapturedLine(
          provinceLabel: context.provinceLabel(provinceId),
          ownerLabel: context.factionLabel(newOwnerId),
        ),
        onTap: context.provinceOverlayTapForProvince(provinceId),
      ),
    ct_models.AppNavalCombatResultEvent(
      :final seaZoneId,
      :final outcomeName,
    ) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.navalCombatResolvedLine(
          seaZoneLabel: context.seaZoneLabel(seaZoneId),
          outcomeName: outcomeName,
        ),
        onTap: context.navalCombatTapForSeaZone(seaZoneId),
      ),
    ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.provinceDiscoveredLine(
          context.provinceLabel(provinceId),
        ),
        onTap: () => context.locateProvinceById(provinceId),
      ),
    ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
      ctTurnFeedEntry(
        text: CtEventFeedText.seaZoneDiscoveredLine(
          context.seaZoneLabel(seaZoneId),
        ),
        onTap: () => context.locateSeaZoneTile(seaZoneId),
      ),
    _ => null,
  };
}
