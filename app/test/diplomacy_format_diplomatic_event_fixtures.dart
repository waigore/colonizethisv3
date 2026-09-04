// Shared fixtures for formatDiplomaticEvent branch tests (Refs #4729).
import 'package:colonizethis_models/colonizethis_models.dart';

const diplomacyFormatHumanId = 'human_gp';
const diplomacyFormatOtherId = 'other_gp';

Game diplomacyFormatMinimalGame({List<DiplomaticEvent> history = const []}) {
  return Game(
    id: 'fmt',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(
        id: diplomacyFormatHumanId,
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: diplomacyFormatOtherId,
        displayName: 'France',
        isHuman: false,
        treasury: 0,
      ),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: diplomacyFormatHumanId,
        factionId2: diplomacyFormatOtherId,
        score: 50,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: history,
  );
}

DiplomaticEvent diplomacyFormatEvent(
  DiplomaticEventType type, {
  String? fromId,
  String? toId,
  OvertureStage? stage,
  int? amount,
  String? reason,
}) {
  return DiplomaticEvent(
    turn: 1,
    intraTurnIndex: 0,
    type: type,
    participants: {diplomacyFormatHumanId, diplomacyFormatOtherId},
    fromFactionId: fromId ?? diplomacyFormatHumanId,
    toFactionId: toId ?? diplomacyFormatOtherId,
    overtureStage: stage,
    amount: amount,
    reason: reason,
  );
}
