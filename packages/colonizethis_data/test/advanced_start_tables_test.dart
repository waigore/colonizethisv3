import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('advanced start tech lists', () {
    test('50-turn list has 23 DAG-valid catalog ids', () {
      expect(kAdvancedStart50TurnTechIds, hasLength(23));
      validateAdvancedStartTechList(kAdvancedStart50TurnTechIds);
    });

    test('100-turn list has 45 DAG-valid catalog ids', () {
      expect(kAdvancedStart100TurnTechIds, hasLength(45));
      validateAdvancedStartTechList(kAdvancedStart100TurnTechIds);
    });

    test('100-turn list includes all 50-turn ids', () {
      expect(
        kAdvancedStart100TurnTechIds.toSet(),
        containsAll(kAdvancedStart50TurnTechIds),
      );
    });

    test('tier params match SPEC tables', () {
      final p50 = advancedStartTierParams(AdvancedStartType.turns50);
      expect(p50.treasury, 20000);
      expect(p50.peasants, 16);
      expect(p50.apprentices, 0);

      final p100 = advancedStartTierParams(AdvancedStartType.turns100);
      expect(p100.treasury, 40000);
      expect(p100.peasants, 16);
      expect(p100.apprentices, 4);
    });

    test('civilian, regiment, and ship tables match SPEC', () {
      expect(
        advancedStartCivilianCounts(AdvancedStartType.turns50),
        kAdvancedStart50TurnCivilianCounts,
      );
      expect(
        advancedStartCivilianCounts(AdvancedStartType.turns100),
        kAdvancedStart100TurnCivilianCounts,
      );
      expect(advancedStartRegimentCount(AdvancedStartType.turns50), 6);
      expect(advancedStartRegimentCount(AdvancedStartType.turns100), 12);
      expect(advancedStartCargoShipCount(AdvancedStartType.turns50), 1);
      expect(advancedStartCargoShipCount(AdvancedStartType.turns100), 6);
    });

    test('NW reveal, prospect, and diplomacy tier helpers match SPEC', () {
      expect(
        advancedStartNwRevealFraction(AdvancedStartType.turns50),
        kAdvancedStart50TurnNwRevealFraction,
      );
      expect(advancedStartNwRevealFraction(AdvancedStartType.turns100), 1.0);
      expect(advancedStartProspectFraction(AdvancedStartType.turns50), 0.50);
      expect(advancedStartProspectFraction(AdvancedStartType.turns100), 0.75);
      expect(
        advancedStartDiplomacyOvertureStage(AdvancedStartType.turns50),
        OvertureStage.tradeConsulate,
      );
      expect(
        advancedStartDiplomacyOvertureStage(AdvancedStartType.turns100),
        OvertureStage.embassy,
      );
      expect(
        advancedStartDevelopmentFraction(AdvancedStartType.turns50),
        kAdvancedStart50TurnDevelopmentFraction,
      );
      expect(
        advancedStartNwColonizationCount(AdvancedStartType.turns100),
        kAdvancedStart100TurnNwColonizationCount,
      );
    });

    test('developable set stays keyed by Resource.name', () {
      expect(
        kAdvancedStartDevelopableResourceIds.contains(Resource.grain.name),
        isTrue,
      );
      expect(
        kAdvancedStartDevelopableResourceIds.contains(Resource.timber.name),
        isTrue,
      );
      expect(advancedStartDevelopableTilePriority(Resource.grain.name), 0);
      expect(advancedStartDevelopableTilePriority(Resource.timber.name), 2);
    });
  });
}
