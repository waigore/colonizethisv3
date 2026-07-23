// Player turn event feed shared types. SPEC/ui/player-turn-event-feed.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:flutter/material.dart';

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}
