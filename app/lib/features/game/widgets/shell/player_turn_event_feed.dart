import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../screens/game/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth, kPlayerTurnFeedToggleButtonKey;

part 'player_turn_event_feed_toggle.dart';
part 'player_turn_event_feed_card.dart';

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}
