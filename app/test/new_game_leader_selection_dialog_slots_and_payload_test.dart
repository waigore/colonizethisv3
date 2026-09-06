import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/gp_default_map_color_swatch.dart';

import 'new_game_leader_selection_dialog_test_support.dart';
import 'new_game_leader_selection_dialog_test_helpers.dart';

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
        expectNewGameLeaderDialogChromeTexts(kNewGameLeaderDialogChromeTexts);
        expect(find.byType(CtToggleSwitch), findsOneWidget);
        expect(find.byType(CheckboxListTile), findsNothing);
        expect(find.byType(CtSlider), findsOneWidget);
        final shell = tester.widget<CtDialogShell>(find.byType(CtDialogShell));
        expect(shell.maxWidth, 540);
        expect(shell.maxHeight, 720);
      },
    );

    testWidgets('large and narrow viewports lay out dialog chrome', (
      WidgetTester tester,
    ) async {
      for (final size in <Size>[
        kNewGameLeaderLargeViewport,
        const Size(520, 420),
      ]) {
        await pumpNewGameLeaderSelectionDialog(tester, surfaceSize: size);
        await tester.pumpAndSettle();
        expect(find.byType(CtDialogShell), findsOneWidget);
        if (size == kNewGameLeaderLargeViewport) {
          expect(
            find.descendant(
              of: find.byType(CtDialogShell),
              matching: find.byType(CustomScrollView),
            ),
            findsOneWidget,
          );
          expect(tester.getRect(find.text('Slot 6')).top, greaterThan(0));
        } else {
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
        }
        expect(tester.getRect(find.text('Start')).top, greaterThanOrEqualTo(0));
      }
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

    // AI profile, seed, infinite mode: new_game_leader_selection_dialog_payload_test.dart
  });
}
