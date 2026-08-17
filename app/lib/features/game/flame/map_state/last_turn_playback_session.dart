// Last-turn playback start-gate and skip session (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'last_turn_playback.dart';

/// Which modal must close before playback may start.
enum LastTurnPlaybackStartGate {
  /// No blocking modal; start after the current frame.
  immediate,

  /// Wait for [TurnNewsDialogClosedEvent] (`DLG50001`).
  newsClose,

  /// Wait for [VictoryOverlayViewFinalStateEvent] (`OVL20001`).
  victoryDismiss,
}

/// News is omitted when victory is set; victory dismiss is the start gate.
LastTurnPlaybackStartGate lastTurnPlaybackStartGate({
  required bool newsDialogWillShow,
  required bool victorySet,
}) {
  if (victorySet) {
    return LastTurnPlaybackStartGate.victoryDismiss;
  }
  if (newsDialogWillShow) {
    return LastTurnPlaybackStartGate.newsClose;
  }
  return LastTurnPlaybackStartGate.immediate;
}

/// Pure session for arm / start-gate / skip / sequential beats.
class LastTurnPlaybackSession {
  LastTurnPlaybackStartGate gate = LastTurnPlaybackStartGate.immediate;
  bool pending = false;
  bool active = false;
  int beatIndex = 0;
  List<LastTurnPlaybackBeat> beats = const [];

  LastTurnPlaybackBeat? get currentBeat {
    if (!active || beatIndex < 0 || beatIndex >= beats.length) {
      return null;
    }
    return beats[beatIndex];
  }

  bool get blockedByStartGate =>
      pending && gate != LastTurnPlaybackStartGate.immediate;

  void arm({required bool newsDialogWillShow, required bool victorySet}) {
    stop(clearPending: true);
    pending = true;
    gate = lastTurnPlaybackStartGate(
      newsDialogWillShow: newsDialogWillShow,
      victorySet: victorySet,
    );
  }

  /// News closed. Returns true when playback may start now.
  bool onNewsClosed() {
    if (!pending || gate != LastTurnPlaybackStartGate.newsClose) {
      return false;
    }
    gate = LastTurnPlaybackStartGate.immediate;
    return true;
  }

  /// Victory overlay dismissed via View final state.
  bool onVictoryDismissed() {
    if (!pending || gate != LastTurnPlaybackStartGate.victoryDismiss) {
      return false;
    }
    gate = LastTurnPlaybackStartGate.immediate;
    return true;
  }

  /// Starts playback when the gate is open. Empty [resolvedBeats] is a no-op.
  bool tryBegin(List<LastTurnPlaybackBeat> resolvedBeats) {
    if (!pending || gate != LastTurnPlaybackStartGate.immediate) {
      return false;
    }
    pending = false;
    if (resolvedBeats.isEmpty) {
      beats = const [];
      active = false;
      beatIndex = 0;
      return false;
    }
    beats = List<LastTurnPlaybackBeat>.unmodifiable(resolvedBeats);
    beatIndex = 0;
    active = true;
    return true;
  }

  /// Advance after [kLastTurnBeatDwellMs]. Returns false when the sequence ended.
  bool advanceAfterDwell() {
    if (!active) {
      return false;
    }
    final next = beatIndex + 1;
    if (next >= beats.length) {
      stop();
      return false;
    }
    beatIndex = next;
    return true;
  }

  void skip() {
    stop(clearPending: true);
  }

  void stop({bool clearPending = false}) {
    active = false;
    beats = const [];
    beatIndex = 0;
    if (clearPending) {
      pending = false;
      gate = LastTurnPlaybackStartGate.immediate;
    }
  }
}
