import 'package:flutter/foundation.dart';

import '../widgets/ct_event_feed_entries_list.dart';

/// Builds one turn-feed row with optional tap and link affordance.
CtEventFeedEntry ctTurnFeedEntry({
  required String text,
  VoidCallback? onTap,
  bool linkAffordance = false,
}) {
  return CtEventFeedEntry(
    text: text,
    onTap: onTap,
    linkAffordance: linkAffordance,
  );
}
