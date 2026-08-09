import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const _ctaFourGp = [
  Player(id: 'gp1', displayName: 'GP1', isHuman: false),
  Player(id: 'gp2', displayName: 'GP2', isHuman: false),
  Player(id: 'gp3', displayName: 'GP3', isHuman: false),
  Player(id: 'gp4', displayName: 'GP4', isHuman: false),
];

DiplomacyRelation _ctaRel(
  String a,
  String b, {
  required num score,
  required RelationLevel level,
  RelationState state = RelationState.atPeace,
  bool formalAlliance = false,
  int sinceTurn = 0,
}) =>
    peaceRelation(
      a,
      b,
      score,
      level: level,
      state: state,
      formalAlliance: formalAlliance,
      sinceTurn: sinceTurn,
      lastInteractionTurn: sinceTurn,
    );

/// Shared three-power game fixture for call-to-arms tests (Refs #3625 / #4028).
Game threePowerCallToArmsGame({
  required bool gp1Human,
  required bool gp2Human,
  required int gp1gp2Score,
  RelationLevel gp1gp2Level = RelationLevel.allied,
  bool gp1gp2FormalAlliance = true,
}) =>
    diplomacyGame(
      id: 'g1',
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < kObserverConquestMinOwProvincesPerGp; i++)
            Province(id: 'oldWorld|gp3_$i', regionId: 'oldWorld', ownerId: 'gp3'),
        ],
      ),
      players: [
        Player(id: 'gp1', displayName: 'GP1', isHuman: gp1Human),
        Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
        const Player(id: 'gp3', displayName: 'GP3', isHuman: false),
      ],
      diplomacyRelations: [
        _ctaRel(
          'gp1',
          'gp2',
          score: gp1gp2Score,
          level: gp1gp2Level,
          formalAlliance: gp1gp2FormalAlliance,
        ),
        _ctaRel('gp2', 'gp3', score: 50, level: RelationLevel.neutral),
        _ctaRel('gp1', 'gp3', score: 50, level: RelationLevel.neutral),
      ],
    );

/// Four-GP call-to-arms game where gp1 is allied with gp2 but at war with gp3.
Game fourGpCallToArmsAtWarGame() => diplomacyGame(
      id: 'g-multi',
      turnNumber: 25,
      players: _ctaFourGp,
      diplomacyRelations: [
        _ctaRel(
          'gp1',
          'gp2',
          score: 80,
          level: RelationLevel.allied,
          formalAlliance: true,
        ),
        _ctaRel(
          'gp1',
          'gp3',
          score: 0,
          level: RelationLevel.hostile,
          state: RelationState.atWar,
          sinceTurn: 1,
        ),
        _ctaRel('gp2', 'gp4', score: 50, level: RelationLevel.neutral),
      ],
    );

/// Four-GP cascade penalty game for human refuse call-to-arms (Refs #3825).
Game fourGpCallToArmsCascadeGame() => diplomacyGame(
      id: 'g-cascade',
      turnNumber: 5,
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
        Player(id: 'gp4', displayName: 'GP4', isHuman: false),
      ],
      diplomacyRelations: [
        _ctaRel(
          'gp1',
          'gp2',
          score: 80,
          level: RelationLevel.allied,
          formalAlliance: true,
        ),
        _ctaRel('gp1', 'gp3', score: 60, level: RelationLevel.friendly),
        _ctaRel('gp1', 'gp4', score: 60, level: RelationLevel.friendly),
      ],
    );

/// Three-power game for isolationist evidence-rule scenarios (Refs #4130).
Game ctaRefuseEvidenceGame({
  required bool allyIsAi,
  required bool atPeaceWithDefender,
}) =>
    diplomacyGame(
      turnNumber: 3,
      players: [
        const Player(id: 'observer', displayName: 'Human', isHuman: true),
        Player(id: 'ally', displayName: 'Ally', isHuman: !allyIsAi),
        const Player(id: 'defender', displayName: 'Defender', isHuman: false),
      ],
      diplomacyRelations: [
        peaceRelation(
          'ally',
          'defender',
          50,
          level: RelationLevel.friendly,
          state: atPeaceWithDefender ? RelationState.atPeace : RelationState.atWar,
        ),
      ],
    );
