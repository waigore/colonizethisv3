import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_test_fixtures.dart';
import 'game_map_players_bar_support.dart';

/// Tests for the in-game shell floating players bar.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Players bar (issue #3898).
void main() {
  suppressLogsForTests();

  testWidgets('renders chips sorted by Old World count descending', (
    WidgetTester tester,
  ) async {
    final game = playersBarGameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);

    await tester.pumpWidget(playersBarHostFor(game));
    await tester.pump();

    expect(find.byKey(kGameMapPlayersBarKey), findsOneWidget);
    expect(
      find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
      findsOneWidget,
    );
    for (final tribe in game.tribes) {
      expect(
        find.byKey(Key('$kGameMapPlayerChipKeyPrefix${tribe.id}')),
        findsNothing,
      );
    }

    expect(
      find.descendant(
        of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
        matching: find.text(
          GameMapPlayersBar.oldWorldRaceLabelFor(game, roster.first.id),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('chip default number is Old World N / 31', (
    WidgetTester tester,
  ) async {
    final game = playersBarGameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);

    await tester.pumpWidget(playersBarHostFor(game));
    await tester.pump();

    for (final player in roster) {
      expect(
        find.descendant(
          of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${player.id}')),
          matching: find.text(
            GameMapPlayersBar.oldWorldRaceLabelFor(game, player.id),
          ),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('highlightPlayerId renders bold accent name style', (
    WidgetTester tester,
  ) async {
    final game = playersBarGameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final target = roster.first;

    await tester.pumpWidget(playersBarHostFor(game, highlightPlayerId: target.id));
    await tester.pump();

    final nameFinder = find.descendant(
      of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${target.id}')),
      matching: find.text(target.displayName),
    );
    final style = tester.widget<Text>(nameFinder).style;
    expect(style?.color, EditorialMonoclePalette.accent);
    expect(style?.fontWeight, FontWeight.w600);
  });

  testWidgets('chip tooltip labels calendar-end strength', (
    WidgetTester tester,
  ) async {
    final game = playersBarGameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);

    await tester.pumpWidget(playersBarHostFor(game));
    await tester.pump();

    final chipFinder = find.byKey(
      Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}'),
    );
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: chipFinder, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, contains('Calendar-end strength'));
    expect(tooltip.message, contains('no province-count winner'));
  });

  testWidgets('chip swatch paints the canonical map ownership tint', (
    WidgetTester tester,
  ) async {
    final game = playersBarGameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);

    await tester.pumpWidget(playersBarHostFor(game));
    await tester.pump();

    for (final player in roster) {
      final expected = ownershipColors[player.id];
      expect(expected, isNotNull);
      final expectedColor = Color.fromARGB(
        0xFF,
        expected!.$1,
        expected.$2,
        expected.$3,
      );
      final swatchContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${player.id}')),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final swatch = swatchContainers.firstWhere(
        (c) => c.constraints?.maxWidth == 8.0,
      );
      final decoration = swatch.decoration as BoxDecoration?;
      expect(decoration?.color, expectedColor);
    }
  });

  testWidgets('formats thousands separators in en_US (>= 1000 score)', (
    WidgetTester tester,
  ) async {
    final base = buildPlayersBarTestGame();
    final roster = GameMapPlayersBar.greatPowerRoster(base);
    final ow = base.worldState.oldWorld;
    final stuffed = <ct_models.Province>[
      for (var i = 0; i < 100; i++)
        ow.provinces.first.copyWith(
          ownerId: roster.first.id,
          id: 'oldWorld|synthetic_$i',
        ),
    ];
    final game = base.copyWith(
      worldState: base.worldState.copyWith(
        oldWorld: ct_models.RegionData(provinces: stuffed, units: ow.units),
      ),
    );
    final expectedLabel = GameMapPlayersBar.oldWorldRaceLabelFor(
      game,
      roster.first.id,
    );

    await tester.pumpWidget(playersBarHostFor(game));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
        matching: find.text(expectedLabel),
      ),
      findsOneWidget,
    );
    expect(expectedLabel, '100 / 31');
  });

  testWidgets('returns SizedBox.shrink() when the GP roster is empty', (
    WidgetTester tester,
  ) async {
    final base = buildPlayersBarTestGame();
    final tribePlayers = base.tribes
        .map(
          (tribe) => ct_models.Player(
            id: tribe.id,
            displayName: tribe.id,
            isHuman: false,
          ),
        )
        .toList();
    final empty = base.copyWith(players: tribePlayers);
    expect(GameMapPlayersBar.greatPowerRoster(empty), isEmpty);

    await tester.pumpWidget(playersBarHostFor(empty));
    await tester.pump();

    expect(find.byKey(kGameMapPlayersBarKey), findsNothing);
  });
}
