import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared three-power game fixture for call-to-arms (alliance mutual defence)
/// tests. Extracted so the call-to-arms suites stay within the split
/// domain-package test file size cap (Refs #3625).
///
/// Built on [TestFixtures.minimalGame] (Refs #3715): the previous inline
/// `Game`/`WorldState` builder matched `minimalGame` with empty New World and an
/// orders-phase turn 1, so only the GP3-owned Old World provinces, the three
/// players, and the diplomacy relations remain expressed here.
Game threePowerCallToArmsGame({
  required bool gp1Human,
  required bool gp2Human,
  required int gp1gp2Score,
  RelationLevel gp1gp2Level = RelationLevel.allied,
  bool gp1gp2FormalAlliance = true,
}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    oldWorld: RegionData(
      provinces: [
        for (var i = 0; i < kObserverConquestMinOwProvincesPerGp; i++)
          Province(
            id: 'oldWorld|gp3_$i',
            regionId: 'oldWorld',
            ownerId: 'gp3',
          ),
      ],
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: gp1Human,
      ),
      Player(
        id: 'gp2',
        displayName: 'GP2',
        isHuman: gp2Human,
      ),
      Player(
        id: 'gp3',
        displayName: 'GP3',
        isHuman: false,
      ),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: gp1gp2Score,
        level: gp1gp2Level,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
        formalAlliance: gp1gp2FormalAlliance,
      ),
      DiplomacyRelation(
        factionId1: 'gp2',
        factionId2: 'gp3',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp3',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}

/// Four-GP call-to-arms game where gp1 is allied with gp2 but at war with gp3.
Game fourGpCallToArmsAtWarGame() => TestFixtures.minimalGame(
      id: 'g-multi',
      turnNumber: 25,
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        Player(id: 'gp4', displayName: 'GP4', isHuman: false),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 80,
          level: RelationLevel.allied,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp3',
          score: 0,
          level: RelationLevel.hostile,
          state: RelationState.atWar,
          sinceTurn: 1,
          lastInteractionTurn: 1,
        ),
        DiplomacyRelation(
          factionId1: 'gp2',
          factionId2: 'gp4',
          score: 50,
          level: RelationLevel.neutral,
          state: RelationState.atPeace,
          sinceTurn: 0,
          lastInteractionTurn: 0,
        ),
      ],
    );

/// Four-GP cascade penalty game for human refuse call-to-arms (Refs #3825).
Game fourGpCallToArmsCascadeGame() => TestFixtures.minimalGame(
      id: 'g-cascade',
      turnNumber: 5,
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        Player(id: 'gp4', displayName: 'GP4', isHuman: false),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 80,
          level: RelationLevel.allied,
          state: RelationState.atPeace,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp3',
          score: 60,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp4',
          score: 60,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
      ],
    );
