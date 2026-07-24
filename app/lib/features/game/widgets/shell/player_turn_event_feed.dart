import 'package:flutter/material.dart';

export 'player_turn_event_feed_card.dart' show PlayerTurnEventFeedCard;
export 'player_turn_event_feed_toggle.dart'
    show PlayerTurnEventsFeedToggleButton;
export 'player_turn_event_feed_toggle_glyph.dart'
    show NewspaperGlyph, PlayerTurnEventFeedUnreadBadge;

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}
