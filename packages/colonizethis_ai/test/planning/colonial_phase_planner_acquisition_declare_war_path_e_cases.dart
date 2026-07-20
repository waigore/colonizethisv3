// Case bodies for `colonial_phase_planner_acquisition_declare_war_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';
import 'ai_planner_fixtures.dart';
import 'colonial_phase_planner_acquisition_declare_war_support.dart';

const String _gp1 = colonialAcquisitionDeclareWarGp1;
const String _gp2 = colonialAcquisitionDeclareWarGp2;
const String _tribe1 = colonialAcquisitionDeclareWarTribe1;
const String _tribe2 = colonialAcquisitionDeclareWarTribe2;

const String _nwProv1 = colonialAcquisitionDeclareWarNwProv1;
const String _nwProv2 = colonialAcquisitionDeclareWarNwProv2;
const String _nwProvGp = colonialAcquisitionDeclareWarNwProvGp;

const String _nwTile1 = colonialAcquisitionDeclareWarNwTile1;

void registerColonialPhasePlannerAcquisitionDeclareWarPathECases() {
  group('planColonialAcquisition declareWar Path E (Refs #2924)', () {
    test('treasury zero with NW recovery override emits declareWar target', () {
      final cheapest = cheapestRegimentBuildCost();
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        activePlayerTreasury: 0,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          expandEconomyPlan: kNwTreasuryRecoveryOverridePlan,
        ),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
        reason:
            'Under the treasury-recovery resource-need override '
            '(treasury == 0, NW == 0, boostTreasuryRecoveryCargo) '
            'the declareWar arm must waive the planner-level '
            'treasury gate so the NW conquest → riches chain can '
            'begin without bypassing build affordability.',
      );
      expect(cheapest, greaterThan(0));
    });

    test(
      'partial treasury with boostTreasuryRecoveryCargo emits declareWar',
      () {
        final game = buildColonialAcquisitionGame(
          gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
          activePlayerTreasury: 500,
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
          diplomacyRelations: <DiplomacyRelation>[
            colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
          ],
        );
        final snapshot = buildColonialAcquisitionSnapshot(
          invadableNw: const [_nwProv1],
          treasury: 500,
          newWorldProvincesOwned: 0,
        );
        expect(
          planColonialAcquisition(
            game: game,
            snapshot: snapshot,
            expandEconomyPlan: const ExpandEconomyPlan(
              forceCheapestRegimentBuild: false,
              boostTreasuryRecoveryCargo: true,
            ),
          ),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.declareWar,
          ),
          reason:
              'Path E declare-war waiver must persist after Path F raises '
              'treasury above zero but below the regiment threshold.',
        );
      },
    );

    test('treasury zero without override keeps declareWar suppressed', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition-declare-war',
        activePlayerTreasury: 0,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionPeaceNeutral(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      expect(
        planColonialAcquisition(
          game: game,
          snapshot: snapshot,
          expandEconomyPlan: ExpandEconomyPlan.defaultPlan,
        ),
        isNull,
        reason:
            'Regression guard: without boostTreasuryRecoveryCargo the '
            'legacy treasury >= cheapestRegimentBuildTreasuryCost gate '
            'must still suppress declareWar at treasury zero.',
      );
    });
  });
}
