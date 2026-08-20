import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_ui_chrome/event_feed/ct_event_feed_text.dart';

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
          outcomeName: 'attackerVictory',
          winnerId: 'gp1',
          turnNumber: 1,
          attackerCasualtyCount: 2,
          defenderCasualtyCount: 1,
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
        'Capital: Attacker victory. gp1 lost 2 regiments; gp2 lost 1.',
      );
      expect(entry.linkAffordance, isFalse);
      entry.onTap?.call();
      expect(tappedProvince, 'oldWorld|cap');
    });

    test('stalemate and zero-loss rows use handbook outcome labels', () {
      final stalemate = singleTurnFeedEntry(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|cap',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'stalemate',
          turnNumber: 1,
        ),
        TurnFeedTestContext(),
      );
      expect(
        stalemate.text,
        'Capital: Stalemate. gp1 lost 0 regiments; gp2 lost 0.',
      );

      final mutual = singleTurnFeedEntry(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|cap',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'mutualAnnihilation',
          turnNumber: 1,
          attackerCasualtyCount: 4,
          defenderCasualtyCount: 3,
        ),
        TurnFeedTestContext(),
      );
      expect(
        mutual.text,
        'Capital: Both armies destroyed. gp1 lost 4 regiments; gp2 lost 3.',
      );

      final defenderHolds = singleTurnFeedEntry(
        const AppCombatResultEvent(
          provinceId: 'oldWorld|cap',
          attackerId: 'gp1',
          defenderId: 'gp2',
          outcomeName: 'defenderVictory',
          winnerId: 'gp2',
          turnNumber: 1,
          attackerCasualtyCount: 5,
          defenderCasualtyCount: 0,
        ),
        TurnFeedTestContext(),
      );
      expect(
        defenderHolds.text,
        'Capital: Defender holds. gp1 lost 5 regiments; gp2 lost 0.',
      );
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
          outcomeName: 'side1Victory',
          turnNumber: 1,
          side1CasualtyCount: 1,
          side2CasualtyCount: 2,
          side2Retreated: true,
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
        'sea1: Attacker victory. gp1 lost 1 ships; gp2 lost 2 ships. '
        'gp2 retreated.',
      );
      entry.onTap?.call();
      expect(tappedSea, 'sea1');
    });

    test('AppNavalCombatResultEvent unknown outcome falls back', () {
      final entry = singleTurnFeedEntry(
        const AppNavalCombatResultEvent(
          seaZoneId: 'sea1',
          side1OwnerId: 'gp1',
          side2OwnerId: 'gp2',
          outcomeName: 'futureEnumValue',
          turnNumber: 1,
        ),
        TurnFeedTestContext(),
      );

      expect(
        entry.text,
        'sea1: Naval battle resolved. gp1 lost 0 ships; gp2 lost 0 ships.',
      );
      expect(entry.text.contains('futureEnumValue'), isFalse);
    });

    test('AppNavalCombatResultEvent maps each handbook outcome', () {
      expect(
        CtEventFeedText.navalBattleOutcomeLabel('side2Victory'),
        'Defender holds',
      );
      expect(
        CtEventFeedText.navalBattleOutcomeLabel('stalemate'),
        'Stalemate',
      );
      expect(
        CtEventFeedText.navalBattleOutcomeLabel('mutualDestruction'),
        'Both fleets destroyed',
      );
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
