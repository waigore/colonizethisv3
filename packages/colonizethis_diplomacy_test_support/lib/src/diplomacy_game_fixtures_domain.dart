import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures_base.dart';
import 'diplomacy_relation_fixtures.dart';

/// Favoured trading partner lookup tests (Refs #3753 R7.1, #3825).
Game favouredTradingGame({
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'A', isHuman: false),
    Player(id: 'gpB', displayName: 'B', isHuman: false),
  ],
  List<DiplomacyRelation> relations = const [],
  List<ColonyState> colonyStates = const [],
}) =>
    diplomacyGame(
      id: 'ftp-lookup-test',
      turnNumber: 5,
      players: players,
      diplomacyRelations: relations,
      colonyStates: colonyStates,
    );

/// Trade-deal relation boost tests (Refs #3753 R10, #3825).
Game tradeBoostGame({
  required num score,
  RelationState state = RelationState.atPeace,
  Set<String> completedTradePairKeys = const <String>{},
  List<OvertureState> overtureStates = const <OvertureState>[],
}) =>
    diplomacyGame(
      id: 'trade-boost-test',
      turnNumber: 7,
      diplomacyRelations: [
        peaceRelation('gp1', 'gp2', score, state: state),
      ],
      overtureStates: overtureStates,
      worldMarketState: WorldMarketState(
        completedTradePairKeys: completedTradePairKeys,
      ),
    );

/// Relation lookup score/helper tests (Refs #3290, #3825).
Game relationLookupGame({
  List<Player> players = const [],
  List<Province> oldWorldProvinces = const [],
  List<Fleet> fleets = const [],
  List<DiplomacyRelation> relations = const [],
  List<DiplomaticEvent> history = const [],
  int turnNumber = 1,
}) =>
    diplomacyGame(
      id: 'g',
      turnNumber: turnNumber,
      players: players,
      oldWorld: RegionData(provinces: oldWorldProvinces, units: const []),
      fleets: fleets,
      diplomacyRelations: relations,
      diplomaticHistoryEvents: history,
    );

Province oldWorldOwnedProvince(String localId, String ownerId) => Province(
      id: 'oldWorld|$localId',
      regionId: 'oldWorld',
      ownerId: ownerId,
    );

Fleet diplomacyTestFleet(String id, String ownerId, int ships) => Fleet(
      id: id,
      ownerId: ownerId,
      regionId: 'oldWorld',
      shipTypeIds: List<String>.filled(ships, 'frigate'),
    );

/// `processAlliances` resolver tests (Refs #3290, #3825).
Game allianceResolverGame({
  List<Player> players = const [
    Player(id: 'gp1', displayName: 'A', isHuman: false),
    Player(id: 'gp2', displayName: 'B', isHuman: false),
  ],
  List<DiplomacyRelation> relations = const [],
  List<Tribe> tribes = const [],
}) =>
    diplomacyGame(
      id: 'g',
      turnNumber: 7,
      players: players,
      tribes: tribes,
      diplomacyRelations: relations,
    );

/// Minimal game for intra-turn diplomatic history tests (#3825).
Game diplomacyHistoryGame({
  int turn = 1,
  List<DiplomaticEvent> history = const [],
}) =>
    diplomacyGame(
      id: 'g1',
      turnNumber: turn,
      diplomaticHistoryEvents: history,
    );
