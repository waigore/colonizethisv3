import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_feed_test_context.dart';

void main() {
  group('buildCtTurnFeedEntries combat and discovery', () {
    test('AppCombatResultEvent text and province overlay tap', () {
      var tappedProvince = '';
      final entry = singleTurnFeedEntry(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|cap',
          attackerId: 'gp1',
          defenderId: 'gp2',
          winnerId: 'gp1',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          provinceOverlayTapForProvince: (provinceId) {
            tappedProvince = provinceId;
            return () {};
          },
        ),
      );

      expect(
        entry.text,
        'Capital battle resolved! gp1 defeated gp2!',
      );
      expect(entry.linkAffordance, isFalse);
      entry.onTap?.call();
      expect(tappedProvince, 'oldWorld|cap');
    });

    test('AppGeneralMedalGainedEvent uses province medal line', () {
      final entry = singleTurnFeedEntry(
        const AppGeneralMedalGainedEvent(
          playerId: 'gp1',
          generalId: 'g1',
          provinceId: 'oldWorld|cap',
          newMedals: 2,
          turnNumber: 5,
        ),
        TurnFeedTestContext(),
      );

      expect(
        entry.text,
        'Victory at Capital: a general earned a medal (now 2).',
      );
    });

    test('AppProvinceCapturedEvent text', () {
      final entry = singleTurnFeedEntry(
        const AppProvinceCapturedEvent(
          provinceId: 'oldWorld|cap',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          turnNumber: 1,
        ),
        TurnFeedTestContext(),
      );

      expect(entry.text, 'Capital captured! gp1 now controls it!');
    });

    test('AppNavalCombatResultEvent text and sea-zone tap', () {
      var tappedSea = '';
      final entry = singleTurnFeedEntry(
        const AppNavalCombatResultEvent(
          seaZoneId: 'sea1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'Decisive',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          navalCombatTapForSeaZone: (seaZoneId) {
            tappedSea = seaZoneId;
            return () {};
          },
        ),
      );

      expect(
        entry.text,
        'sea1 naval battle resolved! Outcome: Decisive!',
      );
      entry.onTap?.call();
      expect(tappedSea, 'sea1');
    });

    test('AppPlayerProvinceDiscoveredEvent locates province', () {
      var located = '';
      final entry = singleTurnFeedEntry(
        const AppPlayerProvinceDiscoveredEvent(
          playerId: 'gp1',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          locateProvinceById: (provinceId) => located = provinceId,
        ),
      );

      expect(entry.text, 'Capital discovered!');
      entry.onTap?.call();
      expect(located, 'oldWorld|cap');
    });

    test('AppPlayerSeaZoneDiscoveredEvent locates sea zone', () {
      var located = '';
      final entry = singleTurnFeedEntry(
        const AppPlayerSeaZoneDiscoveredEvent(
          playerId: 'gp1',
          seaZoneId: 'sea1',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          locateSeaZoneTile: (seaZoneId) => located = seaZoneId,
        ),
      );

      expect(entry.text, 'sea1 discovered!');
      entry.onTap?.call();
      expect(located, 'sea1');
    });
  });
}
