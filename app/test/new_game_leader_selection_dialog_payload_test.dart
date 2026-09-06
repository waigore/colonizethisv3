// AI profile, infinite mode, and seed payload ACs for NewGameLeaderSelectionDialog.
// Split from new_game_leader_selection_dialog_slots_and_payload_test.dart (#4734 Slice H).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('NewGameLeaderSelectionDialog payload extras', () {
    testWidgets(
      'AI profile dropdowns mount for blessed names and forward selected id',
      (WidgetTester tester) async {
        Map<String, String?>? gotProfiles;

        await pumpNewGameLeaderBlessedProfilesDialog(
          tester,
          onConfirmed: (p) => gotProfiles = p,
        );
        expect(find.byType(CtDropdown<String>), findsNWidgets(17));
        await ensureTapNewGameLeaderSelectionStart(tester);
        expect(gotProfiles, isEmpty);

        await pumpNewGameLeaderBlessedProfilesDialog(
          tester,
          onConfirmed: (p) => gotProfiles = p,
        );
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
        expect(find.text(kNewGameLeaderInfiniteModeHelperText), findsOneWidget);
        expect(find.textContaining('no victory condition'), findsNothing);
        expect(
          find.textContaining('The game will continue indefinitely'),
          findsNothing,
        );
      },
    );
  });
}
