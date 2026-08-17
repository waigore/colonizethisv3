// Last-turn spatial playback constants and beat builder (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../region_map/region_map_component_shared_palette.dart';

/// Max spatial beats autoplayed after a resolved turn.
const int kLastTurnPlaybackCap = 6;

/// Dwell (ms) for each camera + pulse beat before advancing.
const int kLastTurnBeatDwellMs = 1200;

/// Pulse opacity sine frequency; matches hover / valid-target family.
const double kLastTurnPulseAngularFrequency =
    RegionMapPalette.hoveredProvinceGlowAngularFrequency;

/// Last-turn pulse stroke (distinct from selection orange and locate cyan).
const Color kLastTurnPulseColor = RegionMapPalette.lastTurnPulseColor;

/// One resolvable spatial outcome for map playback.
@immutable
class LastTurnPlaybackBeat {
  const LastTurnPlaybackBeat({
    required this.tileKey,
    required this.regionId,
    required this.caption,
  });

  final String tileKey;
  final String regionId;
  final String caption;
}

/// Resolves tile/region for a spatial [GameToUIEvent], or null to omit.
typedef LastTurnAnchorResolver =
    ({String tileKey, String regionId})? Function(ct_models.GameToUIEvent event);

/// Player-facing caption for a spatial event (feed-style copy).
typedef LastTurnCaptionBuilder = String Function(ct_models.GameToUIEvent event);

/// Whether [event] is a spatial type eligible for last-turn map playback.
bool isLastTurnSpatialEvent(ct_models.GameToUIEvent event) {
  return switch (event) {
    ct_models.AppCombatResultEvent() => true,
    ct_models.AppNavalCombatResultEvent() => true,
    ct_models.AppProvinceCapturedEvent() => true,
    ct_models.AppWorkOrderCompletedEvent() => true,
    ct_models.AppPlayerProvinceDiscoveredEvent() => true,
    ct_models.AppPlayerSeaZoneDiscoveredEvent() => true,
    _ => false,
  };
}

/// Builds ordered, capped playback beats from a human-scoped event batch.
List<LastTurnPlaybackBeat> buildLastTurnPlaybackBeats({
  required List<ct_models.GameToUIEvent> events,
  required LastTurnAnchorResolver resolveAnchor,
  required LastTurnCaptionBuilder captionFor,
  int cap = kLastTurnPlaybackCap,
}) {
  final beats = <LastTurnPlaybackBeat>[];
  for (final event in events) {
    if (beats.length >= cap) {
      break;
    }
    if (!isLastTurnSpatialEvent(event)) {
      continue;
    }
    final anchor = resolveAnchor(event);
    if (anchor == null) {
      continue;
    }
    beats.add(
      LastTurnPlaybackBeat(
        tileKey: anchor.tileKey,
        regionId: anchor.regionId,
        caption: captionFor(event),
      ),
    );
  }
  return List<LastTurnPlaybackBeat>.unmodifiable(beats);
}
