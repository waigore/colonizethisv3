import 'combat_mode.dart';
import 'dossier_evidence.dart';
import 'diplomacy.dart';
import 'general.dart';
import 'map_view_state.dart';
import 'minor_nation.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'world_market.dart';
import 'world_state.dart';

/// Victory type. Phase 5: military only (31+ OW provinces). SPEC/game/victory.md.
enum VictoryType { military }

extension VictoryTypeJson on VictoryType {
  static VictoryType fromJson(String value) {
    return VictoryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VictoryType.military,
    );
  }

  String toJson() => name;
}

/// Victory state for a finished game.
class VictoryState {
  const VictoryState({
    required this.winnerPlayerId,
    required this.type,
    required this.turnNumber,
  });

  final String winnerPlayerId;
  final VictoryType type;
  final int turnNumber;

  Map<String, dynamic> toJson() => {
    'winnerPlayerId': winnerPlayerId,
    'type': type.toJson(),
    'turnNumber': turnNumber,
  };

  static VictoryState fromJson(Map<String, dynamic> json) {
    return VictoryState(
      winnerPlayerId: json['winnerPlayerId'] as String,
      type: VictoryTypeJson.fromJson(json['type'] as String),
      turnNumber: json['turnNumber'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VictoryState &&
          runtimeType == other.runtimeType &&
          winnerPlayerId == other.winnerPlayerId &&
          type == other.type &&
          turnNumber == other.turnNumber;

  @override
  int get hashCode => Object.hash(winnerPlayerId, type, turnNumber);
}

/// Top-level game container. SPEC/game/world-model.
class Game {
  const Game({
    required this.id,
    required this.worldState,
    required this.players,
    this.minorNations = const [],
    this.tribes = const [],
    this.generals = const [],
    this.turnTimeMapping,
    this.defaultCombatMode,
    this.combatModeByProvinceId = const {},
    this.diplomacyRelations = const [],
    this.overtureStates = const [],
    this.subsidyStates = const [],
    this.colonyStates = const [],
    this.aiControlByGpId = const {},
    this.aiSeedByGpId = const {},
    this.aiProfileByGpId = const {},
    this.hiddenAgendaByGpId = const {},
    this.dossierEvidenceEntries = const [],
    this.diplomaticHistoryEvents = const [],
    this.globalGameSeed,
    this.greatPowerColorOverride,
    this.victory,
    this.calendarCampaignHalted = false,
    this.infiniteMode = false,
    this.richesCashMultiplier = 1.0,
    this.capitalTileGrainBonusPerTurn = 5,
    this.politicalGlyphByPlayerId = const {},
    this.lastHumanCompletedResearchCategory,
    this.lastHumanResearchCategoryCompletionTurn,
    this.mapViewState = MapViewState.defaults,
    this.worldMarketState = WorldMarketState.empty,
    this.ftpPartnershipKeys = const {},
    this.debugDiplomacyUsedPairKeys = const {},
  });

  final String id;
  final WorldState worldState;
  final List<Player> players;
  final List<MinorNation> minorNations;
  final List<Tribe> tribes;

  /// Generals per faction (Great Powers). SPEC/game/military-generals.md. Empty in legacy saves.
  final List<General> generals;

  /// Turn-to-calendar-year mapping. When null (legacy saves), use default per SPEC/game/turn-time-mapping.
  final TurnTimeMapping? turnTimeMapping;

  /// Default combat mode (Auto-Resolve vs Quick Battle). When null, use Auto-Resolve. Phase 4.
  final CombatMode? defaultCombatMode;

  /// Per-battle combat mode override by province id. Phase 4.
  final Map<String, CombatMode> combatModeByProvinceId;

  /// Per faction-pair relations. Phase 4.
  final List<DiplomacyRelation> diplomacyRelations;

  /// Overture state per Minor/Tribe per GP. Phase 4.
  final List<OvertureState> overtureStates;

  /// Active ongoing subsidies (payer -> target with amount per turn). Phase 4.
  final List<SubsidyState> subsidyStates;

  /// Tribes that have become colonies of a Great Power via Tribe Join Empire.
  /// The colony Tribe stays in [tribes]; its provinces/fleets are not transferred.
  /// SPEC/game/diplomacy.md § GP–Minor/Tribe Rules (Join Empire → colony).
  final List<ColonyState> colonyStates;

  /// AI control: true = AI-controlled. When empty, use !player.isHuman. Phase 4.
  final Map<String, bool> aiControlByGpId;

  /// Per-AI seed for determinism. Phase 4.
  final Map<String, int> aiSeedByGpId;

  /// Blessed tuned-profile name per AI Great Power; `null` value = normal AI.
  /// Only AI slots are populated. Refs #3444.
  final Map<String, String?> aiProfileByGpId;

  /// Hidden agenda id per AI Great Power. Phase 6. Never exposed to player.
  final Map<String, String> hiddenAgendaByGpId;

  /// Evidence entries for dossier (observer, subject, agenda, turn, description). Phase 6.
  final List<DossierEvidenceEntry> dossierEvidenceEntries;

  /// Flat, append-only list of diplomatic history events. Phase 6.
  final List<DiplomaticEvent> diplomaticHistoryEvents;

  /// Global game seed for AI determinism. Phase 4.
  final int? globalGameSeed;

  /// Setup-time GP map colours (GP id → [r, g, b]). When null/empty, map uses GDD defaults.
  final Map<String, List<int>>? greatPowerColorOverride;

  /// Victory state when game has been won. Null when game is ongoing.
  final VictoryState? victory;

  /// When true, the campaign calendar cap has been reached without military victory;
  /// no further full-turn resolution mutates state. SPEC/game/turn-time-mapping.md.
  final bool calendarCampaignHalted;

  /// When true, turns continue past the calendar year-1800 cap until military victory.
  /// Set at game creation from [GameSetupConfig.infiniteMode]; immutable in play.
  final bool infiniteMode;

  /// Multiplier for riches-to-treasury conversion. Default 1.0. Scenario/ruleset
  /// may override (e.g. El Dorado 1.5). Per SPEC/program/turn-resolution-phase-details.md.
  final double richesCashMultiplier;

  /// Land-region grain per turn from capital tile bonus (Great Powers). Copied
  /// from setup starting-resources config at game creation. GDD extraction.
  final int capitalTileGrainBonusPerTurn;

  /// 1-character political map glyph per faction id. Used by map UIs for the
  /// political ownership layer.
  final Map<String, String> politicalGlyphByPlayerId;

  /// Last tech-catalog **category** a human Great Power set for Envy mirror tracking
  /// (most recent): either a completed **research** tech’s `category`, or **gathering**
  /// from a completed extraction **build_improvement** on a tracked resource tile.
  /// JSON keys retain the historical `…Research…` names. SPEC/ai/hidden-agendas.md.
  final String? lastHumanCompletedResearchCategory;

  /// Turn number when [lastHumanCompletedResearchCategory] was last updated.
  final int? lastHumanResearchCategoryCompletionTurn;

  /// Persisted Empire overview map state (zoom + display toggles).
  final MapViewState mapViewState;

  /// World market prices and last-turn activity. SPEC/game/world-market.md,
  /// SPEC/program/world-market-resolution.md. Defaults to
  /// [WorldMarketState.empty]; populated from `ResourceRules.defaultMarketPrice`
  /// at game start via [WorldMarketState.withDefaultPrices].
  final WorldMarketState worldMarketState;

  /// Canonical bilateral FTP pair keys (`factionA|factionB`, sorted).
  /// SPEC/game/world-market.md § Favored Trading Partner.
  final Set<String> ftpPartnershipKeys;

  /// Faction-pair keys that have already consumed their per-turn `/set_diplomacy`
  /// debug-mutation quota this turn (sorted `factionA|factionB`). Cleared on
  /// turn advance. Debug tool only. SPEC/ui/debug-console-panel.md.
  final Set<String> debugDiplomacyUsedPairKeys;

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldState': worldState.toJson(),
    'players': players.map((e) => e.toJson()).toList(),
    'minorNations': minorNations.map((e) => e.toJson()).toList(),
    'tribes': tribes.map((e) => e.toJson()).toList(),
    if (turnTimeMapping != null) 'turnTimeMapping': turnTimeMapping!.toJson(),
    if (defaultCombatMode != null) 'defaultCombatMode': defaultCombatMode!.name,
    if (combatModeByProvinceId.isNotEmpty)
      'combatModeByProvinceId': combatModeByProvinceId.map(
        (k, v) => MapEntry(k, v.name),
      ),
    if (diplomacyRelations.isNotEmpty)
      'diplomacyRelations': diplomacyRelations.map((r) => r.toJson()).toList(),
    if (overtureStates.isNotEmpty)
      'overtureStates': overtureStates.map((o) => o.toJson()).toList(),
    if (subsidyStates.isNotEmpty)
      'subsidyStates': subsidyStates.map((s) => s.toJson()).toList(),
    if (colonyStates.isNotEmpty)
      'colonyStates': colonyStates.map((c) => c.toJson()).toList(),
    if (aiControlByGpId.isNotEmpty) 'aiControlByGpId': aiControlByGpId,
    if (aiSeedByGpId.isNotEmpty) 'aiSeedByGpId': aiSeedByGpId,
    if (aiProfileByGpId.isNotEmpty)
      'aiProfileByGpId': aiProfileByGpId.map((k, v) => MapEntry(k, v)),
    if (hiddenAgendaByGpId.isNotEmpty) 'hiddenAgendaByGpId': hiddenAgendaByGpId,
    if (dossierEvidenceEntries.isNotEmpty)
      'dossierEvidenceEntries': dossierEvidenceEntries
          .map((e) => e.toJson())
          .toList(),
    if (diplomaticHistoryEvents.isNotEmpty)
      'diplomaticHistoryEvents': diplomaticHistoryEvents
          .map((e) => e.toJson())
          .toList(),
    if (globalGameSeed != null) 'globalGameSeed': globalGameSeed,
    if (greatPowerColorOverride != null && greatPowerColorOverride!.isNotEmpty)
      'greatPowerColorOverride': greatPowerColorOverride!.map(
        (k, v) => MapEntry(k, v),
      ),
    if (victory != null) 'victory': victory!.toJson(),
    if (calendarCampaignHalted) 'calendarCampaignHalted': true,
    if (infiniteMode) 'infiniteMode': true,
    if (richesCashMultiplier != 1.0)
      'richesCashMultiplier': richesCashMultiplier,
    if (capitalTileGrainBonusPerTurn != 5)
      'capitalTileGrainBonusPerTurn': capitalTileGrainBonusPerTurn,
    if (generals.isNotEmpty)
      'generals': generals.map((e) => e.toJson()).toList(),
    if (politicalGlyphByPlayerId.isNotEmpty)
      'politicalGlyphByPlayerId': politicalGlyphByPlayerId,
    if (lastHumanCompletedResearchCategory != null)
      'lastHumanCompletedResearchCategory': lastHumanCompletedResearchCategory,
    if (lastHumanResearchCategoryCompletionTurn != null)
      'lastHumanResearchCategoryCompletionTurn':
          lastHumanResearchCategoryCompletionTurn,
    if (mapViewState != MapViewState.defaults)
      'mapViewState': mapViewState.toJson(),
    if (worldMarketState != WorldMarketState.empty)
      'worldMarketState': worldMarketState.toJson(),
    if (ftpPartnershipKeys.isNotEmpty)
      'ftpPartnershipKeys': ftpPartnershipKeys.toList()..sort(),
    if (debugDiplomacyUsedPairKeys.isNotEmpty)
      'debugDiplomacyUsedPairKeys': debugDiplomacyUsedPairKeys.toList()..sort(),
  };

  static List<T> _parseModelList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final list = raw as List<dynamic>? ?? const [];
    return list
        .map(
          (e) =>
              fromJson(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)),
        )
        .toList();
  }

