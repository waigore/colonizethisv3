// Pin the 320 dp minimum-viewport contract for NextTurnConfirmationDialog
// (Refs #2870 S8/S10, #4352).
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    const currentTurn = 7;
    const dialog = NextTurnConfirmationDialog(currentTurn: currentTurn);
    final content = [find.text('End turn?'), find.text('No'), find.text('Yes')];

    testWidgets('AC (positive) NextTurnConfirmationDialog @ 320×640: no '
        'RenderFlex overflow exception, title + body + No + Yes render '
        '(the end-aligned No + 8 dp gap + Yes row must fit within the '
        '~288 dp CtDialogShell content column)', (WidgetTester tester) async {
      await pinDialogs320At(
        tester,
        dialog,
        size: kDialogs320MinViewport,
        overflowReason:
            'SPEC/ui/mobile-adaptation.md § 7: NextTurnConfirmationDialog '
            'must not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The title + body + end-aligned '
            'No / Yes CtNinePatchButton row from '
            'SPEC/ui/next-turn-confirmation.md must wrap within the '
            '~288 dp CtDialogShell content column.',
        expectFinders: [...content, find.textContaining('Turn 7 will end')],
      );
    });

    testWidgets('Negative control: NextTurnConfirmationDialog @ 1024×768 '
        'also pumps without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await pinDialogs320At(
        tester,
        dialog,
        size: kDialogs320WideRegressionViewport,
        expectFinders: content,
      );
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — NextTurnConfirmationDialog '
      'warning variant @ 320 dp (Refs #4140)', () {
    const severalCivilians = [
      CivilianMissingWorkOrderEntry(
        unitId: 'e1',
        type: 'explorer',
        tileKey: 'oldWorld|p1|0|0',
        regionId: 'oldWorld',
        locationLabel: 'Old World — Alpha Province',
      ),
      CivilianMissingWorkOrderEntry(
        unitId: 'b1',
        type: 'builder',
        tileKey: 'oldWorld|p2|1|0',
        regionId: 'oldWorld',
        locationLabel: 'Old World — Beta Province',
      ),
      CivilianMissingWorkOrderEntry(
        unitId: 's1',
        type: 'spy',
        tileKey: 'newWorld|p3|2|1',
        regionId: 'newWorld',
        locationLabel: 'New World — Gamma Province',
      ),
    ];

    const warningDialog = NextTurnConfirmationDialog(
      currentTurn: 12,
      civiliansMissingWork: severalCivilians,
    );

    testWidgets('AC (positive) warning variant with several civilians @ '
        '320×640: no RenderFlex overflow; Yes/No remain visible', (
      WidgetTester tester,
    ) async {
      await pinDialogs320At(
        tester,
        warningDialog,
        size: kDialogs320MinViewport,
        overflowReason:
            'SPEC/ui/next-turn-confirmation.md + mobile-adaptation § 7: '
            'the idle-civilian warning variant must not overflow horizontally '
            'at kMinViewportWidth (320 dp) when several rows are listed.',
        expectFinders: [
          find.text('End turn?'),
          find.text('No'),
          find.text('Yes'),
          find.text('These civilians have no work order for the next turn:'),
        ],
      );
      expect(find.text('explorer'), findsOneWidget);
      expect(find.text('builder'), findsOneWidget);
      expect(find.text('spy'), findsOneWidget);
    });
  });
}
