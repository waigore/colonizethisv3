// Table-driven resolveDiplomacyPhase scenarios (Refs #3837 / #4028 / #4130).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'diplomacy_game_fixtures_scenarios.dart';
import 'diplomacy_phase_scenarios.dart';

class DiplomacyPhaseScenario {
  const DiplomacyPhaseScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runDiplomacyPhaseScenario(DiplomacyPhaseScenario scenario) => scenario.run();

DiplomacyPhaseScenario dpsRow(String label, void Function() run) =>
    DiplomacyPhaseScenario(label: label, run: run);

const dpsGp1 = Player(id: 'gp1', displayName: 'GP1', isHuman: true);
const dpsGp1Rich = Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000);
const dpsGp2 = Player(id: 'gp2', displayName: 'GP2', isHuman: true);
const dpsOw = 'oldWorld';

const dpsMinorNapOverture = OvertureState(
  gpId: 'gp1',
  targetId: 'minor1',
  stage: OvertureStage.nap,
  sinceTurn: 0,
);

const dpsOvertureConsulateEmbassy = [
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.tradeConsulate,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.embassy,
  ),
];

const dpsDeclareWarMinor1 = [
  DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'minor1'),
];

const dpsPeaceMinor1 = [
  DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'minor1'),
];

const dpsJoinEmpireMinor1 = [
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: 'minor1',
    overtureStage: OvertureStage.joinEmpire,
  ),
];

Orders dpsDip(String gp, List<DiplomaticOrder> orders) =>
    Orders(diplomaticOrdersByPlayerId: {gp: orders});

Game dpsResolve(Game g, Orders o) => resolveDiplomacyPhase(g, o).game;

Province dpsOwProv(String localId) =>
    Province(id: '$dpsOw|$localId', regionId: dpsOw, ownerId: 'minor1');

Game dpsGrantAidGame() => diplomacyResolverPhaseTestBaseGame().copyWith(
      overtureStates: const [gpMinorEmbassyOverture],
      diplomacyRelations: [gpMinorNeutralRelation()],
    );

Game dpsJoinEmpireGame(WorldState worldState) =>
    diplomacyResolverPhaseTestBaseGame().copyWith(
      players: const [dpsGp1Rich],
      worldState: worldState,
      overtureStates: const [dpsMinorNapOverture],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          score: 60,
          level: RelationLevel.friendly,
        ),
      ],
    );

String? dpsOwOwner(Game g, String localId) =>
    g.worldState.oldWorld.provinces.where((p) => p.id == '$dpsOw|$localId').firstOrNull?.ownerId;

/// Overture, alliance, and war/peace scenarios from part 1 integration tests.
