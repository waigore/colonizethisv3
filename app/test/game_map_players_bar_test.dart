import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show greatPowerPowerScore;
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'support/panel_test_fixtures.dart';

/// Tests for the in-game shell floating players bar.
///
/// SPEC: `SPEC/ui/empire-overview.md` § Players bar (issue #3898).
void main() {
  suppressLogsForTests();

  ct_models.Game gameWithOwnership() {
    final base = buildPlayersBarTestGame();
    final greatPowers = GameMapPlayersBar.greatPowerRoster(base);
    expect(greatPowers.length, greaterThanOrEqualTo(2));
    final ow = base.worldState.oldWorld;
    final provinces = ow.provinces;
    expect(provinces.length, greaterThanOrEqualTo(6));

    ct_models.Province withoutOwner(ct_models.Province p) {
      return ct_models.Province(
        id: p.id,
        regionId: p.regionId,
        displayName: p.displayName,
        fortLevel: p.fortLevel,
        terrain: p.terrain,
        townTileKey: p.townTileKey,
        townDevelopmentLevel: p.townDevelopmentLevel,
      );
    }

    final mutated = <ct_models.Province>[];
    for (var i = 0; i < provinces.length; i++) {
      final cleared = withoutOwner(provinces[i]);
      if (i == 0) {
        mutated.add(cleared.copyWith(ownerId: greatPowers[0].id));
      } else if (i >= 1 && i <= 4) {
        mutated.add(cleared.copyWith(ownerId: greatPowers[1].id));
      } else {
        mutated.add(cleared);
      }
    }
    return base.copyWith(
      worldState: base.worldState.copyWith(
        oldWorld: ct_models.RegionData(provinces: mutated, units: ow.units),
      ),
    );
  }

  Widget hostFor(
    ct_models.Game game, {
    String? highlightPlayerId,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 400,
          child: Stack(
            children: [
              GameMapPlayersBar(
                game: game,
                highlightPlayerId: highlightPlayerId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders chips sorted by power score descending', (
    WidgetTester tester,
  ) async {
    final game = gameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final scoreFormat = NumberFormat.decimalPattern('en_US');

    await tester.pumpWidget(hostFor(game));
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

    final topScore = greatPowerPowerScore(game, roster.first.id);
    expect(
      find.descendant(
        of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
        matching: find.text(scoreFormat.format(topScore)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('chip score equals greatPowerPowerScore formatted en_US', (
    WidgetTester tester,
  ) async {
    final game = gameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final scoreFormat = NumberFormat.decimalPattern('en_US');

    await tester.pumpWidget(hostFor(game));
    await tester.pump();

    for (final player in roster) {
      final expected = scoreFormat.format(
        GameMapPlayersBar.powerScoreFor(game, player.id),
      );
      expect(
        find.descendant(
          of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${player.id}')),
          matching: find.text(expected),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('highlightPlayerId renders bold accent name style', (
    WidgetTester tester,
  ) async {
    final game = gameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final target = roster.first;

    await tester.pumpWidget(hostFor(game, highlightPlayerId: target.id));
    await tester.pump();

    final nameFinder = find.descendant(
      of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${target.id}')),
      matching: find.text(target.displayName),
    );
    final style = tester.widget<Text>(nameFinder).style;
    expect(style?.color, EditorialMonoclePalette.accent);
    expect(style?.fontWeight, FontWeight.w600);
  });

  testWidgets('chip swatch paints the canonical map ownership tint', (
    WidgetTester tester,
  ) async {
    final game = gameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    final ownershipColors = factionOwnershipColorMapForOldWorld(game);

    await tester.pumpWidget(hostFor(game));
    await tester.pump();

    for (final player in roster) {
      final expected = ownershipColors[player.id];
      expect(expected, isNotNull);
      final expectedColor =
          Color.fromARGB(0xFF, expected!.$1, expected.$2, expected.$3);
      final swatchContainers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${player.id}')),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final swatch =
          swatchContainers.firstWhere((c) => c.constraints?.maxWidth == 8.0);
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
    final expectedScore = NumberFormat.decimalPattern('en_US').format(
      GameMapPlayersBar.powerScoreFor(game, roster.first.id),
    );

    await tester.pumpWidget(hostFor(game));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
        matching: find.text(expectedScore),
      ),
      findsOneWidget,
    );
    expect(expectedScore, contains(','));
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

    await tester.pumpWidget(hostFor(empty));
    await tester.pump();

    expect(find.byKey(kGameMapPlayersBarKey), findsNothing);
  });

  test('greatPowerRoster sorts by power score desc then id asc', () {
    final game = gameWithOwnership();
    final roster = GameMapPlayersBar.greatPowerRoster(game);
    for (var i = 0; i < roster.length - 1; i++) {
      final leftScore = greatPowerPowerScore(game, roster[i].id);
      final rightScore = greatPowerPowerScore(game, roster[i + 1].id);
      expect(leftScore >= rightScore, isTrue);
      if (leftScore == rightScore) {
        expect(roster[i].id.compareTo(roster[i + 1].id), lessThan(0));
      }
    }
  });
}
