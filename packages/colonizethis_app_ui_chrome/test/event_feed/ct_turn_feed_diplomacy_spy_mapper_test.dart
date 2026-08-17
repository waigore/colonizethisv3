import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_feed_test_context.dart';

void main() {
  group('buildCtTurnFeedEntries diplomacy and spy', () {
    test('AppDiplomacyChangeEvent link when counterpart resolves', () {
      var tappedFaction = '';
      final entry = singleTurnFeedEntry(
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'minor1',
          changeType: 'war',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          diplomacyDetailTapForFaction: (factionId) {
            tappedFaction = factionId;
            return () {};
          },
        ),
      );

      expect(entry.text, 'gp1 war minor1');
      expect(entry.linkAffordance, isTrue);
      entry.onTap?.call();
      expect(tappedFaction, 'minor1');
    });

    test('AppDiplomacyChangeEvent non-tappable when counterpart missing', () {
      final entry = singleTurnFeedEntry(
        const AppDiplomacyChangeEvent(
          actorId: 'gp1',
          targetId: 'minor1',
          changeType: 'war',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          counterpartFactionId: ({required actorId, required targetId}) => null,
        ),
      );

      expect(entry.linkAffordance, isFalse);
      expect(entry.onTap, isNull);
    });

    test('AppOvertureAdvancedEvent text and diplomacy tap', () {
      final entry = singleTurnFeedEntry(
        const AppOvertureAdvancedEvent(
          offererGpId: 'gp1',
          targetFactionId: 'minor1',
          newStage: 'embassy',
          turnNumber: 1,
        ),
        TurnFeedTestContext(
          overtureStageLabel: (_) => 'Embassy',
        ),
      );

      expect(
        entry.text,
        'Overture advanced! gp1 with minor1: Embassy!',
      );
    });

    test('AppSpyCaughtEvent territory-owner POV copy', () {
      final entry = singleTurnFeedEntry(
        const AppSpyCaughtEvent(
          unitId: 'u1',
          spyOwnerId: 'gp2',
          territoryOwnerId: 'gp1',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(mapPlayerId: 'gp1'),
      );

      expect(
        entry.text,
        'Capital — enemy spy from gp2 caught and eliminated!',
      );
    });

    test('AppSpyCaughtEvent spy-owner POV copy', () {
      final entry = singleTurnFeedEntry(
        const AppSpyCaughtEvent(
          unitId: 'u1',
          spyOwnerId: 'gp1',
          territoryOwnerId: 'gp2',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(mapPlayerId: 'gp1'),
      );

      expect(
        entry.text,
        'Spy caught in Capital! gp2 eliminated your agent!',
      );
    });

    test('AppSpyDefectedEvent new-owner POV copy', () {
      final entry = singleTurnFeedEntry(
        const AppSpyDefectedEvent(
          unitId: 'u1',
          previousOwnerId: 'gp2',
          newOwnerId: 'gp1',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(mapPlayerId: 'gp1'),
      );

      expect(
        entry.text,
        'Capital — enemy spy from gp2 defected to your side!',
      );
    });

    test('AppSpyDefectedEvent previous-owner POV copy', () {
      final entry = singleTurnFeedEntry(
        const AppSpyDefectedEvent(
          unitId: 'u1',
          previousOwnerId: 'gp1',
          newOwnerId: 'gp2',
          provinceId: 'oldWorld|cap',
          turnNumber: 1,
        ),
        TurnFeedTestContext(mapPlayerId: 'gp1'),
      );

      expect(
        entry.text,
        'Spy defected in Capital! Agent joined gp2!',
      );
    });
  });
}
