/// Same-turn formatted feed rows for `OVL70001` (Refs #4715 Slice 3).
library;

import '../../widgets/shell/player_turn_event_feed.dart';

/// Caches formatted [PlayerTurnEventFeedEntry] rows for the last committed turn
/// batch so hidden feed rebuilds skip `buildCtTurnFeedEntries` formatting.
class PlayerTurnEventFeedSessionCache {
  PlayerTurnEventFeedSessionCache._();

  static String? _gameId;
  static int? _committedTurnNumber;
  static List<PlayerTurnEventFeedEntry>? _formattedEntries;
  static int? _badgeCount;

  static List<PlayerTurnEventFeedEntry>? readFormatted({
    required String gameId,
    required int committedTurnNumber,
  }) {
    if (_gameId == gameId &&
        _committedTurnNumber == committedTurnNumber &&
        _formattedEntries != null) {
      return _formattedEntries;
    }
    return null;
  }

  static int readBadgeCount({
    required String gameId,
    required int committedTurnNumber,
    required int fallbackCount,
  }) {
    if (_gameId == gameId &&
        _committedTurnNumber == committedTurnNumber &&
        _badgeCount != null) {
      return _badgeCount!;
    }
    return fallbackCount;
  }

  static void storeFormatted({
    required String gameId,
    required int committedTurnNumber,
    required List<PlayerTurnEventFeedEntry> entries,
    required int badgeCount,
  }) {
    _gameId = gameId;
    _committedTurnNumber = committedTurnNumber;
    _formattedEntries = List<PlayerTurnEventFeedEntry>.unmodifiable(entries);
    _badgeCount = badgeCount;
  }

  static void invalidateForTurnCommit({
    required String gameId,
    required int committedTurnNumber,
    required int badgeCount,
  }) {
    _gameId = gameId;
    _committedTurnNumber = committedTurnNumber;
    _badgeCount = badgeCount;
    _formattedEntries = null;
  }

  static void clear() {
    _gameId = null;
    _committedTurnNumber = null;
    _formattedEntries = null;
    _badgeCount = null;
  }
}
