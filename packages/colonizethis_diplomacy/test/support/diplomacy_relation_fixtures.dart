import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures.dart';

/// Canonical [DiplomacyRelation] builder for diplomacy tests (Refs #3825).
DiplomacyRelation peaceRelation(
  String factionId1,
  String factionId2,
  num score, {
  RelationLevel? level,
  RelationState state = RelationState.atPeace,
  bool formalAlliance = false,
  int? sinceTurn,
  int? lastInteractionTurn,
}) {
  final ids = canonicalPairIds(factionId1, factionId2);
  return DiplomacyRelation(
    factionId1: ids.id1,
    factionId2: ids.id2,
    score: score,
    level: level ?? scoreToLevel(score),
    state: state,
    sinceTurn: sinceTurn ?? 0,
    lastInteractionTurn: lastInteractionTurn ?? 0,
    formalAlliance: formalAlliance,
  );
}

/// Short alias for [peaceRelation] (upsert-index and relation-list tests).
DiplomacyRelation rel(
  String factionId1,
  String factionId2,
  num score, {
  RelationLevel? level,
  RelationState state = RelationState.atPeace,
  bool formalAlliance = false,
  int? sinceTurn,
  int? lastInteractionTurn,
}) =>
    peaceRelation(
      factionId1,
      factionId2,
      score,
      level: level,
      state: state,
      formalAlliance: formalAlliance,
      sinceTurn: sinceTurn,
      lastInteractionTurn: lastInteractionTurn,
    );

/// Minimal game for relation-only unit tests (no province topology).
Game relationsOnlyGame({
  String id = 't',
  int turnNumber = 1,
  List<DiplomacyRelation> relations = const [],
  List<OvertureState> overtureStates = const [],
  List<Player> players = const [],
  RegionData? oldWorld,
  RegionData? newWorld,
}) =>
    diplomacyGame(
      id: id,
      turnNumber: turnNumber,
      players: players,
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: newWorld ?? const RegionData(),
      diplomacyRelations: relations,
      overtureStates: overtureStates,
    );

/// Default gp1–gp2 relation row for decay and modifier tests.
DiplomacyRelation gp1gp2Relation(
  num score, {
  RelationState state = RelationState.atPeace,
}) =>
    peaceRelation('gp1', 'gp2', score, state: state);

/// Two-GP game with a relation list for decay integration tests.
Game gp1gp2DecayGame(
  List<DiplomacyRelation> relations, {
  String id = 'decay-test',
  int turnNumber = 5,
}) =>
    relationsOnlyGame(
      id: id,
      turnNumber: turnNumber,
      players: defaultTwoGpPlayers,
      relations: relations,
    );

/// Shortcut for resolver tests that need [DiplomacyFactionMembership].
DiplomacyFactionMembership diplomacyFactionMembership(Game game) =>
    DiplomacyFactionMembership.from(game);

/// Linear-scan relation lookup for asserting list equality in upsert tests.
DiplomacyRelation? getRelationFromList(
  List<DiplomacyRelation> relations,
  String factionId1,
  String factionId2,
) {
  final key = pairKey(factionId1, factionId2);
  for (final r in relations) {
    if (pairKey(r.factionId1, r.factionId2) == key) return r;
  }
  return null;
}
