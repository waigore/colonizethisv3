import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures_base.dart';

/// Embassy overture from gp1 to minor1 used across phase and subsidy tests.
const gpMinorEmbassyOverture = OvertureState(
  gpId: 'gp1',
  targetId: 'minor1',
  stage: OvertureStage.embassy,
  sinceTurn: 0,
);

const _minor1 = MinorNation(id: 'minor1', displayName: 'Minor 1');
const _defaultSubsidy = [SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 10)];

const _gpMutualEmbassy = [
  OvertureState(gpId: 'gp1', targetId: 'gp2', stage: OvertureStage.embassy),
  OvertureState(gpId: 'gp2', targetId: 'gp1', stage: OvertureStage.embassy),
];

const _aiInvestorMinorEmbassies = [
  OvertureState(gpId: 'gp_ai', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
  OvertureState(gpId: 'gp_ai', targetId: 'minor2', stage: OvertureStage.embassy, sinceTurn: 0),
];

Player _gp1Treasury(int treasury, {bool expertise = false}) => Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      treasury: treasury,
      techUnlocked: expertise ? const {kTechIdDiplomaticExpertise: true} : null,
    );

/// Neutral gp1–minor relation row for subsidy and grant-aid scenarios.
DiplomacyRelation gpMinorNeutralRelation({
  String minorId = 'minor1',
  int score = 50,
}) =>
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: minorId,
      score: score,
      level: RelationLevel.neutral,
    );

/// GP + Minor with embassy overture for subsidy and grant-aid tests.
Game gpMinorEmbassySubsidyGame({
  String id = 'g1',
  int turnNumber = 2,
  int gp1Treasury = 10_000,
  RelationState relationState = RelationState.atPeace,
  List<OvertureState> overtureStates = const [gpMinorEmbassyOverture],
  List<SubsidyState> subsidyStates = _defaultSubsidy,
  bool includeSubsidy = true,
  bool includeDiplomaticExpertiseTech = false,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [_gp1Treasury(gp1Treasury, expertise: includeDiplomaticExpertiseTech)],
      minorNations: const [_minor1],
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
  bool gp2Human = false,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [
        const Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: relationScore,
          level: RelationLevel.friendly,
        ),
      ],
      overtureStates: _gpMutualEmbassy,
      ftpPartnershipKeys: existingFtpKeys,
    );

/// Intervention dedup: one aggressor GP, one AI investor, two minors at war.
Game twoMinorWarGame({String id = 'g', int turnNumber = 4}) => diplomacyGame(
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
      overtureStates: _aiInvestorMinorEmbassies,
      diplomacyRelations: const [
        DiplomacyRelation(factionId1: 'gp_attacker', factionId2: 'minor1', state: RelationState.atPeace),
        DiplomacyRelation(factionId1: 'gp_attacker', factionId2: 'minor2', state: RelationState.atPeace),
      ],
    );

/// Boycott resolver tests: two GPs, optional colony, relation, boycotts/subsidies.
Game boycottResolverGame({
  bool gp1HoldsColony = true,
  RelationState gp1gp2State = RelationState.atPeace,
  List<BoycottState> boycotts = const [],
  List<SubsidyState> subsidies = const [],
}) =>
    diplomacyGame(
      id: 'g-boycott',
      turnNumber: 7,
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      diplomacyRelations: [
        DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: gp1gp2State),
      ],
      colonyStates: gp1HoldsColony
          ? const [ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1)]
          : const [],
      boycottStates: boycotts,
      subsidyStates: subsidies,
    );

/// Boycott blocked-trade-pair helper tests: GPs, colonies, and boycott rows.
Game boycottKeysGame({
  List<ColonyState> colonies = const [],
  List<BoycottState> boycotts = const [],
}) =>
    diplomacyGame(
      id: 'g-boycott-keys',
      turnNumber: 3,
      players: const [
        Player(id: 'gpA', displayName: 'A', isHuman: false),
        Player(id: 'gpB', displayName: 'B', isHuman: false),
      ],
      colonyStates: colonies,
      boycottStates: boycotts,
    );

const _minor2Embassy = OvertureState(
  gpId: 'gp1',
  targetId: 'minor2',
  stage: OvertureStage.embassy,
  sinceTurn: 0,
);

/// GP with embassy overtures to two minors for multi-target subsidy tests.
Game gpTwoMinorsEmbassySubsidyGame({
  String id = 'g-two-minors',
  int turnNumber = 1,
  int gp1Treasury = 10_000,
  bool includeDiplomaticExpertiseTech = true,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: [_gp1Treasury(gp1Treasury, expertise: includeDiplomaticExpertiseTech)],
      minorNations: const [
        _minor1,
        MinorNation(id: 'minor2', displayName: 'Minor 2'),
      ],
      diplomacyRelations: [
        gpMinorNeutralRelation(),
        gpMinorNeutralRelation(minorId: 'minor2'),
      ],
      overtureStates: const [gpMinorEmbassyOverture, _minor2Embassy],
    );
