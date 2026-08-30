import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../widgets/ct_event_feed_entries_list.dart';
import 'ct_event_feed_text.dart';
import 'ct_turn_feed_combat_discovery_mapper.dart';
import 'ct_turn_feed_diplomacy_spy_mapper.dart';
import 'ct_turn_feed_economy_orders_research_mapper.dart';
import 'ct_turn_feed_entry_context.dart';
import 'ct_turn_feed_entry_factory.dart';

export 'ct_turn_feed_entry_context.dart';

/// Maps resolved player turn events into scrollable feed rows.
List<CtEventFeedEntry> buildCtTurnFeedEntries({
  required List<ct_models.GameToUIEvent> events,
  required CtTurnFeedEntryContext context,
}) {
  return events
      .map((ct_models.GameToUIEvent event) => _mapCtTurnFeedEvent(
            event: event,
            context: context,
          ))
      .toList(growable: false);
}

CtEventFeedEntry _mapCtTurnFeedEvent({
  required ct_models.GameToUIEvent event,
  required CtTurnFeedEntryContext context,
}) {
  return mapCtTurnFeedCombatDiscoveryEvent(event: event, context: context) ??
      mapCtTurnFeedDiplomacySpyEvent(event: event, context: context) ??
      mapCtTurnFeedEconomyOrdersResearchEvent(event: event, context: context) ??
      ctTurnFeedEntry(text: CtEventFeedText.eventResolvedFallback);
}
