import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('parseSeedInput', () {
    test('maps empty/invalid to 42; accepts non-negative integers', () {
      for (final input in ['', '   ', 'abc', '-3']) {
        expect(NewGameLeaderSelectionDialog.parseSeedInput(input), 42);
      }
      expect(NewGameLeaderSelectionDialog.parseSeedInput('0'), 0);
      expect(NewGameLeaderSelectionDialog.parseSeedInput(' 99 '), 99);
    });
  });

  group('NewGameLeaderSelectionDialog', () {
    testWidgets(
      'shows six GP swatches, shell chrome, seed/infinite, and terrain slider',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(tester);

        expect(find.byType(GpDefaultMapColorSwatch), findsNWidgets(6));
        expect(find.text('England'), findsWidgets);
        expectNewGameLeaderDialogChromeTexts(const [
          'Choose nations and leaders',
          'Choose six great powers and a leader variant for each',
          'Slot 1',
          'YOU',
          'Slot 2',
          'Slot 6',
          'Game seed',
          'Enter 0 for a random seed',
          'Infinite mode (no victory condition)',
          'Terrain variation:',
          '50%',
          '0% flat — 100% extreme',
        ]);
        expect(find.byType(CtToggleSwitch), findsOneWidget);
        expect(find.byType(CheckboxListTile), findsNothing);
        expect(find.byType(CtSlider), findsOneWidget);
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
          surfaceSize: kNewGameLeaderLargeViewport,
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
        onConfirmed: (ids, leaders, seed, infiniteMode, _, _, _) {
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

    testWidgets(
      'AI profile dropdowns mount for blessed names and forward selected id',
      (WidgetTester tester) async {
        Map<String, String?>? gotProfiles;
        Future<void> pumpBlessed({
          required void Function(Map<String, String?>?) onConfirmed,
        }) {
          return pumpNewGameLeaderSelectionDialog(
            tester,
            surfaceSize: kNewGameLeaderLargeViewport,
            blessedProfileNames: const ['aggressive_v2'],
            onConfirmed: (_, _, _, _, _, profiles, _) => onConfirmed(profiles),
          );
        }

        await pumpBlessed(onConfirmed: (p) => gotProfiles = p);
        expect(find.byType(CtDropdown<String>), findsNWidgets(17));
        await ensureTapNewGameLeaderSelectionStart(tester);
        expect(gotProfiles, isEmpty);

        await pumpBlessed(onConfirmed: (p) => gotProfiles = p);
        await tester.tap(
          find.widgetWithText(CtDropdown<String>, 'Normal').first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('aggressive_v2').last);
        await tester.pumpAndSettle();
        await ensureTapNewGameLeaderSelectionStart(tester);
        expect(gotProfiles?.values, contains('aggressive_v2'));
      },
    );

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
        onConfirmed: (ids, leaders, _, _, _, _, _) {
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

    testWidgets(
      'Start seed field: 0 passes through; cleared falls back to 42',
      (WidgetTester tester) async {
        expect(await confirmNewGameLeaderWithSeed(tester, '0'), 0);
        expect(await confirmNewGameLeaderWithSeed(tester, ''), 42);
      },
    );

    testWidgets('Start passes infiniteMode true when toggle switched on', (
      WidgetTester tester,
    ) async {
      bool? gotInfiniteMode;
      await pumpNewGameLeaderSelectionDialog(
        tester,
        onConfirmed: (_, _, _, infiniteMode, _, _, _) =>
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
        final got = await confirmNewGameLeaderAdvancedStart(
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
        final got = await confirmNewGameLeaderAdvancedStart(
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
          final got = await confirmNewGameLeaderAdvancedStart(
            tester,
            surfaceSize: kNewGameLeaderLargeViewport,
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

    testWidgets('Start passes terrainVariation default and left/right edges', (
      WidgetTester tester,
    ) async {
      for (final case_ in <({bool? dragLeft, double want})>[
        (dragLeft: null, want: 0.5),
        (dragLeft: true, want: 0.0),
        (dragLeft: false, want: 1.0),
      ]) {
        expect(
          await confirmNewGameLeaderTerrain(tester, dragLeft: case_.dragLeft),
          closeTo(case_.want, case_.dragLeft == null ? 1e-9 : 1e-6),
        );
      }
    });

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
          await pumpNewGameLeaderDuplicateEngland(tester);

          expect(hasDangerBorder(tester, 0), isTrue);
          expect(hasDangerBorder(tester, 5), isTrue);
          for (final i in const [1, 2, 3, 4]) {
            expect(hasDangerBorder(tester, i), isFalse);
          }

          await tester.ensureVisible(find.text('Start'));
          await tester.pumpAndSettle();
          expect(newGameLeaderStartButton(tester).enabled, isFalse);
        },
      );

      testWidgets('negative: default config (six unique nations) mounts no '
          'danger-border wrapper under any slot', (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(
          tester,
          baseConfig: GameSetupConfig.defaultConfig,
          surfaceSize: kNewGameLeaderDuplicateSurface,
        );

        for (var i = 0; i < 6; i++) {
          expect(
            newGameLeaderKeyedFinder(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i),
            ),
            findsNothing,
          );
        }
      });

      testWidgets(
        'recovery: replacing the duplicate nation unmounts the wrapper and '
        're-enables Start',
        (WidgetTester tester) async {
          await pumpNewGameLeaderDuplicateEngland(tester);

          expect(hasDangerBorder(tester, 0), isTrue);
          expect(hasDangerBorder(tester, 5), isTrue);

          final slot5Dropdown = find.descendant(
            of: newGameLeaderKeyedFinder(
              NewGameLeaderSelectionDialog.duplicateSlotBorderKey(5),
            ),
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
              newGameLeaderKeyedFinder(
                NewGameLeaderSelectionDialog.duplicateSlotBorderKey(i),
              ),
              findsNothing,
            );
          }
          expect(newGameLeaderStartButton(tester).enabled, isTrue);
        },
      );
    });
  });
}
