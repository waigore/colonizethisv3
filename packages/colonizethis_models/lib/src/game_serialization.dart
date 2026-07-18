/// Game JSON encode/decode helpers extracted so [Game] stays under the models
/// 500 non-comment-line cap (Refs #4068). Public API remains [Game.toJson] /
/// [Game.fromJson] on the aggregate.
library;

import 'advanced_start_type.dart';
import 'combat_mode.dart';
import 'dossier_evidence.dart';
import 'diplomacy.dart';
import 'game.dart';
import 'general.dart';
import 'map_view_state.dart';
import 'minor_nation.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'world_market.dart';
import 'world_state.dart';

List<T> _parseModelList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  final list = raw as List<dynamic>? ?? const [];
  return list
      .map(
        (e) => fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)),
      )
      .toList();
}

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

Game decodeGameFromJson(Map<String, dynamic> json) {
  final players = _parseModelList(json['players'], Player.fromJson);
  final minorNations = _parseModelList(
    json['minorNations'],
    MinorNation.fromJson,
  );
  final tribes = _parseModelList(json['tribes'], Tribe.fromJson);
  final turnTimeMappingRaw = json['turnTimeMapping'];
  final Map<String, dynamic>? turnTimeMappingJson =
      turnTimeMappingRaw is Map<dynamic, dynamic>
      ? Map<String, dynamic>.from(turnTimeMappingRaw)
      : null;
  final defaultCombatModeRaw = json['defaultCombatMode'] as String?;
  final defaultCombatMode = defaultCombatModeRaw != null
      ? CombatMode.values.firstWhere(
          (e) => e.name == defaultCombatModeRaw,
          orElse: () => CombatMode.autoResolve,
        )
      : null;
  final diplomacyRelations = _parseModelList(
    json['diplomacyRelations'],
    DiplomacyRelation.fromJson,
  );
  final overtureStates = _parseModelList(
    json['overtureStates'],
    OvertureState.fromJson,
  );
  // Subsidy save-load migration (Refs #3753 R3): the £/turn model is dropped
  // in favour of percentages, and subsidies only exist GP→Minor/Tribe. On
  // load, drop (a) legacy £-based subsidies (no valid `percent`) and (b) any
  // GP→GP subsidy (target is a Great Power player). The player re-establishes
  // valid subsidies under the percent model.
  final greatPowerIds = players.map((p) => p.id).toSet();
  final subsidyStates =
      _parseModelList(json['subsidyStates'], SubsidyState.fromJson)
          .where(
            (s) =>
                isValidSubsidyPercent(s.percent) &&
                !greatPowerIds.contains(s.targetId),
          )
          .toList();
  final colonyStates = _parseModelList(
    json['colonyStates'],
    ColonyState.fromJson,
  );
  final boycottStates = _parseModelList(
    json['boycottStates'],
    BoycottState.fromJson,
  );
  final allianceBreakCooldowns = _parseModelList(
    json['allianceBreakCooldowns'],
    AllianceBreakCooldownState.fromJson,
  );

  final aiControlRaw = json['aiControlByGpId'] as Map<dynamic, dynamic>? ?? {};
  final aiControlByGpId = aiControlRaw.map(
    (k, v) => MapEntry(k.toString(), v == true),
  );
  final aiSeedRaw = json['aiSeedByGpId'] as Map<dynamic, dynamic>? ?? {};
  final aiSeedByGpId = aiSeedRaw.map(
    (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
  );
  final aiProfileRaw = json['aiProfileByGpId'] as Map<dynamic, dynamic>? ?? {};
  final aiProfileByGpId = aiProfileRaw.map(
    (k, v) => MapEntry<String, String?>(
      k.toString(),
      v == null ? null : v.toString(),
    ),
  );
  final hiddenAgendaRaw =
      json['hiddenAgendaByGpId'] as Map<dynamic, dynamic>? ?? {};
  final hiddenAgendaByGpId = hiddenAgendaRaw.map(
    (k, v) => MapEntry(k.toString(), v.toString()),
  );
  final dossierEvidenceEntries = _parseModelList(
    json['dossierEvidenceEntries'],
    DossierEvidenceEntry.fromJson,
  );
  final diplomaticHistoryEvents = _parseModelList(
    json['diplomaticHistoryEvents'],
    DiplomaticEvent.fromJson,
  );
  final globalGameSeed = json['globalGameSeed'] as int?;
  final greatPowerColorOverrideRaw =
      json['greatPowerColorOverride'] as Map<dynamic, dynamic>?;
  final greatPowerColorOverride = greatPowerColorOverrideRaw?.map(
    (k, v) => MapEntry(
      k.toString(),
      (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
    ),
  );

  final combatModeRaw =
      json['combatModeByProvinceId'] as Map<dynamic, dynamic>? ?? {};
  final combatModeByProvinceId = combatModeRaw.map(
    (k, v) => MapEntry(
      k.toString(),
      CombatMode.values.firstWhere(
        (e) => e.name == v.toString(),
        orElse: () => CombatMode.autoResolve,
      ),
    ),
  );
  final richesCashMultiplier =
      (json['richesCashMultiplier'] as num?)?.toDouble() ?? 1.0;
  final capitalTileGrainBonusPerTurn =
      (json['capitalTileGrainBonusPerTurn'] as num?)?.toInt() ?? 5;
  final generals = _parseModelList(json['generals'], General.fromJson);
  final politicalGlyphRaw =
      json['politicalGlyphByPlayerId'] as Map<dynamic, dynamic>? ?? {};
  final politicalGlyphByPlayerId = politicalGlyphRaw.map(
    (k, v) => MapEntry(k.toString(), v.toString()),
  );
  final mapViewStateRaw = json['mapViewState'];
  final mapViewState = mapViewStateRaw is Map<dynamic, dynamic>
      ? MapViewState.fromJson(Map<String, dynamic>.from(mapViewStateRaw))
      : MapViewState.defaults;
  final worldMarketStateRaw = json['worldMarketState'];
  final worldMarketState = worldMarketStateRaw is Map<dynamic, dynamic>
      ? WorldMarketState.fromJson(
          Map<String, dynamic>.from(worldMarketStateRaw),
        )
      : WorldMarketState.empty;
  final ftpKeysList = json['ftpPartnershipKeys'] as List<dynamic>? ?? [];
  final ftpPartnershipKeys = ftpKeysList.map((e) => e.toString()).toSet();
  final debugDiploKeysList =
      json['debugDiplomacyUsedPairKeys'] as List<dynamic>? ?? [];
  final debugDiplomacyUsedPairKeys = debugDiploKeysList
      .map((e) => e.toString())
      .toSet();
  return Game(
    id: json['id'] as String,
    worldState: WorldState.fromJson(
      Map<String, dynamic>.from(json['worldState'] as Map<dynamic, dynamic>),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    generals: generals,
    turnTimeMapping: turnTimeMappingJson != null
        ? TurnTimeMapping.fromJson(turnTimeMappingJson)
        : null,
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
    globalGameSeed: globalGameSeed,
    greatPowerColorOverride: greatPowerColorOverride,
    victory: json['victory'] is Map<String, dynamic>
        ? VictoryState.fromJson(json['victory'] as Map<String, dynamic>)
        : json['victory'] is Map<dynamic, dynamic>
        ? VictoryState.fromJson(
            Map<String, dynamic>.from(json['victory'] as Map<dynamic, dynamic>),
          )
        : null,
    richesCashMultiplier: richesCashMultiplier,
    capitalTileGrainBonusPerTurn: capitalTileGrainBonusPerTurn,
    politicalGlyphByPlayerId: politicalGlyphByPlayerId,
    lastHumanCompletedResearchCategory:
        json['lastHumanCompletedResearchCategory'] as String?,
    lastHumanResearchCategoryCompletionTurn:
        (json['lastHumanResearchCategoryCompletionTurn'] as num?)?.toInt(),
    mapViewState: mapViewState,
    calendarCampaignHalted: json['calendarCampaignHalted'] as bool? ?? false,
    infiniteMode: json['infiniteMode'] as bool? ?? false,
    worldMarketState: worldMarketState,
    ftpPartnershipKeys: ftpPartnershipKeys,
    debugDiplomacyUsedPairKeys: debugDiplomacyUsedPairKeys,
    advancedStartType: json['advancedStartType'] != null
        ? AdvancedStartTypeJson.fromJson(json['advancedStartType'] as String?)
        : null,
  );
}
