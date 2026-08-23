// Duplicate-slot validation ACs (Refs #4606 Slice D).
// Host: new_game_leader_selection_dialog_slots_and_payload_test.dart.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

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
}
