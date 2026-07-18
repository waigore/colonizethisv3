import 'advanced_start_type.dart';
import 'combat_mode.dart';
import 'dossier_evidence.dart';
import 'diplomacy.dart';
import 'game_serialization.dart';
import 'general.dart';
import 'map_view_state.dart';
import 'minor_nation.dart';
import 'model_collection_equality.dart';
import 'player.dart';
import 'tribe.dart';
import 'turn_time_mapping.dart';
import 'victory.dart';
import 'world_market.dart';
import 'world_state.dart';

export 'victory.dart';

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
    this.boycottStates = const [],
    this.allianceBreakCooldowns = const [],
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
    this.advancedStartType,
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

  /// Active boycotts: a colony-holding Great Power blocking all trade between a
  /// target Great Power and the issuer's colonies (Refs #3753 R6).
  /// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
  final List<BoycottState> boycottStates;

  /// Bilateral post-break overture cooldowns keyed by canonical GP pair
  /// (Refs #3811). Active only while `sinceTurn == currentTurn`.
  final List<AllianceBreakCooldownState> allianceBreakCooldowns;

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

  /// Advanced-start preset when the campaign began after turn 0.
  /// Null for standard turn-0 games and legacy saves. SPEC/game/advanced-starts.md.
  final AdvancedStartType? advancedStartType;

  Map<String, dynamic> toJson() => encodeGameToJson(this);

  static Game fromJson(Map<String, dynamic> json) => decodeGameFromJson(json);

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
      boycottStates: boycottStates ?? this.boycottStates,
      allianceBreakCooldowns:
          allianceBreakCooldowns ?? this.allianceBreakCooldowns,
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
      advancedStartType: advancedStartType ?? this.advancedStartType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          worldState == other.worldState &&
          modelListEquals(players, other.players) &&
          modelListEquals(minorNations, other.minorNations) &&
          modelListEquals(tribes, other.tribes) &&
          modelListEquals(generals, other.generals) &&
          turnTimeMapping == other.turnTimeMapping &&
          defaultCombatMode == other.defaultCombatMode &&
          modelMapEquals(
            combatModeByProvinceId,
            other.combatModeByProvinceId,
          ) &&
          modelListEquals(diplomacyRelations, other.diplomacyRelations) &&
          modelListEquals(overtureStates, other.overtureStates) &&
          modelListEquals(subsidyStates, other.subsidyStates) &&
          modelListEquals(colonyStates, other.colonyStates) &&
          modelListEquals(boycottStates, other.boycottStates) &&
          modelListEquals(
            allianceBreakCooldowns,
            other.allianceBreakCooldowns,
          ) &&
          modelMapEquals(aiControlByGpId, other.aiControlByGpId) &&
          modelMapEquals(aiSeedByGpId, other.aiSeedByGpId) &&
          modelMapEquals(aiProfileByGpId, other.aiProfileByGpId) &&
          modelMapEquals(hiddenAgendaByGpId, other.hiddenAgendaByGpId) &&
          modelListEquals(
            dossierEvidenceEntries,
            other.dossierEvidenceEntries,
          ) &&
          modelListEquals(
            diplomaticHistoryEvents,
            other.diplomaticHistoryEvents,
          ) &&
          globalGameSeed == other.globalGameSeed &&
          modelNullableMapOfListEquals(
            greatPowerColorOverride,
            other.greatPowerColorOverride,
          ) &&
          victory == other.victory &&
          calendarCampaignHalted == other.calendarCampaignHalted &&
          infiniteMode == other.infiniteMode &&
          richesCashMultiplier == other.richesCashMultiplier &&
          capitalTileGrainBonusPerTurn == other.capitalTileGrainBonusPerTurn &&
          modelMapEquals(
            politicalGlyphByPlayerId,
            other.politicalGlyphByPlayerId,
          ) &&
          lastHumanCompletedResearchCategory ==
              other.lastHumanCompletedResearchCategory &&
          lastHumanResearchCategoryCompletionTurn ==
              other.lastHumanResearchCategoryCompletionTurn &&
          mapViewState == other.mapViewState &&
          worldMarketState == other.worldMarketState &&
          modelSetEquals(ftpPartnershipKeys, other.ftpPartnershipKeys) &&
          modelSetEquals(
            debugDiplomacyUsedPairKeys,
            other.debugDiplomacyUsedPairKeys,
          ) &&
          advancedStartType == other.advancedStartType;

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
    Object.hash(
      Object.hashAll(subsidyStates),
      Object.hashAll(colonyStates),
      Object.hashAll(boycottStates),
      Object.hashAll(allianceBreakCooldowns),
    ),
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
      advancedStartType,
    ),
  );
}
