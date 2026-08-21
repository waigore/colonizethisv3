/// [Game.copyWith] implementation extracted so [Game] stays under the models
/// physical-line cap (Refs #4334, #4571).
///
/// Provided as a [mixin] (not an extension) so `import … show Game` still
/// resolves `game.copyWith(...)` — extensions are invisible under `show`.
part of 'game.dart';

Game gameCopyWith(
  Game game, {
  String? id,
  WorldState? worldState,
  List<Player>? players,
  List<MinorNation>? minorNations,
  List<Tribe>? tribes,
  List<General>? generals,
  TurnTimeMapping? turnTimeMapping,
  CombatMode? defaultCombatMode,
  Map<String, CombatMode>? combatModeByProvinceId,
  List<DiplomacyRelation>? diplomacyRelations,
  List<OvertureState>? overtureStates,
  List<SubsidyState>? subsidyStates,
  List<ColonyState>? colonyStates,
  List<BoycottState>? boycottStates,
  List<AllianceBreakCooldownState>? allianceBreakCooldowns,
  Map<String, bool>? aiControlByGpId,
  Map<String, int>? aiSeedByGpId,
  Map<String, String?>? aiProfileByGpId,
  Map<String, String>? hiddenAgendaByGpId,
  List<DossierEvidenceEntry>? dossierEvidenceEntries,
  List<DiplomaticEvent>? diplomaticHistoryEvents,
  LastTurnIntelligenceDigest? lastTurnIntelligenceDigest,
  int? globalGameSeed,
  Map<String, List<int>>? greatPowerColorOverride,
  VictoryState? victory,
  bool? calendarCampaignHalted,
  bool? infiniteMode,
  double? richesCashMultiplier,
  int? capitalTileGrainBonusPerTurn,
  Map<String, String>? politicalGlyphByPlayerId,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
  MapViewState? mapViewState,
  WorldMarketState? worldMarketState,
  Set<String>? ftpPartnershipKeys,
  Set<String>? debugDiplomacyUsedPairKeys,
  AdvancedStartType? advancedStartType,
}) {
  return Game(
    id: id ?? game.id,
    worldState: worldState ?? game.worldState,
    players: players ?? game.players,
    minorNations: minorNations ?? game.minorNations,
    tribes: tribes ?? game.tribes,
    generals: generals ?? game.generals,
    turnTimeMapping: turnTimeMapping ?? game.turnTimeMapping,
    defaultCombatMode: defaultCombatMode ?? game.defaultCombatMode,
    combatModeByProvinceId:
        combatModeByProvinceId ?? game.combatModeByProvinceId,
    diplomacyRelations: diplomacyRelations ?? game.diplomacyRelations,
    overtureStates: overtureStates ?? game.overtureStates,
    subsidyStates: subsidyStates ?? game.subsidyStates,
    colonyStates: colonyStates ?? game.colonyStates,
    boycottStates: boycottStates ?? game.boycottStates,
    allianceBreakCooldowns:
        allianceBreakCooldowns ?? game.allianceBreakCooldowns,
    aiControlByGpId: aiControlByGpId ?? game.aiControlByGpId,
    aiSeedByGpId: aiSeedByGpId ?? game.aiSeedByGpId,
    aiProfileByGpId: aiProfileByGpId ?? game.aiProfileByGpId,
    hiddenAgendaByGpId: hiddenAgendaByGpId ?? game.hiddenAgendaByGpId,
    dossierEvidenceEntries:
        dossierEvidenceEntries ?? game.dossierEvidenceEntries,
    diplomaticHistoryEvents:
        diplomaticHistoryEvents ?? game.diplomaticHistoryEvents,
    lastTurnIntelligenceDigest:
        lastTurnIntelligenceDigest ?? game.lastTurnIntelligenceDigest,
    globalGameSeed: globalGameSeed ?? game.globalGameSeed,
    greatPowerColorOverride:
        greatPowerColorOverride ?? game.greatPowerColorOverride,
    victory: victory ?? game.victory,
    calendarCampaignHalted:
        calendarCampaignHalted ?? game.calendarCampaignHalted,
    infiniteMode: infiniteMode ?? game.infiniteMode,
    richesCashMultiplier: richesCashMultiplier ?? game.richesCashMultiplier,
    capitalTileGrainBonusPerTurn:
        capitalTileGrainBonusPerTurn ?? game.capitalTileGrainBonusPerTurn,
    politicalGlyphByPlayerId:
        politicalGlyphByPlayerId ?? game.politicalGlyphByPlayerId,
    lastHumanCompletedResearchCategory:
        lastHumanCompletedResearchCategory ??
        game.lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn ??
        game.lastHumanResearchCategoryCompletionTurn,
    mapViewState: mapViewState ?? game.mapViewState,
    worldMarketState: worldMarketState ?? game.worldMarketState,
    ftpPartnershipKeys: ftpPartnershipKeys ?? game.ftpPartnershipKeys,
    debugDiplomacyUsedPairKeys:
        debugDiplomacyUsedPairKeys ?? game.debugDiplomacyUsedPairKeys,
    advancedStartType: advancedStartType ?? game.advancedStartType,
  );
}