  static Game fromJson(Map<String, dynamic> json) {
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
    final subsidyStates = _parseModelList(
      json['subsidyStates'],
      SubsidyState.fromJson,
    )
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

    final aiControlRaw =
        json['aiControlByGpId'] as Map<dynamic, dynamic>? ?? {};
    final aiControlByGpId = aiControlRaw.map(
      (k, v) => MapEntry(k.toString(), v == true),
    );
    final aiSeedRaw = json['aiSeedByGpId'] as Map<dynamic, dynamic>? ?? {};
    final aiSeedByGpId = aiSeedRaw.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
    final aiProfileRaw =
        json['aiProfileByGpId'] as Map<dynamic, dynamic>? ?? {};
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
              Map<String, dynamic>.from(
                json['victory'] as Map<dynamic, dynamic>,
              ),
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
    );
  }

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
    Map<String, bool>? aiControlByGpId,
    Map<String, int>? aiSeedByGpId,
    Map<String, String?>? aiProfileByGpId,
    Map<String, String>? hiddenAgendaByGpId,
    List<DossierEvidenceEntry>? dossierEvidenceEntries,
    List<DiplomaticEvent>? diplomaticHistoryEvents,
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
  }) {
    return Game(
      id: id ?? this.id,
      worldState: worldState ?? this.worldState,
      players: players ?? this.players,
      minorNations: minorNations ?? this.minorNations,
      tribes: tribes ?? this.tribes,
      generals: generals ?? this.generals,
      turnTimeMapping: turnTimeMapping ?? this.turnTimeMapping,
      defaultCombatMode: defaultCombatMode ?? this.defaultCombatMode,
      combatModeByProvinceId:
          combatModeByProvinceId ?? this.combatModeByProvinceId,
      diplomacyRelations: diplomacyRelations ?? this.diplomacyRelations,
      overtureStates: overtureStates ?? this.overtureStates,
      subsidyStates: subsidyStates ?? this.subsidyStates,
      colonyStates: colonyStates ?? this.colonyStates,
      aiControlByGpId: aiControlByGpId ?? this.aiControlByGpId,
      aiSeedByGpId: aiSeedByGpId ?? this.aiSeedByGpId,
      aiProfileByGpId: aiProfileByGpId ?? this.aiProfileByGpId,
      hiddenAgendaByGpId: hiddenAgendaByGpId ?? this.hiddenAgendaByGpId,
      dossierEvidenceEntries:
          dossierEvidenceEntries ?? this.dossierEvidenceEntries,
      diplomaticHistoryEvents:
          diplomaticHistoryEvents ?? this.diplomaticHistoryEvents,
      globalGameSeed: globalGameSeed ?? this.globalGameSeed,
      greatPowerColorOverride:
          greatPowerColorOverride ?? this.greatPowerColorOverride,
      victory: victory ?? this.victory,
      calendarCampaignHalted:
          calendarCampaignHalted ?? this.calendarCampaignHalted,
      infiniteMode: infiniteMode ?? this.infiniteMode,
      richesCashMultiplier: richesCashMultiplier ?? this.richesCashMultiplier,
      capitalTileGrainBonusPerTurn:
          capitalTileGrainBonusPerTurn ?? this.capitalTileGrainBonusPerTurn,
      politicalGlyphByPlayerId:
          politicalGlyphByPlayerId ?? this.politicalGlyphByPlayerId,
      lastHumanCompletedResearchCategory:
          lastHumanCompletedResearchCategory ??
          this.lastHumanCompletedResearchCategory,
      lastHumanResearchCategoryCompletionTurn:
          lastHumanResearchCategoryCompletionTurn ??
          this.lastHumanResearchCategoryCompletionTurn,
      mapViewState: mapViewState ?? this.mapViewState,
      worldMarketState: worldMarketState ?? this.worldMarketState,
      ftpPartnershipKeys: ftpPartnershipKeys ?? this.ftpPartnershipKeys,
      debugDiplomacyUsedPairKeys:
          debugDiplomacyUsedPairKeys ?? this.debugDiplomacyUsedPairKeys,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          worldState == other.worldState &&
          _listEquals(players, other.players) &&
          _listEquals(minorNations, other.minorNations) &&
          _listEquals(tribes, other.tribes) &&
          _listEquals(generals, other.generals) &&
          turnTimeMapping == other.turnTimeMapping &&
          defaultCombatMode == other.defaultCombatMode &&
          _mapEquals(combatModeByProvinceId, other.combatModeByProvinceId) &&
          _listEquals(diplomacyRelations, other.diplomacyRelations) &&
          _listEquals(overtureStates, other.overtureStates) &&
          _listEquals(subsidyStates, other.subsidyStates) &&
          _listEquals(colonyStates, other.colonyStates) &&
          _mapEquals(aiControlByGpId, other.aiControlByGpId) &&
          _mapEquals(aiSeedByGpId, other.aiSeedByGpId) &&
          _nullableStringMapEquals(aiProfileByGpId, other.aiProfileByGpId) &&
          _mapEquals(hiddenAgendaByGpId, other.hiddenAgendaByGpId) &&
          _listEquals(dossierEvidenceEntries, other.dossierEvidenceEntries) &&
          _listEquals(diplomaticHistoryEvents, other.diplomaticHistoryEvents) &&
          globalGameSeed == other.globalGameSeed &&
          _mapListEquals(
            greatPowerColorOverride,
            other.greatPowerColorOverride,
          ) &&
          victory == other.victory &&
          calendarCampaignHalted == other.calendarCampaignHalted &&
          infiniteMode == other.infiniteMode &&
          richesCashMultiplier == other.richesCashMultiplier &&
          capitalTileGrainBonusPerTurn == other.capitalTileGrainBonusPerTurn &&
          _mapEquals(
            politicalGlyphByPlayerId,
            other.politicalGlyphByPlayerId,
          ) &&
          lastHumanCompletedResearchCategory ==
              other.lastHumanCompletedResearchCategory &&
          lastHumanResearchCategoryCompletionTurn ==
              other.lastHumanResearchCategoryCompletionTurn &&
          mapViewState == other.mapViewState &&
          worldMarketState == other.worldMarketState &&
          _setEquals(ftpPartnershipKeys, other.ftpPartnershipKeys) &&
          _setEquals(
            debugDiplomacyUsedPairKeys,
            other.debugDiplomacyUsedPairKeys,
          );

  @override
  int get hashCode => Object.hash(
    id,
    worldState,
    Object.hashAll(players),
    Object.hashAll(minorNations),
    Object.hashAll(tribes),
    Object.hashAll(generals),
    turnTimeMapping,
    defaultCombatMode,
    Object.hashAll(combatModeByProvinceId.entries),
    Object.hashAll(diplomacyRelations),
    Object.hashAll(overtureStates),
    Object.hash(Object.hashAll(subsidyStates), Object.hashAll(colonyStates)),
    Object.hashAll(aiControlByGpId.entries),
    Object.hashAll(aiSeedByGpId.entries),
    Object.hashAll(aiProfileByGpId.entries),
    Object.hashAll(hiddenAgendaByGpId.entries),
    Object.hash(
      Object.hashAll(dossierEvidenceEntries),
      Object.hashAll(diplomaticHistoryEvents),
    ),
    globalGameSeed,
    greatPowerColorOverride != null
        ? Object.hashAll(greatPowerColorOverride!.entries)
        : null,
    Object.hash(
      victory,
      calendarCampaignHalted,
      infiniteMode,
      richesCashMultiplier,
      capitalTileGrainBonusPerTurn,
      Object.hashAll(politicalGlyphByPlayerId.entries),
      lastHumanCompletedResearchCategory,
      lastHumanResearchCategoryCompletionTurn,
      mapViewState,
      worldMarketState,
      Object.hashAll(ftpPartnershipKeys),
      Object.hashAll(debugDiplomacyUsedPairKeys),
    ),
  );

  static bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  static bool _mapListEquals(
    Map<String, List<int>>? a,
    Map<String, List<int>>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      final ob = b[e.key];
      if (ob == null || ob.length != e.value.length) return false;
      for (var i = 0; i < e.value.length; i++) {
        if (e.value[i] != ob[i]) return false;
      }
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _nullableStringMapEquals(
    Map<String, String?> a,
    Map<String, String?> b,
  ) => _mapEquals(a, b);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
