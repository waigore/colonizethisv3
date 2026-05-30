import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Tests for the dark editorial-monocle chrome contract on
/// [GameMapEmpireLeftRail] (issue #2861 S3 / R4).
///
/// Asserts the rail buttons paint a 36 × 36 dp surface with the canonical
/// dark gradient + border tokens and a 24 × 24 dp icon glyph tinted in the
/// editorial-monocle accent token cycle (`--accent-dim` default,
/// `--accent` hover, `--accent-bright` pressed). Also pins the no-light-hex
/// rule documented in `SPEC/ui/empire-buttons.md` § Styling.
void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    final result = getDebugInitGameResult();
    game = result.game;

    Hive.init('./.dart_tool/test_hive_empire_rail_chrome');
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

  Widget railScaffold({bool debugConsoleEnabled = false}) {
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

  testWidgets('Rail buttons paint a 36 x 36 dp surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.buttonSize, 36.0);
    for (final key in railButtonKeys) {
      final size = tester.getSize(find.byKey(key));
      expect(
        size.width,
        36.0,
        reason: 'Rail button $key must paint a 36 dp wide tap target',
      );
      expect(
        size.height,
        36.0,
        reason: 'Rail button $key must paint a 36 dp tall tap target',
      );
    }
  });

  testWidgets('Rail buttons paint a 24 x 24 dp icon glyph', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.iconSize, 24.0);
    for (final key in railButtonKeys) {
      final iconFinder = find.descendant(
        of: find.byKey(key),
        matching: find.byType(StrictAssetIcon),
      );
      expect(iconFinder, findsOneWidget);
      final icon = tester.widget<StrictAssetIcon>(iconFinder);
      expect(icon.width, 24.0, reason: 'Rail icon for $key must be 24 dp wide');
      expect(
        icon.height,
        24.0,
        reason: 'Rail icon for $key must be 24 dp tall',
      );
    }
  });

  testWidgets(
    'Idle rail button paints the dark surfaceLite -> bgDeep gradient and 1 dp border',
    (WidgetTester tester) async {
      await tester.pumpWidget(railScaffold());
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byKey(kEmpireProductionButtonKey),
        matching: find.byType(AnimatedContainer),
      );
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      final expectedGradient = CtGradients.railButtonGradient;
      final actualGradient = decoration.gradient as LinearGradient;
      expect(actualGradient.colors[0], expectedGradient.colors[0]);
      expect(actualGradient.colors[1], expectedGradient.colors[1]);
      expect(actualGradient.colors[0], EditorialMonoclePalette.surfaceLite);
      expect(actualGradient.colors[1], EditorialMonoclePalette.bgDeep);

      final border = decoration.border as Border;
      expect(border.top.color, EditorialMonoclePalette.border);
      expect(border.top.width, 1.0);
      expect(border.bottom.color, EditorialMonoclePalette.border);
      expect(border.left.color, EditorialMonoclePalette.border);
      expect(border.right.color, EditorialMonoclePalette.border);
    },
  );

  testWidgets('Hover lifts border color from --border to --accent-dim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    final containerFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(AnimatedContainer),
    );
    expect(containerFinder, findsOneWidget);

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(kEmpireProductionButtonKey)));
    await tester.pumpAndSettle();

    final hovered = tester.widget<AnimatedContainer>(containerFinder);
    final border = (hovered.decoration as BoxDecoration).border as Border;
    expect(
      border.top.color,
      EditorialMonoclePalette.accentDim,
      reason: 'Hover should lift the border color to --accent-dim',
    );
  });

  testWidgets('Idle rail button tints icon glyph with --accent-dim', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    final filterFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(ColorFiltered),
    );
    expect(filterFinder, findsOneWidget);
    final filtered = tester.widget<ColorFiltered>(filterFinder);
    final filter = filtered.colorFilter;
    expect(
      filter,
      equals(
        ColorFilter.mode(
          EditorialMonoclePalette.accentDim,
          BlendMode.srcIn,
        ),
      ),
      reason: 'Idle rail button must tint icon glyph with --accent-dim',
    );
  });

  testWidgets('Hover tints icon glyph with --accent', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(kEmpireProductionButtonKey)));
    await tester.pumpAndSettle();

    final filterFinder = find.descendant(
      of: find.byKey(kEmpireProductionButtonKey),
      matching: find.byType(ColorFiltered),
    );
    final filtered = tester.widget<ColorFiltered>(filterFinder);
    final filter = filtered.colorFilter;
    expect(
      filter,
      equals(
        ColorFilter.mode(
          EditorialMonoclePalette.accent,
          BlendMode.srcIn,
        ),
      ),
      reason: 'Hover should tint the icon glyph with --accent',
    );
  });

  testWidgets('Rail buttons render with 3 dp vertical gaps between them', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.rowGap, 3.0);
    for (var i = 1; i < railButtonKeys.length; i++) {
      final aBottom = tester
          .getRect(find.byKey(railButtonKeys[i - 1]))
          .bottom;
      final bTop = tester.getRect(find.byKey(railButtonKeys[i])).top;
      expect(
        bTop - aBottom,
        3.0,
        reason:
            'Rail button ${railButtonKeys[i]} must sit 3 dp below ${railButtonKeys[i - 1]}',
      );
    }
  });

  testWidgets('No rail descendant paints Colors.white as a Material color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold(debugConsoleEnabled: true));
    await tester.pumpAndSettle();

    final materials = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(GameMapEmpireLeftRail),
            matching: find.byType(Material),
          ),
        )
        .toList();
    expect(materials.isNotEmpty, isTrue, reason: 'Rail must paint Material chrome');
    for (final material in materials) {
      final color = material.color;
      expect(
        color,
        anyOf(isNull, equals(Colors.transparent)),
        reason:
            'Rail Material chrome must be transparent so dark editorial-monocle '
            'chrome shows through (no light parchment / Colors.white surface)',
      );
    }
  });

  testWidgets(
    'Rail exposes Semantics(button: true) with the tooltip label for each entry',
    (WidgetTester tester) async {
      await tester.pumpWidget(railScaffold());
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
              'Rail button ${entry.key} must wrap its glyph in Semantics(button: true, label: "${entry.value}")',
        );
      }
    },
  );
}
