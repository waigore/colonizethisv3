import 'package:colonizethis_app/core/utils/faction_display_name.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('displayNameForFaction (Refs #4512)', () {
    test('GP id returns Player.displayName', () {
      final game = buildPanelTestGame(
        players: [panelTestHumanPlayer(displayName: 'Test Human')],
      );
      expect(
        displayNameForFaction(game, kPanelTestHumanPlayerId),
        'Test Human',
      );
    });

    test('minor id returns displayName when present', () {
      final game = buildPanelTestGame(
        minorNations: const [MinorNation(id: 'm1', displayName: 'Free City')],
      );
      expect(displayNameForFaction(game, 'm1'), 'Free City');
    });

    test('minor id without displayName falls back to id', () {
      final game = buildPanelTestGame(
        minorNations: const [MinorNation(id: 'm2')],
      );
      expect(displayNameForFaction(game, 'm2'), 'm2');
    });

    test('tribe id returns displayName when present', () {
      final game = buildPanelTestGame(
        tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
      );
      expect(displayNameForFaction(game, 't1'), 'Tribe One');
    });

    test('tribe id without displayName falls back to id', () {
      final game = buildPanelTestGame(tribes: const [Tribe(id: 't1')]);
      expect(displayNameForFaction(game, 't1'), 't1');
    });

    test('unknown id returns the raw id', () {
      final game = buildPanelTestGame();
      expect(displayNameForFaction(game, 'nobody'), 'nobody');
    });
  });
}
