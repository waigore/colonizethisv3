// Widget goldens for the in-game Players bar visual acceptance criteria
// (Refs #3898). Pixel baselines live under `app/test/goldens/` and are
// asserted with `matchesGoldenFile`, following the committed golden harness
// pattern (`tech_gp_pennant_goldens_test.dart`, `diplomacy_panel_goldens_test.dart`):
// a keyed `RepaintBoundary` wraps each surface, deterministic fixtures pin
// GP ownership and power scores, and `AppThemes.editorialMonocle` supplies the
// dark-theme chrome.
//
// AC mapping:
//  - AC4  wide chip column sorted by power score with human GP bold accent
//  - AC3  tab-bar trailing cluster: players toggle immediately left of news
//  - AC8  narrow players bar below feed anchor (embedded column contract)
//  - Toggle chrome on/off states for `PlayersBarToggleButton`
//
// SPEC: `SPEC/ui/empire-overview.md` § Players bar / § Players bar toggle.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show greatPowerPowerScore;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show
        kGameMapPlayerChipKeyPrefix,
        kGameMapPlayersBarKey,
        kPlayersBarToggleButtonKey,
        kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/game_map_players_bar.dart';
import 'package:colonizethis_app/features/game/widgets/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/features/game/widgets/players_bar_toggle_button.dart';
import 'package:colonizethis_app/l10n/l10n.dart';

import 'support/panel_test_fixtures.dart';

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
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: surfaceSize == null
              ? child
              : SizedBox(width: surfaceSize.width, height: surfaceSize.height, child: child),
        ),
      ),
    ),
  );
}

Future<void> _pumpBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: wide players bar chips sorted by power with human GP accent '
    '(Refs #3898 AC4)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('players_bar_wide_chips');
      final game = _playersBarGoldenGame();
      final roster = GameMapPlayersBar.greatPowerRoster(game);
      final scoreFormat = NumberFormat.decimalPattern('en_US');

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
      await _pumpBuilt(tester);

      expect(find.byKey(kGameMapPlayersBarKey), findsOneWidget);
      final topScore = greatPowerPowerScore(game, roster.first.id);
      expect(
        find.descendant(
          of: find.byKey(Key('$kGameMapPlayerChipKeyPrefix${roster.first.id}')),
          matching: find.text(scoreFormat.format(topScore)),
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
    'golden: players bar toggle chrome on and off (Refs #3898)',
    (WidgetTester tester) async {
      const onBoundaryKey = ValueKey<String>('players_bar_toggle_on');
      const offBoundaryKey = ValueKey<String>('players_bar_toggle_off');

      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: onBoundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayersBarToggleButton(
                  tooltip: 'Show players bar',
                  showPlayersBar: true,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                PlayersBarToggleButton(
                  tooltip: 'Hide players bar',
                  showPlayersBar: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await _pumpBuilt(tester);

      expect(find.byKey(kPlayersBarToggleButtonKey), findsNWidgets(2));

      await expectLater(
        find.byKey(onBoundaryKey),
        matchesGoldenFile('goldens/players_bar_toggle_on_off.png'),
      );

      // Re-pump off-only surface for a dedicated inactive-state baseline.
      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: offBoundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: PlayersBarToggleButton(
              tooltip: 'Hide players bar',
              showPlayersBar: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      await _pumpBuilt(tester);

      await expectLater(
        find.byKey(offBoundaryKey),
        matchesGoldenFile('goldens/players_bar_toggle_off.png'),
      );
    },
  );

  testWidgets(
    'golden: tab bar trailing cluster players toggle before news (Refs #3898 AC3)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('players_bar_tab_bar_trailing');
      const surfaceWidth = 420.0;

      await tester.pumpWidget(
        _goldenHost(
          boundaryKey: boundaryKey,
          surfaceSize: const Size(surfaceWidth, GameTabBar.height),
          child: GameTabBar(
            regionIndex: 0,
            onRegionIndexChanged: (_) {},
            oldWorldLabel: 'Old World',
            newWorldLabel: 'New World',
            treasury: 12_345,
            treasuryDelta: 100,
            treasuryNotDefined: false,
            cargoUsed: 2,
            cargoCapacity: 8,
            cargoNotDefined: false,
            isCargoUsedReliable: true,
            cargoHoldLabel: 'Cargo 2/8',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayersBarToggleButton(
                  tooltip: 'Show players bar',
                  showPlayersBar: true,
                  onPressed: () {},
                ),
                const SizedBox(width: GameTabBar.clusterTrailingGap),
                PlayerTurnEventsFeedToggleButton(
                  eventCount: 2,
                  tooltip: 'Turn events (2)',
                  showFeed: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await _pumpBuilt(tester);

      expect(find.byKey(kPlayersBarToggleButtonKey), findsOneWidget);
      expect(find.byKey(kPlayerTurnFeedToggleButtonKey), findsOneWidget);
      final playersOffset = tester.getTopLeft(find.byKey(kPlayersBarToggleButtonKey));
      final newsOffset = tester.getTopLeft(find.byKey(kPlayerTurnFeedToggleButtonKey));
      expect(playersOffset.dx, lessThan(newsOffset.dx));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/players_bar_tab_bar_trailing_cluster.png'),
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
                top: GameMapPlayersBar.narrowTopInset + 48 + GameMapPlayersBar.narrowStackGap,
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
      await _pumpBuilt(tester);

      expect(find.byKey(kGameMapPlayersBarKey), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/players_bar_narrow_below_feed_anchor.png'),
      );
    },
  );
}
