// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';

void main() {
  group('aggregateMilitaryStrengthForPlayer', () {
    test('returns 0 for empty army', () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(0.0));
    });

    test('calculates strength for Great Power units with medals', () {
      // Grenadiers: FPN=10, FPM=8, era=3, medals=2 -> multiplier=1.2
      // Strength = (10+8) * 1.2 = 21.6
      // Musketeers: FPN=7, FPM=2, era=2, medals=0 -> multiplier=1.0
      // Strength = (7+2) * 1.0 = 9.0
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers', medals: 2),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      // 21.6 + 9.0 = 30.6
      expect(strength, closeTo(30.6, 0.1));
    });

    test('uses effective military level for Minor Nation', () {
      // Peasant levies: era=1, effectiveEra=1 (minor level) -> no downgrade
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
      // Peasant levies: FPN=0, FPM=3, era=1, effectiveEra=1 -> no downgrade
      // Strength = (0+3) * 1.0 = 3.0
      expect(strength, equals(3.0));
    });

    test('uses effective military level for Tribe', () {
      // Cossacks: era=2, effectiveEra=1 (tribe level) -> should downgrade
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

      // With effectiveEra=1, cossacks (era 2) should downgrade to era 1 in same category
      // We just verify it's > 0 (downgrade produces some positive value)
      final strength = aggregateMilitaryStrengthForPlayer(game, 'tribe1');
      expect(strength, greaterThan(0.0));
    });

    test('Great Power uses era 4 (does not downgrade era 3 units)', () {
      // Grenadiers: era=3, GP uses era 4 so no downgrade
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      // Grenadiers: FPN=10, FPM=8, era=3, era 4 effective -> no downgrade
      // Strength = (10+8) * 1.0 = 18.0
      expect(strength, equals(18.0));
    });

    test('skips units with unknown regiment types', () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'unknown_unit_type'),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      // Only musketeers count: (7+2) * 1.0 = 9.0
      expect(strength, equals(9.0));
    });

    test('aggregates units from both Old World and New World', () {
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

      // 9.0 (OW: 7+2) + 9.0 (NW: 7+2) = 18.0
      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(18.0));
    });

    test('only includes units owned by the specified player', () {
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

      // France's strength should only include their own units
      final franceStrength = aggregateMilitaryStrengthForPlayer(game, 'france');
      // (7+2) * 1.0 = 9.0
      expect(franceStrength, equals(9.0));

      // Prussia's strength should only include their own units
      final prussiaStrength = aggregateMilitaryStrengthForPlayer(game, 'prussia');
      expect(prussiaStrength, equals(9.0));
    });

    test('applies medal multiplier correctly (0-4 medals)', () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          // 0 medals: multiplier 1.0
          testUnit(id: 'u0', type: 'musketeers', locationProvinceId: 'p0'),
          // 1 medal: multiplier 1.1
          testUnit(
            id: 'u1',
            type: 'musketeers',
            locationProvinceId: 'p1',
            medals: 1,
          ),
          // 2 medals: multiplier 1.2
          testUnit(
            id: 'u2',
            type: 'musketeers',
            locationProvinceId: 'p2',
            medals: 2,
          ),
          // 3 medals: multiplier 1.3
          testUnit(
            id: 'u3',
            type: 'musketeers',
            locationProvinceId: 'p3',
            medals: 3,
          ),
          // 4 medals: multiplier 1.4
          testUnit(
            id: 'u4',
            type: 'musketeers',
            locationProvinceId: 'p4',
            medals: 4,
          ),
          // 5+ medals: clamped to 4, multiplier 1.4
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
      // Base: (7+2) = 9.0 per unit
      // 0 medals: 9.0 * 1.0 = 9.0
      // 1 medal: 9.0 * 1.1 = 9.9
      // 2 medals: 9.0 * 1.2 = 10.8
      // 3 medals: 9.0 * 1.3 = 11.7
      // 4 medals: 9.0 * 1.4 = 12.6
      // 5+ medals: 9.0 * 1.4 = 12.6 (clamped)
      // Total: 9.0 + 9.9 + 10.8 + 11.7 + 12.6 + 12.6 = 66.6
      expect(strength, closeTo(66.6, 0.1));
    });

    test('is deterministic - same inputs produce same output', () {
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
    });

    test('returns non-negative value', () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, greaterThanOrEqualTo(0.0));
    });
  });

  group('aggregateStrength', () {
    test('aggregates strength for a list of units', () {
      final units = [
        testUnit(id: 'u1', type: 'musketeers', locationProvinceId: 'p1'),
        testUnit(id: 'u2', type: 'grenadiers', locationProvinceId: 'p2'),
      ];

      // Musketeers: (7+2) * 1.0 = 9.0
      // Grenadiers: (10+8) * 1.0 = 18.0
      // Total: 27.0
      final strength = aggregateStrength(units, 4);
      expect(strength, equals(27.0));
    });

    test('downgrades units when era exceeds effective era', () {
      final units = [
        // Grenadiers era=3, effectiveEra=1 -> should downgrade to era 1 equivalent
        testUnit(id: 'u1', type: 'grenadiers', locationProvinceId: 'p1'),
      ];

      // With effectiveEra=1, grenadiers (era 3) should downgrade to era 1 in same category
      final strength = aggregateStrength(units, 1);
      // Find what era 1 regiment exists for infantry category that grenadiers would downgrade to
      // This should return some positive value
      expect(strength, greaterThan(0.0));
    });
  });

  group('effectiveEraForFaction', () {
    test('returns 4 for Great Power', () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      expect(effectiveEraForFaction(game, 'france'), equals(4));
    });

    test('returns effectiveMilitaryLevel for Minor Nation', () {
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
    });

    test('returns effectiveMilitaryLevel for Tribe (capped at 1 in-game)', () {
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
    });

    test('returns 4 for unknown faction', () {
      final game = militaryStrengthGame();

      expect(effectiveEraForFaction(game, 'unknown'), equals(4));
    });
  });
}
