import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Narrow-layout contract for [GameMapEmpireLeftRail] (issue #2870 S3).
///
/// SPEC: `SPEC/ui/empire-buttons.md` § Narrow rail measurements;
/// `SPEC/ui/mobile-adaptation.md` § In-game shell.
///
/// Pins:
/// - 26 × 26 dp tap target per rail button when `narrow: true`.
/// - 2 dp vertical gap between consecutive buttons.
/// - 24 × 24 dp icon glyph (unchanged from wide layout).
/// - No `Tooltip` widget mounted under any rail button (touch-only).
/// - `Semantics(button: true, label: <tooltip>)` still mounted so a11y is
///   preserved.
///
/// Negative regression guard: with `narrow: false` (default) the existing
/// wide-layout 36 × 36 dp + 3 dp gap + `Tooltip` contract still holds.
void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    final result = getDebugInitGameResult();
    game = result.game;

    Hive.init('./.dart_tool/test_hive_empire_rail_narrow');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  String humanId() => game.players.where((p) => p.isHuman).isNotEmpty
      ? game.players.where((p) => p.isHuman).first.id
      : game.players.first.id;

  overrides({bool debugConsoleEnabled = false}) => [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        availableWorkTargetIdsForUnitProvider.overrideWith(
          (ref, _) => const <String>[],
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
        debugConsoleEnabledProvider.overrideWithValue(debugConsoleEnabled),
      ];

  Widget railScaffold({
    required bool narrow,
    bool debugConsoleEnabled = false,
  }) {
    return ProviderScope(
      overrides: overrides(debugConsoleEnabled: debugConsoleEnabled),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                Positioned(
                  left: 20,
                  top: 0,
                  child: GameMapEmpireLeftRail(
                    game: game,
                    humanPlayerId: humanId(),
                    narrow: narrow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  const List<Key> railButtonKeys = <Key>[
    kEmpireProductionButtonKey,
    kEmpireTradeButtonKey,
    kEmpireCivilianUnitsButtonKey,
    kEmpireMilitaryUnitsButtonKey,
    kEmpireNavalUnitsButtonKey,
    kEmpireDiplomacyButtonKey,
    kEmpireTechnologyButtonKey,
  ];

  group(
    'GameMapEmpireLeftRail narrow layout (Refs #2870 S3)',
    () {
      testWidgets(
        'positive: narrow rail buttons paint a 26 x 26 dp surface',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: true));
          await tester.pumpAndSettle();

          expect(GameMapEmpireLeftRail.narrowButtonSize, 26.0);
          for (final key in railButtonKeys) {
            final size = tester.getSize(find.byKey(key));
            expect(
              size.width,
              26.0,
              reason:
                  'Narrow rail button $key must paint a 26 dp wide tap target',
            );
            expect(
              size.height,
              26.0,
              reason:
                  'Narrow rail button $key must paint a 26 dp tall tap target',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow rail buttons render with 2 dp vertical gaps',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: true));
          await tester.pumpAndSettle();

          expect(GameMapEmpireLeftRail.narrowRowGap, 2.0);
          for (var i = 1; i < railButtonKeys.length; i++) {
            final aBottom = tester
                .getRect(find.byKey(railButtonKeys[i - 1]))
                .bottom;
            final bTop = tester.getRect(find.byKey(railButtonKeys[i])).top;
            expect(
              bTop - aBottom,
              2.0,
              reason:
                  'Narrow rail button ${railButtonKeys[i]} must sit 2 dp below '
                  '${railButtonKeys[i - 1]}',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow rail icon glyph is unchanged at 24 x 24 dp',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: true));
          await tester.pumpAndSettle();

          expect(GameMapEmpireLeftRail.iconSize, 24.0);
          for (final key in railButtonKeys) {
            final iconFinder = find.descendant(
              of: find.byKey(key),
              matching: find.byType(StrictAssetIcon),
            );
            expect(iconFinder, findsOneWidget);
            final icon = tester.widget<StrictAssetIcon>(iconFinder);
            expect(
              icon.width,
              24.0,
              reason: 'Narrow rail icon for $key must remain 24 dp wide',
            );
            expect(
              icon.height,
              24.0,
              reason: 'Narrow rail icon for $key must remain 24 dp tall',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow rail suppresses Tooltip widgets under every button',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: true));
          await tester.pumpAndSettle();

          for (final key in railButtonKeys) {
            final tooltipFinder = find.ancestor(
              of: find.byKey(key),
              matching: find.byType(Tooltip),
            );
            expect(
              tooltipFinder,
              findsNothing,
              reason:
                  'Narrow rail button $key must not be wrapped in a Tooltip '
                  '(touch-only viewports have no hover cursor)',
            );
          }
        },
      );

      testWidgets(
        'positive: narrow rail preserves Semantics(button: true, label)',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: true));
          await tester.pumpAndSettle();

          final Map<Key, String> expectedLabels = <Key, String>{
            kEmpireProductionButtonKey: 'Production',
            kEmpireTradeButtonKey: 'Trade',
            kEmpireCivilianUnitsButtonKey: 'Civilian Units',
            kEmpireMilitaryUnitsButtonKey: 'Military Units',
            kEmpireNavalUnitsButtonKey: 'Naval Units',
            kEmpireDiplomacyButtonKey: 'Diplomacy',
            kEmpireTechnologyButtonKey: 'Technology',
          };

          for (final entry in expectedLabels.entries) {
            final semanticsFinder = find.ancestor(
              of: find.byKey(entry.key),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.button == true &&
                    widget.properties.label == entry.value,
              ),
            );
            expect(
              semanticsFinder,
              findsOneWidget,
              reason:
                  'Narrow rail button ${entry.key} must still expose '
                  'Semantics(button: true, label: "${entry.value}") for a11y',
            );
          }
        },
      );

      testWidgets(
        'negative: wide rail (narrow: false) keeps 36 x 36 dp + Tooltip baseline',
        (WidgetTester tester) async {
          await tester.pumpWidget(railScaffold(narrow: false));
          await tester.pumpAndSettle();

          for (final key in railButtonKeys) {
            final size = tester.getSize(find.byKey(key));
            expect(
              size.width,
              GameMapEmpireLeftRail.buttonSize,
              reason: 'Wide rail button $key must remain 36 dp wide',
            );
            expect(
              size.height,
              GameMapEmpireLeftRail.buttonSize,
              reason: 'Wide rail button $key must remain 36 dp tall',
            );
            final tooltipFinder = find.ancestor(
              of: find.byKey(key),
              matching: find.byType(Tooltip),
            );
            expect(
              tooltipFinder,
              findsOneWidget,
              reason:
                  'Wide rail button $key must still wrap its glyph in a Tooltip',
            );
          }
          for (var i = 1; i < railButtonKeys.length; i++) {
            final aBottom = tester
                .getRect(find.byKey(railButtonKeys[i - 1]))
                .bottom;
            final bTop = tester.getRect(find.byKey(railButtonKeys[i])).top;
            expect(
              bTop - aBottom,
              GameMapEmpireLeftRail.rowGap,
              reason:
                  'Wide rail button ${railButtonKeys[i]} must keep the 3 dp gap',
            );
          }
        },
      );
    },
  );
}
