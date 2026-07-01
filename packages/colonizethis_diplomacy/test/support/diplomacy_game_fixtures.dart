import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Default two-GP player row used by most diplomacy resolver tests.
const defaultTwoGpPlayers = <Player>[
  Player(id: 'gp1', displayName: 'GP1', isHuman: false),
  Player(id: 'gp2', displayName: 'GP2', isHuman: false),
];

/// Flexible base for diplomacy tests on shared [TestFixtures.minimalGame].
///
/// Refs #3825 (centralize inline `Game(` constructors).
Game diplomacyGame({
  String id = 'g',
  TurnPhase phase = TurnPhase.orders,
  int turnNumber = 1,
  List<Player> players = defaultTwoGpPlayers,
  RegionData? oldWorld,
  RegionData? newWorld,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
  Map<String, Map<String, String>>? playerVisibilityByTile,
  List<Fleet> fleets = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<OvertureState> overtureStates = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<SubsidyState> subsidyStates = const [],
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
  List<AllianceBreakCooldownState> allianceBreakCooldowns = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
  Map<String, bool> aiControlByGpId = const {},
  Set<String> ftpPartnershipKeys = const {},
  WorldMarketState? worldMarketState,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) {
  final base = TestFixtures.minimalGame(
    id: id,
    phase: phase,
    turnNumber: turnNumber,
    players: players,
    oldWorld: oldWorld,
    newWorld: newWorld,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    playerVisibilityByTile: playerVisibilityByTile,
    fleets: fleets,
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );
  return base.copyWith(
    subsidyStates: subsidyStates.isEmpty ? base.subsidyStates : subsidyStates,
    colonyStates: colonyStates.isEmpty ? base.colonyStates : colonyStates,
    boycottStates: boycottStates.isEmpty ? base.boycottStates : boycottStates,
    allianceBreakCooldowns: allianceBreakCooldowns.isEmpty
        ? base.allianceBreakCooldowns
        : allianceBreakCooldowns,
    diplomaticHistoryEvents: diplomaticHistoryEvents.isEmpty
        ? base.diplomaticHistoryEvents
        : diplomaticHistoryEvents,
    aiControlByGpId:
        aiControlByGpId.isEmpty ? base.aiControlByGpId : aiControlByGpId,
    ftpPartnershipKeys: ftpPartnershipKeys.isEmpty
        ? base.ftpPartnershipKeys
        : ftpPartnershipKeys,
    worldMarketState: worldMarketState ?? base.worldMarketState,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory ??
        base.lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn ??
            base.lastHumanResearchCategoryCompletionTurn,
  );
}

/// Two-GP game with optional alliance cooldown, overture, and relation state.
Game twoGpGame({
  String id = 'g',
  int turnNumber = 5,
  List<Player> players = const [
    Player(id: 'gp1', displayName: 'A', isHuman: true),
    Player(id: 'gp2', displayName: 'B', isHuman: false),
  ],
  List<DiplomacyRelation> diplomacyRelations = const [
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: 'gp2',
      score: 80,
      formalAlliance: true,
    ),
  ],
  List<AllianceBreakCooldownState> allianceBreakCooldowns = const [],
  List<OvertureState> overtureStates = const [],
  Set<String> ftpPartnershipKeys = const {},
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: players,
      diplomacyRelations: diplomacyRelations,
      allianceBreakCooldowns: allianceBreakCooldowns,
      overtureStates: overtureStates,
      ftpPartnershipKeys: ftpPartnershipKeys,
    );

/// Two GPs with configurable overture row and relation state (GP–GP war rules).
Game twoGpGpWarOvertureGame({
  required List<OvertureState> overtureStates,
  RelationState relationState = RelationState.atPeace,
  int turnNumber = 1,
}) =>
    twoGpGame(
      turnNumber: turnNumber,
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: relationState,
          score: 50,
        ),
      ],
      overtureStates: overtureStates,
    );

