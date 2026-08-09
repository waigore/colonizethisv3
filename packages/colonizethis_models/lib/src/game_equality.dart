/// [Game] equality and hash helpers extracted so [Game] stays under the models
/// 400 physical-line cap (Refs #4136).
library;

import 'game.dart';
import 'model_collection_equality.dart';

bool gameEquals(Game game, Object other) =>
    identical(game, other) ||
    other is Game &&
        game.runtimeType == other.runtimeType &&
        game.id == other.id &&
        game.worldState == other.worldState &&
        modelListEquals(game.players, other.players) &&
        modelListEquals(game.minorNations, other.minorNations) &&
        modelListEquals(game.tribes, other.tribes) &&
        modelListEquals(game.generals, other.generals) &&
        game.turnTimeMapping == other.turnTimeMapping &&
        game.defaultCombatMode == other.defaultCombatMode &&
        modelMapEquals(game.combatModeByProvinceId, other.combatModeByProvinceId) &&
        modelListEquals(game.diplomacyRelations, other.diplomacyRelations) &&
        modelListEquals(game.overtureStates, other.overtureStates) &&
        modelListEquals(game.subsidyStates, other.subsidyStates) &&
        modelListEquals(game.colonyStates, other.colonyStates) &&
        modelListEquals(game.boycottStates, other.boycottStates) &&
        modelListEquals(game.allianceBreakCooldowns, other.allianceBreakCooldowns) &&
        modelMapEquals(game.aiControlByGpId, other.aiControlByGpId) &&
        modelMapEquals(game.aiSeedByGpId, other.aiSeedByGpId) &&
        modelMapEquals(game.aiProfileByGpId, other.aiProfileByGpId) &&
        modelMapEquals(game.hiddenAgendaByGpId, other.hiddenAgendaByGpId) &&
        modelListEquals(game.dossierEvidenceEntries, other.dossierEvidenceEntries) &&
        modelListEquals(game.diplomaticHistoryEvents, other.diplomaticHistoryEvents) &&
        game.globalGameSeed == other.globalGameSeed &&
        modelNullableMapOfListEquals(
          game.greatPowerColorOverride,
          other.greatPowerColorOverride,
        ) &&
        game.victory == other.victory &&
        game.calendarCampaignHalted == other.calendarCampaignHalted &&
        game.infiniteMode == other.infiniteMode &&
        game.richesCashMultiplier == other.richesCashMultiplier &&
        game.capitalTileGrainBonusPerTurn == other.capitalTileGrainBonusPerTurn &&
        modelMapEquals(game.politicalGlyphByPlayerId, other.politicalGlyphByPlayerId) &&
        game.lastHumanCompletedResearchCategory ==
            other.lastHumanCompletedResearchCategory &&
        game.lastHumanResearchCategoryCompletionTurn ==
            other.lastHumanResearchCategoryCompletionTurn &&
        game.mapViewState == other.mapViewState &&
        game.worldMarketState == other.worldMarketState &&
        modelSetEquals(game.ftpPartnershipKeys, other.ftpPartnershipKeys) &&
        modelSetEquals(game.debugDiplomacyUsedPairKeys, other.debugDiplomacyUsedPairKeys) &&
        game.advancedStartType == other.advancedStartType;

int gameHashCode(Game game) => Object.hash(
  game.id,
  game.worldState,
  Object.hashAll(game.players),
  Object.hashAll(game.minorNations),
  Object.hashAll(game.tribes),
  Object.hashAll(game.generals),
  game.turnTimeMapping,
  game.defaultCombatMode,
  Object.hashAll(game.combatModeByProvinceId.entries),
  Object.hashAll(game.diplomacyRelations),
  Object.hashAll(game.overtureStates),
  Object.hash(
    Object.hashAll(game.subsidyStates),
    Object.hashAll(game.colonyStates),
    Object.hashAll(game.boycottStates),
    Object.hashAll(game.allianceBreakCooldowns),
  ),
  Object.hashAll(game.aiControlByGpId.entries),
  Object.hashAll(game.aiSeedByGpId.entries),
  Object.hashAll(game.aiProfileByGpId.entries),
  Object.hashAll(game.hiddenAgendaByGpId.entries),
  Object.hash(
    Object.hashAll(game.dossierEvidenceEntries),
    Object.hashAll(game.diplomaticHistoryEvents),
  ),
  game.globalGameSeed,
  game.greatPowerColorOverride != null
      ? Object.hashAll(game.greatPowerColorOverride!.entries)
      : null,
  Object.hash(
    game.victory,
    game.calendarCampaignHalted,
    game.infiniteMode,
    game.richesCashMultiplier,
    game.capitalTileGrainBonusPerTurn,
    Object.hashAll(game.politicalGlyphByPlayerId.entries),
    game.lastHumanCompletedResearchCategory,
    game.lastHumanResearchCategoryCompletionTurn,
    game.mapViewState,
    game.worldMarketState,
    Object.hashAll(game.ftpPartnershipKeys),
    Object.hashAll(game.debugDiplomacyUsedPairKeys),
    game.advancedStartType,
  ),
);
