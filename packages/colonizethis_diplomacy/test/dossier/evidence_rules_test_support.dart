import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared `Game` fixture for dossier evidence rule tests (`test/dossier/`).
///
/// Most evidence rule tests construct a near-identical empty-world game
/// (orders phase, empty `oldWorld` / `newWorld`) varying only by
/// `turnNumber`, `players`, and a handful of optional diplomacy/AI fields.
/// This helper centralizes that boilerplate.
///
/// Refs waigore/colonizethis#2216 (consolidate duplicated test setup).
Game evidenceGame({
  String id = 'g1',
  int turnNumber = 2,
  required List<Player> players,
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
  Map<String, bool> aiControlByGpId = const {},
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    diplomacyRelations: diplomacyRelations,
    diplomaticHistoryEvents: diplomaticHistoryEvents,
    aiControlByGpId: aiControlByGpId,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn,
  );
}
