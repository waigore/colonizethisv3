import 'package:colonizethis_models/colonizethis_models.dart';

/// Minimal [Game] scaffold for models package tests (Refs #4068 Slice D).
Game minimalGame({
  String id = 'g1',
  int turnNumber = 1,
  TurnPhase phase = TurnPhase.orders,
  List<Player> players = const [
    Player(id: 'p1', displayName: 'Spain', isHuman: true),
  ],
  AdvancedStartType? advancedStartType,
  bool calendarCampaignHalted = false,
  bool infiniteMode = false,
  Set<String> debugDiplomacyUsedPairKeys = const {},
  List<AllianceBreakCooldownState> allianceBreakCooldowns = const [],
  List<SubsidyState> subsidyStates = const [],
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
  WorldMarketState worldMarketState = WorldMarketState.empty,
  MapViewState? mapViewState,
  TurnTimeMapping? turnTimeMapping,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
  double richesCashMultiplier = 1.0,
  Map<String, String?> aiProfileByGpId = const {},
}) {
  return Game(
    id: id,
    advancedStartType: advancedStartType,
    calendarCampaignHalted: calendarCampaignHalted,
    infiniteMode: infiniteMode,
    debugDiplomacyUsedPairKeys: debugDiplomacyUsedPairKeys,
    allianceBreakCooldowns: allianceBreakCooldowns,
    subsidyStates: subsidyStates,
    colonyStates: colonyStates,
    boycottStates: boycottStates,
    minorNations: minorNations,
    tribes: tribes,
    diplomaticHistoryEvents: diplomaticHistoryEvents,
    worldMarketState: worldMarketState,
    mapViewState: mapViewState ?? MapViewState.defaults,
    turnTimeMapping: turnTimeMapping,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn,
    richesCashMultiplier: richesCashMultiplier,
    aiProfileByGpId: aiProfileByGpId,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: turnNumber),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}
