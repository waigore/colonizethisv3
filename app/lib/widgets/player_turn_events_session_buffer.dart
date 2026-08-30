// Buffers human-scoped App* events between turn resolutions for turn news
// (Refs #4532).

import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Collects qualifying [GameToUIEvent]s for one turn-resolution cycle.
class PlayerTurnEventsSessionBuffer {
  final List<GameToUIEvent> _pending = [];

  List<GameToUIEvent> get pending => List<GameToUIEvent>.unmodifiable(_pending);

  void add(GameToUIEvent event, String humanPlayerId) {
    if (!acceptHumanPlayerTurnEvent(event, humanPlayerId)) {
      return;
    }
    _pending.add(event);
  }

  List<GameToUIEvent> takeCommitted() {
    if (_pending.isEmpty) {
      return const [];
    }
    final committed = List<GameToUIEvent>.from(_pending);
    _pending.clear();
    return committed;
  }

  void clear() {
    _pending.clear();
  }
}
