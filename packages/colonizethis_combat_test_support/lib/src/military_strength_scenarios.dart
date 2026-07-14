// Table-driven military-strength scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

/// One row in a military-strength scenario table.
class MilitaryStrengthScenario implements LabeledScenario {
  const MilitaryStrengthScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  @override
  final String label;
  final void Function() run;
}


/// Scenarios for [aggregateMilitaryStrengthForPlayer].
List<MilitaryStrengthScenario> aggregateMilitaryStrengthForPlayerScenarios() => [
  ..._aggregateMilitaryStrengthForPlayerFactionScenarios(),
  ..._aggregateMilitaryStrengthForPlayerFilteringScenarios(),
  ..._aggregateMilitaryStrengthForPlayerMultiplierScenarios(),
];

List<MilitaryStrengthScenario>
_aggregateMilitaryStrengthForPlayerFactionScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'ms-empty-army',
    label: 'returns 0 for empty army',
    run: () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(0.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-gp-medals',
    label: 'calculates strength for Great Power units with medals',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers', medals: 2),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, closeTo(30.6, 0.1));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-minor-era',
    label: 'uses effective military level for Minor Nation',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(
            id: 'u1',
            type: 'peasant_levies',
            ownerId: 'minor1',
            locationProvinceId: 'p1',
          ),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor Nation',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'minor1');
      expect(strength, equals(3.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-tribe-era',
    label: 'uses effective military level for Tribe',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(
            id: 'u1',
            type: 'cossacks',
            ownerId: 'tribe1',
            locationProvinceId: 'p1',
          ),
        ],
        tribes: const [
          Tribe(
            id: 'tribe1',
            displayName: 'Tribe',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'tribe1');
      expect(strength, greaterThan(0.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-gp-era4',
    label: 'Great Power uses era 4 (does not downgrade era 3 units)',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(18.0));
    },
  ),
];

List<MilitaryStrengthScenario>
_aggregateMilitaryStrengthForPlayerFilteringScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'ms-unknown-regiment',
    label: 'skips units with unknown regiment types',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'unknown_unit_type'),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(9.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-ow-nw',
    label: 'aggregates units from both Old World and New World',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'musketeers'),
        ],
        newWorldUnits: [
          testUnit(
            id: 'u2',
            type: 'musketeers',
            locationProvinceId: 'new_york',
          ),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(18.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-owner-filter',
    label: 'only includes units owned by the specified player',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'musketeers'),
          testUnit(
            id: 'u2',
            type: 'musketeers',
            ownerId: 'prussia',
            locationProvinceId: 'berlin',
          ),
        ],
        players: const [
          franceGreatPower,
          Player(id: 'prussia', displayName: 'Prussia', isHuman: false),
        ],
      );

      final franceStrength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(franceStrength, equals(9.0));

      final prussiaStrength = aggregateMilitaryStrengthForPlayer(
        game,
        'prussia',
      );
      expect(prussiaStrength, equals(9.0));
    },
  ),
];

List<MilitaryStrengthScenario>
_aggregateMilitaryStrengthForPlayerMultiplierScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'ms-medal-multipliers',
    label: 'applies medal multiplier correctly (0-4 medals)',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u0', type: 'musketeers', locationProvinceId: 'p0'),
          testUnit(
            id: 'u1',
            type: 'musketeers',
            locationProvinceId: 'p1',
            medals: 1,
          ),
          testUnit(
            id: 'u2',
            type: 'musketeers',
            locationProvinceId: 'p2',
            medals: 2,
          ),
          testUnit(
            id: 'u3',
            type: 'musketeers',
            locationProvinceId: 'p3',
            medals: 3,
          ),
          testUnit(
            id: 'u4',
            type: 'musketeers',
            locationProvinceId: 'p4',
            medals: 4,
          ),
          testUnit(
            id: 'u5',
            type: 'musketeers',
            locationProvinceId: 'p5',
            medals: 10,
          ),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, closeTo(66.6, 0.1));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-deterministic',
    label: 'is deterministic - same inputs produce same output',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers', medals: 3),
        ],
        players: const [franceGreatPower],
      );

      final strength1 = aggregateMilitaryStrengthForPlayer(game, 'france');
      final strength2 = aggregateMilitaryStrengthForPlayer(game, 'france');
      final strength3 = aggregateMilitaryStrengthForPlayer(game, 'france');

      expect(strength1, equals(strength2));
      expect(strength2, equals(strength3));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'ms-non-negative',
    label: 'returns non-negative value',
    run: () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, greaterThanOrEqualTo(0.0));
    },
  ),
];

/// Scenarios for [aggregateStrength].
List<MilitaryStrengthScenario> aggregateStrengthScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'as-list-units',
    label: 'aggregates strength for a list of units',
    run: () {
      final units = [
        testUnit(id: 'u1', type: 'musketeers', locationProvinceId: 'p1'),
        testUnit(id: 'u2', type: 'grenadiers', locationProvinceId: 'p2'),
      ];

      final strength = aggregateStrength(units, 4);
      expect(strength, equals(27.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'as-era-downgrade',
    label: 'downgrades units when era exceeds effective era',
    run: () {
      final units = [
        testUnit(id: 'u1', type: 'grenadiers', locationProvinceId: 'p1'),
      ];

      final strength = aggregateStrength(units, 1);
      expect(strength, greaterThan(0.0));
    },
  ),
];

/// Scenarios for [effectiveEraForFaction].
List<MilitaryStrengthScenario> effectiveEraForFactionScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'eef-gp',
    label: 'returns 4 for Great Power',
    run: () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      expect(effectiveEraForFaction(game, 'france'), equals(4));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'eef-minor',
    label: 'returns effectiveMilitaryLevel for Minor Nation',
    run: () {
      final game = militaryStrengthGame(
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor',
            effectiveMilitaryLevel: 2,
          ),
        ],
      );

      expect(effectiveEraForFaction(game, 'minor1'), equals(2));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'eef-tribe',
    label: 'returns effectiveMilitaryLevel for Tribe (capped at 1 in-game)',
    run: () {
      final game = militaryStrengthGame(
        tribes: const [
          Tribe(
            id: 'tribe1',
            displayName: 'Tribe',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      expect(effectiveEraForFaction(game, 'tribe1'), equals(1));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'eef-unknown',
    label: 'returns 4 for unknown faction',
    run: () {
      final game = militaryStrengthGame();

      expect(effectiveEraForFaction(game, 'unknown'), equals(4));
    },
  ),
];

/// Scenarios for [cavalryFraction].
List<MilitaryStrengthScenario> cavalryFractionScenarios() => [
  MilitaryStrengthScenario(
    scenarioId: 'cf-empty',
    label: 'returns 0 when unit list is empty',
    run: () {
      expect(cavalryFraction([], {}), equals(0.0));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'cf-share',
    label: 'counts cavalry share over all unit ids',
    run: () {
      final unitsById = {
        'u1': testUnit(id: 'u1', type: 'squires', locationProvinceId: 'p1'),
        'u2': testUnit(id: 'u2', type: 'musketeers', locationProvinceId: 'p2'),
      };

      expect(cavalryFraction(['u1', 'u2'], unitsById), equals(0.5));
    },
  ),
  MilitaryStrengthScenario(
    scenarioId: 'cf-missing-denominator',
    label: 'missing units still count toward denominator',
    run: () {
      final unitsById = {
        'u1': testUnit(id: 'u1', type: 'squires', locationProvinceId: 'p1'),
      };

      expect(cavalryFraction(['u1', 'missing'], unitsById), equals(0.5));
    },
  ),
];
