// Widget goldens for the in-game Players bar visual acceptance criteria
// (Refs #3898 / #4720 Slice G). Pixel baselines live under `app/test/goldens/`
// and are asserted with `matchesGoldenFile`.
//
// AC mapping:
//  - AC4  wide chip column sorted by power score with human GP bold accent
//  - AC8  narrow players bar below feed anchor (embedded column contract)
// Toggle chrome: `players_bar_toggle_goldens_test.dart`
// Tab-bar trailing cluster: `players_bar_tab_bar_trailing_goldens_test.dart`
//
// SPEC: `SPEC/ui/empire-overview.md` § Players bar / § Players bar toggle.

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'golden_capture_harness.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';

import 'panel_test_fixtures.dart';

const Map<String, List<int>> _kPlayersBarGoldenColorOverride = {
  'gp1': [200, 40, 40],
  'gp2': [40, 160, 40],
  'gp3': [40, 80, 200],
};

ct_models.Game _playersBarGoldenGame() {
  final base = buildPlayersBarTestGame().copyWith(
    greatPowerColorOverride: _kPlayersBarGoldenColorOverride,
  );
  final greatPowers = GameMapPlayersBar.greatPowerRoster(base);
  final ow = base.worldState.oldWorld;
  final provinces = ow.provinces;

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

Widget _goldenHost({
  required Key boundaryKey,
  required Widget child,
  Size? surfaceSize,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: surfaceSize == null
        ? child
        : SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: child,
          ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: wide players bar chips sorted by Old World N / 31 with human GP '
    'accent (Refs #3898 AC4, #4451)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('players_bar_wide_chips');
      final game = _playersBarGoldenGame();
      final roster = GameMapPlayersBar.greatPowerRoster(game);

      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: boundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GameMapPlayersBar(
              game: game,
              highlightPlayerId: kPanelTestHumanPlayerId,
              embedded: true,
            ),
          ),
        ),
      );
      await pumpForGolden(tester, settle: false);

      expect(find.byKey(kGameMapPlayersBarKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
          matching: find.text(
            GameMapPlayersBar.oldWorldRaceLabelFor(game, roster.first.id),
          ),
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/players_bar_wide_chips_highlighted.png'),
      );
    },
  );

  testWidgets(
    'golden: narrow players bar column below feed anchor (Refs #3898 AC8)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('players_bar_narrow_below_feed');
      final game = _playersBarGoldenGame();

      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: boundaryKey,
          surfaceSize: const Size(320, 180),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: GameMapPlayersBar.narrowTopInset,
                right: GameMapPlayersBar.rightInsetDefault,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const SizedBox(
                    width: 120,
                    height: 48,
                    child: Center(child: Text('Feed anchor')),
                  ),
                ),
              ),
              Positioned(
                top:
                    GameMapPlayersBar.narrowTopInset +
                    48 +
                    GameMapPlayersBar.narrowStackGap,
                right: GameMapPlayersBar.rightInsetDefault,
                child: GameMapPlayersBar(
                  game: game,
                  highlightPlayerId: kPanelTestHumanPlayerId,
                  narrow: true,
                  embedded: true,
                ),
              ),
            ],
          ),
        ),
      );
      await pumpForGolden(tester, settle: false);

      expect(find.byKey(kGameMapPlayersBarKey), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/players_bar_narrow_below_feed_anchor.png'),
      );
    },
  );
}
