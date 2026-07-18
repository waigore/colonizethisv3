import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('ai_victory_config', () {
    test('provincesToVictoryFromOldWorldOwned matches 31 threshold', () {
      expect(provincesToVictoryFromOldWorldOwned(7), 24);
      expect(provincesToVictoryFromOldWorldOwned(31), 0);
      expect(provincesToVictoryFromOldWorldOwned(40), 0);
    });

    test('GP declare-war and build pace constants are configured', () {
      expect(kDeclareWarGpWeakNeighborBonus, greaterThan(0));
      expect(kBuildRegimentBonusWhenBehindVictoryPace, greaterThan(0));
    });

    test('barrel re-exports civilian-build planner constants', () {
      expect(kCivilianBuildBaseScore, 1.0);
      expect(kCivilianBuildMinCapScoreBoost, 50.0);
      expect(kCivilianBuildPoolWeight, 1.0);
      expect(kCivilianBuildResearchPaperReserveShare, 0.5);
      expect(kCivilianBuildPhaseExpand, 'expand');
      expect(isCivilianGatingTech('merchant_companies'), isTrue);
      expect(isCivilianGatingTech('not_a_tech'), isFalse);
    });

    test('region ids remain stable serialization strings', () {
      expect(kOldWorldRegionId, 'oldWorld');
      expect(kNewWorldRegionId, 'newWorld');
    });

    test('researchReservedPaper floors the configured share', () {
      expect(researchReservedPaper(0), 0);
      expect(researchReservedPaper(-1), 0);
      expect(researchReservedPaper(10), 5);
      expect(researchReservedPaper(11), 5);
    });

    test('civilian build cap maps expose expected type keys', () {
      expect(kCivilianBuildMinCountByType.containsKey('Builder'), isTrue);
      expect(kCivilianBuildTargetCountByType.containsKey('Spy'), isTrue);
      expect(kCivilianBuildMaxCountByType.containsKey('Rail Builder'), isTrue);
      expect(
        kCivilianBuildMaxCountByType['Builder']!,
        greaterThanOrEqualTo(kCivilianBuildMinCountByType['Builder']!),
      );
    });

    test('overture embassy kickback scalars stay positive', () {
      expect(kEstablishOvertureEmbassyKickbackBonusMax, greaterThan(0));
      expect(kEstablishOvertureEmbassyKickbackVolumeFull, greaterThan(0));
    });
  });
}
