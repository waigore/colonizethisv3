// Last-turn spatial playback controller for [GameMapArea] (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'dart:async';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_turn_feed_labels.dart';
import 'game_map_area_view.dart';
import 'last_turn_playback.dart';
import 'map_location_resolver.dart';

/// Schedules and runs last-turn spatial pulses after news / victory gates.
mixin GameMapAreaLastTurnPlayback
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels,
        GameMapAreaView {
  /// Beats ready after the start gate; cleared when playback ends.
  List<LastTurnPlaybackBeat> lastTurnPlaybackBeats = const [];

  int lastTurnPlaybackIndex = 0;
  Timer? lastTurnPlaybackTimer;
  String? lastTurnPulseTileKey;
  String? lastTurnPlaybackCaption;
  bool lastTurnPlaybackActive = false;

  /// True after a turn resolution until playback starts or is abandoned.
  bool lastTurnPlaybackPending = false;

  /// When true, wait for [TurnNewsDialogClosedEvent] before starting.
  bool lastTurnPlaybackAwaitingNewsClose = false;

  /// When true, wait for [VictoryOverlayViewFinalStateEvent] before starting.
  bool lastTurnPlaybackAwaitingVictoryDismiss = false;

  bool get isLastTurnPlaybackRunning => lastTurnPlaybackActive;

  void disposeLastTurnPlayback() {
    lastTurnPlaybackTimer?.cancel();
    lastTurnPlaybackTimer = null;
  }

  void onTurnNewsDialogClosedEvent(ct_models.TurnNewsDialogClosedEvent event) {
    if (!mounted || !lastTurnPlaybackPending) {
      return;
    }
    if (!lastTurnPlaybackAwaitingNewsClose) {
      return;
    }
    lastTurnPlaybackAwaitingNewsClose = false;
    startLastTurnPlaybackIfPending();
  }

  void onVictoryOverlayViewFinalStateEvent(
    ct_models.VictoryOverlayViewFinalStateEvent event,
  ) {
    if (!mounted || !lastTurnPlaybackPending) {
      return;
    }
    if (!lastTurnPlaybackAwaitingVictoryDismiss) {
      return;
    }
    lastTurnPlaybackAwaitingVictoryDismiss = false;
    startLastTurnPlaybackIfPending();
  }

  /// Called from [GameMapAreaEvents.onTurnResolutionCompleteEvent] after feed flush.
  void armLastTurnPlaybackAfterResolution({
    required bool newsDialogWillShow,
    required bool victorySet,
  }) {
    stopLastTurnPlayback(clearPending: true);
    lastTurnPlaybackPending = true;
    lastTurnPlaybackAwaitingNewsClose = newsDialogWillShow && !victorySet;
    lastTurnPlaybackAwaitingVictoryDismiss = victorySet;
    if (!lastTurnPlaybackAwaitingNewsClose &&
        !lastTurnPlaybackAwaitingVictoryDismiss) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        startLastTurnPlaybackIfPending();
      });
    }
  }

  void startLastTurnPlaybackIfPending() {
    if (!mounted || !lastTurnPlaybackPending) {
      return;
    }
    if (lastTurnPlaybackAwaitingNewsClose ||
        lastTurnPlaybackAwaitingVictoryDismiss) {
      return;
    }
    lastTurnPlaybackPending = false;
    final beats = buildLastTurnPlaybackBeats(
      events: resolvedPlayerTurnEvents,
      resolveAnchor: resolveLastTurnAnchor,
      captionFor: captionForLastTurnEvent,
    );
    if (beats.isEmpty) {
      return;
    }
    lastTurnPlaybackBeats = beats;
    lastTurnPlaybackIndex = 0;
    lastTurnPlaybackActive = true;
    showLastTurnPlaybackBeat(0);
  }

  ({String tileKey, String regionId})? resolveLastTurnAnchor(
    ct_models.GameToUIEvent event,
  ) {
    return switch (event) {
      ct_models.AppCombatResultEvent(:final provinceId) ||
      ct_models.AppProvinceCapturedEvent(:final provinceId) ||
      ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
        _anchorForProvince(provinceId),
      ct_models.AppNavalCombatResultEvent(:final seaZoneId) ||
      ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
        _anchorForSeaZone(seaZoneId),
      ct_models.AppWorkOrderCompletedEvent(
        :final targetTileKey,
        :final provinceId,
      ) =>
        _anchorForWorkOrder(targetTileKey, provinceId),
      _ => null,
    };
  }

  ({String tileKey, String regionId})? _anchorForProvince(String provinceId) {
    final province = provinceByPrefixedId(provinceId);
    if (province == null) {
      return null;
    }
    final tileKey = tileKeyForProvinceLocation(widget.game, province);
    if (tileKey == null) {
      return null;
    }
    return (tileKey: tileKey, regionId: province.regionId);
  }

  ({String tileKey, String regionId})? _anchorForSeaZone(String seaZoneId) {
    final tileKey = tileKeyForSeaZoneEvent(seaZoneId);
    if (tileKey == null) {
      return null;
    }
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) {
      return null;
    }
    return (tileKey: tileKey, regionId: regionId);
  }

  ({String tileKey, String regionId})? _anchorForWorkOrder(
    String targetTileKey,
    String provinceId,
  ) {
    if (targetTileKey.isNotEmpty) {
      final regionId = ct_models.Unit.regionIdFromTileKey(targetTileKey);
      if (regionId != null) {
        return (tileKey: targetTileKey, regionId: regionId);
      }
    }
    return _anchorForProvince(provinceId);
  }

  String captionForLastTurnEvent(ct_models.GameToUIEvent event) {
    return switch (event) {
      ct_models.AppCombatResultEvent(
        :final provinceId,
        :final winnerId,
        :final attackerId,
        :final defenderId,
      ) =>
        '${provinceLabel(provinceId)} battle resolved! '
            '${factionLabel(winnerId)} defeated '
            '${factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
      ct_models.AppProvinceCapturedEvent(
        :final provinceId,
        :final newOwnerId,
      ) =>
        '${provinceLabel(provinceId)} captured! '
            '${factionLabel(newOwnerId)} now controls it!',
      ct_models.AppNavalCombatResultEvent(
        :final seaZoneId,
        :final outcomeName,
      ) =>
        '${seaZoneLabel(seaZoneId)} naval battle resolved! '
            'Outcome: $outcomeName!',
      ct_models.AppWorkOrderCompletedEvent(
        :final provinceId,
        :final workTarget,
      ) =>
        '${provinceLabel(provinceId)} work completed! '
            '${workTargetLabel(workTarget)} finished!',
      ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
        '${provinceLabel(provinceId)} discovered!',
      ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
        '${seaZoneLabel(seaZoneId)} discovered!',
      _ => '',
    };
  }

  void showLastTurnPlaybackBeat(int index) {
    lastTurnPlaybackTimer?.cancel();
    if (!mounted || index < 0 || index >= lastTurnPlaybackBeats.length) {
      stopLastTurnPlayback();
      return;
    }
    final beat = lastTurnPlaybackBeats[index];
    lastTurnPlaybackIndex = index;
    setState(() {
      lastTurnPulseTileKey = beat.tileKey;
      lastTurnPlaybackCaption = beat.caption;
    });
    locateTile(beat.tileKey, beat.regionId);
    lastTurnPlaybackTimer = Timer(
      const Duration(milliseconds: kLastTurnBeatDwellMs),
      () {
        if (!mounted || !lastTurnPlaybackActive) {
          return;
        }
        final next = index + 1;
        if (next >= lastTurnPlaybackBeats.length) {
          stopLastTurnPlayback();
          return;
        }
        showLastTurnPlaybackBeat(next);
      },
    );
  }

  void skipLastTurnPlayback() {
    if (!lastTurnPlaybackActive && !lastTurnPlaybackPending) {
      return;
    }
    stopLastTurnPlayback(clearPending: true);
  }

  void stopLastTurnPlayback({bool clearPending = false}) {
    lastTurnPlaybackTimer?.cancel();
    lastTurnPlaybackTimer = null;
    final wasActive = lastTurnPlaybackActive;
    lastTurnPlaybackActive = false;
    lastTurnPlaybackBeats = const [];
    lastTurnPlaybackIndex = 0;
    if (clearPending) {
      lastTurnPlaybackPending = false;
      lastTurnPlaybackAwaitingNewsClose = false;
      lastTurnPlaybackAwaitingVictoryDismiss = false;
    }
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
