// Unit tests for GP tech-researcher helpers. Refs #3862.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_gp_researchers.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  Game multiGpGame({
    required Map<String, bool> gp1Tech,
    required Map<String, bool> gp2Tech,
    required Map<String, bool> gp3Tech,
  }) {
    return buildPanelTestGame(
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP One',
          isHuman: true,
          techUnlocked: gp1Tech,
        ),
        Player(
          id: 'gp2',
          displayName: 'GP Two',
          isHuman: false,
          techUnlocked: gp2Tech,
        ),
        Player(
          id: 'gp3',
          displayName: 'GP Three',
          isHuman: false,
          techUnlocked: gp3Tech,
        ),
      ],
      minorNations: [
        const MinorNation(id: 'm1', displayName: 'Minor'),
      ],
    );
  }

  group('gpPlayersWithTechUnlocked', () {
    test('returns only GPs with techUnlocked true', () {
      final game = multiGpGame(
        gp1Tech: {kTechIdCropRotation: true},
        gp2Tech: const {},
        gp3Tech: {kTechIdCropRotation: true},
      );
      final researchers = gpPlayersWithTechUnlocked(game, kTechIdCropRotation);
      expect(researchers.map((p) => p.id).toList(), ['gp1', 'gp3']);
    });

    test('excludes in-progress-only GPs', () {
      final game = buildPanelTestGame(
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP One',
            isHuman: true,
            researchProgressByTechId: const {kTechIdCropRotation: 10},
          ),
        ],
      );
      expect(gpPlayersWithTechUnlocked(game, kTechIdCropRotation), isEmpty);
    });

    test('returns empty when no GP unlocked tech', () {
      final game = buildPanelTestGame(players: [panelTestHumanPlayer()]);
      expect(gpPlayersWithTechUnlocked(game, kTechIdCropRotation), isEmpty);
    });
  });

  group('orderGpResearchers', () {
    test('context player first then setup order', () {
      final game = multiGpGame(
        gp1Tech: {kTechIdCropRotation: true},
        gp2Tech: const {},
        gp3Tech: {kTechIdCropRotation: true},
      );
      final researchers = gpPlayersWithTechUnlocked(game, kTechIdCropRotation);
      final ordered = orderGpResearchers(
        researchers: researchers,
        contextPlayerId: 'gp1',
        game: game,
      );
      expect(ordered.map((p) => p.id).toList(), ['gp1', 'gp3']);
    });

    test('context absent uses setup order only', () {
      final game = multiGpGame(
        gp1Tech: {kTechIdCropRotation: true},
        gp2Tech: const {},
        gp3Tech: {kTechIdCropRotation: true},
      );
      final researchers = gpPlayersWithTechUnlocked(game, kTechIdCropRotation);
      final ordered = orderGpResearchers(
        researchers: researchers,
        contextPlayerId: 'gp2',
        game: game,
      );
      expect(ordered.map((p) => p.id).toList(), ['gp1', 'gp3']);
    });
  });

  group('gpMapColorForPlayer', () {
    test('uses greatPowerColorOverride when present', () {
      final base = buildPanelTestGame(players: [panelTestHumanPlayer()]);
      final game = base.copyWith(
        greatPowerColorOverride: const {
          'gp1': [200, 40, 40],
        },
      );
      final color = gpMapColorForPlayer(game, 'gp1');
      expect(color, const Color(0xFFC82828));
    });

    test('falls back to factionOwnershipColorMapForOldWorld without override', () {
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(),
          const Player(id: 'gp2', displayName: 'GP Two', isHuman: false),
        ],
      );
      final color = gpMapColorForPlayer(game, 'gp1');
      // Sorted gp ids → gp1 is index 0 in regionPalette (180, 80, 80).
      expect(color, const Color(0xFFB45050));
    });
  });
}
