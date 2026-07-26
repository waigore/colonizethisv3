// SPEC/ui/next-turn-confirmation.md — warning variant for idle civilians.

import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show CivilianMissingWorkOrderEntry;
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const _sampleEntry = CivilianMissingWorkOrderEntry(
  unitId: 'e1',
  type: 'explorer',
  tileKey: 'oldWorld|p1|0|0',
  regionId: 'oldWorld',
  locationLabel: 'Old World — Alpha',
);

void main() {
  suppressLogsForTests();

  Widget hostApp({required List<CivilianMissingWorkOrderEntry> entries}) {
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(
        body: Center(
          child: NextTurnConfirmationDialog(
            currentTurn: 5,
            civiliansMissingWork: entries,
          ),
        ),
      ),
    );
  }

  testWidgets('warning variant lists civilians and dont-show toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(hostApp(entries: const [_sampleEntry]));
    await tester.pumpAndSettle();

    expect(
      find.text('These civilians have no work order for the next turn:'),
      findsOneWidget,
    );
    expect(find.text('explorer'), findsOneWidget);
    expect(find.text('No work order'), findsOneWidget);
    expect(find.byType(CtToggleSwitch), findsOneWidget);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    expect(find.byType(CtDialogShell), findsOneWidget);
  });

  testWidgets('go-to closes without confirming', (WidgetTester tester) async {
    CivilianMissingWorkOrderEntry? goToTarget;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await showNextTurnConfirmationDialog(
                    context,
                    currentTurn: 2,
                    civiliansMissingWork: const [_sampleEntry],
                    onGoToCivilian: (entry) => goToTarget = entry,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Locate'));
    await tester.pumpAndSettle();

    expect(goToTarget?.unitId, 'e1');
  });

  testWidgets('Yes with dont-show selected returns persist flag', (
    WidgetTester tester,
  ) async {
    NextTurnConfirmationResult? result;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showNextTurnConfirmationDialog(
                    context,
                    currentTurn: 2,
                    civiliansMissingWork: const [_sampleEntry],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CtToggleSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(result?.confirmed, isTrue);
    expect(result?.persistDontShowAgain, isTrue);
  });

  testWidgets('No leaves persistDontShowAgain false when toggle selected', (
    WidgetTester tester,
  ) async {
    NextTurnConfirmationResult? result;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await showNextTurnConfirmationDialog(
                    context,
                    currentTurn: 2,
                    civiliansMissingWork: const [_sampleEntry],
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CtToggleSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(result?.confirmed, isFalse);
    expect(result?.persistDontShowAgain, isFalse);
  });
}
