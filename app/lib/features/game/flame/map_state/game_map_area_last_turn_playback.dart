// Last-turn spatial playback controller for [GameMapArea] (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_map_area.dart';
import 'game_map_area_last_turn_playback_anchors.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_turn_feed_locate.dart';
import 'game_map_area_view.dart';
import 'last_turn_playback.dart';
import 'last_turn_playback_session.dart';

/// Schedules and runs last-turn spatial pulses after news / victory gates.
mixin GameMapAreaLastTurnPlayback
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels,
        GameMapAreaTurnFeedLocate,
        GameMapAreaView,
        GameMapAreaLastTurnPlaybackAnchors {
  final LastTurnPlaybackSession lastTurnPlayback = LastTurnPlaybackSession();

  Timer? lastTurnPlaybackTimer;
  String? lastTurnPulseTileKey;
  String? lastTurnPlaybackCaption;

  bool get isLastTurnPlaybackRunning => lastTurnPlayback.active;

  void disposeLastTurnPlayback() {
    lastTurnPlaybackTimer?.cancel();
    lastTurnPlaybackTimer = null;
  }

  void onTurnNewsDialogClosedEvent(ct_models.TurnNewsDialogClosedEvent event) {
    if (!mounted || !lastTurnPlayback.onNewsClosed()) {
      return;
    }
    startLastTurnPlaybackIfPending();
  }

  void onVictoryOverlayViewFinalStateEvent(
    ct_models.VictoryOverlayViewFinalStateEvent event,
  ) {
    if (!mounted || !lastTurnPlayback.onVictoryDismissed()) {
      return;
    }
    startLastTurnPlaybackIfPending();
  }

  /// Called from [GameMapAreaEvents.onTurnResolutionCompleteEvent] after feed flush.
  void armLastTurnPlaybackAfterResolution({
    required bool newsDialogWillShow,
    required bool overlayWillShow,
  }) {
    stopLastTurnPlayback(clearPending: true);
    lastTurnPlayback.arm(
      newsDialogWillShow: newsDialogWillShow,
      overlayWillShow: overlayWillShow,
    );
    if (lastTurnPlayback.blockedByStartGate) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      startLastTurnPlaybackIfPending();
    });
  }

  void startLastTurnPlaybackIfPending() {
    if (!mounted || lastTurnPlayback.blockedByStartGate) {
      return;
    }
    final beats = buildLastTurnPlaybackBeats(
      events: resolvedPlayerTurnEvents,
      resolveAnchor: resolveLastTurnAnchor,
      captionFor: captionForLastTurnEvent,
    );
    if (!lastTurnPlayback.tryBegin(beats)) {
      return;
    }
    showLastTurnPlaybackBeat();
  }

  void showLastTurnPlaybackBeat() {
    lastTurnPlaybackTimer?.cancel();
    final beat = lastTurnPlayback.currentBeat;
    if (!mounted || beat == null) {
      stopLastTurnPlayback();
      return;
    }
    setState(() {
      lastTurnPulseTileKey = beat.tileKey;
      lastTurnPlaybackCaption = beat.caption;
    });
    locateTile(beat.tileKey, beat.regionId);
    lastTurnPlaybackTimer = Timer(
      const Duration(milliseconds: kLastTurnBeatDwellMs),
      () {
        if (!mounted || !lastTurnPlayback.active) {
          return;
        }
        if (!lastTurnPlayback.advanceAfterDwell()) {
          stopLastTurnPlayback();
          return;
        }
        showLastTurnPlaybackBeat();
      },
    );
  }

  void skipLastTurnPlayback() {
    if (!lastTurnPlayback.active && !lastTurnPlayback.pending) {
      return;
    }
    stopLastTurnPlayback(clearPending: true);
  }

  void stopLastTurnPlayback({bool clearPending = false}) {
    lastTurnPlaybackTimer?.cancel();
    lastTurnPlaybackTimer = null;
    final wasActive = lastTurnPlayback.active;
    lastTurnPlayback.stop(clearPending: clearPending);
    if (!mounted) {
      return;
    }
    if (wasActive ||
        lastTurnPulseTileKey != null ||
        lastTurnPlaybackCaption != null) {
      setState(() {
        lastTurnPulseTileKey = null;
        lastTurnPlaybackCaption = null;
      });
    }
  }
}