/// Two-GP game for pending-human-decision resolver flow tests (Refs #3562).
Game twoGpPendingFlowGame({
  required bool targetHuman,
  required int score,
  List<OvertureState> overtures = const [],
  Set<String> ftpKeys = const {},
  int gp1Treasury = 0,
}) =>
    diplomacyGame(
      id: 'pending-flow',
      turnNumber: 2,
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: false,
          treasury: gp1Treasury,
        ),
        Player(id: 'gp2', displayName: 'GP2', isHuman: targetHuman),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: score,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
      ],
      overtureStates: overtures,
      ftpPartnershipKeys: ftpKeys,
    );

/// Two-GP game with per-player fleet ship counts (power-score tests).
Game twoGpGameWithFleets({
  required List<String> shipTypesGp1,
  required List<String> shipTypesGp2,
  String id = 'g',
  int turnNumber = 1,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: true),
        Player(id: 'gp2', displayName: 'B', isHuman: true),
      ],
      fleets: [
        Fleet(
          id: 'f1',
          ownerId: 'gp1',
          regionId: 'oldWorld',
          shipTypeIds: shipTypesGp1,
        ),
        Fleet(
          id: 'f2',
          ownerId: 'gp2',
          regionId: 'oldWorld',
          shipTypeIds: shipTypesGp2,
        ),
      ],
      diplomacyRelations: const [],
    );

/// Four-GP game for voluntary alliance-break resolver tests (R11).
Game fourGpGame({
  String id = 'g-break',
  int turnNumber = 10,
  required int gp1gp2Score,
  required bool gp1gp2FormalAlliance,
  RelationState gp1gp2State = RelationState.atPeace,
  int gp1gp3Score = 60,
  int gp1gp4Score = 60,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        Player(id: 'gp4', displayName: 'GP4', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: gp1gp2Score,
          level: scoreToLevel(gp1gp2Score),
          state: gp1gp2State,
          sinceTurn: 0,
          lastInteractionTurn: 0,
          formalAlliance: gp1gp2FormalAlliance,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp3',
          score: gp1gp3Score,
          level: scoreToLevel(gp1gp3Score),
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp4',
          score: gp1gp4Score,
          level: scoreToLevel(gp1gp4Score),
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
        const DiplomacyRelation(
          factionId1: 'gp2',
          factionId2: 'gp3',
          score: 50,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
      ],
    );

/// Four-GP game for alliance-break × decay integration tests (Refs #3753 S17).
Game fourGpBreakDecayGame({
  String id = 'g-break-decay',
  int turnNumber = 10,
  required num gp1gp2Score,
  required num gp1gp3Score,
  required num gp1gp4Score,
  required num gp2gp3Score,
}) {
  DiplomacyRelation rel(
    String a,
    String b,
    num score, {
    bool formalAlliance = false,
  }) {
    final ids = canonicalPairIds(a, b);
    return DiplomacyRelation(
      factionId1: ids.id1,
      factionId2: ids.id2,
      score: score,
      level: scoreToLevel(score),
      state: RelationState.atPeace,
      sinceTurn: 0,
      lastInteractionTurn: 0,
      formalAlliance: formalAlliance,
    );
  }

  return diplomacyGame(
    id: id,
    turnNumber: turnNumber,
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      Player(id: 'gp3', displayName: 'GP3', isHuman: false),
      Player(id: 'gp4', displayName: 'GP4', isHuman: false),
    ],
    diplomacyRelations: [
      rel('gp1', 'gp2', gp1gp2Score, formalAlliance: true),
      rel('gp1', 'gp3', gp1gp3Score),
      rel('gp1', 'gp4', gp1gp4Score),
      rel('gp2', 'gp3', gp2gp3Score),
    ],
  );
}

/// Shared entry for subsidy resolver tests (alias for [gpMinorEmbassySubsidyGame]).
Game subsidyResolverGame({
  String id = 'g1',
  int turnNumber = 2,
  int gp1Treasury = 10_000,
  RelationState relationState = RelationState.atPeace,
  List<OvertureState> overtureStates = const [
    OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    ),
  ],
  List<SubsidyState> subsidyStates = const [
    SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
  ],
  bool includeSubsidy = true,
  bool includeDiplomaticExpertiseTech = false,
}) =>
    gpMinorEmbassySubsidyGame(
      id: id,
      turnNumber: turnNumber,
      gp1Treasury: gp1Treasury,
      relationState: relationState,
      overtureStates: overtureStates,
      subsidyStates: subsidyStates,
      includeSubsidy: includeSubsidy,
      includeDiplomaticExpertiseTech: includeDiplomaticExpertiseTech,
    );

