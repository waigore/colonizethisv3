import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
          'Infinite mode',
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

    testWidgets(
      'Infinite mode helper is truthful with toggle off (Refs #4641)',
      (WidgetTester tester) async {
        await pumpNewGameLeaderSelectionDialog(tester);
        expect(find.text('Infinite mode'), findsOneWidget);
        expect(
          find.text(
            'Skips the year-1800 calendar stop. Owning 31 or more Old World '
            'provinces still ends the campaign. You cannot change this after '
            'Start.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('no victory condition'), findsNothing);
        expect(
          find.textContaining('The game will continue indefinitely'),
          findsNothing,
        );
      },
    );
  });
}
