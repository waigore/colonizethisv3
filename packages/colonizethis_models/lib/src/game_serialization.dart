/// Game JSON encode/decode helpers extracted so [Game] stays under the models
/// 500 non-comment-line cap (Refs #4068). Public API remains [Game.toJson] /
/// [Game.fromJson] on the aggregate.
library;

export 'game_serialization_decode.dart' show decodeGameFromJson;

import 'advanced_start_type.dart';
import 'game.dart';
import 'world_market.dart';

Map<String, dynamic> encodeGameToJson(Game game) {
  return {
    'id': game.id,
    'worldState': game.worldState.toJson(),
    'players': game.players.map((e) => e.toJson()).toList(),
    'minorNations': game.minorNations.map((e) => e.toJson()).toList(),
    'tribes': game.tribes.map((e) => e.toJson()).toList(),
    if (game.turnTimeMapping != null)
      'turnTimeMapping': game.turnTimeMapping!.toJson(),
    if (game.defaultCombatMode != null)
      'defaultCombatMode': game.defaultCombatMode!.name,
    if (game.combatModeByProvinceId.isNotEmpty)
      'combatModeByProvinceId': game.combatModeByProvinceId.map(
        (k, v) => MapEntry(k, v.name),
      ),
    if (game.diplomacyRelations.isNotEmpty)
      'diplomacyRelations': game.diplomacyRelations
          .map((r) => r.toJson())
          .toList(),
    if (game.overtureStates.isNotEmpty)
      'overtureStates': game.overtureStates.map((o) => o.toJson()).toList(),
    if (game.subsidyStates.isNotEmpty)
      'subsidyStates': game.subsidyStates.map((s) => s.toJson()).toList(),
    if (game.colonyStates.isNotEmpty)
      'colonyStates': game.colonyStates.map((c) => c.toJson()).toList(),
    if (game.boycottStates.isNotEmpty)
      'boycottStates': game.boycottStates.map((b) => b.toJson()).toList(),
    if (game.allianceBreakCooldowns.isNotEmpty)
      'allianceBreakCooldowns': game.allianceBreakCooldowns
          .map((c) => c.toJson())
          .toList(),
    if (game.aiControlByGpId.isNotEmpty)
      'aiControlByGpId': game.aiControlByGpId,
    if (game.aiSeedByGpId.isNotEmpty) 'aiSeedByGpId': game.aiSeedByGpId,
    if (game.aiProfileByGpId.isNotEmpty)
      'aiProfileByGpId': game.aiProfileByGpId.map((k, v) => MapEntry(k, v)),
    if (game.hiddenAgendaByGpId.isNotEmpty)
      'hiddenAgendaByGpId': game.hiddenAgendaByGpId,
    if (game.dossierEvidenceEntries.isNotEmpty)
      'dossierEvidenceEntries': game.dossierEvidenceEntries
          .map((e) => e.toJson())
          .toList(),
    if (game.diplomaticHistoryEvents.isNotEmpty)
      'diplomaticHistoryEvents': game.diplomaticHistoryEvents
          .map((e) => e.toJson())
          .toList(),
    if (game.globalGameSeed != null) 'globalGameSeed': game.globalGameSeed,
    if (game.greatPowerColorOverride != null &&
        game.greatPowerColorOverride!.isNotEmpty)
      'greatPowerColorOverride': game.greatPowerColorOverride!.map(
        (k, v) => MapEntry(k, v),
      ),
    if (game.victory != null) 'victory': game.victory!.toJson(),
    if (game.calendarCampaignHalted) 'calendarCampaignHalted': true,
    if (game.infiniteMode) 'infiniteMode': true,
    if (game.richesCashMultiplier != 1.0)
      'richesCashMultiplier': game.richesCashMultiplier,
    if (game.capitalTileGrainBonusPerTurn != 5)
      'capitalTileGrainBonusPerTurn': game.capitalTileGrainBonusPerTurn,
    if (game.generals.isNotEmpty)
      'generals': game.generals.map((e) => e.toJson()).toList(),
    if (game.politicalGlyphByPlayerId.isNotEmpty)
      'politicalGlyphByPlayerId': game.politicalGlyphByPlayerId,
    if (game.lastHumanCompletedResearchCategory != null)
      'lastHumanCompletedResearchCategory':
          game.lastHumanCompletedResearchCategory,
    if (game.lastHumanResearchCategoryCompletionTurn != null)
      'lastHumanResearchCategoryCompletionTurn':
          game.lastHumanResearchCategoryCompletionTurn,
    'mapViewState': game.mapViewState.toJson(),
    if (game.worldMarketState != WorldMarketState.empty)
      'worldMarketState': game.worldMarketState.toJson(),
    if (game.ftpPartnershipKeys.isNotEmpty)
      'ftpPartnershipKeys': game.ftpPartnershipKeys.toList()..sort(),
    if (game.debugDiplomacyUsedPairKeys.isNotEmpty)
      'debugDiplomacyUsedPairKeys': game.debugDiplomacyUsedPairKeys.toList()
        ..sort(),
    if (game.advancedStartType != null)
      'advancedStartType': game.advancedStartType!.toJson(),
  };
}
