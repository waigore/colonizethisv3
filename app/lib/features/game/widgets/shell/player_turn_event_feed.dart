import 'package:flutter/material.dart';

export 'player_turn_event_feed_card.dart' show PlayerTurnEventFeedCard;
export 'player_turn_event_feed_toggle.dart'
    show PlayerTurnEventsFeedToggleButton;
export 'player_turn_event_feed_toggle_glyph.dart'
    show NewspaperGlyph, PlayerTurnEventFeedUnreadBadge;

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({
    required this.text,
    this.onTap,
    this.linkAffordance = false,
  });

  final String text;
  final VoidCallback? onTap;

  /// When true, the row shows a trailing chevron so screen-navigation taps
  /// read as links (distinct from map-focus tappable rows).
  final bool linkAffordance;
}
