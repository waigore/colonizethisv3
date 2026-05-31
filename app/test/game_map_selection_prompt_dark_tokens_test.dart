// Pins the dark editorial-monocle contract for the work-target selection
// prompt overlay banner rendered by [GameMapCanvasStack] when the map is
// in work target selection mode.
//
// SPEC: `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay
// tokens + the matching AC under § Acceptance criteria — banner background
// resolves from [EditorialMonoclePalette.bgDeep] at
// `kMapSelectionPromptBackgroundAlpha = 0.85` with a 1 px
// [EditorialMonoclePalette.accentDim] border; the prompt text resolves to
// [EditorialMonoclePalette.fg]; the `cancel` action paints its background
// with [EditorialMonoclePalette.surface] and its label foreground with
// [EditorialMonoclePalette.accentBright]; Material `Colors.black` /
// `Colors.white` / Material colour-scheme lookups are forbidden on the
// banner chrome.
//
// Refs #2861 (in-game shell + empire overview — dark editorial-monocle
// chrome alignment for the map area selection prompt).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_map_canvas_stack.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_selection_prompt_dark_tokens');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  /// Pumps a [GameMapArea] under `AppThemes.editorialMonocle`, fires the
  /// explore selection-mode event, and waits until the selection prompt
  /// banner is visible. Returns the [WidgetTester] focused on the running
  /// app so the calling test can locate sub-widgets.
  Future<void> pumpAndEnterSelectionMode(WidgetTester tester) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

    final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
        ? game.worldState.oldWorld.units.first.id
        : game.worldState.newWorld.units.first.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) => bus),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          mapViewDataProvider.overrideWith((ref) => mapViewData),
        ],
        child: MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: GameMapArea(game: game, mapViewData: mapViewData),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: kWorkTargetExplore,
      ),
    );
    await tester.pump();

    var selectionReady = false;
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 5));
      if (find.text('Select a tile, or click cancel').evaluate().isNotEmpty) {
        selectionReady = true;
        break;
      }
    }
    expect(
      selectionReady,
      isTrue,
      reason:
          'selection prompt overlay must mount once the bus event commits the '
          'work-target selection mode entry path',
    );
  }

  /// Returns the [DecoratedBox] that paints the dark banner background
  /// behind the selection-mode prompt (the descendant of the Positioned
  /// banner whose decoration declares the bgDeep fill + accent-dim border).
  DecoratedBox bannerDecoratedBox(WidgetTester tester) {
    final candidates = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((d) {
          final decoration = d.decoration;
          if (decoration is! BoxDecoration) return false;
          final color = decoration.color;
          if (color == null) return false;
          // Match the bgDeep-with-canonical-alpha fill so we land on the
          // selection-prompt banner instead of unrelated DecoratedBox
          // descendants (e.g. minimap chrome, side-panel surfaces).
          final expected = EditorialMonoclePalette.bgDeep.withValues(
            alpha: kMapSelectionPromptBackgroundAlpha,
          );
          return color.toARGB32() == expected.toARGB32();
        })
        .toList();
    expect(
      candidates.length,
      1,
      reason:
          'exactly one DecoratedBox in the tree should paint the bgDeep + 0.85 '
          'alpha banner fill (the selection prompt overlay)',
    );
    return candidates.single;
  }

  testWidgets(
    'selection prompt banner background paints bgDeep + accent-dim border',
    (WidgetTester tester) async {
      await pumpAndEnterSelectionMode(tester);

      final banner = bannerDecoratedBox(tester);
      final decoration = banner.decoration as BoxDecoration;

      final expectedColor = EditorialMonoclePalette.bgDeep.withValues(
        alpha: kMapSelectionPromptBackgroundAlpha,
      );
      expect(decoration.color, equals(expectedColor));
      // Material primaries are forbidden — the banner must not fall back
      // to `Colors.black.withValues(alpha: 0.72)`.
      expect(
        decoration.color,
        isNot(equals(const Color(0xFF000000).withValues(alpha: 0.72))),
        reason: 'banner background must not paint the legacy black + 0.72',
      );

      final border = decoration.border;
      expect(
        border,
        isA<Border>(),
        reason: 'banner must paint a Border around the bgDeep surface',
      );
      final borderTop = (border as Border).top;
      expect(borderTop.color, equals(EditorialMonoclePalette.accentDim));
      expect(borderTop.width, equals(1.0));
    },
  );

  testWidgets(
    'selection prompt label resolves to EditorialMonoclePalette.fg',
    (WidgetTester tester) async {
      await pumpAndEnterSelectionMode(tester);

      final promptText = tester.widget<Text>(
        find.text('Select a tile, or click cancel'),
      );
      final style = promptText.style;
      expect(style, isNotNull);
      expect(style!.color, equals(EditorialMonoclePalette.fg));
      // Material defaults are forbidden — the prompt must not paint white.
      expect(
        style.color,
        isNot(equals(const Color(0xFFFFFFFF))),
        reason: 'prompt text must not paint Material Colors.white',
      );
    },
  );

  testWidgets(
    'cancel action paints surface bg and accentBright fg',
    (WidgetTester tester) async {
      await pumpAndEnterSelectionMode(tester);

      final cancelButton = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('cancel'),
          matching: find.byType(TextButton),
        ),
      );
      final style = cancelButton.style;
      expect(style, isNotNull);

      // ButtonStyle exposes resolved colours via MaterialStateProperty;
      // the selection-prompt cancel button declares static colours from
      // EditorialMonoclePalette, so resolve against an empty state set.
      final resolvedBg = style!.backgroundColor?.resolve(<WidgetState>{});
      final resolvedFg = style.foregroundColor?.resolve(<WidgetState>{});
      expect(resolvedBg, equals(EditorialMonoclePalette.surface));
      expect(resolvedFg, equals(EditorialMonoclePalette.accentBright));
      // Material primaries are forbidden — must not paint white-on-black.
      expect(
        resolvedBg,
        isNot(equals(const Color(0xFFFFFFFF))),
        reason: 'cancel button background must not paint Material Colors.white',
      );
      expect(
        resolvedFg,
        isNot(equals(const Color(0xFF000000))),
        reason: 'cancel button label must not paint Material Colors.black',
      );

      // The inner Text label MUST also explicitly set the accent-bright
      // colour so the foreground holds whether ButtonStyle is overridden
      // by a future M3 default.
      final cancelLabel = tester.widget<Text>(find.text('cancel'));
      final labelStyle = cancelLabel.style;
      expect(labelStyle, isNotNull);
      expect(labelStyle!.color, equals(EditorialMonoclePalette.accentBright));
    },
  );

  test(
    'kMapSelectionPromptBackgroundAlpha is pinned at 0.85 per SPEC',
    () {
      expect(kMapSelectionPromptBackgroundAlpha, equals(0.85));
    },
  );
}
