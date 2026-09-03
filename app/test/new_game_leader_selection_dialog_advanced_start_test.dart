// Advanced start selector and terrain-variation payload ACs
// (Refs #3895 / #4720 Slice G).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_dropdown.dart';

import 'new_game_leader_selection_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('NewGameLeaderSelectionDialog', () {
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
  });
}