/// Minimal game with configurable overtures for overture-clear helper tests.
Game diplomacyGameWithOvertures(List<OvertureState> overtures) =>
    TestFixtures.minimalGame(
      players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      overtureStates: overtures,
    );

/// GP + Minor with embassy overture for subsidy and grant-aid tests.
Game gpMinorEmbassySubsidyGame({
  String id = 'g1',
  int turnNumber = 2,
  int gp1Treasury = 10_000,
  RelationState relationState = RelationState.atPeace,
  List<OvertureState> overtureStates = const [
    OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.embassy,
      sinceTurn: 0,
    ),
  ],
  List<SubsidyState> subsidyStates = const [
    SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10),
  ],
  bool includeSubsidy = true,
  bool includeDiplomaticExpertiseTech = false,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: true,
          treasury: gp1Treasury,
          techUnlocked: includeDiplomaticExpertiseTech
              ? const {kTechIdDiplomaticExpertise: true}
              : null,
        ),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          state: relationState,
          score: 50,
        ),
      ],
      overtureStates: overtureStates,
      subsidyStates: includeSubsidy ? subsidyStates : const [],
    );

/// Two GPs with mutual embassy overtures (FTP resolver tests).
Game gpGpEmbassyGame({
  String id = 'ftp-test',
  int turnNumber = 3,
  int relationScore = 70,
  Set<String> existingFtpKeys = const {},
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: relationScore,
          level: RelationLevel.friendly,
        ),
      ],
      overtureStates: const [
        OvertureState(
          gpId: 'gp1',
          targetId: 'gp2',
          stage: OvertureStage.embassy,
        ),
        OvertureState(
          gpId: 'gp2',
          targetId: 'gp1',
          stage: OvertureStage.embassy,
        ),
      ],
      ftpPartnershipKeys: existingFtpKeys,
    );

/// Intervention dedup: one aggressor GP, one AI investor, two minors at war.
Game twoMinorWarGame({
  String id = 'g',
  int turnNumber = 4,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: const [
        Player(id: 'gp_attacker', displayName: 'Aggressor', isHuman: false),
        Player(id: 'gp_ai', displayName: 'AI Investor', isHuman: false),
      ],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'Minor 1'),
        MinorNation(id: 'minor2', displayName: 'Minor 2'),
      ],
      overtureStates: const [
        OvertureState(
          gpId: 'gp_ai',
          targetId: 'minor1',
          stage: OvertureStage.embassy,
          sinceTurn: 0,
        ),
        OvertureState(
          gpId: 'gp_ai',
          targetId: 'minor2',
          stage: OvertureStage.embassy,
          sinceTurn: 0,
        ),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp_attacker',
          factionId2: 'minor1',
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp_attacker',
          factionId2: 'minor2',
          state: RelationState.atPeace,
        ),
      ],
    );

/// Shared `Game` fixture for dossier evidence rule tests (`test/dossier/`).
///
/// Builds on [TestFixtures.minimalGame] (Refs #3715, #3825).
Game evidenceGame({
  String id = 'g1',
  int turnNumber = 2,
  required List<Player> players,
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<DiplomaticEvent> diplomaticHistoryEvents = const [],
  Map<String, bool> aiControlByGpId = const {},
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: players,
      diplomacyRelations: diplomacyRelations,
      diplomaticHistoryEvents: diplomaticHistoryEvents,
      aiControlByGpId: aiControlByGpId,
      lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
      lastHumanResearchCategoryCompletionTurn:
          lastHumanResearchCategoryCompletionTurn,
    );
