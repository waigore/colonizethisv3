/// [Game] JSON decode helper extracted so [game_serialization.dart] stays under
/// the models physical-line cap (Refs #4334 wave 3). Public API remains
/// [Game.fromJson] on the aggregate.
library;

import 'advanced_start_type.dart';
import 'combat_mode.dart';
import 'dossier_evidence.dart';
import 'diplomacy.dart';
import 'game.dart';
import 'general.dart';
import 'last_turn_intelligence_digest.dart';
import 'map_view_state.dart';
import 'minor_nation.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'world_market.dart';
import 'world_state.dart';

List<T> parseGameModelList<T>(
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

Game decodeGameFromJson(Map<String, dynamic> json) {
  final players = parseGameModelList(json['players'], Player.fromJson);
  final minorNations = parseGameModelList(
    json['minorNations'],
    MinorNation.fromJson,
  );
  final tribes = parseGameModelList(json['tribes'], Tribe.fromJson);
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
  final diplomacyRelations = parseGameModelList(
    json['diplomacyRelations'],
    DiplomacyRelation.fromJson,
  );
  final overtureStates = parseGameModelList(
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
      parseGameModelList(json['subsidyStates'], SubsidyState.fromJson)
          .where(
            (s) =>
                isValidSubsidyPercent(s.percent) &&
                !greatPowerIds.contains(s.targetId),
          )
          .toList();
  final colonyStates = parseGameModelList(
    json['colonyStates'],
    ColonyState.fromJson,
  );
  final boycottStates = parseGameModelList(
    json['boycottStates'],
    BoycottState.fromJson,
  );
  final allianceBreakCooldowns = parseGameModelList(
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
  final dossierEvidenceEntries = parseGameModelList(
    json['dossierEvidenceEntries'],
    DossierEvidenceEntry.fromJson,
  );
  final diplomaticHistoryEvents = parseGameModelList(
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
  final generals = parseGameModelList(json['generals'], General.fromJson);
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
    lastTurnIntelligenceDigest:
        json['lastTurnIntelligenceDigest'] is Map<String, dynamic>
        ? LastTurnIntelligenceDigest.fromJson(
            json['lastTurnIntelligenceDigest'] as Map<String, dynamic>,
          )
        : json['lastTurnIntelligenceDigest'] is Map<dynamic, dynamic>
        ? LastTurnIntelligenceDigest.fromJson(
            Map<String, dynamic>.from(
              json['lastTurnIntelligenceDigest'] as Map<dynamic, dynamic>,
            ),
          )
        : null,
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