/// Instance [Game.copyWith] via mixin so `show Game` importers keep access
/// (Refs #4571). Unconstrained mixin avoids recursive `on Game` inheritance.
mixin GameCopyWith {
  Game copyWith({
    String? id,
    WorldState? worldState,
    List<Player>? players,
    List<MinorNation>? minorNations,
    List<Tribe>? tribes,
    List<General>? generals,
    TurnTimeMapping? turnTimeMapping,
    CombatMode? defaultCombatMode,
    Map<String, CombatMode>? combatModeByProvinceId,
    List<DiplomacyRelation>? diplomacyRelations,
    List<OvertureState>? overtureStates,
    List<SubsidyState>? subsidyStates,
    List<ColonyState>? colonyStates,
    List<BoycottState>? boycottStates,
    List<AllianceBreakCooldownState>? allianceBreakCooldowns,
    Map<String, bool>? aiControlByGpId,
    Map<String, int>? aiSeedByGpId,
    Map<String, String?>? aiProfileByGpId,
    Map<String, String>? hiddenAgendaByGpId,
    List<DossierEvidenceEntry>? dossierEvidenceEntries,
    List<DiplomaticEvent>? diplomaticHistoryEvents,
    LastTurnIntelligenceDigest? lastTurnIntelligenceDigest,
    int? globalGameSeed,
    Map<String, List<int>>? greatPowerColorOverride,
    VictoryState? victory,
    bool? calendarCampaignHalted,
    bool? infiniteMode,
    double? richesCashMultiplier,
    int? capitalTileGrainBonusPerTurn,
    Map<String, String>? politicalGlyphByPlayerId,
    String? lastHumanCompletedResearchCategory,
    int? lastHumanResearchCategoryCompletionTurn,
    MapViewState? mapViewState,
    WorldMarketState? worldMarketState,
    Set<String>? ftpPartnershipKeys,
    Set<String>? debugDiplomacyUsedPairKeys,
    AdvancedStartType? advancedStartType,
  }) =>
      gameCopyWith(
        this as Game,
        id: id,
        worldState: worldState,
        players: players,
        minorNations: minorNations,
        tribes: tribes,
        generals: generals,
        turnTimeMapping: turnTimeMapping,
        defaultCombatMode: defaultCombatMode,
        combatModeByProvinceId: combatModeByProvinceId,
        diplomacyRelations: diplomacyRelations,
        overtureStates: overtureStates,
        subsidyStates: subsidyStates,
        colonyStates: colonyStates,
        boycottStates: boycottStates,
        allianceBreakCooldowns: allianceBreakCooldowns,
        aiControlByGpId: aiControlByGpId,
        aiSeedByGpId: aiSeedByGpId,
        aiProfileByGpId: aiProfileByGpId,
        hiddenAgendaByGpId: hiddenAgendaByGpId,
        dossierEvidenceEntries: dossierEvidenceEntries,
        diplomaticHistoryEvents: diplomaticHistoryEvents,
        lastTurnIntelligenceDigest: lastTurnIntelligenceDigest,
        globalGameSeed: globalGameSeed,
        greatPowerColorOverride: greatPowerColorOverride,
        victory: victory,
        calendarCampaignHalted: calendarCampaignHalted,
        infiniteMode: infiniteMode,
        richesCashMultiplier: richesCashMultiplier,
        capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
        politicalGlyphByPlayerId: politicalGlyphByPlayerId,
        lastHumanCompletedResearchCategory:
            lastHumanCompletedResearchCategory,
        lastHumanResearchCategoryCompletionTurn:
            lastHumanResearchCategoryCompletionTurn,
        mapViewState: mapViewState,
        worldMarketState: worldMarketState,
        ftpPartnershipKeys: ftpPartnershipKeys,
        debugDiplomacyUsedPairKeys: debugDiplomacyUsedPairKeys,
        advancedStartType: advancedStartType,
      );
}
