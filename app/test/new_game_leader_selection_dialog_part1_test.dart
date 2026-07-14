import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

import 'support/new_game_leader_selection_dialog_test_support.dart';

const _largeViewport = Size(900, 2000);
const _duplicateSurface = Size(900, 1600);
const _duplicateEnglandIds = <String>[
  'england',
  'france',
  'spain',
  'portugal',
  'netherlands',
  'england',
];

GameSetupConfig get _duplicateEnglandConfig =>
    GameSetupConfig(selectedGreatPowerIds: _duplicateEnglandIds);

void main() {
  suppressLogsForTests();

  Future<void> enterSeed(WidgetTester tester, String value) async {
    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> tapSliderEdge(WidgetTester tester, {required bool left}) async {
    final slider = find.byType(CtSlider);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final rect = tester.getRect(slider);
    await tester.tapAt(
      Offset(left ? rect.left + 1 : rect.right - 1, rect.center.dy),
    );
    await tester.pumpAndSettle();
  }

  CtNinePatchButton startButton(WidgetTester tester) {
    return tester.widget<CtNinePatchButton>(
      find.ancestor(
        of: find.text('Start'),
        matching: find.byType(CtNinePatchButton),
      ),
    );
  }

  void expectDialogChromeTexts(Iterable<String> texts) {
    for (final text in texts) {
      expect(find.text(text), findsOneWidget);
    }
  }

  Finder keyed(String key) => find.byKey(ValueKey<String>(key));

  Text keyedText(WidgetTester tester, String key) =>
      tester.widget<Text>(keyed(key));

  Future<void> pumpDuplicateEngland(WidgetTester tester) {
    return pumpNewGameLeaderSelectionDialog(
      tester,
      baseConfig: _duplicateEnglandConfig,
      surfaceSize: _duplicateSurface,
    );
  }

  Future<int?> confirmWithSeed(WidgetTester tester, String seed) async {
    int? gotSeed;
    await pumpNewGameLeaderSelectionDialog(
      tester,
      onConfirmed: (_, _, s, _, _, __, ___) => gotSeed = s,
    );
    await enterSeed(tester, seed);
    await ensureTapNewGameLeaderSelectionStart(tester);
    return gotSeed;
  }

  Future<double?> confirmTerrain(WidgetTester tester, {bool? dragLeft}) async {
    double? gotTerrainVariation;
    await pumpNewGameLeaderSelectionDialog(
      tester,
      onConfirmed: (_, _, _, _, terrainVariation, __, ___) =>
          gotTerrainVariation = terrainVariation,
    );
    if (dragLeft != null) {
      await tapSliderEdge(tester, left: dragLeft);
    }
    await ensureTapNewGameLeaderSelectionStart(tester);
    return gotTerrainVariation;
  }

  Future<AdvancedStartType?> confirmAdvancedStart(
    WidgetTester tester, {
    Size surfaceSize = const Size(800, 1300),
    GameSetupConfig? baseConfig,
    Future<void> Function(WidgetTester tester)? beforeStart,
  }) async {
    AdvancedStartType? gotAdvancedStart;
    await pumpNewGameLeaderSelectionDialog(
      tester,
      surfaceSize: surfaceSize,
      baseConfig: baseConfig,
      onConfirmed: (_, _, _, _, _, __, advancedStart) =>
          gotAdvancedStart = advancedStart,
    );
    if (beforeStart != null) {
      await beforeStart(tester);
    }
    await ensureTapNewGameLeaderSelectionStart(tester);
    return gotAdvancedStart;
  }

  group('parseSeedInput', () {
    test('empty and invalid map to 42', () {
      expect(NewGameLeaderSelectionDialog.parseSeedInput(''), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('   '), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('abc'), 42);
      expect(NewGameLeaderSelectionDialog.parseSeedInput('-3'), 42);
    });

    test('accepts non-negative integers', () {
      expect(NewGameLeaderSelectionDialog.parseSeedInput('0'), 0);
      expect(NewGameLeaderSelectionDialog.parseSeedInput(' 99 '), 99);
    });
  });

  group('NewGameLeaderSelectionDialog', () {
    testWidgets('shows six GP colour swatches and default nation labels', (
      WidgetTester tester,
    ) async {
      await pumpNewGameLeaderSelectionDialog(tester);

      expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
      expect(find.text('England'), findsWidgets);
      // Mockup slot labels: "Slot N" with an uppercase "YOU" tag on slot 0.
      expectDialogChromeTexts(const [
        'Choose nations and leaders',
        'Choose six great powers and a leader variant for each',
        'Slot 1',
        'YOU',
        'Slot 2',
        'Slot 6',
        'Game seed',
        'Enter 0 for a random seed',
        'Infinite mode (no victory condition)',
      ]);
      // Infinite mode uses the pixel-art CtToggleSwitch, not Material chrome.
      expect(find.byType(CtToggleSwitch), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets(
      'CtDialogShell frame is pinned to the mockup-authoritative 540 dp width',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(tester);

        // SPEC/ui/new-game-leader-selection-dialog.md § Dialog frame width:
        // the dialog frame is pinned to the refreshed mockup
        // `.dialog-shell{max-width:540px}` (Refs #3506/#3507 D1). This guards
        // against regressing to the stale 480 dp figure in the original
        // D1 text — the mockup is the visual source of truth.
        final shell = tester.widget<CtDialogShell>(find.byType(CtDialogShell));
        expect(shell.maxWidth, 540);
        expect(shell.maxHeight, 720);
      },
    );

    testWidgets(
      'large viewport: six slots visible; single shell vertical scroll only',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(
          tester,
          surfaceSize: _largeViewport,
        );
        await tester.pumpAndSettle();

        final shell = find.byType(CtDialogShell);
        expect(
          find.descendant(of: shell, matching: find.byType(CustomScrollView)),
          findsOneWidget,
        );

        final viewHeight = tester.view.physicalSize.height;
        final player6Top = tester.getRect(find.text('Slot 6')).top;
        final startTop = tester.getRect(find.text('Start')).top;
        expect(player6Top, greaterThan(0));
        expect(player6Top, lessThan(viewHeight));
        expect(startTop, greaterThan(player6Top));
        expect(startTop, lessThan(viewHeight));
      },
    );

    testWidgets('narrow viewport: shell scroll reaches Start', (
      WidgetTester tester,
    ) async {
      await pumpNewGameLeaderSelectionDialog(
        tester,
        surfaceSize: const Size(520, 420),
      );
      await tester.pumpAndSettle();

      final scrollable = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.byType(Scrollable),
      );
      await tester.dragUntilVisible(
        find.text('Start'),
        scrollable,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start'));
      expect(tester.getRect(find.text('Start')).top, greaterThanOrEqualTo(0));
    });

    testWidgets('Start passes default ordered Great Power ids and leader map', (
      WidgetTester tester,
    ) async {
      List<String>? gotIds;
      Map<String, String>? gotLeaders;
      int? gotSeed;
      bool? gotInfiniteMode;

      await pumpNewGameLeaderSelectionDialog(
        tester,
        onConfirmed: (ids, leaders, seed, infiniteMode, _, __, ___) {
          gotIds = ids;
          gotLeaders = leaders;
          gotSeed = seed;
          gotInfiniteMode = infiniteMode;
        },
      );

      await ensureTapNewGameLeaderSelectionStart(tester);

      expect(gotIds, GameSetupConfig.defaultConfig.selectedGreatPowerIds);
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!.length, 6);
      expect(gotLeaders!['england'], 'queen_victoria');
      expect(gotSeed, 42);
      expect(gotInfiniteMode, isFalse);
    });

    testWidgets('AI slots show profile dropdown when blessed names exist', (
      WidgetTester tester,
    ) async {
      Map<String, String?>? gotProfiles;
      await pumpNewGameLeaderSelectionDialog(
        tester,
        surfaceSize: _largeViewport,
        blessedProfileNames: const ['aggressive_v2'],
        onConfirmed: (_, _, _, _, _, profiles, __) => gotProfiles = profiles,
      );
      expect(find.byType(CtDropdown<String>), findsNWidgets(17));
      await ensureTapNewGameLeaderSelectionStart(tester);
      expect(gotProfiles, isEmpty);
    });

    testWidgets('selecting blessed profile forwards aiProfileByGpId', (
      WidgetTester tester,
    ) async {
      Map<String, String?>? gotProfiles;
      await pumpNewGameLeaderSelectionDialog(
        tester,
        surfaceSize: _largeViewport,
        blessedProfileNames: const ['aggressive_v2'],
        onConfirmed: (_, _, _, _, _, profiles, __) => gotProfiles = profiles,
      );
      final profileDropdowns = find.widgetWithText(
        CtDropdown<String>,
        'Normal',
      );
      await tester.tap(profileDropdowns.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('aggressive_v2').last);
      await tester.pumpAndSettle();
      await ensureTapNewGameLeaderSelectionStart(tester);
      expect(gotProfiles?.values, contains('aggressive_v2'));
    });

    testWidgets('Cancel closes dialog without calling onConfirmed', (
      WidgetTester tester,
    ) async {
      var confirmed = false;
      await pumpNewGameLeaderSelectionDialog(
        tester,
        onConfirmed: (_, _, _, _, _, _, _) {
          confirmed = true;
        },
      );

      await ensureTapNewGameLeaderSelectionCancel(tester);

      expect(confirmed, isFalse);
      expect(find.text('Choose nations and leaders'), findsNothing);
    });

    testWidgets('changing slot 1 nation to Sweden updates order and leader', (
      WidgetTester tester,
    ) async {
      List<String>? gotIds;
      Map<String, String>? gotLeaders;

      await pumpNewGameLeaderSelectionDialog(
        tester,
        onConfirmed: (ids, leaders, _, _, _, __, ___) {
          gotIds = ids;
          gotLeaders = leaders;
        },
      );

      await tester.tap(find.text('England'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sweden'));
      await tester.pumpAndSettle();

      await ensureTapNewGameLeaderSelectionStart(tester);

      expect(gotIds, isNotNull);
      expect(gotIds!.first, 'sweden');
      expect(gotLeaders, isNotNull);
      expect(gotLeaders!['sweden'], 'gustavus');
    });

    testWidgets('Start passes seed 0 when field is 0', (
      WidgetTester tester,
    ) async {
      expect(await confirmWithSeed(tester, '0'), 0);
    });

    testWidgets('Start uses 42 when field is cleared', (
      WidgetTester tester,
    ) async {
      expect(await confirmWithSeed(tester, ''), 42);
    });

    testWidgets('Start passes infiniteMode true when toggle switched on', (
      WidgetTester tester,
    ) async {
      bool? gotInfiniteMode;
      await pumpNewGameLeaderSelectionDialog(
        tester,
        onConfirmed: (_, _, _, infiniteMode, _, __, ___) =>
            gotInfiniteMode = infiniteMode,
      );
      final toggle = find.byType(CtToggleSwitch);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await ensureTapNewGameLeaderSelectionStart(tester);
      expect(gotInfiniteMode, isTrue);
    });

    group('Advanced start selector (Refs #3895)', () {
      testWidgets('default Start emits AdvancedStartType.none', (
        WidgetTester tester,
      ) async {
        final got = await confirmAdvancedStart(
          tester,
          beforeStart: (t) async {
            expect(find.text('Advanced start'), findsOneWidget);
            expect(find.text('None (Turn 0)'), findsOneWidget);
          },
        );
        expect(got, AdvancedStartType.none);
      });

      testWidgets('selecting 50 Turns In forwards AdvancedStartType.turns50', (
        WidgetTester tester,
      ) async {
        final got = await confirmAdvancedStart(
          tester,
          beforeStart: (t) async {
            final advancedDropdown = find.widgetWithText(
              CtDropdown<AdvancedStartType>,
              'None (Turn 0)',
            );
            await t.ensureVisible(advancedDropdown);
            await t.pumpAndSettle();
            await t.tap(advancedDropdown);
            await t.pumpAndSettle();
            await t.tap(find.text('50 Turns In (1598)').last);
            await t.pumpAndSettle();
          },
        );
        expect(got, AdvancedStartType.turns50);
      });

      testWidgets(
        'non-locked profile shows disabled helper and Start emits none',
        (WidgetTester tester) async {
          final got = await confirmAdvancedStart(
            tester,
            surfaceSize: _largeViewport,
            baseConfig: GameSetupConfig(
              numProvincesOldWorld: 24,
              numProvincesNewWorld: 12,
            ),
            beforeStart: (t) async {
              expect(
                find.text(
                  'Advanced start requires the standard six-power campaign '
                  'profile.',
                ),
                findsOneWidget,
              );
            },
          );
          expect(got, AdvancedStartType.none);
        },
      );
    });

    testWidgets(
      'shows terrain variation slider with default helper and label',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        expect(find.byType(CtSlider), findsOneWidget);
        expect(find.text('Terrain variation:'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('0% flat — 100% extreme'), findsOneWidget);
      },
    );

    testWidgets(
      'Start passes default terrainVariation 0.5 when slider not moved',
      (WidgetTester tester) async {
        expect(await confirmTerrain(tester), closeTo(0.5, 1e-9));
      },
    );

    testWidgets(
      'Start passes terrainVariation 0.0 after dragging slider to leftmost',
      (WidgetTester tester) async {
        expect(
          await confirmTerrain(tester, dragLeft: true),
          closeTo(0.0, 1e-6),
        );
      },
    );

    testWidgets(
      'Start passes terrainVariation 1.0 after dragging slider to rightmost',
      (WidgetTester tester) async {
        expect(
          await confirmTerrain(tester, dragLeft: false),
          closeTo(1.0, 1e-6),
        );
      },
    );

    // Duplicate slot validation feedback contract (#2867 R19).
    group('Duplicate slot validation feedback (#2867 R19)', () {
      bool hasDangerBorder(WidgetTester tester, int slotIndex) {
        final finder = find.byKey(
          ValueKey<String>(
            NewGameLeaderSelectionDialog.duplicateSlotBorderKey(slotIndex),
          ),
        );
        if (finder.evaluate().isEmpty) return false;
        final DecoratedBox box = tester.widget<DecoratedBox>(finder);
        final BoxDecoration decoration = box.decoration as BoxDecoration;
        final BoxBorder? border = decoration.border;
        if (border is! Border) return false;
        return border.top.color == EditorialMonoclePalette.danger &&
            border.top.width ==
                NewGameLeaderSelectionDialog.duplicateSlotBorderWidth;
      }

      testWidgets(
        'positive: two slots sharing England wrap both nation dropdowns in '
        '1 dp --danger DecoratedBox and Start stays disabled',
        (WidgetTester tester) async {
          await pumpDuplicateEngland(tester);

          expect(hasDangerBorder(tester, 0), isTrue);
          expect(hasDangerBorder(tester, 5), isTrue);
          for (final i in const [1, 2, 3, 4]) {
            expect(hasDangerBorder(tester, i), isFalse);
          }

          await tester.ensureVisible(find.text('Start'));
          await tester.pumpAndSettle();
          expect(startButton(tester).enabled, isFalse);
        },
      );

      testWidgets('negative: default config (six unique nations) mounts no '
          'danger-border wrapper under any slot', (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(
          tester,
          baseConfig: GameSetupConfig.defaultConfig,
          surfaceSize: _duplicateSurface,
        );

        for (var i = 0; i < 6; i++) {
          expect(
            keyed(NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i)),
            findsNothing,
          );
        }
      });

      testWidgets(
        'recovery: replacing the duplicate nation unmounts the wrapper and '
        're-enables Start',
        (WidgetTester tester) async {
          await pumpDuplicateEngland(tester);

          expect(hasDangerBorder(tester, 0), isTrue);
          expect(hasDangerBorder(tester, 5), isTrue);

          final slot5Dropdown = find.descendant(
            of: keyed(NewGameLeaderSelectionDialog.duplicateSlotBorderKey(5)),
            matching: find.byType(CtDropdown<String>),
          );
          await tester.ensureVisible(slot5Dropdown);
          await tester.pumpAndSettle();
          await tester.tap(slot5Dropdown);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sweden').last);
          await tester.pumpAndSettle();

          for (var i = 0; i < 6; i++) {
            expect(
              keyed(NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i)),
              findsNothing,
            );
          }
          expect(startButton(tester).enabled, isTrue);
        },
      );
    });

    // Dark editorial-monocle chrome contract (#2867 S6 / R1 / R2 / R21).
    group('Dark editorial-monocle chrome (#2867 S6)', () {
      testWidgets(
        'title resolves --accent color and letterSpacing == fontSize * 0.05',
        (WidgetTester tester) async {
          await pumpNewGameLeaderSelectionDialog(tester);
          final Text title = keyedText(tester, 'leaderSelectionDialogTitle');
          expect(title.style?.color, EditorialMonoclePalette.accent);
          final double fontSize = title.style?.fontSize ?? 16;
          expect(title.style?.letterSpacing, closeTo(fontSize * 0.05, 1e-9));
        },
      );

      testWidgets('renders exactly one CtBrassDivider keyed below the title', (
        WidgetTester tester,
      ) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        final dividerFinder = keyed('leaderSelectionDialogBrassDivider');
        expect(dividerFinder, findsOneWidget);
        expect(find.byType(CtBrassDivider), findsOneWidget);
        expect(
          tester.getRect(dividerFinder).top,
          greaterThanOrEqualTo(
            tester.getRect(keyed('leaderSelectionDialogTitle')).bottom,
          ),
        );
      });

      testWidgets('intro paints --muted italic body color', (
        WidgetTester tester,
      ) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        final Text intro = keyedText(tester, 'leaderSelectionDialogIntro');
        expect(intro.style?.color, EditorialMonoclePalette.muted);
        expect(intro.style?.fontStyle, FontStyle.italic);
      });

      testWidgets('title does NOT use the raw textTheme.titleMedium color '
          '(regression guard against unstyled headings)', (
        WidgetTester tester,
      ) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        final Text title = keyedText(tester, 'leaderSelectionDialogTitle');
        expect(
          title.style?.color,
          isNot(equals(AppThemes.colonial.textTheme.titleMedium?.color)),
        );
      });
    });
  });
}
