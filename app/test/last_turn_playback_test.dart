import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_shared_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('last_turn_playback constants', () {
    test('pin cap dwell and frequency', () {
      expect(kLastTurnPlaybackCap, 6);
      expect(kLastTurnBeatDwellMs, 1200);
      expect(kLastTurnPulseAngularFrequency, 6.283185307179586);
    });
  });

  group('buildLastTurnPlaybackBeats', () {
    ({String tileKey, String regionId})? resolve(GameToUIEvent event) {
      return switch (event) {
        AppCombatResultEvent(:final provinceId) => (
          tileKey: 'oldWorld|$provinceId|0|0',
          regionId: 'oldWorld',
        ),
        AppNavalCombatResultEvent(:final seaZoneId) => (
          tileKey: 'newWorld|$seaZoneId|1|1',
          regionId: 'newWorld',
        ),
        AppWorkOrderCompletedEvent(:final targetTileKey)
            when targetTileKey.isNotEmpty =>
          (tileKey: targetTileKey, regionId: 'oldWorld'),
        AppPlayerProvinceDiscoveredEvent(:final provinceId) => (
          tileKey: 'oldWorld|$provinceId|2|2',
          regionId: 'oldWorld',
        ),
        _ => null,
      };
    }

    String caption(GameToUIEvent event) => event.runtimeType.toString();

    test('plays spatial events in batch order and skips non-spatial', () {
      const events = <GameToUIEvent>[
        AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_a',
          turnNumber: 2,
        ),
        AppCombatResultEvent(
          provinceId: 'oldWorld|p1',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 2,
        ),
        AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'gp2',
          changeType: 'peace',
          turnNumber: 2,
        ),
        AppNavalCombatResultEvent(
          seaZoneId: 'sz1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'victory',
          turnNumber: 2,
        ),
      ];
      final beats = buildLastTurnPlaybackBeats(
        events: events,
        resolveAnchor: resolve,
        captionFor: caption,
      );
      expect(beats, hasLength(2));
      expect(beats[0].regionId, 'oldWorld');
      expect(beats[0].tileKey, 'oldWorld|oldWorld|p1|0|0');
      expect(beats[1].regionId, 'newWorld');
    });

    test('omits unresolved anchors and stays stable', () {
      const events = <GameToUIEvent>[
        AppCombatResultEvent(
          provinceId: 'oldWorld|missing',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 2,
        ),
        AppWorkOrderCompletedEvent(
          playerId: 'gp1',
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
          targetTileKey: 'oldWorld|c|3|3',
          provinceId: 'oldWorld|p2',
          turnNumber: 2,
        ),
      ];
      final beats = buildLastTurnPlaybackBeats(
        events: events,
        resolveAnchor: (e) {
          if (e is AppCombatResultEvent) return null;
          return resolve(e);
        },
        captionFor: caption,
      );
      expect(beats, hasLength(1));
      expect(beats.single.tileKey, 'oldWorld|c|3|3');
    });

    test('caps at kLastTurnPlaybackCap', () {
      final events = <GameToUIEvent>[
        for (var i = 0; i < 10; i++)
          AppCombatResultEvent(
            provinceId: 'oldWorld|p$i',
            attackerId: 'gp1',
            defenderId: 'gp2',
            outcomeName: 'attackerVictory',
            winnerId: 'gp1',
            turnNumber: 2,
          ),
      ];
      final beats = buildLastTurnPlaybackBeats(
        events: events,
        resolveAnchor: resolve,
        captionFor: caption,
      );
      expect(beats, hasLength(kLastTurnPlaybackCap));
    });

    test('empty spatial batch yields no beats', () {
      const events = <GameToUIEvent>[
        AppResearchCompleteEvent(
          playerId: 'gp1',
          techId: 'tech_a',
          turnNumber: 2,
        ),
        AppMarketTurnSummaryEvent(
          playerId: 'gp1',
          totalSpent: 1,
          totalReceived: 0,
          carryForwardOrderCount: 0,
          turnNumber: 2,
        ),
      ];
      final beats = buildLastTurnPlaybackBeats(
        events: events,
        resolveAnchor: resolve,
        captionFor: caption,
      );
      expect(beats, isEmpty);
    });
  });

  group('isLastTurnSpatialEvent', () {
    test('classifies spatial vs non-spatial', () {
      expect(
        isLastTurnSpatialEvent(
          const AppPlayerProvinceDiscoveredEvent(
            playerId: 'gp1',
            provinceId: 'oldWorld|p1',
            turnNumber: 1,
          ),
        ),
        isTrue,
      );
      expect(
        isLastTurnSpatialEvent(
          const AppProvinceCapturedEvent(
            provinceId: 'oldWorld|p1',
            previousOwnerId: 'gp2',
            newOwnerId: 'gp1',
            turnNumber: 1,
          ),
        ),
        isTrue,
      );
      expect(
        isLastTurnSpatialEvent(
          const AppPlayerSeaZoneDiscoveredEvent(
            playerId: 'gp1',
            seaZoneId: 'sz1',
            turnNumber: 1,
          ),
        ),
        isTrue,
      );
      expect(
        isLastTurnSpatialEvent(
          const AppResearchCompleteEvent(
            playerId: 'gp1',
            techId: 't',
            turnNumber: 1,
          ),
        ),
        isFalse,
      );
    });
  });

  group('last-turn pulse colour', () {
    test('is distinct from selection orange and locate cyan', () {
      expect(
        kLastTurnPulseColor,
        isNot(RegionMapPalette.mapSelectedHighlightOrange),
      );
      expect(
        kLastTurnPulseColor,
        isNot(RegionMapPalette.mapSecondarySelectionCyan),
      );
    });
  });

  group('last-turn playback Skip copy', () {
    test('English Skip label comes from AppLocalizations', () {
      expect(
        lookupAppLocalizations(const Locale('en')).map_lastTurnPlayback_skip,
        'Skip',
      );
    });
  });
}
