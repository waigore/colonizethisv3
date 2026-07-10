// Shared fixtures for breakAlliance validator scenarios (Refs #3949 wave 3).
//
// Refs #3753 R11. SPEC/program/orders.md § Diplomatic orders / break alliance.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game breakAllianceValidatorTwoGpAllianceGame({
  bool formalAlliance = true,
  RelationState state = RelationState.atPeace,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        level: RelationLevel.allied,
        state: state,
        formalAlliance: formalAlliance,
      ),
    ],
  );
}
